<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

[CmdletBinding()]
[OutputType([void])]
param (
    [string]
    $Task = 'default',

    [hashtable]
    $Parameters = @{},

    [string]
    $BuildFile
)


[string] $thisScriptPath = $MyInvocation.MyCommand.Path
[string] $thisScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
[string] $thisProjectName = Split-Path $thisScriptRoot -Leaf

if (-not ($PSBoundParameters.ContainsKey('BuildFile'))) {
    [string] $BuildFile = Join-Path $thisScriptRoot tools | Join-Path -ChildPath ('{0}.psake.ps1' -f $thisProjectName)
}

Write-Verbose ('Running task "{0}"' -f $itemTask)

Invoke-psake -buildFile $BuildFile -taskList $Task -parameters $Parameters
exit ( [int]( -not $psake.build_success ) )
