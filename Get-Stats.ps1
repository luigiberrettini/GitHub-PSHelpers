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