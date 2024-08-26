<#
.SYNOPSIS
    Simple ETL Log Filter - Using Get-WindowsUpdateLog creates a Tempory XML, uses a regular expression to extract specific details.

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

# Generate the WindowsUpdate.log file
Get-WindowsUpdateLog -LogPath "C:\Path\To\WindowsUpdate.log"

# Stream the contents of the log file
Get-Content -Path "C:\Path\To\WindowsUpdate.log" -Wait

# Define the path to the WindowsUpdate.log file
$logPath = "C:\Path\To\WindowsUpdate.log"

# Define the pattern to filter specific events
$pattern = "Error|Warning|Update"

# Use Select-String to filter the log file
Select-String -Path $logPath -Pattern $pattern | Select-Object -Last 50



# Once the file is found, start monitoring it
Get-Content $FileName -Wait -Tail $TailLines | ForEach-Object {
    $line = $_

    $lineCount++