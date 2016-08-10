
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


#region Public functions


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
                   ValueFromPipeline=$true,
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

    #Write-Debug "Passed parameters`:`n - Major`: $Major`n - Minor`; $Minor`n - Patch`: $Patch`n - PreRelease`: '$PreRelease'`n - Build`: '$Build'`n"

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


        Export-ModuleMember -Function @('ToString', 'FromString', 'StepMajor', 'StepMinor', 'StepPatch', 'StepPreRelease', 'StepBuild') -Variable @('Major', 'Minor', 'Patch', 'PreRelease', 'Build')
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
   Increments a Semantic Version number.

.DESCRIPTION
   Increments a Semantic Version number.

   - Incrementing the Major number will reset the Minor number and the Patch number to 0. The PreRelease and Build number will not be changed.

   - Incrementing the Minor number will reset the Patch number to 0. The Major, PreRelease number, and the Build number will not be changed.

   - Incrementing the Patch number does not change any other parts of the version number.

   - Incrementing the PreRelease number does not change any other parts of the version number.

   - Incrementing the Build number does not change any other parts of the version number.

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

        # Specifies that the build number should be incremented. Increments the last build indicator found. No other component of the version number will be incremented. This is default.
        [Parameter(ParameterSetName='Build')]
        [switch]
        $Build,

        # Specifies that the pre-release number should be incremented. Increments the last pre-release indicator found. No other component of the version number will be incremented.
        [Parameter(ParameterSetName='PreRelease')]
        [switch]
        $PreRelease,

        # Specifies that the patch number should be incremented. No other component of the version number will be incremented.
        [Parameter(ParameterSetName='Patch')]
        [switch]
        [Alias('Revision')]
        $Patch,

        # Specifies that the minor number should be incremented. This also resets the patch number to zero. No other component of the version number will be incremented.
        [Parameter(ParameterSetName='Minor')]
        [switch]
        $Minor,

        # Specifies that the major number should be incremented. This also resets the minor number and patch number to zero. No other component of the version number will be incremented.
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


function Convert-SemanticVersionToSystemVersion {
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
    [OutputType([System.Version])]
    param (
        # The semantic version to be converted. Must be a string or an object that can be converted to a string, and the string must be a valid semantic version string.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [object]
        [Alias('SemanticVersion', 'SemVer')]
        $InputObject
    )

    try {
        $SemVer = New-SemanticVersion -String $InputObject.ToString()
    }
    catch {
        throw 'InputObject.ToString() was not a valid semantic version string.'
    }



    [int32] $SysVerMajor = $SemVer.Major
    [int32] $SysVerMinor = $SemVer.Minor
    [int32] $SysVerBuild = 0
    [int32] $SysVerRevision = $SemVer.Patch

    if ($SemVer.Build.Length -gt 0) {
        [string[]] $BuildArray = @($SemVer.Build -split '\.')
        [bool] $numberFound = $false

        if ($BuildArray.Count -gt 1) {
            Write-Warning 'System.Version format does not support multiple build indicators. Only the last numeric build indicator will be retained.'
        }

        for ($i = ($BuildArray.Count - 1); $i -ge 0; $i--) {
            if ($BuildArray[$i] -match '\d+') {
                $numberFound = $true
                [int32] $SysVerBuild = [int32] $BuildArray[$i]
                break
            }
        }

        if (!$numberFound) {

            Write-Warning "System.Version format does not support non-numeric build indicators. Semantic build version `"$($SemVer.Build)`" will not be saved to System.Version."
        }
    }

    if ($SemVer.PreRelease.Length -gt 0) {
        Write-Warning "System.Version format does not support pre-release versions. Semantic pre-release version `"$($SemVer.PreRelease)`" will not be saved to System.Version."
    }

    New-Object -TypeName System.Version -ArgumentList @($SysVerMajor, $SysVerMinor, $SysVerBuild, $SysVerRevision)
}


function Convert-SystemVersionToSemanticVersion {
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
    [OutputType('Custom.SemanticVersion')]
    Param
    (
        # A version in System.Version format.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [System.Version]
        $Version
    )

    $SemVerMajor = $Version.Major
    $SemVerMinor = $Version.Minor

    if ($Version.Revision -lt 1) {
        $SemVerPatch = 0
    }
    else {
        $SemVerPatch = $Version.Revision
    }

    $SemVerPreRelease = ''

    if ($Version.Build -lt 1) {
        $SemVerBuild = ''
    }
    else {
        $SemVerBuild = $Version.Build
    }

    New-SemanticVersion -Major $SemVerMajor -Minor $SemVerMinor -Patch $SemVerPatch -PreRelease $SemVerPreRelease -Build $SemVerBuild
}


#endregion Public functions


Export-ModuleMember -Function @('New-SemanticVersion', 'Step-SemanticVersion', 'Convert-SemanticVersionToSystemVersion', 'Convert-SystemVersionToSemanticVersion')
