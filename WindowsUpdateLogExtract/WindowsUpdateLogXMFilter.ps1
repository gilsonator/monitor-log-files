<#
.SYNOPSIS
    Simple Windows Event Filter.

.DESCRIPTION
    This script ouputs the Windows Update log file, highlighting different log levels with colours.

    By David Gilson
    
    Found LogName using:
    Get-WinEvent -ListLog '*Update*' | Select-Object -Property 'LogName'

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-7.4 

.PARAMETER TailLines
    The number of lines to display from the end of the log file. Default is 0 so only new lines output.

.PARAMETER Delay
    The delay, in seconds, to wait for the log file to be created if it does not exist. The default is 5 seconds.

.PARAMETER EventLevels
    Display only specific event levels, seperated by comma. 
    0 (Verbose)     1 (Critical)     2  (Error)     3  (Warning)     4  (Information) 

.EXAMPLE
    
#>
param (
    [ValidateSet(0, 1, 2, 3, 4)]
    [int[]]$EventLevels = (4,5), # -EventLevels (0,1,2,3,4)
    [int]$Hours = 1 # -Hours 12 
)
Clear-Host
$MilliSeconds = 3600000 * $Hours # (60 * 60 * 1000)

# (Level=1 or Level=2 or Level=3)
# $LevelsQuery = $EventLevels | ForEach-Object { "Level=$_ or" } 

$LevelsQuery += ForEach-Object -Begin {
    $count = 0
    $retValue = ""
} -Process {
    $count++

    if ($count -ne $myArray.Count) {
        $retValue += $_
    } else {
        $retValue += "Level="
    }
     #+ ($isLast ? " last" : "")
} -End { $retValue }

Write-Host $LevelsQuery

# I know XML very much - Using the FilterXML parameter:
#$xmlQuery = @"
#<QueryList>
#  <Query Id="0" Path="Microsoft-Windows-WindowsUpdateClient/Operational">
#    <Select Path="Microsoft-Windows-WindowsUpdateClient/Operational">*[System[($LevelsQuery) 
#        and TimeCreated[timediff(@SystemTime) &lt;=$MilliSeconds]]]</Select>
#  </Query>
#</QueryList>
#"@
#
#Write-Debug $xmlQuery
#
#$events = Get-WinEvent -FilterXML $xmlQuery
#
## Write-Host $events.Level
#foreach ($event in $events) {
#    switch ($event.Level) {
#        0 { if (0 -in $EventLevels) { Write-Host "Verbose" -ForegroundColor Gray } }
#        1 { if (1 -in $EventLevels) { Write-Host "Critical" -ForegroundColor Red } }
#        2 { if (2 -in $EventLevels) { Write-Host "Warning" -ForegroundColor Yellow } }
#        3 { if (3 -in $EventLevels) { Write-Host "Log level: 3 (Warning)" -ForegroundColor Yellow } }
#        4 { if (4 -in $EventLevels) { Write-Host "Information" -ForegroundColor Green } }
#        Default { Write-Host "Unknown log level" -ForegroundColor White }
#    }
#}

# DG: Other ways...
# Using the Where-Object cmdlet:

#$PastDate = (Get-Date) - (New-TimeSpan -Hours $HoursDiff)
#Get-WinEvent -LogName 'Microsoft-Windows-WindowsUpdateClient/Operational' 
#    | Where-Object { $_.TimeCreated -ge $PastDate }
    

# Using the FilterHashtable parameter:
# $Yesterday = (Get-Date) - (New-TimeSpan -Day 1)
# Get-WinEvent -FilterHashtable @{ LogName='Windows PowerShell'; Level=3; StartTime=$Yesterday }

# Using the FilterXPath parameter:
# $XPath = '*[System[Level=3 and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]'
# Get-WinEvent -LogName 'WindowsUpdateClient' -FilterXPath $XPath
