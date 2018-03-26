function Compare-SemanticVersion {
    <#
     .SYNOPSIS
        Compares two semantic version numbers.

     .DESCRIPTION
        The Test-SemanticVersion function compares two semantic version numbers and returns an object that contains the
        results of the comparison.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.1.1' -DifferenceVersion '1.2.0'

        ReferenceVersion Precedence DifferenceVersion IsCompatible
        ---------------- ---------- ----------------- ------------
        1.1.1            <          1.2.0                     True

        This command show sthe results of compare two semantic version numbers that are not equal in precedence but are
        compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '0.1.1' -DifferenceVersion '0.1.0'

        ReferenceVersion Precedence DifferenceVersion IsCompatible
        ---------------- ---------- ----------------- ------------
        0.1.1            >          0.1.0                    False

        This command shows the results of comparing two semantic version numbers that are are not equal in precedence
        and are not compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3' -DifferenceVersion '1.2.3-0'

        ReferenceVersion Precedence DifferenceVersion IsCompatible
        ---------------- ---------- ----------------- ------------
        1.2.3            >          1.2.3-0                  False

        This command shows the results of comparing two semantic version numbers that are are not equal in precedence
        and are not compatible.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+5'

        ReferenceVersion Precedence DifferenceVersion IsCompatible
        ---------------- ---------- ----------------- ------------
        1.2.3-4+5        =          1.2.3-4+5                 True

        This command shows the results of comparing two semantic version numbers that are exactly equal in precedence.

     .EXAMPLE
        Compare-SemanticVersion -ReferenceVersion '1.2.3-4+5' -DifferenceVersion '1.2.3-4+6789'

        ReferenceVersion Precedence DifferenceVersion IsCompatible
        ---------------- ---------- ----------------- ------------
        1.2.3-4+5        =          1.2.3-4+6789              True

        This command shows the results of comparing two semantic version numbers that are exactly equal in precedence,
        even if they have different build numbers.

     .INPUTS
        System.Object

            Any objects you pipe into this function are converted into strings then are evaluated as Semantic Versions.

     .OUTPUTS
        psobject

            The output objects are custom psobject with detail of how the ReferenceVersion compares with the
            DifferenceVersion

     .NOTES
        To sort a collection of Semantic Version numbers based on the semver.org precedence rules

            Sort-Object -Property Major,Minor,Patch,@{e = {$_.PreRelease -eq ''}; Ascending = $true},PreRelease,Build

    #>
    [CmdletBinding()]
    [Alias('crsemver')]
    [OutputType([psobject])]
    param (
        # Specifies the version used as a reference for comparison.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Parameter Set 1',
                   Position=0)]
        [ValidateScript({
            if (Test-SemanticVersion -InputObject $_) {
                return $true
            }
            else {
                $erHash = Debug-SemanticVersion -InputObject $_ -ParameterName ReferenceVersion
                $er = Write-Error @erHash 2>&1
                throw $er
            }
        })]
        [Alias('r')]
        $ReferenceVersion,

        # Specifies the version that is compared to the reference version.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='Parameter Set 1',
                   Position=1)]
        [ValidateScript({
            if (Test-SemanticVersion -InputObject $_) {
                return $true
            }
            else {
                $erHash = Debug-SemanticVersion -InputObject $_ -ParameterName DifferenceVersion
                $er = Write-Error @erHash 2>&1
                throw ($er)
            }
        })]
        [Alias('d', 'InputObject')]
        $DifferenceVersion
    )

    begin {
        $refVer = New-SemanticVersion -InputObject $ReferenceVersion.ToString()
    }

    process {
        foreach ($item in $DifferenceVersion) {
            $difVer = New-SemanticVersion -InputObject $item.ToString()

            [int] $precedence = $refVer.CompareTo($difVer)

            $result = [Activator]::CreateInstance([psobject])
            $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
                'ReferenceVersion',
                $refVer.ToString()
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
                'DifferenceVersion',
                $difVer.ToString()
            )))
            $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSNoteProperty], @(
                'IsCompatible',
                $refVer.CompatibleWith($difVer)
            )))
            $result.psobject.Members.Add([Activator]::CreateInstance([System.Management.Automation.PSAliasProperty], @(
                #TODO: Deprecate: This should read "IsCompatible", not "AreCompatible".
                'AreCompatible',
                'IsCompatible'
            )))

            $result.pstypenames.Insert(0, 'PoshSemanticVersionComparison')

            $result
        }
    }
}


Export-ModuleMember -Function Compare-SemanticVersion -Alias crsemver
