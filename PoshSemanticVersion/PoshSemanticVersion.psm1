<#
 .SYNOPSIS
    PoshSemanticVersion module.
#>

param ()

# Initialization code is BELOW the function definitions.


#region Internal functions


function Split-SemanticVersion {
    <#
     .SYNOPSIS
        Splits up a Semantic Version string into a hastable.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        # The string to split into Semantic Version components.
        [Parameter(Mandatory=$true)]
        [string]
        [Alias('version')]
        $string
    )

    [hashtable] $semVerHash = @{}

    if ($string -match $NamedSemVerRegEx) {
        $semVerHash['Major'] = $Matches['major']
        $semVerHash['Minor'] = $Matches['minor']
        $semVerHash['Patch'] = $Matches['patch']

        if ($Matches.ContainsKey('prerelease')) {
            $semVerHash['PreRelease'] =  [string[]] @($Matches['prerelease'] -split '\.')
        }
        else {
            $semVerHash['PreRelease'] = @()
        }

        if ($Matches.ContainsKey('build')) {
            $semVerHash['Build'] = [string[]] @($Matches['build'] -split '\.')
        }
        else {
            $semVerHash['Build'] = @()
        }
    }
    else {
        throw 'Unable to parse string.'
    }

    $semVerHash
}


#endregion Internal functions


#region Exported functions

[System.Collections.Generic.List[string]] $exportedFunctions = [Activator]::CreateInstance([System.Collections.Generic.List[string]])


$exportedFunctions.Add('New-SemanticVersion')
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

        This command take the Major, Minor, Patch, PreRelease, and Build parameters and produces the same output as the
        previous example.

     .EXAMPLE
        $semver = New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.4 -Build build.5

        $semver.ToString()

        1.2.3-alpha.4+build.5

        This example shows that the object output from the previous command can be saved to a variable. Then by
        calling the object's ToString() method, a valid Semantic Version string is returned.
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

        # A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility
        # requirements as denoted by its associated normal version.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array
        # will be joined using dot separators.
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
                    throw ($messages.MetadataIdentifierCannotContainSpaces -f $messages.PreReleaseLabelName)
                }

                if ($item -eq '') {
                    throw ($messages.MetadataIdentifierCannotBeEmpty -f $messages.PreReleaseLabelName)
                }

                if ($item -notmatch '^[0-9A-Za-z-]+$') {
                    throw ($messages.MetadataIdentifierCanOnlyContainAlphanumericsAndHyphen -f $messages.PreReleaseLabelName)
                }

                if ($item -match '^\d\d+$' -and ($item -like '0*')) {
                    throw $messages.PreReleaseIdentifierCannotHaveLeadingZero
                }
            }

            $true
        })]
        $PreRelease = [string[]] @(),

        # The build metadata.
        # The value can be a string or an array of strings. If an array of strings is provided, the elements of the array
        # will be joined using dot separators.
        [Parameter(ParameterSetName='Elements')]
        [AllowEmptyCollection()]
        [ValidateScript({
            if ($_ -is [array]) {
                [string[]] $eval = [string[]] $_
            }
            else {
                [string[]] $eval = [string[]] @($_.ToString() -split '\.')
            }

            foreach ($item in $eval) {
                if ($item -match '\s') {
                    throw ($messages.MetadataIdentifierCannotContainSpaces -f $messages.BuildLabelName)
                }

                if ($item -eq '') {
                    throw ($messages.MetadataIdentifierCannotBeEmpty -f $messages.BuildLabelName)
                }

                if ($item -notmatch '^[0-9A-Za-z-]+$') {
                    throw ($messages.MetadataIdentifierCanOnlyContainAlphanumericsAndHyphen -f $messages.BuildLabelName)
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
            $er = Test-SemanticVersion -Version $_ -AsErrorRecord
            if ($null -eq $er) {
                $true
            }
            else {
                throw $er
            }
        })]
        [Alias('String', 'Version')]
        $InputObject
    )

    # Unfortunately, PSv2 does not think that $PreRelease or $Build are initialized if the user did not specify
    # anything for the parameter, even if the default value is an empty array, so we have to do the following.
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
            [string[]]
            $PreRelease = @(),

            # A string.
            [string[]]
            $Build = @()
        )

        New-Variable -Name customObjectTypeName -Value PoshSemanticVersion -Option Constant
        New-Variable -Name NamedSemVerRegEx -Value (
            '^(?<major>(0|[1-9][0-9]*))' +
            '\.(?<minor>(0|[1-9][0-9]*))' +
            '\.(?<patch>(0|[1-9][0-9]*))' +
            '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' +
            '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
        ) -Option Constant
        New-Variable -Name PreReleasePattern -Value '^(|(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)$' -Option Constant
        New-Variable -Name BuildPattern -Value '^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$' -Option Constant

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
                    if (@($_.pstypenames) -contains 'PoshSemanticVersion') {
                        $true
                    }
                    else {
                        #throw (New-Object -TypeName System.ArgumentException -ArgumentList @(($messages.ObjectNotOfType -f $customObjectTypeName)))
                        throw (New-Object -TypeName System.ArgumentException -ArgumentList @('Invalid object type "{0}".' -f $_.GetType()))
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
                [string[]] $VersionPreRelease = $Version.GetPreRelease()
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
                        if ($Label -notmatch $BuildPattern) {
                            throw (New-Object -TypeName System.ArgumentException -ArgumentList @('Invalid Build label specified.'))
                        }
                    }

                    'Pre*' {
                        if ($Label -notmatch $PreReleasePattern) {
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
                    if ($PSBoundParameters.ContainsKey('Label') -and $Label -match $BuildPattern) {
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
                [ValidatePattern('^(|([0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))$')]
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

    $semVer.pstypenames.Insert(0, $customObjectTypeName)

    $semVer
}


$exportedFunctions.Add('Test-SemanticVersion')
function Test-SemanticVersion {
    <#
     .SYNOPSIS
        Tests if a string is a valid Semantic Version.

     .DESCRIPTION
        The Test-SemanticVersion function verifies that a supplied string meets the Semantic Version 2.0 specification.

        If an invalid Semantic Version string is supplied to Test-SemanticVersion and the Verbose switch is used, the
        verbose output stream will include additional details that may help when troubleshooting an invalid version.

     .EXAMPLE
        Test-SemanticVersion '1.2.3-alpha.1+build.456'

        True

        This example shows the result if the provided string is a valid Semantic Version.

     .EXAMPLE
        Test-SemanticVersion '1.2.3-alpha.01+build.456'

        False

        This example shows the result if the provided string is not a valid Semantic Version.

     .INPUTS
        System.Object

            Any objects used as input to this function are converted to strings before being processed.

     .NOTES
        Determining problems with invalid Semantic Version strings

            1.  Validate normal version Major/Minor/Patch
                a.  Validate element count is 3
                b.  Validate not empty elements
                c.  Validate non-negative integer values
                d.  Validate no leading zeros
            2.  Validate pre-release label
                a.  Identifiers MUST NOT be empty
                b.  Identifiers MUST comprise only ASCII alphanumerics and hyphen
                c.  Numeric identifiers MUST NOT include leading zeroes
            3.  Validate build label
                a.  Identifiers MUST NOT be empty
                b.  Identifiers MUST comprise only ASCII alphanumerics and hyphen
    #>
    [CmdletBinding(DefaultParameterSetName='BoolOutput')]
    [OutputType([bool], ParameterSetName='BoolOutput')]
    [OutputType([System.Management.Automation.ErrorRecord], ParameterSetName='ErrorRecord')]
    param (
        # The Semantic Version string to validate.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [object[]]
        [Alias('Version')]
        $InputObject,

        # Indicates that this function returns ErrorRecord objects instead of boolean values.
        [Parameter(Mandatory=$true,
                   ParameterSetName='ErrorRecord')]
        [switch]
        $AsErrorRecord
    )

    begin {
        [string] $normalVersionPattern = '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
        [string] $preReleasePattern = '^(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*$'
        [string] $buildPattern = '^[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*$'
    }

    process {
        foreach ($item in $InputObject) {
            [string] $version = $item -as [string]
            [bool] $isValid = $version -match $semVerRegEx
            [string] $messageId = ''
            [string] $message = ''
            [string] $recommendedAction = ''

            if ($isValid) {
                $messageId = 'ValidSemanticVersion'
                $message = $messages[$messageId] -f $version
                $recommendedAction = ''

                if (-not $AsErrorRecord) {
                    $isValid
                }
            }
            else {
                [string] $normalVersion = ''
                [string] $prereleaseLabel = ''
                [string] $buildLabel = ''

                # Try to split the string into the standard semver parts in order to find out why it is invalid.
                # normalVersion-preRelease+build
                if ($version.Contains('-') -and $version.Contains('+')) {
                    $normalVersion = @($version -split '\-', 2)[0]
                    $prereleaseLabel = @(@($version -split '\-', 2)[-1] -split '\+', 2)[0]
                    $buildLabel = @(@($version -split '\-', 2)[-1] -split '\+', 2)[-1]
                }
                # normalVersion-preRelease
                elseif ($version.Contains('-') -and -not $version.Contains('+')) {
                    $normalVersion = @($version -split '\-', 2)[0]
                    $prereleaseLabel = @($version -split '\-', 2)[-1]
                    $buildLabel = ''
                }
                # normalVersion+build
                elseif (-not $version.Contains('-') -and $version.Contains('+')) {
                    $normalVersion = @($version -split '\+', 2)[0]
                    $prereleaseLabel = ''
                    $buildLabel = @($version -split '\+', 2)[-1]
                }
                # normalVersion
                else {
                    $normalVersion = $version
                    $prereleaseLabel = ''
                    $buildLabel = ''
                }

                Write-Debug "`$normalVersion: $normalVersion"
                Write-Debug "`$prereleaseLabel: $prereleaseLabel"
                Write-Debug "`$buildLabel: $buildLabel"

                # Validate normal version.
                if ($normalVersion -notmatch $normalVersionPattern) {
                    $messageId = 'CannotParseNormalVersion'
                    $message = $messages[$messageId]
                    $recommendedAction = $messages[$messageId + 'RecommendedAction']

                    [string[]] $normalVersionElements = $normalVersion -split '\-'
                    if ($normalVersionElements.Length -ne 3) {
                        $message = 'A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative integers, and MUST NOT contain leading zeroes. X is the major version, Y is the minor version, and Z is the patch version.'
                    }
                    else {
                        for ($i = 0; $i -lt $normalVersionElements.Length; $i++) {
                            switch ($i) {
                                0 {$elementName = 'Major'}
                                1 {$elementName = 'Minor'}
                                2 {$elementName = 'Patch'}
                            }

                            if ($normalVersionElements[$i].Trim() -eq '') {
                                $message = '{0} version must not be empty' -f $elementName
                                break
                            }

                            if ($normalVersionElements[$i] -notmatch '^\d+$') {
                                #$message = '{0} version must be a non-negative integer value.' -f $elementName
                                $messageId = 'ElementCannotBeNegativeOrHaveLeadingZero'
                                $message = $messages[$messageId] -f $elementName
                                $recommendedAction = $messages[$messageId + 'RecommendedAction']
                                break
                            }

                            if ($normalVersionElements[$i] -as [int] -as [string] -ne $normalVersionElements[$i]) {
                                #$message = '{0} version must not contain leading zeros.' -f $elementName
                                $messageId = 'ElementCannotBeNegativeOrHaveLeadingZero'
                                $message = $messages[$messageId] -f $elementName
                                $recommendedAction = $messages[$messageId + 'RecommendedAction']
                                break
                            }
                        }
                    }
                }
                # Validate pre-release.
                elseif ($prereleaseLabel.Length -ne 0 -and $prereleaseLabel -notmatch $preReleasePattern) {
                    $messageId = 'LabelInvalid'
                    $message = $messages[$messageId] -f 'PreRelease'
                    $recommendedAction = $messages[$messageId + 'RecommendedAction']

                    [string[]] $prereleaseIndicators = @($prereleaseLabel -split '\.')
                    for ($i = 0; $i -lt $prereleaseIndicators.Length; $i++) {
                        if ($prereleaseIndicators[$i].Trim() -eq '') {
                            $message = '{0} indicator at index {1} cannot be empty.' -f 'Pre-release', $i
                        }
                        elseif ($prereleaseIndicators[$i] -notmatch '^([0-9A-Z-][A-Z-]*|[1-9A-Z-][0-9A-Z-]+)$') {
                            $message = '{0} indicator at index {1} must contain only alphanumeric characters or hyphen. Numeric indicators must not contain leading zero.' -f 'Pre-release', $i
                        }
                    }
                }
                # Validate build.
                elseif ($buildLabel.Length -ne 0 -and $buildLabel -notmatch $buildPattern) {
                    $messageId = 'LabelInvalid'
                    $message = $messages[$messageId] -f 'Build'
                    $recommendedAction = $messages[$messageId + 'RecommendedAction']

                    [string[]] $buildIndicators = @($buildLabel -split '\.')
                    for ($i = 0; $i -lt $buildIndicators.Length; $i++) {
                        if ($buildIndicators[$i].Trim() -eq '') {
                            $message = '{0} indicator at index {1} cannot be empty.' -f 'Build', $i
                        }
                        elseif ($buildIndicators[$i] -notmatch '^[0-9A-Z-]+$') {
                            $message = '{0} indicator at index {1} must contain only alphanumeric characters or hyphen.' -f 'Build', $i
                        }
                    }
                }

                if ($AsErrorRecord) {
                    [System.FormatException] $ex = New-Object -TypeName System.FormatException -ArgumentList @($message)

                    [hashtable] $erHash = @{
                        Exception = $ex
                        Message = $message
                        Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                        ErrorId = $messageId
                        TargetObject = $item
                        RecommendedAction = $recommendedAction
                        CategoryActivity = 'Test-SemanticVersion'
                        CategoryReason = 'Invalid Input'
                        CategoryTargetName = 'InputObject'
                        CategoryTargetType = $item.GetType()
                    }

                    [System.Management.Automation.ErrorRecord] $errorRecord = Write-Error @erHash 2>&1

                    $errorRecord
                }
                else {
                    $isValid
                }
            }
            Write-Verbose $message
        }
    }
}


$exportedFunctions.Add('Compare-SemanticVersion')
function Compare-SemanticVersion {
    <#
     .SYNOPSIS
        Compares two semantic version numbers.

     .DESCRIPTION
        The Test-SemanticVersion function compares two semantic version numbers and returns an object that contains the
        results of the comparison.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.1.1' -DifferenceVersion '1.2.0'

        ReferenceVersion DifferenceVersion Precedence AreCompatible
        ---------------- ----------------- ---------- -------------
        1.1.1            1.2.0             <                   True

        This command show sthe results of compare two semantic version numbers that are not equal in precedence but are
        compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '0.1.1' -DifferenceVersion '0.1.0'

        ReferenceVersion DifferenceVersion Precedence AreCompatible
        ---------------- ----------------- ---------- -------------
        0.1.1            0.1.0             >                  False

        This command shows the results of comparing two semantic version numbers that are are not equal in precedence
        and are not compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3' -DifferenceVersion '1.2.3-0'

        ReferenceVersion DifferenceVersion Precedence AreCompatible
        ---------------- ----------------- ---------- -------------
        1.2.3            1.2.3-0           >                  False

        This command shows the results of comparing two semantic version numbers that are are not equal in precedence
        and are not compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+5'

        ReferenceVersion DifferenceVersion Precedence AreCompatible
        ---------------- ----------------- ---------- -------------
        1.2.3-4+5        1.2.3-4+5         =                   True

        This command shows the results of comparing two semantic version numbers that are exactly equal in precedence.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+6789'

        ReferenceVersion DifferenceVersion Precedence AreCompatible
        ---------------- ----------------- ---------- -------------
        1.2.3-4+5        1.2.3-4+6789      =                   True

        This command shows the results of comparing two semantic version numbers that are exactly equal in precedence,
        even if they have different build numbers.

     .NOTES
        To sort a collection of Semantic Version numbers based on the semver.org precedence rules

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
                throw ($messages.ValueNotValidSemanticVersion -f 'ReferenceVersion')
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
                throw ($messages.ValueNotValidSemanticVersion -f 'DifferenceVersion')
            }
        })]
        $DifferenceVersion
    )

    $refVer = New-SemanticVersion -InputObject $ReferenceVersion.ToString()
    $difVer = New-SemanticVersion -InputObject $DifferenceVersion.ToString()

    [int] $precedence = $refVer.CompareTo($difVer)

    $result = [Activator]::CreateInstance([psobject])
    $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
        'ReferenceVersion',
        $refVer.ToString()
    )))
    $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
        'DifferenceVersion',
        $difVer.ToString()
    )))
    $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
        'Precedence',
        $(
            if ($precedence -eq 0) {
                '='
            }
            elseif ($precedence -gt 0) {
                '>'
            }
            else {
                '<'
            }
        )
    )))
    $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
        #TODO: This should read "IsCompatible", not "AreCompatible".
        'AreCompatible',
        $refVer.CompatibleWith($difVer)
    )))

    $result
}


$exportedFunctions.Add('Step-SemanticVersion')
function Step-SemanticVersion {
    <#
     .SYNOPSIS
        Increments a Semantic Version number.

     .DESCRIPTION
        The Step-SemanticVersion function increments the elements of a Semantic Version number in a way that is
        compliant with the Semantic Version 2.0 specification.

        - Incrementing the Major number will reset the Minor number and the Patch number to 0. A pre-release version
          will be incremented to the normal version number.
        - Incrementing the Minor number will reset the Patch number to 0. A pre-release version will be incremented to
          the normal version number.
        - Incrementing the Patch number does not change any other parts of the version number. A pre-release version
          will be incremented to the normal version number.
        - Incrementing the PreRelease number does not change any other parts of the version number.
        - Incrementing the Build number does not change any other parts of the version number.

     .EXAMPLE
        '1.1.1' | Step-SemanticVersion

        Major      : 1
        Minor      : 1
        Patch      : 2
        PreRelease : 0
        Build      :

        This command takes a semantic version string from the pipeline and increments the pre-release version. Because
        the element to increment was not specified, the default value of 'PreRelease was used'.

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

        This command converts the string '1.1.1' to the semantic version object equivalent of '1.1.2'. This example
        shows the use of the parameter aliases "v" and "i" for Version and Level (increment), respectively.

     .EXAMPLE
        Step-SemanticVersion 1.1.1 Major

        Major      : 2
        Minor      : 0
        Patch      : 0
        PreRelease :
        Build      :

        This command converts the string '1.1.1' to the semantic version object equivalent of '2.0.0'. This example
        shows the use of positional parameters.

     .NOTES
        Values used when determining valid test results:

            SemVer  PreRelease PrePatch PreMinor PreMajor Patch  Minor  Major
            ------  ---------- -------- -------- -------- ------ ------ -----
            0.0.0-0 0.0.0-1    0.0.1-0  0.1.0-0  1.0.0-0  0.0.0  0.0.0  0.0.0
            0.0.0   0.0.1-0    0.0.1-0  0.1.0-0  1.0.0-0  0.0.1  0.1.0  1.0.0
            1.0.0-0 1.0.0-1    1.0.1-0  1.1.0-0  2.0.0-0  1.0.0  1.0.0  1.0.0
            1.0.0   1.0.1-0    1.0.1-0  1.1.0-0  2.0.0-0  1.0.1  1.1.0  2.0.0
            1.0.1-0 1.0.1-1    1.0.2-0  1.1.0-0  2.0.0-0  1.0.1  1.1.0  2.0.0
            1.0.1   1.0.2-0    1.0.2-0  1.1.0-0  2.0.0-0  1.0.2  1.1.0  2.0.0
            1.1.0-0 1.1.0-1    1.1.1-0  1.2.0-0  2.0.0-0  1.1.0  1.1.0  2.0.0
            1.1.0   1.1.1-0    1.1.1-0  1.2.0-0  2.0.0-0  1.1.1  1.2.0  2.0.0
            1.1.1-0 1.1.1-1    1.1.2-0  1.2.0-0  2.0.0-0  1.1.1  1.2.0  2.0.0
            1.1.1   1.1.2-0    1.1.2-0  1.2.0-0  2.0.0-0  1.1.2  1.2.0  2.0.0
            2.0.0-0 2.0.0-1    2.0.1-0  2.1.0-0  3.0.0-0  2.0.0  2.0.0  2.0.0
            2.0.0   2.0.1-0    2.0.1-0  2.1.0-0  3.0.0-0  2.0.1  2.1.0  3.0.0
    #>
    [CmdletBinding()]
    [OutputType('PoshSemanticVersion')]
    param (
        # The Semantic Version number to be incremented.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateScript({
            if (Test-SemanticVersion -Version $_.ToString()) {
                $true
            }
            else {
                throw ($messages.ValueNotValidSemanticVersion -f 'InputObject')
            }
        })]
        [Alias('Version', 'v')]
        $InputObject,

        # The desired increment type.
        # Valid values are Build, PreRelease, PrePatch, PreMinor, PreMajor, Patch, Minor, or Major.
        # The default value is PreRelease.
        [Parameter(Position=1)]
        [string]
        [ValidateSet('Build', 'PreRelease', 'PrePatch', 'PreMinor', 'PreMajor', 'Patch', 'Minor', 'Major')]
        [Alias('Release', 'i')]
        $Increment = 'PreRelease',

        # The metadata label to use for an increment type of Build, PreRelease, PreMajor, PreMinor, or PrePatch.
        # If specified, the value replaces the existing label. If not specified, the label will be incremented.
        # This parameter is ignored for an increment type of Major, Minor, or Patch.
        [Parameter(Position=2)]
        [string]
        [Alias('preid', 'Identifier')]
        $Label
    )

    $newSemVer = New-SemanticVersion -InputObject $InputObject

    if ($PSBoundParameters.ContainsKey('Label')) {
        try {
            $newSemVer.Increment($Increment, $Label)
        }
        catch [System.ArgumentOutOfRangeException],[System.ArgumentException] {
            $er = Write-Error -Exception $_.Exception -Category InvalidArgument -TargetObject $InputObject 2>&1
            $PSCmdlet.ThrowTerminatingError($er)
        }
        catch {
            $er = Write-Error -Exception $_.Exception -Message ('Error using label "{0}" when incrementing version "{1}".' -f $Label, $InputObject.ToString()) -TargetObject $InputObject 2>&1
            $PSCmdlet.ThrowTerminatingError($er)
        }
    }
    else {
        $newSemVer.Increment($Increment)
    }

    $newSemVer
}


#endregion Exported functions


#region Internal variables


New-Variable -Name CustomObjectTypeName -Value PoshSemanticVersion -Option Constant

New-Variable -Name SemVerRegEx -Value (
    '^(0|[1-9][0-9]*)\.' +
    '(0|[1-9][0-9]*)\.' +
    '(0|[1-9][0-9]*)' +
    '(-(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*)?' +
    '(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
) -Option Constant

New-Variable -Name NamedSemVerRegEx -Value (
    '^(?<major>(0|[1-9][0-9]*))' +
    '\.(?<minor>(0|[1-9][0-9]*))' +
    '\.(?<patch>(0|[1-9][0-9]*))' +
    '(-(?<prerelease>(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*)(\.(0|[1-9][0-9]*|[0-9]+[A-Za-z-]+[0-9A-Za-z-]*|[A-Za-z-]+[0-9A-Za-z-]*))*))?' +
    '(\+(?<build>[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*))?$'
) -Option Constant

[hashtable] $messages = data {
    ConvertFrom-StringData @'
    ValidSemanticVersion=
    InvalidSemanticVersion=
    ElementCannotBeNegativeOrHaveLeadingZero={0} version must be a non-negative integer and must not contain leading zeros.
    ElementCannotBeNegativeOrHaveLeadingZeroRecommendedAction=Verify the element is a non-negative integer and does not have leading zeros.
    CannotParseNormalVersion=A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative integers, and MUST NOT contain leading zeroes. X is the major version, Y is the minor version, and Z is the patch version.
    CannotParseNormalVersionRecommendedAction=Verify the input string begins with three non-negative integers without leading zeros.
    LabelInvalid={0} label is not valid.
    LabelInvalidRecommendedAction=Verify the label is in the correct format.
    FileNotFoundError=The specified file was not found.
    MetadataIdentifierCanOnlyContainAlphanumericsAndHyphen={0} identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].
    MetadataIdentifierCannotContainSpaces={0} identifier cannot contain spaces.
    MetadataIdentifierCannotBeEmpty={0} identifiers MUST not be empty.
    PreReleaseIdentifierCannotHaveLeadingZero=PreRelease identifiers MUST NOT include leading zeroes.
    PreReleaseLabelName=PreRelease
    BuildLabelName=Build
    ValueNotValidSemanticVersion={0} value is not a valid semantic version.
    ObjectNotOfType=Input object type must be of type "{0}".
    InvalidReleaseLevel=Invalid release level: "{0}".
'@
}

[hashtable] $localizedMessages = @{}

#endregion Internal variables

Import-LocalizedData -BindingVariable localizedMessages -Filename messages -ErrorAction SilentlyContinue

foreach ($key in $localizedMessages.Keys) {
    $messages[$key] = $localizedMessages[$key]
}

#Export-ModuleMember -Function $exportedFunctions

Remove-Variable exportedFunctions, localizedMessages, key