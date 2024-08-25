<#
.SYNOPSIS
    Simple CBS Log Monitor - CBS (Component-Based Servicing)

.DESCRIPTION
    This script monitors the CBS log file, highlighting different log levels with colours.
    It is similar to the Linux 'tail -F' command.

    By David Gilson
    
    I created this to help diagnose issues I encountered while updating Windows 11.

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
    [string]$FileName = "$env:SystemRoot\Logs\CBS\CBS.log",
    [int]$TailLines = 0,
    [int]$Delay = 5,
    [ValidateSet("All", "Info", "Warning", "Error")]
    [string]$LogLevel = "All"
)

# Set the debug and verbose preferences to display messages
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

# Initialize the line count
[int]$lineCount = 0

Clear-Host
try {
    # Wait for the file to be created, as Get-Content with -Wait doesn't wait for the file to be created.
    while (-Not (Test-Path $FileName)) {
        Write-Host "Waiting for the file '$FileName' to be created..." -ForegroundColor Yellow
        Start-Sleep -Seconds $Delay
    }

    # Once the file is found, start monitoring it
    Get-Content $FileName -Wait -Tail $TailLines | ForEach-Object {
        $line = $_

        $lineCount++

        # Adding match for hresultmsg:
        # if ($line -match '^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}), (?<level>\w+)\s+(?<component>\w+)\s+(?<message>.+?)( \[HRESULT = (?<hresult>0x[0-9A-Fa-f]+) - (?<hresultmsg>[A-Za-z_]+)\])?$') {
        # Note: Using one Regex pattern gives better performace, one pass, but harder to read.
        # Otherwise can be split into two passes, slight performance impact, but easier to read and debug:
        if ($line -match '^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}), (?<level>\w+)\s+(?<component>\w+)\s+(?<message>.+?)?$') {
            $date = $matches['date']
            $time = $matches['time']
            $level = $matches['level'].Trim()
            $component = $matches['component'].Trim()
            $message = $matches['message'].Trim()

            # Combined:
            # $hresult = $matches['hresult']
            # $hresultmsg = $matches['hresultmsg']

            if ($LogLevel -eq "All" -or $LogLevel -eq $level) {
                # Set color based on log level
                switch ($level) {
                    "Error" { $color = "DarkRed" }
                    "Warning" { $color = "Yellow" }
                    "Info" { $color = "Green" }
                    default { $color = "White" }
                }
                Write-Host "$date $time` " -NoNewline -ForegroundColor DarkGreen
                Write-Host "[$level] >` " -NoNewline -ForegroundColor $color
                Write-Host "$component`: " -NoNewline -ForegroundColor Magenta
                Write-Host "$message"

                # Split second pass of message
                if ($message -match '\[HRESULT = (?<hresult>0x[0-9A-Fa-f]+) - (?<hresultmsg>[A-Za-z_]+)\]$') {
                    $hresult = $matches['hresult']
                    $hresultmsg = $matches['hresultmsg']
            
                    Write-Host "$hresult - $hresultmsg" -ForegroundColor DarkMagenta
                }
            }
        } else {
            # Show line for debugging
            Write-Verbose "Unmatched line: $line"
        }
    }
} catch {
    Write-Host "An error occurred." -ForegroundColor Red
    Write-Verbose "An error occurred: $_"
} finally {
    Write-Host "Script stopped. Total lines processed: $lineCount" -ForegroundColor Cyan
}
