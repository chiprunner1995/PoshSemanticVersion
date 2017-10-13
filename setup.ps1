#Requires -Version 3
#Requires -Module psake

<#
.Synopsis
    Starts a build automation task.
.DESCRIPTION
    Project build tasks entrypoint.
#>
[CmdletBinding(SupportsShouldProcess=$true,
               ConfirmImpact='Low')]
[OutputType([void])]
param (
    # The build task to run.
    [string[]]
    [ValidateSet('Help', 'Build', 'Test', 'UnitTest', 'Analyze', 'Compile', 'Init')]
    $Task = 'default',

    # A hashtable containing parameters to be passed into the psake build script. These parameters will be processed
    # before the 'Properties' function of the script is processed.  This means you can access parameters from within
    # the 'Properties' function!
    [hashtable]
    $Parameters = @{},

    # A hashtable containing properties to be passed into the psake build script. These properties will override
    # matching properties that are found in the 'Properties' function of the script.
    [hashtable]
    $Properties = @{},

    # The path to the psake build script for this project.
    [string]
    $BuildFile
)

Import-Module -Name psake -ErrorAction Stop

[string] $thisScriptPath = $MyInvocation.MyCommand.Path
[string] $thisScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
[string] $thisProjectName = Split-Path $thisScriptRoot -Leaf
[int] $exitCode = 0

if ($PSBoundParameters.ContainsKey('BuildFile')) {
    $_buildFile = Resolve-Path -Path $BuildFile | Select-Object -ExpandProperty ProviderPath
}
else {
    $_buildFile = Join-Path $thisScriptRoot tools | Join-Path -ChildPath default.psake.ps1
}

Write-Verbose ('Running task "{0}"' -f $itemTask)

if ($pscmdlet.ShouldProcess($_buildFile, 'Run psake')) {
    Invoke-psake -nologo -buildFile $_buildFile -taskList $Task -parameters $Parameters -properties $Properties
}

$exitCode = [int] (-not $psake.build_success)

if ($exitCode -eq 0) {
    Remove-Module -Name psake -Force -ErrorAction SilentlyContinue
}

exit $exitCode