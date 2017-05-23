function Add-ReposAsSubtrees {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable[]]
    $SourceRepoList,

    [Parameter(Mandatory = $true)]
    [string]
    $BaseFolder,

    [Parameter(Mandatory = $true)]
    [string]
    $TargetRepoUrl,

    [Parameter(Mandatory = $true)]
    [scriptblock]
    $PrepParamsFunc
  )

  if ($SourceRepoList.Length -eq 0 -or [string]::IsNullOrEmpty($BaseFolder) -or [string]::IsNullOrEmpty($TargetRepoUrl)) {
    throw "Source repos, base folder and target repo must be supplied"
  }

  if (!(Test-Path -Path $BaseFolder)) {
    throw "Base folder does not exist"
  }

  $targetRepoName = (Split-Path -Path $TargetRepoUrl -Leaf) -replace '.git', ''
  $TargetRepoPath = Join-Path -Path $BaseFolder -ChildPath $targetRepoName
  
  Push-Location

  Set-Location $BaseFolder

  if (!(Test-Path -Path $TargetRepoPath)) {
    Write-Output "`r`n$TargetRepoUrl"
    git clone $TargetRepoUrl
  }

  Set-Location $TargetRepoPath

  foreach ($sourceRepo in $SourceRepoList) {
    $params = (& $PrepParamsFunc $sourceRepo)
    
    Add-RepoAsSubtree `
      -TargetRepoPath $TargetRepoPath `
      -SourceRemoteName $params.SourceRemoteName `
      -SourceRepoUrl $params.SourceRepoUrl `
      -DestinationPrefix $params.DestinationPrefix
  }

  Pop-Location
}

function Add-RepoAsSubtree {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]
    $TargetRepoPath,

    [Parameter(Mandatory = $true)]
    [string]
    $SourceRemoteName,

    [Parameter(Mandatory = $true)]
    [string]
    $SourceRepoUrl,

    [Parameter(Mandatory = $true)]
    [string]
    $DestinationPrefix
  )
  
  $destination = Join-Path -Path $TargetRepoPath -ChildPath $DestinationPrefix
  
  Write-Output "`r`n**************************************** BEGIN - $SourceRepoUrl"

  Write-Output "`r`n-------------------- Create folder $destination"
  New-Item -Type Directory -Path $destination | Out-Null
  
  Write-Output "`r`n-------------------- git remote add -f $SourceRemoteName $sourceRepoUrl`r`n"
  git remote add -f $SourceRemoteName $SourceRepoUrl
  
  Write-Output "`r`n-------------------- git merge -s ours --no-commit $SourceRemoteName/master`r`n"
  git merge --allow-unrelated-histories -s ours --no-commit $SourceRemoteName/master
  
  Write-Output "`r`n-------------------- git read-tree --prefix=$DestinationPrefix\ -u $SourceRemoteName/master`r`n"
  git read-tree --prefix=$DestinationPrefix/ -u $SourceRemoteName/master
  
  Write-Output "`r`n-------------------- git add . --all AND git commit -m `'Merge $sourceRepoUrl as our subdirectory`'`r`n"
  git add . --all
  git commit -m ("Merge $sourceRepoUrl as our subdirectory")
  
  Write-Output "`r`n-------------------- git pull --no-rebase -s subtree $SourceRemoteName master`r`n"
  git pull --no-rebase -s subtree $SourceRemoteName master
  
  Write-Output "`r`n-------------------- git push origin master`r`n"
  git push origin master
  
  Write-Output "`r`n-------------------- git remote rm $SourceRemoteName`r`n"
  git remote rm $SourceRemoteName
  
  Write-Output "`r`n**************************************** END - $SourceRepoUrl`r`n"
}

# An example of param builder function
function Get-ParamsHash {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]
    $SourceRepo
  )

  $sourceRemoteName = (Split-Path -Path $SourceRepo.Folder -Leaf)
  $sourceRepoUrl = $SourceRepo.Url
  $sourceRepoFolder = $SourceRepo.Folder
  
  return @{
    'SourceRemoteName' = $sourceRemoteName;
    'SourceRepoUrl' = $sourceRepoUrl;
    'DestinationPrefix' = $sourceRepoFolder
  }
}