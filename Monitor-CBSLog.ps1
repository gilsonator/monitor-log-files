<#
.SYNOPSIS
    Simple CBS Log Monitor - CBS (Component-Based Servicing)

.DESCRIPTION
    This script monitors the CBS log file, highlighting different log levels with colours.
    It is similar to the Linux 'tail -F' command.

    By David Gilson

    The Core componentization services include the following:
    CBS (Component Based Servicing)
    CSI (Component Servicing Infrastructure)
    DMI (Driver Management and Install)
    CMI (Component Management Infrastructure)
    SMI (Systems Management Infrastructure)
    KTM (Kernel Transaction Manager)

.LINK
    https://techcommunity.microsoft.com/t5/ask-the-performance-team/understanding-component-based-servicing/ba-p/373012

.PARAMETER FileName
    The path to the CBS log file. Default is "$env:SystemRoot\Logs\CBS\CBS.log".

.PARAMETER TailLines
    The number of lines to display from the end of the log file. Default is 10.

.PARAMETER Delay
    The delay in seconds between each check of the log file. Default is 1 second.

.EXAMPLE
    .\Monitor-CBSLog.ps1 -FileName "C:\Windows\Logs\CBS\CBS.log" -TailLines 20 -Delay 2

    This example runs the script with a specified log file, displays the last 20 lines, and sets a delay of 2 seconds between checks.
#>

param (
    [string]$FileName = "$env:SystemRoot\Logs\CBS\CBS.log",
    [int]$TailLines = 10,
    [int]$Delay = 1
)

# Wait for the file to be created
while (-Not (Test-Path $FileName)) {
    Write-Host "Waiting for the file '$FileName' to be created..." -ForegroundColor Yellow
    Start-Sleep -Seconds $Delay
}

# Once the file is found, start monitoring it
while ($true) {
    Clear-Host
    $lines = Get-Content $FileName -Tail $TailLines
    foreach ($line in $lines) {
        if ($line -match '^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}), (?<level>\w+)\s+(?<component>\w+)\s+(?<message>.+)$') {
            $date = $matches['date']
            $time = $matches['time']
            $level = $matches['level'].Trim()
            $component = $matches['component'].Trim()
            $message = $matches['message']

            # Set color based on log level
            switch ($level) {
                "Error" { $color = "Red" }
                "Warning" { $color = "Yellow" }
                "Info" { $color = "Green" }
                default { $color = "White" }
            }

            Write-Host "$date $time`t" -NoNewline -ForegroundColor Yellow
            Write-Host "$level`t" -NoNewline -ForegroundColor $color
            Write-Host "$component`t" -NoNewline -ForegroundColor Magenta
            Write-Host "$message"
        } else {
            Write-Host $line
        }
    }
    Start-Sleep -Seconds $Delay
}
