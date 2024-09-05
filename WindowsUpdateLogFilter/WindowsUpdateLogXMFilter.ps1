<#
.SYNOPSIS
    Simple Windows Event Filter.

.DESCRIPTION
    This script outputs any events recorded in Windows Events, highlighting different log levels with colors.

    By David Gilson

.NOTES    
    I found the LogName using:
    Get-WinEvent -ListLog '*Update*' | Select-Object -Property 'LogName'

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-7.4 

.PARAMETER EventLevels
    Display only specific event levels, separated by commas. Defaults to ("Information").
    "Verbose", "Critical", "Error", "Warning", "Information"

.PARAMETER Hours
    Display only specific events in the last number of hours from now. Defaults to the last 24 hours.

.PARAMETER ExportCSVPath
    Create a .csv file based on date/time, instead of outputting. Defaults to users temp folder

.EXAMPLE
    WindowsUpdateLogXMLFilter.ps1 -EventLevels Critical,Error,Warning -Hours 24
    Will search for Critical, Error, or Warning events recorded in the last 24 hours from now.
#>
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Critical", "Error", "Warning", "Information")]
    [string[]]$EventLevels = @("Information"),

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 72)]
    [int]$Hours = 24, # -Hours 24 

    [Parameter(Mandatory=$false)]
    [bool]$ExportCSV = $false,

    [Parameter(Mandatory=$false)]
    $ExportCSVPath = $env:Temp
)

if ($ExportCSV) {
    # Resolve the ExportCSVPath path relative to the script's directory
    if ([System.IO.Path]::IsPathRooted($ExportCSVPath)) {
        $exportCSVPath = $ExportCSVPath
    } else {
        $exportCSVPath = Join-Path -Path $PSScriptRoot -ChildPath $ExportCSVPath
    }

    $DateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportCSVPath += "\WindowsUpdateLogExport_$DateTime.csv"
    
}

# Clear-Host
# $ErrorActionPreference = "Stop"

$stringBuilder = New-Object System.Text.StringBuilder

# Map levels to their corresponding values
$levelMap = @{
    "Verbose" = 0
    "Critical" = 1
    "Error" = 2
    "Warning" = 3
    "Information" = 4
}

# Iterate through the EventLevels array
foreach ($Level in $EventLevels) {
    $stringBuilder.Append("Level=$($levelMap[$Level]) or ") | Out-Null
}

# Remove any trailing spaces, ‘o’, or ‘r’ characters from the end of the string. 
# This is useful when you want to ensure that the exact sequence " or " is removed from the end of the string.
$LevelsQuery = $stringBuilder.ToString().TrimEnd(" or ".ToCharArray())

Write-Debug $LevelsQuery

$MilliSeconds = 3600000 * $Hours # (60 * 60 * 1000)

# I know XML very well - So I decided to use the FilterXML parameter:
$xmlQuery = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-WindowsUpdateClient/Operational">
    <Select Path="Microsoft-Windows-WindowsUpdateClient/Operational">*[System[($LevelsQuery) 
        and TimeCreated[timediff(@SystemTime) &lt;=$MilliSeconds]]]</Select>
  </Query>
</QueryList>
"@

$events = Get-WinEvent -FilterXML $xmlQuery -ErrorAction Stop
# Another way in XML, is using the FilterXPath parameter:
# NOTE: The timediff function works within the XML query format used by Get-WinEvent -FilterXML. 
#       The -FilterXPath parameter has limitations and doesn’t support all XPath functions, 
#       which is why the timediff function doesn’t work:
# $XPath = "*[System[($LevelsQuery) and TimeCreated[timediff(@SystemTime) &lt;=$MilliSeconds]]]"
# $events = Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' -FilterXPath $XPath

if ($ExportCSV) {
    $filteredEvents = @()
} else {
    Write-Host "Date`t`t`tLevel`t`tMessage`t`tDetails" -ForegroundColor Blue 
}

if ($events.Count -eq 0) {
    Write-Host  "No Windows Update Events ($($EventLevels -join ', '))" `
                "returned in the past $($Hours -gt 1 ? "{0:N0} hours" -f $Hours : "hour")" -ForegroundColor Yellow
} else {
    foreach ($event in $events) {
        if ($ExportCSV) {
            $filteredEvent  = [PSCustomObject]@{
                TimeCreated = $event.TimeCreated
                Level       = $event.LevelDisplayName
                Message     = $event.Message
                Data        = if ($event.Opcode -eq 12) { $event.Properties[0].Value }
            }
            # Add the filtered event to the array
            $filteredEvents += $filteredEvent
        } else { # Write to host
            Write-Host $event.TimeCreated -ForegroundColor Green -NoNewline
            Write-Host "`t" -NoNewline
            Write-Host $event.LevelDisplayName -ForegroundColor Yellow -NoNewline
            Write-Host "`t" -NoNewline
            Write-Host $event.Message -ForegroundColor White -NoNewline
            # For downloads, show package
            Write-Host "`t" -NoNewline
            Write-Host ($event.Opcode -eq 12 ? $event.Properties[0].Value : "") -ForegroundColor Magenta
        }
    }

    # Export csv..
    if ($ExportCSV) {
        $filteredEvents | Export-Csv -Path $exportCSVPath
        Write-Host $events.Count "Windows Update Events ($($EventLevels -join ', ')) exported to" $exportCSVPath `
            -ForegroundColor Yellow
    }
}

# DG NOTES: There are other ways to accomplish this, refer to above link:
#
# Not Completed:
# Using the Where-Object cmdlet:
# $PastDate = (Get-Date) - (New-TimeSpan -Hours $HoursDiff)
# Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' 
#    | Where-Object { $_.TimeCreated -ge $PastDate }

# Using the FilterHashtable parameter:
# $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
# Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-WindowsUpdateClient/Operational'; Level=3; StartTime=$Yesterday }

