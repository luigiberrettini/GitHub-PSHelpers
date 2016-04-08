function Write-NumberOfRepos {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  Get-GitHubRepositories -ForOrganization -Organization $Organization | Out-Null
  $repos = $global:GITHUB_API_OUTPUT | ? { $($_.owner.login) -eq $Organization -and -not $_.Fork }
  Write-Output 'Number of repos' ($repos | Measure-Object).Count
}

function Get-OrgMembers {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  Get-GitHubOrgMembers -Organization $Organization | Out-Null
  $global:GITHUB_API_OUTPUT | ? {$_.Name.Length -ne 0 } | % { Write-Output $_.Name }
}

function Get-NotRecentlyPushedOrgRepos {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG,

    [Parameter(Mandatory = $true)]
    [int]
    $NumberOfMonthsAgo = 6,

    [Parameter(Mandatory = $false)]
    [string[]]
    $ExcludedTeams = @()
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  Get-GitHubTeams | Out-Null
  $orgTeams = $global:GITHUB_API_OUTPUT | % { $_.Team.Name }

  $monthsAgo = [DateTime]::Now.AddMonths(-$numberOfMonthsAgo).ToString("u").Replace(" ", "T")

  $notRecentlyPushedRepos = @()
  $orgTeams |
    ? { $ExcludedTeams -notcontains $_ } |
    % {
      $teamName = $_
      Get-GitHubTeamRepos -Organization YTech -TeamName $teamName | Out-Null
      $notRecentlyPushedTeamRepos = $global:GITHUB_API_OUTPUT |
        ? { $_.pushed_at -le $monthsAgo } |
        % { $_.name }
      $notRecentlyPushedRepos += @{ TeamName = $teamName; RepoNames = $notRecentlyPushedTeamRepos }
    }

  $notRecentlyPushedRepos |
    ? { $_.RepoNames.Length -gt 0 } |
    % { Write-Output $_.TeamName $_.RepoNames '' }
}

function Get-TopCommitter {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $Organization = $Env:GITHUB_ORG
  )

  if ([string]::IsNullOrEmpty($Organization))
    { throw "An organization must be supplied"}

  Get-GitHubRepositories -ForOrganization -Organization $Organization | Out-Null
  $repos = $global:GITHUB_API_OUTPUT | ? { $($_.owner.login) -eq $Organization -and -not $_.Fork } | % { $_.name }
  
  $repoCommitsPerUser = @()
  $repos |
    % { $repoCommitsPerUser += Get-RepoCommitsPerUser -Organization $Organization -RepoName $_ }
  
  $commitsPerUser |
    Group-Object Name |
    Select-Object Name, @{Name="Number of commits"; Expression = { ($_.Group | Measure-Object Count -Sum).Sum  } } |
    Format-Table -AutoSize
}