<#
.SYNOPSIS
    Simple Windows Event Filter.

.DESCRIPTION
    This script outputs any events recorded in Windows Events, highlighting different log levels with colors, sorts by TimeCreated

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
    Display only specific events in the last number of hours from now. Defaults to the last 24 hours. Max is one week, 168 hours.

.PARAMETER ExportCSV
    Export results to comma seperated file (.csv)
    If no ExportCSVPath is specified, defaults to users temp folder. Example:
    C:\Users\username\AppData\Local\Temp\WindowsUpdateLogExport_20241103_180323.csv

.PARAMETER ExportCSVPath
    Create a .csv file based on date/time, instead of outputting. Defaults to users temp folder

.PARAMETER Pause
    Pause output after filling the console window. Defaults to $false

.EXAMPLE
    WindowsUpdateLogXMLFilter.ps1 -EventLevels Critical,Error,Warning -Hours 24
    Will search for Critical, Error, or Warning events recorded in the last 24 hours from now.
#>
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Verbose", "Critical", "Error", "Warning", "Information")]
    [string[]]$EventLevels = @("Information"),

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 168)]
    [int]$Hours = 24, # -Hours 24 

    [Parameter(Mandatory=$false)]
    $ExportCSV,

    # [Parameter(Mandatory=$false)]
    # $ExportCSVPath = $env:Temp,

    # Pause on console height
    [Parameter(Mandatory=$false)]
    [switch]$Pause
)

if ($ExportCSV) {
    if ($ExportCSV.Length -eq 0) { $ExportCSVPath = $env:Temp}
    # Resolve the ExportCSVPath path relative to the script's directory
    if ([System.IO.Path]::IsPathRooted($ExportCSVPath)) {
        $exportCSVPath = $ExportCSVPath
    } else {
        $exportCSVPath = Join-Path -Path $PSScriptRoot -ChildPath $ExportCSVPath
    }

    $DateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $exportCSVPath += "\WindowsUpdateLogExport_$DateTime.csv"
}

$title = 'Windows Update Log XML Filter'
Write-Host "$([char]0x1B)]0;$title$([char]0x7)"
Clear-Host

try {
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

    if ($events.Count -eq 0) {
        Write-Host  "No Windows Update Events ($($EventLevels -join ', '))" `
        "returned in the past $($Hours -gt 1 ? "{0:N0} hours" -f $Hours : "hour")" -ForegroundColor Yellow
    } else {
        if ($ExportCSV) {
            $filteredEvents = @()
        } else {
            Write-Host "Date`t`t`tLevel`t`tMessage`t`t`t`tDetails" -ForegroundColor Blue 
        }

        $sortedEvents = $events | Sort-Object -Property TimeCreated

        # Initialize the line count
        [int]$lineCount = 0
        [int]$lineOuputCount = 0
        
        foreach ($event in $sortedEvents) {
            $lineCount++
            $data = $event.Opcode -eq 12 ? $event.Properties[0].Value : ""

            if ($ExportCSV) {
                $filteredEvent  = [PSCustomObject]@{
                    TimeCreated = $event.TimeCreated
                    Level       = $event.LevelDisplayName
                    Message     = $event.Message
                    Data        = $data
                }
                # Add the filtered event to the array
                $filteredEvents += $filteredEvent
            } else { # Write to host
                $lineOuputCount++
                $consoleHeight = $Host.UI.RawUI.WindowSize.Height
                
                Write-Debug $consoleHeight","$lineCount
                Write-Host $event.TimeCreated -ForegroundColor Green -NoNewline
                Write-Host "`t" -NoNewline
                Write-Host $event.LevelDisplayName -ForegroundColor Yellow -NoNewline
                Write-Host "`t" -NoNewline
                Write-Host $event.Message -ForegroundColor White -NoNewline
                # For downloads, show package
                Write-Host "`t" -NoNewline
                Write-Host $data -ForegroundColor Magenta
                
                #  Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.421.75.0) - Current Channel (Broad)
                if ($data -match 'KB\d+') {
                    $kbNumber = $matches[0]
                    Write-Debug $kbNumber

                    $searchTerm = "Windows update $kbNumber details"
                    $encodedSearchTerm = [System.Web.HttpUtility]::UrlEncode($searchTerm)
                    $bingSearchUrl = "https://www.bing.com/search?q=$encodedSearchTerm"

                    Write-Host " ($bingSearchUrl)" -ForegroundColor DarkGray
                }
                
                if ($Pause -eq $true -and ($lineOuputCount -gt $consoleHeight -4)) {
                    Read-Host -Prompt "Press Enter to continue..."
                    $lineOuputCount = 0
                }
            }
        }

        # Export csv..
        if ($ExportCSV) {
            $filteredEvents | Export-Csv -Path $exportCSVPath
            Write-Host $events.Count "Windows Update Events ($($EventLevels -join ', ')) exported to" $exportCSVPath `
                -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "An error occurred." -ForegroundColor Red
    Write-Verbose "An error occurred: $_"
} finally {
    Write-Host "Script stopped. Total lines processed: $lineCount" -ForegroundColor Cyan
    $title = '' # Reset title
    Write-Host "$([char]0x1B)]0;$title$([char]0x7)"
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

