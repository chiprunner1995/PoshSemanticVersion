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
        [ValidateScript({
            if (Test-SemanticVersion -InputObject $_) {
                return $true
            }
            else {
                $erHash = Debug-SemanticVersion -InputObject $_ -ParameterName string
                $er = Write-Error @erHash 2>&1
                throw ($er)
            }
        })]
        [string]
        [Alias('Version', 'String')]
        $InputObject
    )

    [hashtable] $semVerHash = @{}

    if ($InputObject -match ('^' + $NamedSemanticVersionPattern + '$')) {
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
