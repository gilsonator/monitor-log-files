<#
.SYNOPSIS
    Simple CBS Log Monitor - CBS (Component-Based Servicing).

.DESCRIPTION
    This script monitors the CBS log file, highlighting different log levels with colours.
    It is similar to the Linux 'tail -F' command.
    By David Gilson
    
    I created this to help diagnose issues encountered while updating Windows 11.
    The core componentization services include the following:
    - CBS (Component Based Servicing)
    - CSI (Component Servicing Infrastructure)
    - DMI (Driver Management and Install)
    - CMI (Component Management Infrastructure)
    - SMI (Systems Management Infrastructure)
    - KTM (Kernel Transaction Manager)

.LINK
    https://github.com/gilsonator/monitor-log-files

.LINK
    https://techcommunity.microsoft.com/t5/ask-the-performance-team/understanding-component-based-servicing/ba-p/373012

.LINK
    https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences

.LINK
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-content?view=powershell-7.4#-wait

.PARAMETER FileName
    The path to the CBS log file. Default is "$env:SystemRoot\Logs\CBS\CBS.log".

.PARAMETER TailLines
    The number of lines to display from the end of the log file. Default is 0, so only new lines are output.

.PARAMETER Delay
    The delay, in seconds, to wait for the log file to be created if it does not exist. The default is 5 seconds.

.PARAMETER LogLevel
    Display only specific log levels. Options are "All", "Info", "Warning", "Error". Default is "All".

.PARAMETER Wait
    Wait for changes in the source file. Default is $true.

.PARAMETER Pause
    If Wait is not specified, pause output after filling the console window. Default is $false.

.EXAMPLE
    .\Monitor-CBSLog.ps1 -FileName "C:\Windows\Logs\CBS\CBS.log" -TailLines 20 -Delay 2 -LogLevel "Error"
    This example runs the script with a specified log file, displays the last 20 lines of "Error" level logs, and sets a delay of 2 seconds between checks.
#>

param (
    [string]$FileName = "$env:SystemRoot\Logs\CBS\CBS.log",
    [int]$TailLines = 0,
    [int]$Delay = 5,
    [ValidateSet("All", "Info", "Warning", "Error")]
    [string]$LogLevel = "All",
    [Parameter(Mandatory=$false)]
    [switch]$Wait,
    [Parameter(Mandatory=$false)]
    [switch]$Pause
)

# Set console title
$title = 'Monitor-CBS Logfile'
Write-Host "$([char]0x1B)]0;$title$([char]0x7)"

# Set the debug and verbose preferences to display messages
$DebugPreference = "Continue"
$VerbosePreference = "Continue"

# Initialize the line count
[int]$lineCount = 0
[int]$pauseLines = 0

Clear-Host
try {
    # Wait for the file to be created, as Get-Content with -Wait doesn't wait for the file to be created.
    while (-Not (Test-Path $FileName)) {
        Write-Host "Waiting for the file '$FileName' to be created..." -ForegroundColor Yellow
        Start-Sleep -Seconds $Delay
    }

    # Once the file is found, start monitoring it, if -Wait is present
    # I use Splatting to create a hashtable of parameters and pass -Wait on
    $parameters = @{
        Path = $FileName
        Wait = $Wait
        Tail = $TailLines
    }
    
    Get-Content @parameters | ForEach-Object {
        $line = $_

        $lineCount++
        $pauseLines++
        $consoleHeight = $Host.UI.RawUI.WindowSize.Height

        # Adding match for hresultmsg:
        # Note: Using one Regex pattern gives better performace, one pass, but harder to read.
        # if ($line -match '^(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}), (?<level>\w+)\s+(?<component>\w+)\s+(?<message>.+?)( \[HRESULT = (?<hresult>0x[0-9A-Fa-f]+)( - (?<hresultmsg>[A-Za-z_]+)\]))?$') {
        #
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
                Write-Host "$message" -NoNewline -ForegroundColor White

                # Split second pass of $message. Optional if HRESULT Message is missing:
                if ($message -match '\[HRESULT = (?<hresult>0x[0-9A-Fa-f]+)( - (?<hresultmsg>[A-Za-z_]+))?\]$') {
                    $hresult = $matches['hresult']
                    # $hresultmsg = $matches['hresultmsg']

                    $searchTerm = "HRESULT = $hresult"
                    $encodedSearchTerm = [System.Web.HttpUtility]::UrlEncode($searchTerm)
                    $bingSearchUrl = "https://www.bing.com/search?q=$encodedSearchTerm"

                    if ($hresult -ne "0x00000000") {
                        Write-Host " ($bingSearchUrl)" -NoNewline -ForegroundColor DarkGray
                    }
                }
            }
        } else {
            # Show line for debugging
            Write-Verbose "Unmatched line: $line"
        }
        
        $title = "Monitor-CBS Logfile - ($($lineCount))"
        Write-Host "$([char]0x1B)]0;$title$([char]0x7)"
        
        if ((!$Wait.IsPresent -and $Pause.IsPresent) -and ($pauseLines -gt $consoleHeight - 4)) {
            Read-Host -Prompt "Press Enter to continue..."
            $pauseLines = 0
        }                
    }
} catch {
    Write-Host "An error occurred." -ForegroundColor Red
    Write-Verbose "An error occurred: $_"
} finally {
    Write-Host "Total lines processed: $lineCount" -ForegroundColor Cyan
    $title = '' # Reset title
    Write-Host "$([char]0x1B)]0;$title$([char]0x7)"
}
