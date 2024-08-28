<#
.SYNOPSIS
    Simple Windows Event Filter - Using Get-WindowsUpdateLog creates a Tempory XML, uses a regular expression to extract specific details.

.DESCRIPTION
    This script monitors the Windows Update log file, highlighting different log levels with colours.
    It is similar to the Linux 'tail -F' command.

    By David Gilson
    
    Found LogName using:
    Get-WinEvent -ListLog '*Update*' | Select-Object -Property 'LogName'

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-winevent?view=powershell-7.4 

.PARAMETER TailLines
    The number of lines to display from the end of the log file. Default is 0 so only new lines output.

.PARAMETER Delay
    The delay, in seconds, to wait for the log file to be created if it does not exist. The default is 5 seconds.

.PARAMETER LogLevel
    Display only specific log levels. "All", "Info", "Warning", "Error". Default is "All".

.EXAMPLE
    
#>
param (
    [ValidatePattern("^\d+(,\d+)*$")]
    [string]$EventLevels = "0,1,2,3,4,5",  # Default to levels 1, 2, 3 and 4

    [ValidateRange(1, 100)]
    [int]$EventCount = 10,  # Default to showing the last 10 events

    [int]$Hours = 12 # Number of Hours to show, defaults to 12
)

$MilliSeconds = (60 * 60 * 1000) * $Hours

# Using the FilterXML parameter:
$xmlQuery = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-WindowsUpdateClient/Operational">
    <Select Path="Microsoft-Windows-WindowsUpdateClient/Operational">*[System[(Level=1  or Level=2 or Level=3 or Level=4 or Level=0) and TimeCreated[timediff(@SystemTime) &lt;=$MilliSeconds]]]</Select>
  </Query>
</QueryList>
"@

Write-Debug $xmlQuery
Get-WinEvent -FilterXML $xmlQuery

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
