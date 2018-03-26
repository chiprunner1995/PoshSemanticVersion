function New-SemanticVersion {
    <#
     .SYNOPSIS
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

        This command converts a valid Semantic Version string into a Semantic Version object. The output of the command
        is a Semantic Version object with the elements of the version split into separate properties.

     .EXAMPLE
        New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.4 -Build build.5

        Major      : 1
        Minor      : 2
        Patch      : 3
        PreRelease : alpha.4
        Build      : build.5

        This command takes the Major, Minor, Patch, PreRelease, and Build parameters and produces the same output as the
        previous example.

     .EXAMPLE
        New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha, 4 -Build build, 5

        Major      : 1
        Minor      : 2
        Patch      : 3
        PreRelease : alpha.4
        Build      : build.5

        This command uses arrays for the PreRelease and Build parameters, but produces the same output as the
        previous example.

     .EXAMPLE
        $semver = New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.4 -Build build.5

        $semver.ToString()

        1.2.3-alpha.4+build.5

        This example shows that the object output from the previous command can be saved to a variable. Then by
        calling the object's ToString() method, a valid Semantic Version string is returned.

     .INPUTS
        System.Object

            All Objects piped to this function are converted into Semantic Version objects.

    #>
    [CmdletBinding(DefaultParameterSetName='Elements')]
    [Alias('nsemver')]
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

        # A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility
        # requirements as denoted by its associated normal version.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array
        # will be joined using dot separators.
        [Parameter(ParameterSetName='Elements')]
        [AllowEmptyCollection()]
        $PreRelease = @(),

        # The build metadata.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array
        # will be joined using dot separators.
        [Parameter(ParameterSetName='Elements')]
        [AllowEmptyCollection()]
        $Build = @(),

        # A valid semantic version string to be converted into a SemanticVersion object.
        [Parameter(ParameterSetName='String',
                   ValueFromPipeline=$true,
                   Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            [int] $tmpInt = 0
            [decimal] $tmpDecimal = 0.0

            if ([int]::TryParse($_.ToString(), [ref] $tmpInt)) {
                $paramValue = '{0}.0.0' -f $tmpInt
            }
            elseif ([decimal]::TryParse($_.ToString(), [ref] $tmpDecimal)) {
                $paramValue = '{0}.0' -f $tmpDecimal
            }
            else {
                $paramValue = $_
            }

            if (Test-SemanticVersion -InputObject $paramValue) {
                return $true
            }
            else {
                $erHash = Debug-SemanticVersion -InputObject $paramValue -ParameterName InputObject
                $er = Write-Error @erHash 2>&1
                throw ($er)
            }
        })]
        [Alias('Version', 'v', 'String')]
        [object[]]
        $InputObject
    )

    begin {
        [scriptblock] $semVerDynamicModuleScriptBlock = {
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
                [Parameter(Mandatory=$true)]
                [ValidateScript({$($_ -match '^(0|(\d*[A-Z-]+|[1-9A-Z-])[\dA-Z-]*)$')})]
                [string[]]
                $PreRelease = @(),

                # A string.
                [ValidateScript({$($_ -match '^[\dA-Z-]+$')})]
                [string[]]
                $Build = @()
            )

            New-Variable -Option Constant -Name customObjectTypeName -Value PoshSemanticVersion

            New-Variable -Option Constant -Name PreReleaseIdRegEx -Value '^(0|(\d*[A-Z-]+|[1-9A-Z-])[\dA-Z-]*)$'

            New-Variable -Option Constant -Name PreReleaseRegEx -Value '^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$'

            New-Variable -Option Constant -Name BuildIdRegEx -Value '^[\dA-Z-]+$'

            New-Variable -Option Constant -Name BuildRegEx -Value '^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$'

            New-Variable -Option Constant -Name SemVerRegEx -Value $(
                '^(0|[1-9]\d*)' +
                '(\.(0|[1-9]\d*)){2}' +
                '(-(0|(\d*[A-Z-]+|[1-9A-Z-])[\dA-Z-]*)(\.(0|(\d*[A-Z-]+|[1-9A-Z-])[\dA-Z-]*))*)?' +
                '(\+[\dA-Z-]*(\.[\dA-Z-]*)?)?' +
                '(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
            )

            New-Variable -Option Constant -Name NamedSemVerRegEx -Value $(
                '^(?<major>(0|[1-9][0-9]*))' +
                '\.(?<minor>(0|[1-9][0-9]*))' +
                '\.(?<patch>(0|[1-9][0-9]*))' +
                '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' +
                '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
            )



            [System.Collections.Generic.List[string]] $exportedFunctions = [Activator]::CreateInstance([System.Collections.Generic.List[string]])

            $exportedFunctions.Add('CompareTo')
            function CompareTo {
                <#
                 .SYNOPSIS
                    Compare this SemVerObj to another.
                 .DESCRIPTION
                    Returns 0 if both objects are equal
                    Returns 1 if this object is a higher precedence than the other.
                    Returns -1 if this object is a lower precedence than the other.
                #>
                [CmdletBinding()]
                [OutputType([int])]
                param (
                    # The number to be incremented.
                    [Parameter(Mandatory=$true)]
                    [ValidateScript({
                        $(@($_.pstypenames) -contains $customObjectTypeName)
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
                    [string[]] $VersionPreRelease = $Version.GetPreRelease()
                    [int] $shortestArray = $PreRelease.Length

                    if ($shortestArray -gt $VersionPreRelease.Length) {
                        $shortestArray = $VersionPreRelease.Length
                    }

                    for ([int] $i = 0; $i -lt $shortestArray; $i++) {
                        if ($PreRelease[$i] -match '^[0-9]+$' -and ($VersionPreRelease[$i] -match '^[0-9]+$')) {
                            if (([int] $PreRelease[$i]) -gt ([int] $VersionPreRelease[$i])) {
                                $returnValue = 1
                            }
                            elseif (([int] $PreRelease[$i]) -lt ([int] $VersionPreRelease[$i])) {
                                $returnValue = -1
                            }
                        }
                        elseif ($PreRelease[$i] -notmatch '^[0-9]+$' -and ($VersionPreRelease[$i] -match '^[0-9]+$')) {
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

                $returnValue
            }

            function CompareVersions {
                <#
                 .SYNOPSIS
                    Compare this version with a new string.
                 .DESCRIPTION
                    This is an internal implementation of CompareTo that does not require the Typename name to match.

                    Returns 0 if both objects are equal
                    Returns 1 if this object is a higher precedence than the other.
                    Returns -1 if this object is a lower precedence than the other.
                #>
                [CmdletBinding()]
                [OutputType([int])]
                param (
                    # The version to compare against.
                    [Parameter(Mandatory=$true)]
                    [ValidateScript({$($_ -match $NamedSemVerRegEx)})]
                    [string]
                    $DifferenceVersion
                )

                [int] $returnValue = 0

                if ($DifferenceVersion -match $NamedSemVerRegEx) {
                    [hashtable] $difHash = @{}

                    $difHash['Major'] = [int] $Matches['major']
                    $difHash['Minor'] = [int] $Matches['minor']
                    $difHash['Patch'] = [int] $Matches['patch']
                    $difHash['PreRelease'] = [string[]] @()
                    $difHash['Build'] = [string[]] @()

                    if ($Matches.ContainsKey('preRelease')) {
                        $difHash['PreRelease'] = [string[]] @($Matches['preRelease'] -split '\.')
                    }

                    if ($Matches.ContainsKey('build')) {
                        $difHash['Bulid'] = [string[]] @($Matches['build'] -split '\.')
                    }
                }
                else {
                    throw (New-Object -TypeName System.ArgumentException -ArgumentList @('DifferenceVersion was invalid Semantic Version string.'))
                }


                if ($Major -gt $difHash.Major) {
                    $returnValue = 1
                }
                elseif ($Major -lt $difHash.Major) {
                    $returnValue = -1
                }

                if ($returnValue -eq 0) {
                    if ($Minor -gt $difHash.Minor) {
                        $returnValue = 1
                    }
                    elseif ($Minor -lt $difHash.Minor) {
                        $returnValue = -1
                    }
                }

                if ($returnValue -eq 0) {
                    if ($Patch -gt $difHash.Patch) {
                        $returnValue = 1
                    }
                    elseif ($Patch -lt $difHash.Patch) {
                        $returnValue = -1
                    }
                }

                if ($returnValue -eq 0 -and ($PreRelease.Length -ne 0 -or ($difHash.PreRelease.Length -ne 0))) {
                    if ($PreRelease.Length -eq 0 -and ($difHash.PreRelease.Length -ne 0)) {
                        $returnValue = 1
                    }
                    elseif ($PreRelease.Length -ne 0 -and ($difHash.PreRelease.Length -eq 0)) {
                        $returnValue = -1
                    }
                }

                if ($returnValue -eq 0) {
                    [string[]] $VersionPreRelease = $difHash.PreRelease
                    [int] $shortestArray = $PreRelease.Length

                    if ($shortestArray -gt $VersionPreRelease.Length) {
                        $shortestArray = $VersionPreRelease.Length
                    }

                    for ([int] $i = 0; $i -lt $shortestArray; $i++) {
                        if ($PreRelease[$i] -match '^[0-9]+$' -and ($VersionPreRelease[$i] -match '^[0-9]+$')) {
                            if (([int] $PreRelease[$i]) -gt ([int] $VersionPreRelease[$i])) {
                                $returnValue = 1
                            }
                            elseif (([int] $PreRelease[$i]) -lt ([int] $VersionPreRelease[$i])) {
                                $returnValue = -1
                            }
                        }
                        elseif ($PreRelease[$i] -notmatch '^[0-9]+$' -and ($VersionPreRelease[$i] -match '^[0-9]+$')) {
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

                $returnValue
            }

            $exportedFunctions.Add('CompatibleWith')
            function CompatibleWith {
                <#
                 .SYNOPSIS
                    Test if the current version is compatible with the parameter argument version.
                #>
                [CmdletBinding()]
                [OutputType([bool])]
                param (
                    # The number to be incremented.
                    [Parameter(Mandatory=$true)]
                    [ValidateScript({$(@($_.pstypenames) -contains $customObjectTypeName)})]
                    [psobject]
                    $Version
                )

                [bool] $isCompatible = $true

                if ((CompareTo -Version $Version) -eq 0) {
                    $isCompatible = $true
                }
                elseif ($Major -eq 0) {
                    $isCompatible = $false
                }
                elseif ($Major -ne $Version.Major) {
                    $isCompatible = $false
                }
                elseif ($PreRelease.Length -ne 0 -and $Version.GetPreRelease().Length -ne 0) {
                    if ([string]::Join('.', $PreRelease) -ne [string]::Join('.', $Version.GetPreRelease())) {
                        $isCompatible = $false
                    }
                    else {
                        if ($Major -ne $Version.Major) {
                            $isCompatible = $false
                        }
                        if ($Minor -ne $Version.Minor) {
                            $isCompatible = $false
                        }
                        if ($Patch -ne $Version.Patch) {
                            $isCompatible = $false
                        }
                    }
                }
                elseif ($PreRelease.Length -ne 0 -or $Version.GetPreRelease().Length -ne 0) {
                    $isCompatible = $false
                }

                $isCompatible
            }

            $exportedFunctions.Add('Equals')
            function Equals {
                <#
                 .SYNOPSIS
                    Determine if this semver object is equal in precedence to another semver object.
                #>
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
                    $Version
                )

                (CompareTo -Version $Version) -eq 0
            }

            $exportedFunctions.Add('GetBuild')
            function GetBuild {
                <#
                 .SYNOPSIS
                    Returns the build element as a string array.
                #>
                [OutputType([string[]])]
                param ()

                $Build
            }

            $exportedFunctions.Add('GetMajor')
            function GetMajor {
                <#
                 .SYNOPSIS
                    Returns the major element of the version.
                #>
                [OutputType([int])]
                param ()

                $Major
            }

            $exportedFunctions.Add('GetMinor')
            function GetMinor {
                <#
                 .SYNOPSIS
                    Returns the minor element of the version.
                #>
                [OutputType([int])]
                param ()

                $Minor
            }

            $exportedFunctions.Add('GetPatch')
            function GetPatch {
                <#
                 .SYNOPSIS
                    Returns the patch element of the version.
                #>
                [OutputType([int])]
                param ()

                $Patch
            }

            $exportedFunctions.Add('GetPreRelease')
            function GetPreRelease {
                <#
                 .SYNOPSIS
                    Returns the prerelease element as a string array.
                #>
                [OutputType([string[]])]
                param ()

                $PreRelease
            }

            $exportedFunctions.Add('Increment')
            function Increment {
                <#
                 .SYNOPSIS
                    Increments the version by the specifield release level.
                #>
                [OutputType([void])]
                param (
                    # The type on increment level to perform.
                    [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
                    [string]
                    $Level = 'PreRelease',

                    # An optional label that can be used with a Level value of "Build" or any of the "Pre*" Levels.
                    [string]
                    $Label
                )

                [int] $numericValue = 0

                if ($PSBoundParameters.ContainsKey('Label')) {
                    switch -Wildcard ($Level) {
                        'Build' {
                            if ($Label -notmatch $BuildRegEx) {
                                throw (New-Object -TypeName System.ArgumentException -ArgumentList @('Invalid Build label specified.'))
                            }
                        }

                        'Pre*' {
                            if ($Label -notmatch $PreReleaseRegEx) {
                                throw (New-Object -TypeName System.ArgumentException -ArgumentList @('Invalid PreRelease label specified.'))
                            }
                        }

                        default {
                            Write-Warning -Message 'The Label parameter is only used when combined with a Level parameter value of Build, PreRelease, PreMajor, PreMinor, or PrePatch. It will be ignored.'
                        }
                    }
                }

                switch ($Level) {
                    'Build' {
                        if ($PSBoundParameters.ContainsKey('Label') -and $Label -match $BuildRegEx) {
                            $Script:Build = @($Label -split '\.')
                        }
                        elseif ($Build.Length -eq 0) {
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

                            if ($PSBoundParameters.ContainsKey('Label')) {
                                $Script:PreRelease = @($Label -split '\.')
                            }
                            else {
                                $Script:PreRelease = @('0')
                            }
                        }
                        else {
                            if ($PSBoundParameters.ContainsKey('Label')) {
                                # If there is an existing prerelease label, the new label must be of a higher precedence.
                                if ((CompareVersions -DifferenceVersion ('{0}.{1}.{2}-{3}' -f $Major, $Minor, $Patch, $Label)) -lt 0) {
                                    $Script:PreRelease = @($Label -split '\.')
                                }
                                else {
                                    throw (New-Object -TypeName System.ArgumentOutOfRangeException -ArgumentList @('Label', 'New prerelease label is must be of a higher precedence than existing prerelease label.'))
                                }
                            }
                            elseif (-not ($PreRelease[-1].Length -gt 1 -and $PreRelease[-1] -like '0*') -and [int]::TryParse($PreRelease[-1], [ref] $numericValue)) {
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
                        if ($PSBoundParameters.ContainsKey('Label')) {
                            $Script:PreRelease = @($Label -split '\.')
                        }
                        else {
                            $Script:PreRelease = @('0')
                        }
                    }

                    'PreMinor' {
                        $Script:PreRelease = @()
                        $Script:Patch = 0
                        $Script:Minor++
                        if ($PSBoundParameters.ContainsKey('Label')) {
                            $Script:PreRelease = @($Label -split '\.')
                        }
                        else {
                            $Script:PreRelease = @('0')
                        }
                    }

                    'PreMajor' {
                        $Script:PreRelease = @()
                        $Script:Patch = 0
                        $Script:Minor = 0
                        $Script:Major++
                        if ($PSBoundParameters.ContainsKey('Label')) {
                            $Script:PreRelease = @($Label -split '\.')
                        }
                        else {
                            $Script:PreRelease = @('0')
                        }
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

            $exportedFunctions.Add('SetBuild')
            function SetBuild {
                <#
                 .SYNOPSIS
                    Set the build version
                #>
                [CmdletBinding()]
                [OutputType([void])]
                param (
                    # The new build label.
                    [Parameter(Mandatory=$true)]
                    [ValidateScript({$($_ -match $BuildRegEx)})]
                    [string]
                    $Build
                )

                $Script:Build = $Build
            }

            $exportedFunctions.Add('ToString')
            function ToString {
                <#
                 .SYNOPSIS
                    Return a string representation of this object.
                #>
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

            Export-ModuleMember -Function $exportedFunctions

            Remove-Variable exportedFunctions
        }

    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Elements') {
            [string] $badParameterName = 'InputObject'

            # PSv2 does not initialize $PreRelease or $Build if they were not specifies or if they had empty arrays.
            # So they have to be reinitialized here if they were not specified.
            if ($PSBoundParameters.ContainsKey('Build')) {
                [string] $testBuild = $Build -join '.'
                if ($testBuild -notmatch ('^' + $BuildPattern + '$')) {
                    $badParameterName = 'Build'
                }
                [string[]] $Build = @($testBuild -split '\.')
            }
            else {
                [string[]] $Build = @()
            }

            if ($PSBoundParameters.ContainsKey('PreRelease')) {
                [string] $testPreRelease = $PreRelease -join '.'
                if ($testPreRelease -notmatch ('^' + $PreReleasePattern + '$')) {
                    $badParameterName = 'PreRelease'
                }
                [string[]] $PreRelease = @($testPreRelease -split '\.')
            }
            else {
                [string[]] $PreRelease = @()
            }

            [string] $InputObject = "$Major.$Minor.$Patch$(if ($PreRelease.Length -gt 0) {'-' + $($PreRelease -join '.')})$(if ($Build.Length -gt 0) {'+' + $($Build -join '.')})"

            if (-not $(Test-SemanticVersion -InputObject $InputObject)) {
                $erHash = Debug-SemanticVersion -InputObject $InputObject -ParameterName $badParameterName
                $er = Write-Error @erHash 2>&1
                $PSCmdlet.ThrowTerminatingError($er)
            }
        }

        foreach ($item in $InputObject) {
            [int] $tmpInt = 0
            [decimal] $tmpDecimal = 0.0

            if ([int]::TryParse($item.ToString(), [ref] $tmpInt)) {
                $paramValue = '{0}.0.0' -f $tmpInt
            }
            elseif ([decimal]::TryParse($item.ToString(), [ref] $tmpDecimal)) {
                $paramValue = '{0}.0' -f $tmpDecimal
            }
            else {
                $paramValue = $item
            }

            [hashtable] $semVerHash = Split-SemanticVersion $paramValue.ToString()

            switch ($semVerHash.Keys) {
                'Major' {
                    [int] $Major = $semVerHash['Major']
                }

                'Minor' {
                    [int] $Minor = $semVerHash['Minor']
                }

                'Patch' {
                    [int] $Patch = $semVerHash['Patch']
                }

                'PreRelease' {
                    [string[]] $PreRelease = @($semVerHash['PreRelease'])
                }

                'Build' {
                    [string[]] $Build = @($semVerHash['Build'])
                }
            }

            [psobject] $semVer = New-Module -Name ($customObjectTypeName + 'DynamicModule') -ArgumentList @($Major, $Minor, $Patch, $PreRelease, $Build) -AsCustomObject -ScriptBlock $semVerDynamicModuleScriptBlock

            $semVer.pstypenames.Insert(0, $customObjectTypeName)

            $semVer
        }
    }
}


Export-ModuleMember -Function New-SemanticVersion -Alias nsemver
