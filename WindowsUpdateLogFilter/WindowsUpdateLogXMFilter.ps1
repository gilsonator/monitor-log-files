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

.EXAMPLE
    WindowsUpdateLogXMLFilter.ps1 -EventLevels Critical,Error,Warning -Hours 24
    Will search for Critical, Error, or Warning events recorded in the last 24 hours from now.
#>
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Critical", "Error", "Warning", "Information")]
    [string[]]$EventLevels = @("Information"),

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 24)]
    [int]$Hours = 24 # -Hours 24 
)

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

Write-Debug $xmlQuery

try {
    $events = Get-WinEvent -FilterXML $xmlQuery -ErrorAction Stop
    # $events | Format-Table -AutoSize 

    Write-Host "Date`t`t`tLevel`t`tMessage" -ForegroundColor Blue
    foreach ($event in $events) {
        Write-Host $event.TimeCreated -ForegroundColor Green -NoNewline
        Write-Host "`t" -NoNewline
        Write-Host $event.LevelDisplayName -ForegroundColor Yellow -NoNewline
        Write-Host "`t" -NoNewline
        Write-Host $event.Message -ForegroundColor White
    }
}
catch {
    
    $formattedNumber = "{0:N0}" -f $Hours
    # Modified from this...
    <# 
    $formattedString = "No Windows Update Events ($($EventLevels -join ', ')) recorded in the past "
    if ($Hours -gt 1) { 
       $formattedString += $formattedNumber + " hours." 
    } else { 
       $formattedString += $formattedNumber + " hour." 
    }
    Write-Host $formattedString -ForegroundColor Yellow 
    Write-Host ""
    #>
    # To this: to combine in one line, Which is better? I feel the above is easier to read, and debug
    
    Write-Host -ForegroundColor Yellow @"
No Windows Update Events ($($EventLevels -join ', ')) returned in the past $formattedNumber $($Hours -gt 1 ? "hours." : "hour." )

"@
}

# DG: Other ways, not complete...
# Using the Where-Object cmdlet:

# $PastDate = (Get-Date) - (New-TimeSpan -Hours $HoursDiff)
# Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' 
#    | Where-Object { $_.TimeCreated -ge $PastDate }

# Using the FilterHashtable parameter:
# $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
# Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-WindowsUpdateClient/Operational'; Level=3; StartTime=$Yesterday }

# Using the FilterXPath parameter:
# $XPath = '*[System[Level=3 and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]'
# Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' -FilterXPath $XPath
