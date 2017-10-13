
#region Initialization


Properties {
    # The base directory of the project.
    $ProjectDir = Split-Path $psake.build_script_file -Parent | Split-Path -Parent

    # The name of the project.
    $ProjectName = Split-Path $ProjectDir -Leaf

    # The directory containing the source code for the project.
    $SourceDir = Join-Path $ProjectDir $ProjectName

    # The directory that contains the release (within OutputDir).
    $ReleaseDir = Join-Path $ProjectDir release

    # The directory that contains the release (within OutputDir).
    # TODO: Find a function that will remove all debug and strictmode statements from a script.
    #$DebugDir = Join-Path $ProjectDir debug

    # The file containing metadata for the release.
    $ReleaseMetadataFile = Join-Path $SourceDir -ChildPath ('{0}.psd1' -f $ProjectName)

    # The file containing release notes.
    $ReleaseNotesFile = Join-Path $ProjectDir ReleaseNotes.md

    # The file containing metadata for the project.
    $ProjectMetadataFile = Join-Path $ProjectDir project.json

    # The target configuration for the build.
    $BuildConfiguration = 'Release'

    # The directory containing the unit tests for this project.
    $UnitTestDir = Join-Path $ProjectDir tests

    # The directory containing tools used for building the project.
    $ToolsDir = Join-Path $ProjectDir tools
}


#FormatTaskName -format {
#    param (
#        $taskName
#    )
#
#    Write-Host '  --------  ' -NoNewline -ForegroundColor DarkMagenta -BackgroundColor Black
#    Write-Host $taskName -NoNewline -ForegroundColor Cyan -BackgroundColor Black
#    Write-Host '  --------  ' -ForegroundColor DarkMagenta -BackgroundColor Black
#}


#endregion Initialization


#region Tasks


Task Default -depends Build -description 'Calls Build task.'


#Task Install -depends Compile, Deploy, Clean
#Task Deploy -depends Compile
#Task Publish -depends Release


# Analyze, UnitTest, Clean
Task Release -depends Clean, Analyze, UnitTest -requiredVariables ChangeType, ChangeStage, ChangeDescription -description 'Update release version information.' {
    <#
        Update the project to a final/stable release.
            - Requires that the current version is a pre-release.
            - Requires that the ChangeType, ChangeStage, and ChangeDescription parameters have been set.
            - Requires that the ChangeStage be specified as 'Stable'.

        ChangeType:
            - Major
            - Minor
            - Patch
            - Breaking
            - Feature
            - Fix
    #>
    
    [string[]] $validChangeTypes = @('Major', 'Minor', 'Patch', 'Breaking', 'Feature', 'Fix')
    [string[]] $validChangeStages = @('Stable')

    Assert ($validChangeTypes -contains $ChangeType) ('The ChangeType parameter requires one of of the following values: {0}' -f ($validChangeTypes -join ', '))
    Assert ($validChangeStages -contains $ChangeStage) ('The ChangeStage parameter requires one of of the following values: {0}' -f ($validChangeStages -join ', '))
    Assert ($ChangeDescription.ToString().Length -gt 0) 'The ChangeDescription parameter must be used to describe the change in this release.'

    $currentProjectVersion = GetProjectVersion

    Import-Module -Name (Join-Path $ToolsDir SemanticVersion.psm1) -ErrorAction Stop

    $currentSemanticVersion = $null
    if (Test-SemanticVersion $currentProjectVersion) {
        $currentSemanticVersion = $currentProjectVersion | New-SemanticVersion
    }
    else {
        $msVersion = New-Object System.Version

        if ([System.Version]::TryParse($currentProjectVersion, ([ref] $msVersion))) {
            $currentSemanticVersion = $msVersion | Convert-SystemVersionToSemanticVersion
        }
        else {
            Assert $false 'Unable to convert current version to a semantic version or System.Version'
        }
    }

    Assert ($currentSemanticVersion.PreRelease.Length -ge 1) 'Release can only be applied to a pre-release version. Change this release to a pre-release version first, then try again.'

    Write-Verbose 'Updating version number'
    switch ($ChangeType) {
        'Breaking' {$ChangeType = 'Major'; break}
        'Feature' {$ChangeType = 'Minor'; break}
        'Fix' {$ChangeType = 'Patch'; break}
    }

    switch ($ChangeType) {
        'Major' {
            $newSemanticVersion = $currentSemanticVersion | Step-SemanticVersion -Major
            break
        }

        'Minor' {
            $newSemanticVersion = $currentSemanticVersion | Step-SemanticVersion -Minor
            break
        }

        'Patch' {
            $newSemanticVersion = $currentSemanticVersion | Step-SemanticVersion -Patch
            break
        }
    }

    SetProjectVersion $newSemanticVersion.ToString()

    Write-Verbose 'Updating release notes'
    if (Test-Path $ReleaseNotesFile -PathType Leaf) {
        $releaseDate = [string] (Get-Date -Format 'yyyy-MM-dd')

        [string[]] $updatedContent = @()
        $fileContent = Get-Content $ReleaseNotesFile

        $wasUnreleasedSectionFound = $false
        foreach ($line in $fileContent) {
            if ($line -match '^## Unreleased$' -and (-not $wasUnreleasedSectionFound)) {
                $wasUnreleasedSectionFound = $true
                $line = '## {0}.{1}.{2} - {3}' -f $newSemanticVersion.Major, $newSemanticVersion.Minor, $newSemanticVersion.Patch, $releaseDate
                $updatedContent += $line
                $updatedContent += ''
                $updatedContent += $ChangeDescription
                $updatedContent += ''
            }
            else {
                $updatedContent += $line
            }
        }

        if (-not $wasUnreleasedSectionFound) {
            $fileContent = $updatedContent
            $updatedContent = @()

            $mostRecentFound = $false
            foreach ($line in $fileContent) {
                if ($line -match '^##\s[0-9]+\.[0-9]+\.[0-9]+\s-\s[0-9]{4}-[0-9]{2}-[0-9]{2}(|\s.*)?$' -and (-not $mostRecentFound)) {
                    $mostRecentFound = $true
                    $updatedContent += '## {0}.{1}.{2} - {3}' -f $newSemanticVersion.Major, $newSemanticVersion.Minor, $newSemanticVersion.Patch, $releaseDate
                    $updatedContent += ''
                    $updatedContent += $ChangeDescription
                    $updatedContent += ''
                }

                $updatedContent += $line
            }
        }

        $updatedContent | Set-Content -Path $ReleaseNotesFile
    }

    Write-Verbose 'Cleaning release directory'
    CleanReleaseDir
}


Task Analyze -description 'Check sourcecode for best practices.' {
    # Seven axes of code quality: comments, unit tests, duplication, complexity, coding rules, potential bugs and architecture & design

    Write-Warning -Message ('Task "{0}" is not written yet.' -f $psake.context.Peek().currentTaskName)
}


Task Build -depends UnitTest -description 'Compile and increment build version.' {
    <#
        On build:
            - If the version is not a pre-release version:
                - Change the version to a patch pre-release
                - Warn the user the version has been changed to a patch pre-release
            - If the version does not have a build version:
                - Set the build version to 0
                - Warn the user that the build number has been set.
            - If the build number has only one indicator
                - Warn the user to include a branch or issue number in the build number.
            - Save new version to project.json and module manifest.
    #>

    $currentProjectVersion = GetProjectVersion
    #Write-Host ('Current Project Version: {0}' -f $currentProjectVersion) -ForegroundColor Green

    Import-Module -Name (Join-Path $ToolsDir SemanticVersion.psm1) -ErrorAction Stop

    $currentSemanticVersion = $null
    if (Test-SemanticVersion $currentProjectVersion) {
        $currentSemanticVersion = $currentProjectVersion | New-SemanticVersion
    }
    else {
        $msVersion = New-Object System.Version

        if ([System.Version]::TryParse($currentProjectVersion, ([ref] $msVersion))) {
            $currentSemanticVersion = $msVersion | Convert-SystemVersionToSemanticVersion
        }
        else {
            Assert $false 'Unable to convert current version to a semantic version or System.Version'
        }
    }


    $newSemanticVersion = $currentSemanticVersion

    if ($newSemanticVersion.PreRelease.Length -eq 0) {
        $newSemanticVersion = $newSemanticVersion | Step-SemanticVersion -PreRelease -Patch
        Write-Warning 'The project version will be changed to a pre-release version.'
    }

    # Increment build version.
    $newSemanticVersion = $newSemanticVersion | Step-SemanticVersion -Build

    # For a new build, the build version should be +issue-<id>.<build_index>
    if (@($newSemanticVersion.Build -split '\.').Count -eq 1) {
        Write-Warning ('You should specify the current branch or issue number in the build number.' + "`n" + '    Example:  3.8.0-1+feature-34.0   or   3.8.0-1+issue-34.0 ')
    }

    Write-Host ('Updating version number from "{0}" to "{1}"' -f $currentProjectVersion.ToString(),$newSemanticVersion.ToString()) -ForegroundColor Green

    SetProjectVersion $newSemanticVersion.ToString()

    # Get contents of the ReleaseNotes file and update the copied module manifest file
    # with the release notes.
    # DO NOT USE UNTIL UPDATE-MODULEMANIFEST IS FIXED - DOES NOT HANDLE SINGLE QUOTES CORRECTLY.
    # if ($ReleaseNotesPath) {
    #     $releaseNotes = @(Get-Content $ReleaseNotesPath)
    #     Update-ModuleManifest -Path $PublishDir\${ModuleName}.psd1 -ReleaseNotes $releaseNotes
    # }
}


Task UnitTest -depends Compile -description 'Run unit tests.' {
    Write-Warning -Message ('Task "{0}" is not written yet.' -f $psake.context.Peek().currentTaskName)
}


Task Compile -depends Init -requiredVariables SourceDir, ReleaseDir -description 'Compile and copy all required artifacts to release directory.' {
    Assert ([System.IO.Path]::IsPathRooted($SourceDir)) ('SourceDir must be an absolute path: "{0}"' -f $SourceDir)
    Assert (Test-Path $SourceDir) ('SourceDir cannot be found: "{0}"' -f $SourceDir)
    Assert (Test-Path $SourceDir -PathType Container) ('SourceDir must be a directory: "{0}"' -f $SourceDir)

    Assert ([System.IO.Path]::IsPathRooted($ReleaseDir)) ('ReleaseDir must be an absolute path: "{0}"' -f $ReleaseDir)
    Assert (Test-Path $ReleaseDir) ('ReleaseDir cannot be found: "{0}"' -f $ReleaseDir)
    Assert (Test-Path $ReleaseDir -PathType Container) ('ReleaseDir must be a directory: "{0}"' -f $ReleaseDir)

    Copy-Item -Path $SourceDir -Destination $ReleaseDir -Recurse #-Exclude $Exclude
}


Task Init -depends Clean -requiredVariables ReleaseDir -description 'Prepare the project for the compile process.' {
    Assert ([System.IO.Path]::IsPathRooted($ReleaseDir)) ('ReleaseDir must be an absolute path: "{0}"' -f $ReleaseDir)

    if (Test-Path $ReleaseDir) {
        Assert (Test-Path $ReleaseDir -PathType Container) ('ReleaseDir must be a directory: "{0}"' -f $ReleaseDir)
    }
    else {
        $null = New-Item $ReleaseDir -ItemType Directory
        Assert (Test-Path $ReleaseDir -PathType Container) ('ReleaseDir was not created in "Init" task: "{0}"' -f $ReleaseDir)
    }
}


Task Clean -requiredVariables ProjectDir, ReleaseDir -description 'Ensure output directory is empty.' {
    CleanReleaseDir

    #Assert ([System.IO.Path]::IsPathRooted($ProjectDir)) ('ProjectDir must be an absolute path: "{0}"' -f $ProjectDir)
    #Assert (Test-Path $ProjectDir) ('ProjectDir cannot be found: "{0}"' -f $ProjectDir)
    #Assert (Test-Path $ProjectDir -PathType Container) ('ProjectDir must be a directory: "{0}"' -f $ProjectDir)
    #
    #Assert ([System.IO.Path]::IsPathRooted($ReleaseDir)) ('ReleaseDir must be an absolute path: "{0}"' -f $ReleaseDir)
    #
    ## Sanity check the dir we are about to "clean".  If $OutputDir were to
    ## inadvertently get set to $null, the Remove-Item commmand removes the
    ## contents of \*.
    #if ((Test-Path $ReleaseDir) -and $ReleaseDir.Contains($ProjectDir)) {
    #    Assert (Test-Path $ReleaseDir -PathType Container) ('ReleaseDir must be a directory: "{0}"' -f $ReleaseDir)
    #    Remove-Item -Path (Join-Path $ReleaseDir *) -Recurse -Force
    #
    #    Assert (@(Get-ChildItem $ReleaseDir -Recurse -Force).Count -eq 0) ('ReleaseDir did not get cleaned in clean task: "{0}"' -f $ReleaseDir)
    #}
}


Task ? -description 'Helper to display task info' {
	Write-Host 'Available Tasks: ' -ForegroundColor Cyan
    $psake.Context.Peek().Tasks.GetEnumerator() |
        Select-Object @{n = 'Task'; e = {$_.Name -replace '^.',([string] $_.Name[0]).ToUpper()}},@{n='Description';e={$_.Value.description}} |
        Sort-Object Task

    #$psake.Context.Peek().Tasks.GetEnumerator() |
    #    Select-Object @{n = 'Task'; e = {$_.Name -replace '^.',([string] $_.Name[0]).ToUpper()}},@{n='Description';e={$_.Value.description}} |
    #    Where-Object {$_.Description.Length -ge 1} |
    #    Sort-Object Task
}


#endregion Tasks


#region Helper functions


function GetProjectVersion {
    param ()

    [string] $version = ''

    if (Test-Path $ProjectMetadataFile -PathType Leaf) {
        $version = Get-Content $ProjectMetadataFile |
            ConvertFrom-Json |
            Select-Object -ExpandProperty version
    }

    if (-not ($version.Length -ge 1)) {
        if (Test-Path $ReleaseMetadataFile -PathType Leaf) {
            $version = Test-ModuleManifest -Path $ReleaseMetadataFile |
                Select-Object -ExpandProperty Version |
                ForEach-Object {$_.ToString()}
        }
    }

    if ($version.Length -ge 1) {
        $version
    }
    else {
        throw 'Unable to find project version information.'
    }
}


function SetProjectVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string] $version
    )


    if (Test-Path $ProjectMetadataFile -PathType Leaf) {
        $projObj = Get-Content $ProjectMetadataFile |
            ConvertFrom-Json

        $projObj.version = $version.ToString()

        $projObj |
            ConvertTo-Json |
            Set-Content $ProjectMetadataFile
    }

    if (Test-Path $ReleaseMetadataFile -PathType Leaf) {
        $releaseObj = Test-ModuleManifest -Path $ReleaseMetadataFile

        #Write-Host $releaseObj.Version -ForegroundColor Cyan


        $msCurrentVersion = $releaseObj.Version

        #Write-Host $msCurrentVersion.ToString() -ForegroundColor Green

        $msNewVersion = $version | Convert-SemanticVersionToSystemVersion

        $fileContent = Get-Content $ReleaseMetadataFile

        #$fileContent | ForEach-Object {
        #
        #}

        [string[]] $newContent = @()

        foreach ($line in $fileContent) {
            if ($line -like ('ModuleVersion = *{0}*' -f $msCurrentVersion.ToString())) {
                #Write-Host 'Match' -ForegroundColor Red
                #Write-Host $line -ForegroundColor Cyan
                $line = $line.Replace($msCurrentVersion.ToString(), $msNewVersion.ToString())
                #Write-Host $line -ForegroundColor Green
            }

            $newContent += $line
        }

        #$newContent

        $newContent | Set-Content $ReleaseMetadataFile
    }
}


function CleanReleaseDir {
param ()

    if (-not (Test-Path $ProjectDir -PathType Container)) {
        throw ('ProjectDir must be a directory or was not found: "{0}"' -f $ProjectDir)
    }

    if (-not (Test-Path $ReleaseDir -PathType Container)) {
        throw ('ReleaseDir must be a directory or was not found: "{0}"' -f $ReleaseDir)
    }

    if ((Test-Path $ReleaseDir) -and $ReleaseDir.Contains($ProjectDir)) {
        Remove-Item -Path (Join-Path $ReleaseDir *) -Recurse -Force

        if (@(Get-ChildItem $ReleaseDir -Recurse -Force).Count -gt 0) {
            throw ('ReleaseDir did not get cleaned: "{0}"' -f $ReleaseDir)
        }
    }
}


#endregion Helper functions
