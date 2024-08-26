<#
.SYNOPSIS
    Simple Windows Update Log Log Filter - Using Get-WindowsUpdateLog creates a Tempory XML, uses a regular expression to extract specific details.

.DESCRIPTION
    This script monitors the CBS log file, highlighting different log levels with colours.
    It is similar to the Linux 'tail -F' command.

    By David Gilson

.LINK
    https://learn.microsoft.com/en-us/powershell/module/windowsupdate/get-windowsupdatelog?view=windowsserver2022-ps

.PARAMETER FileName
    The path to the CBS log file. Default is "$env:SystemRoot\Logs\CBS\CBS.log".

.PARAMETER TailLines
    The number of lines to display from the end of the log file. Default is 0 so only new lines output.

.PARAMETER Delay
    The delay, in seconds, to wait for the log file to be created if it does not exist. The default is 5 seconds.

.PARAMETER LogLevel
    Display only specific log levels. "All", "Info", "Warning", "Error". Default is "All".

.EXAMPLE
    .\Monitor-CBSLog.ps1 -FileName "C:\Windows\Logs\CBS\CBS.log" -TailLines 20 -Delay 2 -Level "Error"

    This example runs the script with a specified log file, displays the last 20 lines of "Error", and sets a delay of 2 seconds between checks.
#>
param (
    [ValidatePattern("^\d+(,\d+)*$")]
    [string]$EventLevels = "1,2,3,4",  # Default to levels 1, 2, 3 and 4

    [ValidateRange(1, 100)]
    [int]$EventCount = 10,  # Default to showing the last 10 events

    [int]$HoursDiffFromNow = 1 # Default to last hour from current time
)

# Import the functions from EventFunctions.ps1
Import-Module .\SharedModules\EventFunctions.psm1

# Continuously monitor and display new events
#while ($true) {
    #Clear-Host  # Clear the console for better readability
    $events = Get-Events -EventCount $EventCount -EventLevels $eventLevelsFormatted -TimeDiff $startTimeDiff 
    foreach ($event in $events) {
        $eventTime = $event.TimeCreated
        $eventId = $event.Id
        $eventMessage = $event.Message
        Write-Output "Time: $eventTime, Event ID: $eventId, Message: $eventMessage"
    }
#   Start-Sleep -Seconds 5  # Adjust the sleep interval as needed
#}
