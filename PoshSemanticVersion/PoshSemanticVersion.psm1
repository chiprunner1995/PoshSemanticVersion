#region Private functions


function Split-SemanticVersion {
    <#
    .Synopsis
        Splits a semantic version string into a hashtable of semantic version components.

    .Description
        Splits a semantic version string into a hashtable of semantic version components.

    .Notes
        PreRelease and Build are stored as string arrays, without the dot separators.
    #>
    [CmdletBinding()]
    [OutputType('hashtable', [hashtable])]
    param (
        # The string to split into separate components.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'Input string value is not a valid semantic version.'
            }
        })]
        [Alias('Version')]
        $InputObject
    )

    if ($InputObject.ToString() -match $NamedSemVerRegEx) {
        [hashtable] $semVerHash = @{
            Major = [int] $Matches['major']
            Minor = [int] $Matches['minor']
            Patch = [int] $Matches['patch']
        }

        if ($Matches.ContainsKey('prerelease')) {
            $semVerHash.Add('PreRelease', ([string[]] @($Matches['prerelease'] -split '\.')))
        }

        if ($Matches.ContainsKey('build')) {
            $semVerHash.Add('Build', ([string[]] @($Matches['build'] -split '\.')))
        }

        $semVerHash
    }
    else {
        throw 'Unable to parse InputObject.'
    }
}


#endregion Private functions



#region Public functions


[string[]] $exportedFunctions = @()


$exportedFunctions += 'New-SemanticVersion'
function New-SemanticVersion {
    <#
    .Synopsis
        Creates a new semantic version.

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
    [CmdletBinding(DefaultParameterSetName='Elements')]
    [OutputType('PoshSemanticVersion')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        # The major version must be incremented if any backwards incompatible changes are introduced to the public API.
        [Parameter(ParameterSetName='Elements')]
        [ValidateRange(0, 2147483647)]
        [int]
        $Major = 0,

        # The minor version must be incremented if new, backwards compatible functionality is introduced to the public API.
        [Parameter(ParameterSetName='Elements')]
        [ValidateRange(0, 2147483647)]
        [int]
        $Minor = 0,

        # The patch version must be incremented if only backwards compatible bug fixes are introduced.
        [Parameter(ParameterSetName='Elements')]
        [ValidateRange(0, 2147483647)]
        [int]
        $Patch = 0,

        # A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility requirements as denoted by its associated normal version.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array will be joined using dot separators.
        [Parameter(ParameterSetName='Elements')]
        [AllowEmptyCollection()]
        [ValidateScript({
            if ($_ -is [array]) {
                [string[]] $eval = [string[]] $_
            }
            else {
                [string[]] $eval = @($_.ToString() -split '\.')
            }

            foreach ($item in $eval) {
                if ($item -match '\s') {
                    throw 'PreRelease identifiers cannot contain spaces.'
                }

                if ($item -eq '') {
                    throw 'PreRelease identifiers MUST not be empty.'
                }

                if ($item -notmatch '^[0-9A-Za-z-]+$') {
                    throw 'PreRelease identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].'
                }

                if ($item -match '^\d\d+$' -and ($item -like '0*')) {
                    throw 'PreRelease identifiers MUST NOT include leading zeroes.'
                }
            }

            $true
        })]
        $PreRelease = [string[]] @(),

        # The build metadata.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array will be joined using dot separators.
        [Parameter(ParameterSetName='Elements')]
        [AllowEmptyCollection()]
        [ValidateScript({
            if ($_ -is [array]) {
                [string[]] $eval = [string[]] $_
            }
            else {
                [string[]] $eval = @($_.ToString() -split '\.')
            }

            foreach ($item in $eval) {
                if ($item -match '\s') {
                    throw 'Build identifiers cannot contain spaces.'
                }

                if ($item -eq '') {
                    throw 'Build identifiers MUST NOT be empty.'
                }

                if ($item -notmatch '^[0-9A-Za-z-]+$') {
                    throw 'Build identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].'
                }
            }

            $true
        })]
        $Build = [string[]] @(),

        # A valid semantic version string to be converted into a SemanticVersion object.
        [Parameter(ParameterSetName='String',
                   ValueFromPipeline=$true,
                   Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_) {
                $true
            }
            else {
                throw 'Input string value is not a valid semantic version.'
            }
        })]
        [Alias('String', 'Version')]
        $InputObject
    )

    # Unfortunately, PSv2 does not think that $PreRelease or $Build are initialized if the user did not specify anything for the parameter, even if the default value is an empty array, so we have to do the following.
    if ($PSBoundParameters.ContainsKey('PreRelease')) {
        if ($PreRelease -isnot [array]) {
            [string[]] $PreRelease = @($PreRelease.ToString() -split '\.')
        }
    }
    else {
        [string[]] $PreRelease = @()
    }

    if ($PSBoundParameters.ContainsKey('Build')) {
        if ($Build -isnot [array]) {
            [string[]] $Build = @($Build.ToString() -split '\.')
        }
    }
    else {
        [string[]] $Build = @()
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Elements' {
        }

        'String' {
            [hashtable] $semVerHash = Split-SemanticVersion $InputObject.ToString()

            switch ($semVerHash.Keys) {
                'Major' {
                    $Major = $semVerHash['Major']
                }

                'Minor' {
                    $Minor = $semVerHash['Minor']
                }

                'Patch' {
                    $Patch = $semVerHash['Patch']
                }

                'PreRelease' {
                    $PreRelease = $semVerHash['PreRelease']
                }

                'Build' {
                    $Build = $semVerHash['Build']
                }
            }
        }
    }

    [psobject] $semVer = New-Module -Name ($customObjectTypeName + 'DynamicModule') -ArgumentList @($Major, $Minor, $Patch, $PreRelease, $Build) -AsCustomObject -ScriptBlock {
        [CmdletBinding()]
        param (
            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int]
            $Major = 0,

            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int]
            $Minor = 0,

            # An unsigned int.
            [ValidateRange(0, 2147483647)]
            [int]
            $Patch = 0,

            # A string.
            [ValidatePattern('^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$')]
            [string[]]
            $PreRelease = @(),

            # A string.
            [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
            [string[]]
            $Build = @()
        )

        New-Variable -Name customObjectTypeName -Value PoshSemanticVersion -Option Constant

        [string[]] $_preRelease = $PreRelease
        [string[]] $_build = $Build



        #Set-Variable -Name Major, Minor, Patch, PreRelease, Build -Option ReadOnly

        function CompareTo {
            <#
            .Synopsis
                Compare this SemVerObj to another.
            .Description
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
                    if (@($_.pstypenames) -contains 'PoshSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "PoshSemanticVersion".'
                    }
                })]
                [psobject]
                $Version
            )

            [int] $returnValue = 0

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

            if ($returnValue -eq 0 -and ($PreRelease.Length -ne 0 -or ($Version.GetPreRelease().Length -ne 0))) {
                if ($PreRelease.Length -eq 0 -and ($Version.GetPreRelease().Length -ne 0)) {
                    $returnValue = 1
                }
                elseif ($PreRelease.Length -ne 0 -and ($Version.GetPreRelease().Length -eq 0)) {
                    $returnValue = -1
                }
            }

            if ($returnValue -eq 0) {
                #[string[]] $PreReleaseArray = [string]::Join('.', $PreRelease) -split '\.'
                [string[]] $VersionPreRelease = $Version.GetPreRelease()
                #[int] $shortestArray = $PreReleaseArray.Length
                [int] $shortestArray = $PreRelease.Length

                if ($shortestArray -gt $VersionPreRelease.Length) {
                    $shortestArray = $VersionPreRelease.Length
                }

                for ([int] $i = 0; $i -lt $shortestArray; $i++) {
                    if ($PreRelease[$i] -notmatch '^[0-9]+$' -and ($VersionPreRelease[$i] -match '^[0-9]+$')) {
                        $returnValue = 1
                    }
                    elseif ($PreRelease[$i] -match '^[0-9]+$' -and ($VersionPreRelease[$i] -notmatch '^[0-9]+$')) {
                        $returnValue = -1
                    }
                    elseif ($PreRelease[$i] -gt $VersionPreRelease[$i]) {
                        $returnValue = 1
                    }
                    elseif ($PreRelease[$i] -lt $VersionPreRelease[$i]) {
                        $returnValue = -1
                    }

                    if ($returnValue -ne 0) {
                        break
                    }
                }

                if ($returnValue -eq 0) {
                    if ($PreRelease.Length -gt $VersionPreRelease.Length) {
                        $returnValue = 1
                    }
                    elseif ($PreRelease.Length -lt $VersionPreRelease.Length) {
                        $returnValue = -1
                    }
                }
            }

            return $returnValue
        }

        function CompatibleWith {
            <#
            .Synopsis
                Test if the current version is compatible with the parameter argument version.
            #>
            [CmdletBinding()]
            [OutputType([bool])]
            param (
                # The number to be incremented.
                [Parameter(Mandatory=$true)]
                [ValidateScript({
                    if (@($_.pstypenames) -contains 'PoshSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "PoshSemanticVersion".'
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
            #elseif ([string]::Join('.', $PreRelease) -ne [string]::Join('.', $Version.GetPreRelease())) {
            elseif ($PreRelease.Length -ne 0 -and $Version.GetPreRelease().Length -ne 0) {
                if ([string]::Join('.', $PreRelease) -ne [string]::Join('.', $Version.GetPreRelease())) {
                    $IsCompatible = $false
                }
                else {
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
            }
            elseif ($PreRelease.Length -ne 0 -or $Version.GetPreRelease().Length -ne 0) {
                $IsCompatible = $false
            }

            return $IsCompatible
        }

        function Equals {
            <#
            .Synopsis
                Determine if this semver object is equal in precedence to another semver object.
            #>
            [CmdletBinding()]
            [OutputType([bool])]
            param (
                # The number to be incremented.
                [Parameter(Mandatory=$true)]
                [ValidateScript({
                    if (@($_.pstypenames) -contains 'PoshSemanticVersion') {
                        $true
                    }
                    else {
                        throw 'Input object type must be of type "PoshSemanticVersion".'
                    }
                })]
                [psobject]
                $Version
            )

            (CompareTo -Version $Version) -eq 0
        }

        function GetBuild {
            <#
            .Synopsis
                Returns the build element as a string array.
            #>
            [CmdletBinding()]
            [OutputType([string[]])]
            param ()

            return $Build
        }

        #function GetHashCode {
        #    [CmdletBinding()]
        #    [OutputType([int])]
        #    param ()
        #    [int] $hash = 13
        #
        #    $hash = ($hash * 7) + $Major.GetHashCode()
        #    $hash = ($hash * 7) + $Minor.GetHashCode()
        #    $hash = ($hash * 7) + $Patch.GetHashCode()
        #    $hash = ($hash * 7) + $PreRelease.GetHashCode()
        #
        #    return $hash
        #}

        function GetMajor {
            <#
            .Synopsis
                Returns the major element of the version.
            #>
            [CmdletBinding()]
            [OutputType([int])]
            param ()

            return $Major
        }

        function GetMinor {
            <#
            .Synopsis
                Returns the minor element of the version.
            #>
            [CmdletBinding()]
            [OutputType([int])]
            param ()

            return $Minor
        }

        function GetPatch {
            <#
            .Synopsis
                Returns the patch element of the version.
            #>
            [CmdletBinding()]
            [OutputType([int])]
            param ()

            return $Patch
        }

        function GetPreRelease {
            <#
            .Synopsis
                Returns the prerelease element as a string array.
            #>
            [CmdletBinding()]
            [OutputType([string[]])]
            param ()

            return $PreRelease
        }

        function Increment {
            <#
            .Synopsis
                Increments the version by the specifield release level.
            #>
            [CmdletBinding()]
            [OutputType([void])]
            param (
                [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
                [string]
                $Level = 'PreRelease'
            )

            [int] $numericValue = 0

            switch ($Level) {
                'Build' {
                    if ($Build.Length -eq 0) {
                        $Script:Build = @('0')
                    }
                    else {
                        if (-not ($Build[-1].Length -gt 1 -and $Build[-1] -like '0*') -and [int]::TryParse($Build[-1], [ref] $numericValue)) {
                            $Script:Build[-1] = [string] ++$numericValue
                        }
                        else {
                            $Script:Build += '0'
                        }
                    }
                }

                'PreRelease' {
                    if ($PreRelease.Length -eq 0) {
                        $Script:Patch++
                        $Script:PreRelease = @('0')
                    }
                    else {
                        if (-not ($PreRelease[-1].Length -gt 1 -and $PreRelease[-1] -like '0*') -and [int]::TryParse($PreRelease[-1], [ref] $numericValue)) {
                            $Script:PreRelease[-1] = [string] ++$numericValue
                        }
                        else {
                            $Script:PreRelease += '0'
                        }
                    }
                }

                'PrePatch' {
                    $Script:PreRelease = @()
                    $Script:Patch++
                    $Script:PreRelease = @('0')
                }

                'PreMinor' {
                    $Script:PreRelease = @()
                    $Script:Patch = 0
                    $Script:Minor++
                    $Script:PreRelease = @('0')
                }

                'PreMajor' {
                    $Script:PreRelease = @()
                    $Script:Patch = 0
                    $Script:Minor = 0
                    $Script:Major++
                    $Script:PreRelease = @('0')
                }

                'Patch' {
                    if ($PreRelease.Length -eq 0) {
                        $Script:Patch++
                    }

                    $Script:PreRelease = @()
                }

                'Minor' {
                    if ($Patch -ne 0 -or $PreRelease.Length -eq 0) {
                        $Script:Minor++
                    }

                    $Script:PreRelease = @();
                    $Script:Patch = 0
                }

                'Major' {
                    if ($Patch -ne 0 -or $Minor -ne 0 -or $PreRelease.Length -eq 0) {
                        $Script:Major++
                    }

                    $Script:PreRelease = @()
                    $Script:Minor = 0
                    $Script:Patch = 0
                }

                default {
                    throw ('Invalid release level: {0}' -f $Level)
                }
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

        function ToString {
            <#
            .Synopsis
                Return a string representation of this object.
            #>
            [CmdletBinding()]
            [OutputType([string])]
            param ()

            [string] "$Major.$Minor.$Patch$(
                if ($PreRelease.Length -ne 0) {
                    '-' + [string]::Join('.', $PreRelease)
                }
            )$(
                if ($Build.Length -ne 0) {
                    '+' + [string]::Join('.', $Build)
                }
            )"
        }

        [bool] $InDevelopmentMode = $false
        if ($PreRelease.Length) {
            Set-Variable -Name InDevelopmentMode -Value $true -Force
        }

        Export-ModuleMember -Function @(
            'CompareTo',
            'Equals',
            #'GetHashCode',
            'CompatibleWith',
            'ToString',
            'Increment',
            'GetMajor',
            #'SetMajor',
            'GetMinor',
            #'SetMinor',
            'GetPatch',
            #'SetPatch',
            'GetPreRelease',
            #'SetPreRelease',
            'GetBuild'
            #'SetBuild',
        )
    }

    $semVer.pstypenames.Insert(0, $customObjectTypeName)

    $semVer
}


$exportedFunctions += 'Test-SemanticVersion'
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
    [OutputType('bool', [bool])]
    param (
        # The semantic version string to validate.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        $Version
    )

    if ($Version.ToString() -match $SemVerRegEx) {
        $true
    }
    else {
        $false
    }
}


$exportedFunctions += 'Compare-SemanticVersion'
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
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 1',
                   Position=0)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'ReferenceVersion is not a valid semantic version.'
            }
        })]
        $ReferenceVersion,

        # Specifies the version that is compared to the reference version.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Parameter Set 1',
                   Position=1)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw 'DifferenceVersion is not a valid semantic version.'
            }
        })]
        $DifferenceVersion
    )

    $refVer = New-SemanticVersion -InputObject $ReferenceVersion.ToString()
    $difVer = New-SemanticVersion -InputObject $DifferenceVersion.ToString()

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


$exportedFunctions += 'Step-SemanticVersion'
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
        Step-SemanticVersion -Version 1.1.1 -Level Minor

        Major      : 1
        Minor      : 2
        Patch      : 0
        PreRelease :
        Build      :

        This command converts the string '1.1.1' to the semantic version object equivalent of '1.2.0'.

    .EXAMPLE
        Step-SemanticVersion -v 1.1.1 -i patch

        Major      : 1
        Minor      : 1
        Patch      : 2
        PreRelease :
        Build      :

        This command converts the string '1.1.1' to the semantic version object equivalent of '1.1.2'. This example shows the use of the parameter aliases "v" and "i" for Version and Level (increment), respectively.

    .EXAMPLE
        Step-SemanticVersion 1.1.1 Major

        Major      : 2
        Minor      : 0
        Patch      : 0
        PreRelease :
        Build      :

        This command converts the string '1.1.1' to the semantic version object equivalent of '2.0.0'. This example shows the use of positional parameters.

    .NOTES
        Test Results

            SemVer  Build PreRelease PrePatch PreMinor PreMajor Patch  Minor  Major
            ------  ----- ---------- -------- -------- -------- ------ ------ -----
            0.0.0-0       0.0.0-1    0.0.1-0  0.1.0-0  1.0.0-0  0.0.0  0.0.0  0.0.0
            0.0.0         0.0.1-0    0.0.1-0  0.1.0-0  1.0.0-0  0.0.1  0.1.0  1.0.0
            1.0.0-0       1.0.0-1    1.0.1-0  1.1.0-0  2.0.0-0  1.0.0  1.0.0  1.0.0
            1.0.0         1.0.1-0    1.0.1-0  1.1.0-0  2.0.0-0  1.0.1  1.1.0  2.0.0
            1.0.1-0       1.0.1-1    1.0.2-0  1.1.0-0  2.0.0-0  1.0.1  1.1.0  2.0.0
            1.0.1         1.0.2-0    1.0.2-0  1.1.0-0  2.0.0-0  1.0.2  1.1.0  2.0.0
            1.1.0-0       1.1.0-1    1.1.1-0  1.2.0-0  2.0.0-0  1.1.0  1.1.0  2.0.0
            1.1.0         1.1.1-0    1.1.1-0  1.2.0-0  2.0.0-0  1.1.1  1.2.0  2.0.0
            1.1.1-0       1.1.1-1    1.1.2-0  1.2.0-0  2.0.0-0  1.1.1  1.2.0  2.0.0
            1.1.1         1.1.2-0    1.1.2-0  1.2.0-0  2.0.0-0  1.1.2  1.2.0  2.0.0
            2.0.0-0       2.0.0-1    2.0.1-0  2.1.0-0  3.0.0-0  2.0.0  2.0.0  2.0.0
            2.0.0         2.0.1-0    2.0.1-0  2.1.0-0  3.0.0-0  2.0.1  2.1.0  3.0.0

    #>
    [CmdletBinding()]
    [OutputType('PoshSemanticVersion')]
    param (
        # The semantic version number to be incremented.
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
        [Alias('InputObject', 'v')]
        $Version,

        # The part of the version to increment.
        # Valid values are Build, PreRelease, PrePatch, PreMinor, PreMajor, Patch, Minor, or Major.
        # The default value is PreRelease.
        [Parameter(Position=1)]
        [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
        [string]
        [Alias('Release', 'Increment', 'i')]
        $Level = 'PreRelease'
    )

    $newSemVer = New-SemanticVersion -InputObject $Version

    switch ($Level) {
        'Build' {
            $newSemVer.Increment('Build')
        }

        'PreRelease' {
            $newSemVer.Increment('PreRelease')
        }

        'PrePatch' {
            $newSemVer.Increment('PrePatch')
        }

        'PreMinor' {
            $newSemVer.Increment('PreMinor')
        }

        'PreMajor' {
            $newSemVer.Increment('PreMajor')
        }

        'Patch' {
            $newSemVer.Increment('Patch')
        }

        'Minor' {
            $newSemVer.Increment('Minor')
        }

        'Major' {
            $newSemVer.Increment('Major')
        }

        default {
            throw ('Invalid release level: "{0}".' -f $Level)
        }
    }

    $newSemVer
}


#endregion Public functions


#region Private variables


New-Variable -Name CustomObjectTypeName -Value PoshSemanticVersion -Option Constant


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


#endregion Private variables


Export-ModuleMember -Function $exportedFunctions
