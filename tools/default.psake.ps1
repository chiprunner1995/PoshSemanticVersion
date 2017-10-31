
Properties {
    # The base directory of the project.
    $ProjectDir = Split-Path $psake.build_script_file -Parent | Split-Path -Parent

    # The name of the project.
    $ProjectName = Split-Path $ProjectDir -Leaf

    # The directory containing the source code for the project.
    $SourceDir = Join-Path $ProjectDir $ProjectName

    # The name of the target build configuration.
    # Example: Release, Debug, Dev, Test, Prod
    $ConfigurationName = 'Debug'

    # The root output directory that the built project files are copied to.
    # Be sure to add this directory to the project's VCS config ignore paths.
    $TargetDir = Join-Path $ProjectDir dist | Join-Path -ChildPath $ConfigurationName

    # The build metadata file that is compiled with the build.
    # A module manifest, script info, or other assembly information file.
    $BuildInfoFileName = $ProjectName + '.psd1'

    # The path to the build metadata file.
    $BuildInfoFilePath = Join-Path $SourceDir $BuildInfoFileName

    # The directory containing tests
    $TestDir = Join-Path $ProjectDir tests

    # The directory containing tools used when building the project.
    $ToolsDir = Join-Path $ProjectDir tools

    # The file containing release notes.
    $ReleaseNotesFilePath = Join-Path $ProjectDir ReleaseNotes.md
}


#region Tasks


Task Default -depends Build -description 'Run default task "build".'


#TODO: Create "Publish" task.
#TODO: Create "Install" task.
#TODO: Create "Release" task.
#TODO: Create "Version" task.


Task Test -depends Analyze, UnitTest -description 'Run tests.'


Task Analyze -depends Build -requiredVariables SourceDir -description 'Check source code for best practices.' {
    if (@(Get-Module | Select-Object -ExpandProperty Name) -notcontains 'PSScriptAnalyzer') {
        Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
    }
    $analysisResults = Invoke-ScriptAnalyzer -Path $SourceDir -Recurse

    if ($analysisResults.Count -gt 0) {
        Write-Host -Object ($analysisResults | Out-String) -ForegroundColor Red
    }

    Assert ($analysisResults.Count -eq 0) 'Script analysis did not pass.'
    Remove-Module -Name PSScriptAnalyzer -ErrorAction SilentlyContinue
}


Task UnitTest -depends Build -requiredVariables TestDir, TargetDir -description 'Run unit tests.' {
    Push-Location -Path $TestDir -ErrorAction Stop
    Set-StrictMode -Version Latest
    Remove-Module $ProjectName -Force -ErrorAction SilentlyContinue
    Import-Module $BuildInfoFilePath -Force -ErrorAction Stop
    if (@(Get-Module | Select-Object -ExpandProperty Name) -notcontains 'Pester') {
        Import-Module Pester -ErrorAction Stop
    }
    $testResults = Invoke-Pester -PesterOption @{IncludeVSCodeMarker=$true} -PassThru -ErrorAction Stop
    Assert ($testResults.FailedCount -eq 0) ('Unit tests failed: {0}' -f $testResults.FailedCount)
    Remove-Module Pester -ErrorAction SilentlyContinue
    Set-StrictMode -Off
    Pop-Location
}


Task Build -depends Compile -description 'Generate or update build metadata after compiling.' {}


Task Compile -depends Init, Clean -requiredVariables SourceDir, TargetDir -description 'Copy all required artifacts to build target directory.' {
    Assert ([System.IO.Path]::IsPathRooted($SourceDir)) ('SourceDir must be an absolute path: "{0}"' -f $SourceDir)
    Assert (Test-Path $SourceDir) ('SourceDir cannot be found: "{0}"' -f $SourceDir)
    Assert (Test-Path $SourceDir -PathType Container) ('SourceDir must be a directory: "{0}"' -f $SourceDir)

    Copy-Item -Path $SourceDir -Destination $TargetDir -Recurse #-Exclude $Exclude
}


Task Clean -depends Init -requiredVariables TargetDir -description 'Remove artifacts from previous compile process.' {
    Remove-Item -Path (Join-Path $TargetDir *) -Recurse -Force

    Assert (@(Get-ChildItem $TargetDir -Recurse -Force).Count -eq 0) ('TargetDir did not get cleaned: "{0}"' -f $TargetDir)
}


Task Init -requiredVariables TargetDir -description 'Prepare the project for the compile process.' {
    Assert ([System.IO.Path]::IsPathRooted($TargetDir)) ('TargetDir must be an absolute path: "{0}"' -f $TargetDir)

    if (!(Test-Path $TargetDir)) {
        $null = New-Item $TargetDir -ItemType Directory -Force
        Assert (Test-Path $TargetDir -PathType Container) ('TargetDir could not be created in "Init" task: "{0}"' -f $TargetDir)
    }

    Assert (Test-Path $TargetDir -PathType Container) ('TargetDir must be a directory: "{0}"' -f $TargetDir)
}


Task '?' -depends Help


Task Help -description 'Display task descriptions' {
	Write-Host 'Available Tasks: ' -ForegroundColor Cyan
    $psake.Context.Peek().Tasks.GetEnumerator() |
        Select-Object @{n = 'Task'; e = {$_.Name}} ,@{n = 'Description'; e = {$_.Value.description}} |
        Where-Object {$_.Description -ne ''} |
        Sort-Object Task
}


#endregion Tasks