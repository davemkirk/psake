function Invoke-PsakeProfileFunction{
[CmdletBinding(DefaultParametersetName="BuildFileAndTaskList")]
param(
  [Parameter(ParameterSetName="TaskListOnly",Position=0,Mandatory=0)]
  [string[]]$taskList2 = @(),  

  [Parameter(ParameterSetName="BuildFileAndTaskList",Position=0,Mandatory=0)]
  [string]$buildFile,
  [Parameter(ParameterSetName="BuildFileAndTaskList",Position=1,Mandatory=0)]
  [string[]]$taskList = @(),
  
  #Named Only Parameters
  [Parameter(Mandatory=0)]
  [string]$framework = '3.5',
  [Parameter(Mandatory=0)]
  [switch]$docs = $false,
  [Parameter(Mandatory=0)]
  [System.Collections.Hashtable]$parameters = @{},
  [Parameter(Mandatory=0)]
  [System.Collections.Hashtable]$properties = @{}
)
 
 switch($PsCmdlet.ParameterSetName)
 {
 "BuildFileAndTaskList"  { 
    if($buildFile -notmatch ".*\.ps1" -and $taskList.Count -eq 0)
    {
      $taskList = @($buildFile)
      $buildFile = $null
    }
  }
   
 "TaskListOnly" {
    $buildFile = $null
    $taskList = $taskList2
  }
}
#write-host ("{0} {1}" -f $buildFile, ($taskList -join ","))
#return

$erroractionpreference = "SilentlyContinue"

$buildFilePath = split-path -parent $(resolve-path $buildFile)
$currentScriptPath = Split-Path -parent $MyInvocation.MyCommand.path
$currentPath = ".\"
$scriptsFolder = ".\scripts"
$searchPaths = @($buildFilePath, $currentScriptPath, $currentPath, $scriptsFolder); 

remove-module psake -ea 'SilentlyContinue'
foreach($path in $searchPaths){ #looking for the path to the psake module to use.
  if(test-path (join-path $path psake.psm1 -ea 'SilentlyContinue') -ea 'SilentlyContinue'){
    $modulePath = $path
    
    break
  }
}

$erroractionpreference = "Continue"

if(-not $modulePath -or -not(test-path $modulePath)){ throw "psake module not found in the configured search paths [$($searchPaths -join '][')]." }
import-module (join-path $modulePath psake.psm1)


try
{
  pushd $modulePath #needed to run psake from an arbitrary path and use the defaultBuildFileName from config

  try
  {
    if($buildFile)
    {
      invoke-psake $buildFile $taskList $framework $docs $parameters $properties
    }
    else
    {
      invoke-psake -taskList $taskList -framework $framework -docs:$docs -parameters $parameters -properties $properties
    }
  }
  finally
  {
    popd
  }
}
finally
{
  remove-module psake -ea 'SilentlyContinue'
}

}

set-alias psake Invoke-PsakeProfileFunction