# EventFunctions.ps1

function Get-FilterXml {
    param (
        [string]$LogPath = "Microsoft-Windows-WindowsUpdateClient/Operational",
        [string]$EventLevels,
        [int]$TimeDiff = 3600000 # Default to last hour in milliseconds
    )

    $eventLevelsFormatted = $EventLevels -replace ",", " or Level="

    return @"
<QueryList>
  <Query Id="0" Path="$LogPath">
    <Select Path="$LogPath">*[System[(Level=$eventLevelsFormatted) 
        and TimeCreated[timediff(@SystemTime) <= $TimeDiff]]]</Select>
  </Query>
</QueryList>
"@
}

function Get-Events {
    param (
        [string]$EventLevels,
        [int]$TimeDiff
    )
    $filterXml = Get-FilterXml -EventLevels $EventLevels
    Write-Output $filterXml
    
    $events = Get-WinEvent -FilterXml $filterXml | Sort-Object TimeCreated -Descending 
    return $events
}
