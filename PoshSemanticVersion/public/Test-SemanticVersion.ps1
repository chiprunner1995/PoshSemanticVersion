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

            Any object you pipe to this function will be converted to a string and tested for validity.

    #>
    [CmdletBinding(DefaultParameterSetName='BoolOutput')]
    [Alias('tsemver')]
    [OutputType([bool])]
    param (
        # The Semantic Version string to validate.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [object[]]
        [Alias('Version', 'v')]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            [string] $version = $item -as [string]

            $debugHash = Debug-SemanticVersion -InputObject $item -ParameterName InputObject
            Write-Verbose -Message ($debugHash.Message + ' ' + $debugHash.RecommendedAction)

            $version -match ('^' + $SemanticVersionPattern + '$')
        }
    }
}


Export-ModuleMember -Function Test-SemanticVersion -Alias tsemver
