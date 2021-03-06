function Add-UsersToTeam {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG,

    [Parameter(Mandatory = $true)]
    [string]
    $TeamName,

    [Parameter(Mandatory = $false)]
    [string[]]
    $ExcludeUsersBelongingTo = @()
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  if ([string]::IsNullOrEmpty($TeamName))
    { throw "A team name must be supplied"}

  Get-GitHubTeams $Organization | Out-Null
  $teams = $global:GITHUB_API_OUTPUT

  $teamsToExclude = @()
  $teamsToExclude += $TeamName
  $ExcludeUsersBelongingTo | % { $teamsToExclude += $_ }
  $teamsToExclude = $teamsToExclude | Sort-Object -Unique

  $membersToExclude = @()
  $teams | ? { $_.Team.Name -in $teamsToExclude } | % { $membersToExclude += ($_.Members | Select-Object -ExpandProperty login) }

  $otherMembers = @()
  $teams |  ? { $_.Team.Name -ne $TeamName } | % { $otherMembers += ($_.Members | Select-Object -ExpandProperty login) }

  $uniqueMembersToAdd = $otherMembers | Sort-Object -Unique | ? { $membersToExclude -notcontains $_ }
  if ($uniqueMembersToAdd)
    { Add-GitHubTeamMembership -Organization $Organization -TeamName $TeamName -UserNames $uniqueMembersToAdd }
}

function Add-ReposToTeam {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG,

    [Parameter(Mandatory = $true)]
    [string]
    $TeamName,
    
    [Parameter(Mandatory = $false)]
    [string]
    $Permission = 'none',

    [Parameter(Mandatory = $false)]
    [string[]]
    $ExcludeReposOwnedBy = @()
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  if ([string]::IsNullOrEmpty($TeamName))
    { throw "A team name must be supplied"}

  Get-GitHubTeamRepos -Organization $Organization -TeamName $TeamName | Out-Null
  $teamRepos = $global:GITHUB_API_OUTPUT | ? { -not $_.Fork } | % { $_.Name }

  $reposToExclude = @()
  $ExcludeReposOwnedBy |
    % {
      Get-GitHubTeamRepos -Organization $Organization -TeamName $_ | Out-Null
      $reposToExclude += $global:GITHUB_API_OUTPUT | ? { -not $_.Fork } | % { $_.Name }
    }

  $reposNotToBeAdded = ($teamRepos + $reposToExclude) | Sort-Object -Unique

  Get-GitHubRepositories -ForOrganization -Organization $Organization | Out-Null
  $global:GITHUB_API_OUTPUT |
    ? { -not $_.Fork -and $($_.owner.login) -eq $Organization -and $reposNotToBeAdded -notcontains $_.Name } |
    % { Add-GitHubTeamRepo -Organization $Organization -TeamName $TeamName -Permission $Permission -RepoName $_.Name }
}