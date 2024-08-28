# Helper functions
function Convert-TimeToMilliseconds {
    param (
        [int]$Hours
    )
    return $Hours *  3600000
}

function Format-EventLevelsSQL {
  param (
    [string] $Levels
  )

  return $EventLevels -replace ",", " or Level="
}

# Public functions
function Get-FilterXml {
    param (
        $LogPath,
        [string]$EventLevels,
        $TimeDiff = 3600000 # Default to last hour in milliseconds
    )

 @"
<QueryList>
  <Query Id="0" Path="$LogPath">
    <Select Path="$LogPath">*[System[(Level=$eventLevelsFormatted) and TimeCreated[timediff(@SystemTime) &lt;=$TimeDiff]]]</Select>
  </Query>
</QueryList>
"@
}
