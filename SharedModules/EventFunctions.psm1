# Helper functions

function Get-TimeInMilliseconds {
  [CmdletBinding(DefaultParameterSetName = 'HoursSet')]
  param (
      [Parameter(ParameterSetName = 'HoursSet', Mandatory = $false)]
      [ValidateRange(1, 24)]
      [int]$Hours = 24,

      [Parameter(ParameterSetName = 'DaysSet', Mandatory = $false)]
      [ValidateRange(1, 7)]
      [int]$Days = 1,

      [Parameter(ParameterSetName = 'WeeksSet', Mandatory = $false)]
      [ValidateRange(1, 4)]
      [int]$Weeks = 1
  )

  switch ($PSCmdlet.ParameterSetName) {
      'HoursSet' { $MilliSeconds = 3600000 * $Hours } # (60 * 60 * 1000)
      'DaysSet' { $MilliSeconds = 86400000 * $Days }  # (24 * 60 * 60 * 1000)
      'WeeksSet' { $MilliSeconds = 604800000 * $Weeks } # (7 * 24 * 60 * 60 * 1000)
  }

  Write-Output "Milliseconds: $MilliSeconds"
}

# Usage examples:
# Get-TimeInMilliseconds -Hours 12  # Uses HoursSet
# Get-TimeInMilliseconds -Days 2    # Uses DaysSet
# Get-TimeInMilliseconds -Weeks 1   # Uses WeeksSet

function Get-EventQuery {
  [CmdletBinding(DefaultParameterSetName = 'HoursSet')]
  param (
      [Parameter(ParameterSetName = 'HoursSet', Mandatory = $false)]
      [ValidateRange(1, 24)]
      [int]$Hours = 24,

      [Parameter(ParameterSetName = 'DaysSet', Mandatory = $false)]
      [ValidateRange(1, 7)]
      [int]$Days = 1,

      [Parameter(ParameterSetName = 'WeeksSet', Mandatory = $false)]
      [ValidateRange(1, 4)]
      [int]$Weeks = 1,

      [Parameter(Mandatory = $false)]
      [ValidateSet("Verbose", "Critical", "Error", "Warning", "Information")]
      [string[]]$EventLevels = @("Information")
  )

  switch ($PSCmdlet.ParameterSetName) {
      'HoursSet' { $MilliSeconds = 3600000 * $Hours } # (60 * 60 * 1000)
      'DaysSet' { $MilliSeconds = 86400000 * $Days }  # (24 * 60 * 60 * 1000)
      'WeeksSet' { $MilliSeconds = 604800000 * $Weeks } # (7 * 24 * 60 * 60 * 1000)
  }

  $LevelsQuery = $EventLevels -join " or "

  $xmlQuery = @"
<QueryList>
<Query Id="0" Path="Microsoft-Windows-WindowsUpdateClient/Operational">
  <Select Path="Microsoft-Windows-WindowsUpdateClient/Operational">*[System[($LevelsQuery) 
      and TimeCreated[timediff(@SystemTime) <=$MilliSeconds]]]</Select>
</Query>
</QueryList>
"@

  Write-Output $xmlQuery
}

# Usage examples:
# Get-EventQuery -Hours 12  # Uses HoursSet
# Get-EventQuery -Days 2    # Uses DaysSet
# Get-EventQuery -Weeks 1   # Uses WeeksSet
