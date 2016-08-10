

<#
$SemVerRegEx = '^(0|[1-9][0-9]*)' + 
               '\.(0|[1-9][0-9]*)' + 
               '\.(0|[1-9][0-9]*)' + 
               '(-(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)?' + 
               '(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
#>


<#
# Labeled groups.
$SemVerRegEx = '^(?<major>(0|[1-9][0-9]*))' + 
               '\.(?<minor>(0|[1-9][0-9]*))' + 
               '\.(?<patch>(0|[1-9][0-9]*))' + 
               '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' + 
               '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
#>


function New-SemanticVersion {
<#
.Synopsis
   Creates a new semantic version number.

.DESCRIPTION
   Creates a new semantic version number.

.EXAMPLE
   Example of how to use this cmdlet

.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding(DefaultParameterSetName='Components')]
    [OutputType('Custom.SemanticVersion')]
    param (
        [Parameter(ParameterSetName='String',
                   Position=0,
                   ValueFromPipeline,
                   Mandatory=$true)]
        [ValidateScript({
            if ($_ -match '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$') {
                return $true
            }
            else {
                throw 'Invalid semantic version formatting.'
            }
        })]
        [string]
        $String,

        # The major portion of the version number.
        [Parameter(ParameterSetName='Components',
                   Position=0,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        $Major,

        # The minor portion of the version number.
        [Parameter(ParameterSetName='Components',
                   Position=1,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        $Minor,

        # The patch portion of the version number.
        [Parameter(ParameterSetName='Components',
                   Position=2,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        [Alias('Revision')]
        $Patch,

        # The pre-release portion of the version number.
        [Parameter(ParameterSetName='Components',
                   Position=3)]
        [ValidateScript({
            if ($_ -eq '') {
                $true
            }
            elseif ($_ -match '\s') {
                throw 'PreRelease cannot contain spaces.'
            }
            else {
                $_ -split '\.' |
                    foreach {
                        if (([string] $_) -eq '') {
                            throw 'Identifiers MUST NOT be empty.'
                        }

                        if ($_ -notmatch '^[0-9A-Za-z-]+$') {
                            throw 'Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].'
                        }

                        if ($_ -match '^\d\d+$' -and ($_ -like '0*')) {
                            throw 'Numeric identifiers MUST NOT include leading zeroes.'
                        }
                    }
            }

            $true
        })]
        [string]
        $PreRelease,

        # The build portion of the version number.
        [Parameter(ParameterSetName='Components',
                   Position=4)]
        [ValidateScript({
            if ($_ -eq '') {
                $true
            }
            elseif ($_ -match '\s') {
                throw 'Build cannot contain spaces.'
            }
            else {
                $_ -split '\.' |
                    foreach {
                        if (([string] $_) -eq '') {
                            throw 'Identifiers MUST NOT be empty.'
                        }

                        if ($_ -notmatch '^[0-9A-Za-z-]+$') {
                            throw 'Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].'
                        }
                    }
            }

            $true
        })]
        [string]
        $Build
    )

    Write-Debug "Passed parameters`:`n - Major`: $Major`n - Minor`; $Minor`n - Patch`: $Patch`n - PreRelease`: '$PreRelease'`n - Build`: '$Build'`n"

    #if (($Major -eq 0) -and ($PreRelease -eq '')) {
    #    Write-Debug 'Evaluated'
    #    $PreRelease = 'InitialDevelopment'
    #}

    $SemVerObj = New-Module -Name SemanticVersionObjectPrototype -AsCustomObject -ScriptBlock {
        [CmdletBinding()]
        param (
            [ValidateRange(0, 2147483647)]
            [int32]
            $Major = 0,

            [ValidateRange(0, 2147483647)]
            [int32]
            $Minor = 0,

            [ValidateRange(0, 2147483647)]
            [int32]
            $Patch = 0,

            [ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
            [string]
            $PreRelease,

            [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
            [string]
            $Build
        )


        function ToString {
            [string] $outputString = ''

            $outputString += '{0}.{1}.{2}' -f $Major, $Minor, $Patch

            if ($PreRelease -ne '') {
                $outputString += '-{0}' -f $PreRelease
            }

            if ($Build -ne '') {
                $outputString += '+{0}' -f $Build
            }

            $outputString
        }


        function FromString {
            param (
                [Parameter(Mandatory=$true)]
                [ValidatePattern('^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$')]
                [string]
                $String
            )

            $SemVerRegEx = '^(?<major>(0|[1-9][0-9]*))' + 
                           '\.(?<minor>(0|[1-9][0-9]*))' + 
                           '\.(?<patch>(0|[1-9][0-9]*))' + 
                           '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' + 
                           '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'

            [int32] $tmpMajor = 0
            [int32] $tmpMinor = 0
            [int32] $tmpPatch = 0
            [string] $tmpPreRelease = ''
            [string] $tmpBuild = ''

            if ($String -match $SemVerRegEx) {
                switch ($Matches.Keys) {
                    'major' {
                        $tmpMajor = $Matches['major']
                    }

                    'minor' {
                        $tmpMinor = $Matches['minor']
                    }

                    'patch' {
                        $tmpPatch = $Matches['patch']
                    }

                    'prerelease' {
                        $tmpPreRelease = $Matches['prerelease']
                    }

                    'build' {
                        $tmpBuild = $Matches['build']
                    }
                }
            }
            else {
                throw "Unrecognized semantic version format `"$String`"."
            }


            $Script:Major = $tmpMajor
            $Script:Minor = $tmpMinor
            $Script:Patch = $tmpPatch
            $Script:PreRelease = $tmpPreRelease
            $Script:Build = $tmpBuild
        }


        function ToMSVersion {
            [int32] $MSMajor = $Script:Major
            [int32] $MSMinor = $Script:Minor
            [int32] $MSBuild = 0
            [int32] $MSRevision = $Script:Patch

            if ($Script:Build.Length -gt 0) {
                [string[]] $BuildArray = $Script:Build -split '\.'
                [bool] $numberFound = $false

                if ($BuildArray.Count -gt 1) {
                    Write-Warning 'MS Version format does not support multiple build indicators. Only the last numeric build indicator will be retained.'
                }

                for ($i = ($BuildArray.Count - 1); $i -ge 0; $i--) {
                    if ($BuildArray[$i] -match '\d+') {
                        $numberFound = $true
                        [int32] $MSBuild = [int32] $BuildArray[$i]
                        break
                    }
                }

                if (!$numberFound) {

                    Write-Warning "MS Version format does not support non-numeric build indicators. Build version `"$Build`" will not be saved to MS Version."
                }
            }

            if ($Script:PreRelease -ne '') {
                Write-Warning "MS Version format does not support pre-release versions. Pre-release version `"$PreRelease`" will not be saved to MS Version."
            }

            New-Object -TypeName System.Version -ArgumentList @($MSMajor, $MSMinor, $MSBuild, $MSRevision)
        }


        function FromMSVersion {
            param (
                [System.Version]
                $Version
            )

            $Script:Major = $Version.Major
            $Script:Minor = $Version.Minor

            if ($Version.Revision -lt 1) {
                $Script:Patch = 0
            }
            else {
                $Script:Patch = $Version.Revision
            }

            $Script:PreRelease = ''

            if ($Version.Build -lt 1) {
                $Script:Build = ''
            }
            else {
                $Script:Build = $Version.Build
            }

        }


        function StepMajor {
            $Script:Major++
            $Script:Minor = 0
            $Script:Patch = 0
        }


        function StepMinor {
            $Script:Minor++
            $Script:Patch = 0
        }


        function StepPatch {
            $Script:Patch++
        }


        function StepPreRelease {
            switch ($PreRelease) {
                '' {
                    $Script:PreRelease = '1'
                }
                default {
                    [string[]] $preReleaseArray = $PreRelease -split '\.'
                    [bool] $numberFound = $false

                    for ($i = $preReleaseArray.Count - 1; $i -ge 0; $i--) {
                        if ($preReleaseArray[$i] -match '^\d+$') {
                            $numberFound = $true
                            $preReleaseArray[$i] = ([int] $preReleaseArray[$i]) + 1
                            break
                        }
                    }

                    if (!$numberFound) {
                        $preReleaseArray += '1'
                    }

                    $Script:PreRelease = $preReleaseArray -join '.'
                }
            }
        }


        function StepBuild {
            switch ($Build) {
                '' {
                    $Script:Build = '1'
                }
                default {
                    [string[]] $buildArray = $Build -split '\.'
                    [bool] $numberFound = $false

                    for ($i = $buildArray.Count - 1; $i -ge 0; $i--) {
                        if ($buildArray[$i] -match '^\d+$') {
                            $numberFound = $true
                            $buildArray[$i] = [string] (([int] $buildArray[$i]) + 1)
                            break
                        }
                    }

                    if (!$numberFound) {
                        $buildArray += '1'
                    }

                    $Script:Build = $buildArray -join '.'
                }
            }
        }


        Export-ModuleMember -Function @('ToString', 'FromString', 'ToMSVersion', 'FromMSVersion', 'StepMajor', 'StepMinor', 'StepPatch', 'StepPreRelease', 'StepBuild') -Variable @('Major', 'Minor', 'Patch', 'PreRelease', 'Build')
    }

    $SemVerObj.pstypenames.Insert(0, 'Custom.SemanticVersion')

    switch ($PSCmdlet.ParameterSetName) {
        'Components' {
            $SemVerObj.Major = $Major
            $SemVerObj.Minor = $Minor
            $SemVerObj.Patch = $Patch

            if ($PreRelease) {
                $SemVerObj.PreRelease = $PreRelease
            }

            if ($Build) {
                $SemVerObj.Build = $Build
            }

            $SemVerObj
        }

        'String' {
            $SemVerObj.Major = 0
            $SemVerObj.Minor = 0
            $SemVerObj.Patch = 0

            try {
                $SemVerObj.FromString($String)
            }
            catch {
                throw "Error setting semantic version using string `"$String`"."
            }

            $SemVerObj
        }
    }
}


function Step-SemanticVersion {
<#
.Synopsis
   Increments a System.Version number.

.DESCRIPTION
   Increments a System.Version number.

   - Incrementing the Major number will reset the Minor number and the Revision number to 0. The Build number will not be changed.

   - Incrementing the Minor number will reset the Revision number to 0. The Major number and the Build number will not be changed.

   - Incrementing the Build number does not change any other parts of the version number.

   - Incrementing the Revision number will also change the MajorRevision and MinorRevision numbers. The Major number, Minor number, and Build number will not be changed.

   - Incrementing the MajorRevision number will also change the Revision number. The Major number, Minor number, Build number, and MinorRevision number will not be changed.

   - Incrementing the MinorRevision number will also change the Revision number. The Major number, Minor number, Build number, and the MajorRevision number will not be changed.

.EXAMPLE
   Example of how to use this cmdlet

.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding(DefaultParameterSetName='Build')]
    [OutputType('Custom.SemanticVersion')]
    param (
        # The number to be incremented.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({
            if (@($_.pstypenames) -contains 'Custom.SemanticVersion') {
                $true
            }
            else {
                throw 'Input object type must be of type "Custom.SemanticVersion".'
            }
        })]
        [psobject]
        [Alias('Version','Number')]
        $InputObject,

        [Parameter(ParameterSetName='Build')]
        [switch]
        $Build,

        [Parameter(ParameterSetName='PreRelease')]
        [switch]
        $PreRelease,

        [Parameter(ParameterSetName='Patch')]
        [switch]
        [Alias('Revision')]
        $Patch,

        [Parameter(ParameterSetName='Minor')]
        [switch]
        $Minor,

        [Parameter(ParameterSetName='Major')]
        [switch]
        $Major
    )

    $updatedSemVer = $InputObject.psobject.copy()

    switch ($PSCmdlet.ParameterSetName) {
        'Build' {
            $updatedSemVer.StepBuild()
        }
        'PreRelease' {
            $updatedSemVer.StepPreRelease()
        }
        'Patch' {
            $updatedSemVer.StepPatch()
        }
        'Minor' {
            $updatedSemVer.StepMinor()
        }
        'Major' {
            $updatedSemVer.StepMajor()
        }
    }

    $updatedSemVer
}


# function ConvertTo-SemanticVersionFromMSVersion


# function ConvertFrom-SemanticVersionToMSVersion


Export-ModuleMember -Function '*-*'