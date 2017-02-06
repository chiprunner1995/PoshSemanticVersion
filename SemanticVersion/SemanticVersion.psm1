#region Public functions


function New-SemanticVersion {
<#
.Synopsis
    Creates a new semantic version number.

.DESCRIPTION
    Creates a new object representing a semantic version number.

.EXAMPLE
    New-SemanticVersion -String '1.2.3-alpha.4+build.5'


    Major      : 1
    Minor      : 2
    Patch      : 3
    PreRelease : alpha.4
    Build      : build.5

    This command converts a valid Semantic Version string into a Semantic Version object. The output of the command is a Semantic Version object with the elements of the version split into separate properties.

.EXAMPLE
    New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.4 -Build build.5


    Major      : 1
    Minor      : 2
    Patch      : 3
    PreRelease : alpha.4
    Build      : build.5

    This command take the Major, Minor, Patch, PreRelease, and Build parameters and produces the same output as the previous example.

.EXAMPLE
    $semver = New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.4 -Build build.5

    $semver.ToString()

    1.2.3-alpha.4+build.5

    This example shows that the object output from the previous command can be saved to a variable. Then by calling the object's ToString() method, a valid Semantic Version string is returned.

#>
    [CmdletBinding(DefaultParameterSetName='Components')]
    [OutputType('CustomSemanticVersion')]
    param (
        [Parameter(ParameterSetName='String',
                   Position=0,
                   ValueFromPipeline=$true,
                   Mandatory=$true)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'Object string value is not a valid semantic version.'
            }
        })]
        [object]
        $String,

        # The major version must be incremented if any backwards incompatible changes are introduced to the public API.
        [Parameter(ParameterSetName='Components',
                   Position=0,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        $Major = 0,

        # The minor version must be incremented if new, backwards compatible functionality is introduced to the public API.
        [Parameter(ParameterSetName='Components',
                   Position=1,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        $Minor = 0,

        # The patch version must be incremented if only backwards compatible bug fixes are introduced. 
        [Parameter(ParameterSetName='Components',
                   Position=2,
                   Mandatory=$true)]
        [ValidateRange(0, 2147483647)]
        [int32]
        $Patch = 0,

        # A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility requirements as denoted by its associated normal version.
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
        $PreRelease = '',

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
        $Build = ''
    )

    #Write-Debug "Passed parameters`:`n - Major`: $Major`n - Minor`; $Minor`n - Patch`: $Patch`n - PreRelease`: '$PreRelease'`n - Build`: '$Build'`n"

    switch ($PSCmdlet.ParameterSetName) {
        'Components' {
        }

        'String' {
            if ($String -match $NamedSemVerRegEx) {
                switch ($Matches.Keys) {
                    'major' {
                        Write-Debug "Major = $($Matches['major'])"
                        $Major = $Matches['major']
                        continue
                    }

                    'minor' {
                        write-Debug "Minor = $($matches['minor'])"
                        $Minor = $Matches['minor']
                        continue
                    }

                    'patch' {
                        write-Debug "Patch = $($matches['patch'])"
                        $Patch = $Matches['patch']
                        continue
                    }

                    'prerelease' {
                        write-Debug "PreRelease = $($matches['prerelease'])"
                        $PreRelease = $Matches['prerelease']
                        continue
                    }

                    'build' {
                        write-Debug "Build = $($matches['build'])"
                        $Build = $Matches['build']
                        continue
                    }
                }
            }
            else {
                throw "Unrecognized semantic version format `"$String`"."
            }
        }
    }

    $SemVerObj = New-Module -Name ($SemanticVersionTypeName + 'ObjectPrototype') -ArgumentList @($Major, $Minor, $Patch, $PreRelease, $Build) -AsCustomObject -ScriptBlock {
        [CmdletBinding()]
        param (
            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int32]
            $Major = 0,

            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int32]
            $Minor = 0,

            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int32]
            $Patch = 0,

            # A string.
            [ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
            [string]
            $PreRelease = '',

            # A string.
            [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
            [string]
            $Build = ''
        )

        function CompareTo {
            <#
                Compare this SemVerObj to another.
                Return 0 if both objects are equal
                Return 1 if this object is a higher precedence than the other.
                Return -1 if this object is a lower precedence than the other.
            #>
            [CmdletBinding()]
            [OutputType([int])]
            param (
                # The number to be incremented.
                [Parameter(Mandatory=$true)]
                [ValidateScript({
                    if (@($_.pstypenames) -contains 'CustomSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "CustomSemanticVersion".'
                    }
                })]
                [psobject]
                $Version
            )

            [int32] $returnValue = 0

            if ($Major -gt $Version.Major) {
                $returnValue = 1
            }
            elseif ($Major -lt $Version.Major) {
                $returnValue = -1
            }

            if ($returnValue -eq 0) {
                if ($Minor -gt $Version.Minor) {
                    $returnValue = 1
                }
                elseif ($Minor -lt $Version.Minor) {
                    $returnValue = -1
                }
            }

            if ($returnValue -eq 0) {
                if ($Patch -gt $Version.Patch) {
                    $returnValue = 1
                }
                elseif ($Patch -lt $Version.Patch) {
                    $returnValue = -1
                }
            }

            if ($returnValue -eq 0 -and ($PreRelease.Length -gt 0 -or ($Version.PreRelease.Length -gt 0))) {
                if ($PreRelease.Length -eq 0 -and ($Version.PreRelease.Length -gt 0)) {
                    $returnValue = 1
                }
                elseif ($PreRelease.Length -gt 0 -and ($Version.PreRelease.Length -eq 0)) {
                    $returnValue = -1
                }
            }

            if ($returnValue -eq 0) {
                [string[]] $PreReleaseArray = @($PreRelease -split '\.')
                [string[]] $VersionPreReleaseArray = @($Version.PreRelease -split '\.')
                [int] $shortestArray = $PreReleaseArray.Length

                if ($shortestArray -gt $VersionPreReleaseArray.Length) {
                    $shortestArray = $VersionPreReleaseArray.Length
                }

                for ([int] $i = 0; $i -lt $shortestArray; $i++) {
                    if ($PreReleaseArray[$i] -notmatch '^[0-9]+$' -and ($VersionPreReleaseArray[$i] -match '^[0-9]+$')) {
                        $returnValue = 1
                    }
                    elseif ($PreReleaseArray[$i] -match '^[0-9]+$' -and ($VersionPreReleaseArray[$i] -notmatch '^[0-9]+$')) {
                        $returnValue = -1
                    }
                    elseif ($PreReleaseArray[$i] -gt $VersionPreReleaseArray[$i]) {
                        $returnValue = 1
                    }
                    elseif ($PreReleaseArray[$i] -lt $VersionPreReleaseArray[$i]) {
                        $returnValue = -1
                    }


                    if ($returnValue -ne 0) {
                        break
                    }
                }

                if ($returnValue -eq 0) {
                    if ($PreReleaseArray.Length -gt $VersionPreReleaseArray.Length) {
                        $returnValue = 1
                    }
                    elseif ($PreReleaseArray.Length -lt $VersionPreReleaseArray.Length) {
                        $returnValue = -1
                    }
                }
            }

            return $returnValue
        }

        function CompatibleWith {
            # Test if the current version is compatible with the parameter argument version.
            [CmdletBinding()]
            [OutputType([bool])]
            param (
                # The number to be incremented.
                [Parameter(Mandatory=$true)]
                [ValidateScript({
                    if (@($_.pstypenames) -contains 'CustomSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "CustomSemanticVersion".'
                    }
                })]
                [psobject]
                $Version
            )

            [bool] $IsCompatible = $true

            if ((CompareTo -Version $Version) -eq 0) {
                $IsCompatible = $true
            }
            elseif ($Major -eq 0) {
                $IsCompatible = $false
            }
            elseif ($Major -ne $Version.Major) {
                $IsCompatible = $false
            }
            elseif ($PreRelease -ne $Version.PreRelease) {
                $IsCompatible = $false
            }
            elseif ($PreRelease.Length -gt 0 -and ($PreRelease -eq $Version.PreRelease)) {
                if ($Major -ne $Version.Major) {
                    $IsCompatible = $false
                }
                if ($Minor -ne $Version.Minor) {
                    $IsCompatible = $false
                }
                if ($Patch -ne $Version.Patch) {
                    $IsCompatible = $false
                }
            }

            return $IsCompatible
        }

        function Equals {
            [CmdletBinding()]
            [OutputType([bool])]
            param (
                # The number to be incremented.
                [Parameter(Mandatory=$true)]
                [ValidateScript({
                    if (@($_.pstypenames) -contains 'CustomSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "CustomSemanticVersion".'
                    }
                })]
                [psobject]
                $Version
            )

            (CompareTo -Version $Version) -eq 0
        }

        function FromString {
            [CmdletBinding()]
            [OutputType([void])]
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

        function GetBuild {
            [CmdletBinding()]
            [OutputType([string])]
            param ()

            return $Build
        }

        function GetHashCode {
            [CmdletBinding()]
            [OutputType([int])]
            param ()
            [int] $hash = 13

            $hash = ($hash * 7) + $Major.GetHashCode()
            $hash = ($hash * 7) + $Minor.GetHashCode()
            $hash = ($hash * 7) + $Patch.GetHashCode()
            $hash = ($hash * 7) + $PreRelease.GetHashCode()

            return $hash
        }

        function GetMajor {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $Major
        }

        function GetMinor {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $Minor
        }

        function GetPatch {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $Patch
        }

        function GetPreRelease {
            [CmdletBinding()]
            [OutputType([string])]
            param ()

            return $PreRelease
        }

        function Increment {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
                [string]
                $Type = 'Build'
            )

            switch ($Type) {
                'Build' {
                    IncrementBuild
                }

                'PreRelease' {
                    IncrementPreRelease
                }

                'PrePatch' {
                    $Script:PreRelease = ''
                    IncrementPatch
                    $Script:PreRelease = '0'
                }

                'PreMinor' {
                    $Script:PreRelease = ''
                    IncrementMinor
                    $Script:PreRelease = '0'
                }

                'PreMajor' {
                    $Script:PreRelease = ''
                    IncrementMajor
                    $Script:PreRelease = '0'
                }

                'Patch' {
                    IncrementPatch
                }

                'Minor' {
                    IncrementMinor
                }

                'Major' {
                    IncrementMajor
                }
            }
        }

        function IncrementBuild {
            [CmdletBinding()]
            [OutputType([void])]
            param ()
            switch ($Build) {
                '' {
                    $Script:Build = '0'
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
                        $buildArray += '0'
                    }

                    $Script:Build = $buildArray -join '.'
                }
            }
        }

        function IncrementMajor {
            [CmdletBinding()]
            [OutputType([void])]
            param ()

            if ($PreRelease.Length -eq 0) {
                $Script:Major++
                $Script:Minor = 0
                $Script:Patch = 0
            }
            else {
                $Script:PreRelease = ''

                if ($Minor -gt 0 -or ($Patch -gt 0)) {
                    $Script:Major++
                    $Script:Minor = 0
                    $Script:Patch = 0
                }
            }
        }

        function IncrementMinor {
            [CmdletBinding()]
            [OutputType([void])]
            param ()

            if ($PreRelease.Length -eq 0) {
                $Script:Minor++
                $Script:Patch = 0
            }
            else {
                $Script:PreRelease = ''

                if ($Patch -gt 0) {
                    $Script:Minor++
                    $Script:Patch = 0
                }
            }
        }

        function IncrementPatch {
            [CmdletBinding()]
            [OutputType([void])]
            param ()

            if ($PreRelease.Length -eq 0) {
                $Script:Patch++
            }
            else {
                $Script:PreRelease = ''
            }
        }

        function IncrementPreRelease {
            <#

                Increment the pre-release version.

            #>
            [CmdletBinding()]
            [OutputType([void])]
            param ()

            if ($PreRelease.Length -eq 0) {
                $Script:Patch++
                $Script:PreRelease = '0'
            }
            else {

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
                    $preReleaseArray += '0'
                }

                $Script:PreRelease = $preReleaseArray -join '.'
            }
        }

        function SetBuild {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
                [string]
                $Build
            )

            $Script:Build = $Build
        }

        function SetMajor {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Major
            )

            if ($Major -ne ($Script:Major + 1)) {
                throw 'You can only increment Major by 1.'
            }

            IncrementMajor
        }

        function SetMinor {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Minor
            )

            if ($Minor -ne ($Script:Minor + 1)) {
                throw 'You can only increment Minor by 1.'
            }

            IncrementMinor
        }

        function SetPatch {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Patch
            )

            if ($Patch -ne ($Script:Patch + 1)) {
                throw 'You can only increment Patch by 1.'
            }

            IncrementPatch
        }

        function SetPreRelease {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
                [string]
                $PreRelease
            )

            $Script:PreRelease = $PreRelease
        }

        function ToString {
            [CmdletBinding()]
            [OutputType([string])]
            param ()

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

        [bool] $InDevelopmentMode = $false
        if ($PreRelease.Length -gt 0) {
            Set-Variable -Name InDevelopmentMode -Value $true -Force
        }

        Export-ModuleMember -Function @('CompareTo', 'Equals', 'GetHashCode', 'CompatibleWith', 'ToString', 'FromString', 'Increment', 'GetMajor', 'SetMajor', 'IncrementMajor', 'GetMinor', 'SetMinor', 'IncrementMinor', 'GetPatch', 'SetPatch', 'IncrementPatch', 'GetPreRelease', 'SetPreRelease', 'IncrementPreRelease', 'GetBuild', 'SetBuild', 'IncrementBuild')
    } |
        Add-Member -MemberType ScriptProperty -Name Major -Value {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $this.GetMajor()
        } -SecondValue {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Major
            )

            if ($Major -ne ($this.GetMajor() + 1)) {
                throw 'You can only increment Major by 1.'
            }

            $this.SetMajor($Major)
        } -PassThru |
        Add-Member -MemberType ScriptProperty -Name Minor -Value {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $this.GetMinor()
        } -SecondValue {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Minor
            )

            if ($Minor -ne ($this.GetMinor() + 1)) {
                throw 'You can only increment Minor by 1.'
            }

            $this.SetMinor($Minor)
        } -PassThru |
        Add-Member -MemberType ScriptProperty -Name Patch -Value {
            [CmdletBinding()]
            [OutputType([int32])]
            param ()

            return $this.GetPatch()
        } -SecondValue {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidateRange(1,2147483647)]
                [int32]
                $Patch
            )

            if ($Patch -ne ($this.GetPatch() + 1)) {
                throw 'You can only increment Patch by 1.'
            }

            $this.SetPatch($Patch)
        } -PassThru |
        Add-Member -MemberType ScriptProperty -Name PreRelease -Value {
            [CmdletBinding()]
            [OutputType([string])]
            param ()

            $returnPreRelease = $this.GetPreRelease()

            

            return $this.GetPreRelease()
        } -SecondValue {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
                [string]
                $PreRelease
            )

            $this.SetPreRelease($PreRelease)
        } -PassThru |
        Add-Member -MemberType ScriptProperty -Name Build -Value {
            [CmdletBinding()]
            [OutputType([string])]
            param ()

            return $this.GetBuild()
        } -SecondValue {
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [Parameter(Mandatory=$true)]
                [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
                [string]
                $Build
            )

            $this.SetBuild($Build)
        } -PassThru

    $SemVerObj.pstypenames.Insert(0, $SemanticVersionTypeName)

    $SemVerObj
}


function Test-SemanticVersion {
<#
.Synopsis
    Tests if a string is a valid semantic version.

.DESCRIPTION
    The Test-SemanticVersion function verifies that a supplied string meets the Semantic Version 2.0 specification.

.EXAMPLE
    Test-SemanticVersion '1.2.3-alpha.1+build.456'

    True

    This example shows the result if the provided string is a valid semantic version.

.EXAMPLE
    Test-SemanticVersion '1.2.3-alpha.01+build.456'

    False

    This example shows the result if the provided string is not a valid semantic version.
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The semantic version string to validate.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [object]
        $Version
    )

    if ($Version.ToString() -match $SemVerRegEx) {
        $true
    }
    else {
        $false
    }
}


function Compare-SemanticVersion {
<#
.Synopsis
    Compares two semantic version numbers.

.DESCRIPTION
    The Test-SemanticVersion function compares two semantic version numbers and returns an object that contains the results of the comparison.

.EXAMPLE
    Compare-SemanticVersion -ReferenceVersion '1.1.1' -DifferenceVersion '1.2.0'

    ReferenceVersion                  DifferenceVersion                 Precedence                                            AreCompatible
    ----------------                  -----------------                 ----------                                            -------------
    1.1.1                             1.2.0                             <                                                              True

    This command show sthe results of compare two semantic version numbers that are not equal in precedence but are compatible.

.EXAMPLE
    Compare-SemanticVersion -ReferenceVersion '0.1.1' -DifferenceVersion '0.1.0'

    ReferenceVersion                  DifferenceVersion                 Precedence                                            AreCompatible
    ----------------                  -----------------                 ----------                                            -------------
    0.1.1                             0.1.0                             >                                                             False

    This command shows the results of comparing two semantic version numbers that are are not equal in precedence and are not compatible.

.EXAMPLE
    Compare-SemanticVersion -ReferenceVersion '1.2.3' -DifferenceVersion '1.2.3-0'

    ReferenceVersion                  DifferenceVersion                 Precedence                                            AreCompatible
    ----------------                  -----------------                 ----------                                            -------------
    1.2.3                             1.2.3-0                           >                                                             False

    This command shows the results of comparing two semantic version numbers that are are not equal in precedence and are not compatible.

.EXAMPLE
    Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+5'

    ReferenceVersion                  DifferenceVersion                 Precedence                                            AreCompatible
    ----------------                  -----------------                 ----------                                            -------------
    1.2.3-4+5                         1.2.3-4+5                         =                                                              True

    This command shows the results of comparing two semantic version numbers that are exactly equal in precedence.

.EXAMPLE
    Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+6789'

    ReferenceVersion                  DifferenceVersion                 Precedence                                            AreCompatible
    ----------------                  -----------------                 ----------                                            -------------
    1.2.3-4+5                         1.2.3-4+6789                      =                                                              True

    This command shows the results of comparing two semantic version numbers that are exactly equal in precedence, even if they have different build numbers.

.NOTES
    To sort a collection of semantic version numbers based on the semver.org precedence rules

        Sort-Object -Property Major,Minor,Patch,@{e = {$_.PreRelease -eq ''}; Ascending = $true},PreRelease,Build

#>
    [CmdletBinding()]
    [OutputType([psobject])]
    param (
        # Specifies the version used as a reference for comparison.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'ReferenceVersion is not a valid semantic version.'
            }
        })]
        [object]
        $ReferenceVersion,

        # Specifies the version that is compared to the reference version.
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'DifferenceVersion is not a valid semantic version.'
            }
        })]
        [object]
        $DifferenceVersion
    )

    $refVer = New-SemanticVersion -String $ReferenceVersion.ToString()
    $difVer = New-SemanticVersion -String $DifferenceVersion.ToString()

    [int] $precedence = $refVer.CompareTo($difVer)
    

    New-Object -TypeName psobject |
        Add-Member -MemberType NoteProperty -Name ReferenceVersion -Value $refVer.ToString() -PassThru |
        Add-Member -MemberType NoteProperty -Name DifferenceVersion -Value $difVer.ToString() -PassThru |
        Add-Member -MemberType NoteProperty -Name Precedence -Value $(
            if ($precedence -eq 0) {
                '='
            }
            elseif ($precedence -gt 0) {
                '>'
            }
            else {
                '<'
            }
        ) -PassThru |
        Add-Member -MemberType NoteProperty -Name AreCompatible -Value $refVer.CompatibleWith($difVer) -PassThru
}


#function Sort-SemanticVersion {
#<#
#.Synopsis
#    Sorts a series of Semantic Versions
#
#.DESCRIPTION
#    The Sort-SemanticVersion function sorts a series of Semantic Version numbers based on the Semantic Version 2.0 specification's precedence rules.
#
#.EXAMPLE
#
#
#.EXAMPLE
#
##>
#    [CmdletBinding()]
#    [OutputType([psobject[]])]
#    param (
#        # Specifies the version used as a reference for comparison.
#        [Parameter(Mandatory=$true,
#                   ValueFromPipeline=$true)]
#        [ValidateScript({
#            if (Test-SemanticVersion -Version $_.ToString()) {
#                $true
#            }
#            else {
#                throw 'Version is not a valid semantic version.'
#            }
#        })]
#        [psobject[]]
#        $Version
#    )
#
#    begin {
#        $outputCollection = @()
#    }
#
#    process {
#        foreach ($subObject in $Version) {
#            $outputCollection += New-SemanticVersion -String ($subObject.ToString())
#        }
#    }
#
#    end {
#        $outputCollection | Sort-Object -Property Major,Minor,Patch,@{e = {$_.PreRelease -eq ''}; Ascending = $true},PreRelease,Build
#    }
#}


function Step-SemanticVersion {
<#
.Synopsis
    Increments a Semantic Version number.

.DESCRIPTION
    The Step-SemanticVersion function increments the elements of a semantic version number in a way that is compliant with the Semantic Version 2.0 specification.

    - Incrementing the Major number will reset the Minor number and the Patch number to 0. A pre-release version will be incremented to the normal version number.

    - Incrementing the Minor number will reset the Patch number to 0. A pre-release version will be incremented to the normal version number.

    - Incrementing the Patch number does not change any other parts of the version number. A pre-release version will be incremented to the normal version number.

    - Incrementing the PreRelease number does not change any other parts of the version number.

    - Incrementing the Build number does not change any other parts of the version number.

.EXAMPLE
    '1.1.1' | Step-SemanticVersion

    Major      : 1
    Minor      : 1
    Patch      : 2
    PreRelease : 0
    Build      :

    This command takes a semantic version string from the pipeline and increments the pre-release version. Because the element to increment was not specified, the default value of 'PreRelease was used'.


.EXAMPLE
    '1.1.1' | Step-SemanticVersion

    Major      : 1
    Minor      : 2
    Patch      : 0
    PreRelease :
    Build      :

    This command converts the string '1.1.1' to the semantic version object equivalent of '1.2.0'.

#>
    [CmdletBinding(DefaultParameterSetName='PreRelease')]
    [OutputType('CustomSemanticVersion')]
    param (
        # The number to be incremented.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'InputObject is not a valid semantic version.'
            }
        })]
        [object]
        [Alias('Version','SemanticVersion','SemVer')]
        $InputObject,

        [Parameter(ParameterSetName='Build')]
        [switch]
        $Build,

        [Parameter(ParameterSetName='PreRelease')]
        [Parameter(ParameterSetName='Patch')]
        [Parameter(ParameterSetName='Minor')]
        [Parameter(ParameterSetName='Major')]
        [switch]
        $PreRelease,

        [Parameter(ParameterSetName='Patch')]
        [switch]
        $Patch,

        [Parameter(ParameterSetName='Minor')]
        [switch]
        $Minor,

        [Parameter(ParameterSetName='Major')]
        [switch]
        $Major
    )

    <#
        ,

        [Parameter(ParameterSetName='Element')]
        [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
        [string]
        [Alias('Component')]
        $Element = 'Build'
    #>


    $updatedSemVer = New-SemanticVersion -String $InputObject.ToString()


    #foreach ($key in $PSBoundParameters.Keys) {
    #    Write-Host ('Parameter: {0}' -f $key) -ForegroundColor Green
    #}
    #
    #return
    #
    #
    #Write-Host 'Getting Parameter Set' -ForegroundColor Cyan
    #Write-Host ($PSCmdlet.ParameterSetName) -ForegroundColor Cyan
    #return


    #[bool] $IsExistingPreRelease = $false
    #[byte] $ExistingReleaseType = 0
    #
    #if ($updatedSemVer.PreRelease.Length -gt 0) {
    #    $IsExistingPreRelease = $true
    #}
    #
    #if ($updatedSemVer.Major -gt 0) {
    #    $ExistingReleaseType = 3
    #}
    #
    #if ($updatedSemVer.Minor -gt 0) {
    #    $ExistingReleaseType = 2
    #}
    #
    #if ($updatedSemVer.Patch -gt 0) {
    #    $ExistingReleaseType = 1
    #}





    if ($PSBoundParameters.Keys -contains 'Build') {
        $updatedSemVer.Increment('Build')
    }
    elseif ($PSBoundParameters.Keys -contains 'PreRelease') {
        if ($PSBoundParameters.Keys -contains 'Patch') {
            $updatedSemVer.Increment('PrePatch')
        }
        elseif ($PSBoundParameters.Keys -contains 'Minor') {
            $updatedSemVer.Increment('PreMinor')
        }
        elseif ($PSBoundParameters.Keys -contains 'Major') {
            $updatedSemVer.Increment('PreMajor')
        }
        else {
            $updatedSemVer.Increment('PreRelease')
        }
    }
    elseif ($PSBoundParameters.Keys -contains 'Patch') {
        $updatedSemVer.Increment('Patch')
    }
    elseif ($PSBoundParameters.Keys -contains 'Minor') {
        $updatedSemVer.Increment('Minor')
    }
    elseif ($PSBoundParameters.Keys -contains 'Major') {
        $updatedSemVer.Increment('Major')
    }
    else {
        $updatedSemVer.Increment('Build')
    }




    #switch ($Element) {
    #    'Build' {
    #        $updatedSemVer.Increment('Build')
    #    }
    #
    #    'PreRelease' {
    #        $updatedSemVer.Increment('PreRelease')
    #    }
    #
    #    'PrePatch' {
    #        $updatedSemVer.Increment('PrePatch')
    #    }
    #
    #    'PreMinor' {
    #        $updatedSemVer.Increment('PreMinor')
    #    }
    #
    #    'PreMajor' {
    #        $updatedSemVer.Increment('PreMajor')
    #    }
    #
    #    'Patch' {
    #        $updatedSemVer.Increment('Patch')
    #    }
    #
    #    'Minor' {
    #        $updatedSemVer.Increment('Minor')
    #    }
    #
    #    'Major' {
    #        $updatedSemVer.Increment('Major')
    #    }
    #}



    $updatedSemVer
}


function Convert-SemanticVersionToSystemVersion {
<#
.Synopsis
    Converts a Semantic Version object to a .NET System.Version object.

.DESCRIPTION
    The Convert-SemanticVersionToSystemVersion function converts a SemanticVersion object to a .NET System.Version 
    object. If the SemanticVersion object contains information that cannot be converted into the System.Version 
    object, the conversion will continue but a warning will be returned explaining the issue.

.EXAMPLE
    '1.2.3+4' | Convert-SemanticVersionToSystemVersion

    Major  Minor  Build  Revision
    -----  -----  -----  --------
    1      2      4      3

    This command converts a semantic version string into a .NET System.Version object.

.EXAMPLE
    '1.2.3-4+5' | Convert-SemanticVersionToSystemVersion

    WARNING: System.Version format does not support pre-release versions. Semantic pre-release version "4" will not be saved to
    System.Version.

    Major  Minor  Build  Revision
    -----  -----  -----  --------
    1      2      5      3

    This command converts a semantic version string into a .NET System.Version object. Because pre-release information
    is not supported by System.Version objects, a warning is returned explaining the issue.

.EXAMPLE
    '1.2.3+build' | Convert-SemanticVersionToSystemVersion

    WARNING: System.Version format does not support non-numeric build indicators. Semantic build version "build" will not be saved to
    System.Version.

    Major  Minor  Build  Revision
    -----  -----  -----  --------
    1      2      3      -1

    This command converts a semantic version string into a .NET System.Version object. Because System.Version object
    cannot contain non-numeric data, a warning is also returned.

.EXAMPLE
    '1.2.3+4.5.6' | Convert-SemanticVersionToSystemVersion

    WARNING: System.Version format does not support multiple build indicators. Only the last numeric build indicator will be retained.

    Major  Minor  Build  Revision
    -----  -----  -----  --------
    1      2      6      3

    This command converts a semantic version string into a .NET System.Version object. Because System.Version object
    cannot multiple indicators for the build number, a warning is returned.

#>
    [CmdletBinding()]
    [OutputType([System.Version])]
    param (
        # The semantic version to be converted. Must be a string or an object that can be converted to a string, and the string must be a valid semantic version string.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'InputObject is not a valid semantic version.'
            }
        })]
        [object]
        [Alias('SemanticVersion', 'SemVer')]
        $InputObject,

        # Specifies that the resulting System.Version object use all four identifiers (Major, Minor, Build, Revision). By default, the System.Version object only uses the first three identifers in order to meet semantic version specification.
        [switch]
        $ExpandAllIdentifiers,

        # Specifies that the resulting System.Version object will use the semantic version's patch number for the System.Version Build, and the semantic version's build number for the System.Version Revision. By default, the values are reversed.
        [switch]
        $ReverseBuildAndPatch

    )

    try {
        $SemVer = New-SemanticVersion -String $InputObject.ToString()
    }
    catch {
        throw 'InputObject.ToString() was not a valid semantic version string.'
    }

    [int32] $SysVerBuild = 0

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
        Write-Warning "System.Version format does not support pre-release versions. Semantic pre-release version `"$($SemVer.PreRelease)`" will not be saved to System.Version. The resulting System.Version will represent the previous non-pre-release Semantic Version."

        [uint16] $major = $SemVer.Major
        [uint16] $minor = $SemVer.Minor
        [uint16] $patch = $SemVer.Patch

        if ($patch -gt 0) {
            $patch--
        }
        elseif ($minor -gt 0) {
            $minor--
        }
        elseif ($major -gt 0) {
            $major--
        }

        $SemVer = New-SemanticVersion -Major $major -Minor $minor -Patch $patch
    }

    
    if ($ExpandAllIdentifiers -or $ReverseBuildAndPatch) {
        if ($ReverseBuildAndPatch) {
            New-Object -TypeName System.Version -ArgumentList @($SemVer.Major, $SemVer.Minor, $SemVer.Patch, $SysVerBuild)
        }
        else {
            New-Object -TypeName System.Version -ArgumentList @($SemVer.Major, $SemVer.Minor, $SysVerBuild, $SemVer.Patch)
        }
    }
    else {
        New-Object -TypeName System.Version -ArgumentList @($SemVer.Major, $SemVer.Minor, $SemVer.Patch)
    }
}


function Convert-SystemVersionToSemanticVersion {
<#
.Synopsis
    Converts a .NET System.Version object to a Semantic Version object.

.DESCRIPTION
    The Convert-SystemVersionToSemanticVersion function converts a .NET System.Version object to a SemanticVersion
    object.

.EXAMPLE
    '1.2.3.4' | Convert-SystemVersionToSemanticVersion


    Major      : 1
    Minor      : 2
    Patch      : 4
    PreRelease :
    Build      : 3

.EXAMPLE
    '1.2.3' | Convert-SystemVersionToSemanticVersion


    Major      : 1
    Minor      : 2
    Patch      : 3
    PreRelease :
    Build      :

.EXAMPLE
    '1.2.0.3' | Convert-SystemVersionToSemanticVersion


    Major      : 1
    Minor      : 2
    Patch      : 3
    PreRelease :
    Build      :

#>
    [CmdletBinding()]
    [OutputType('CustomSemanticVersion')]
    Param
    (
        # A version in System.Version format.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [version]
        $Version,

        # Specifies that if the System.Version has both a Build number and a Revision number, the build number will be used for setting the Semantic Version Patch version.
        # If not specified, the default behavior is to use the Revision number for the Patch version.
        [switch]
        $ConvertBuildToPatch
    )

    [int] $SemVerPatch = 0
    [string] $SemVerPreRelease = ''
    [string] $SemVerBuild      = ''

    if ($Version.Revision -le 0) {
        $SemVerPatch = 0

        if ($Version.Build -ge 0) {
            $SemVerPatch = [int] $Version.Build
        }
    }
    elseif ($ConvertBuildToPatch) {
        $SemVerPatch = [int] $Version.Build
    }
    else {
        $SemVerPatch = $Version.Revision

        if ($Version.Build -gt 0) {
            $SemVerBuild = $Version.Build
        }
    }

    New-SemanticVersion -Major $Version.Major -Minor $Version.Minor -Patch $SemVerPatch -Build $SemVerBuild
}


#endregion Public functions


#region Private functions


function TestPesterModuleImport {
    # This function exists only to verify we have imported the module correctly for the Pester tests.
    return $true
}


#endregion Private functions


#region Private variables


[string] $SemanticVersionTypeName = 'CustomSemanticVersion'

[string] $SemVerRegEx = '^(0|[1-9][0-9]*)' + 
                        '\.(0|[1-9][0-9]*)' + 
                        '\.(0|[1-9][0-9]*)' + 
                        '(-(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)?' + 
                        '(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'

[string] $NamedSemVerRegEx = '^(?<major>(0|[1-9][0-9]*))' + 
                             '\.(?<minor>(0|[1-9][0-9]*))' + 
                             '\.(?<patch>(0|[1-9][0-9]*))' + 
                             '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' + 
                             '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'

New-Variable BUILD_RELEASE_TYPE ([int] 0) -Option Constant
New-Variable PRERELEASE_TYPE ([int] 1) -Option Constant

data releaseType {
    @{
        Build = 0
        PreRelease = 1
        Patch = 2
        Minor = 3
        Major = 4
    }
}


#endregion Private variables


#region Execution


Export-ModuleMember -Function @('New-SemanticVersion', 'Test-SemanticVersion', 'Compare-SemanticVersion', 'Step-SemanticVersion','Convert-SemanticVersionToSystemVersion', 'Convert-SystemVersionToSemanticVersion')


#endregion Execution