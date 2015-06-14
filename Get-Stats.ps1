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