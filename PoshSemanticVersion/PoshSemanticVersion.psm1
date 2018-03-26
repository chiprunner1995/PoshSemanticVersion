param ()

Set-StrictMode -Version Latest

# Initialization code is BELOW the function definitions.

#TODO: Load private functions.
$privateScriptFiles = @(Get-ChildItem -Path $PSScriptRoot/private/*.ps1)
foreach ($file in $privateScriptFiles) {
    . $file.FullName
}

# Load public functions.
$publicScriptFiles = @(Get-ChildItem -Path $PSScriptRoot/public/*.ps1)
foreach ($file in $publicScriptFiles) {
    . $file.FullName
}

#region Internal variables

New-Variable -Option Constant -Name CustomObjectTypeName -Value PoshSemanticVersion
Write-Debug "CustomObjectTypeName: $CustomObjectTypeName"

New-Variable -Scope Script -Option Constant -Name NormalVersionElementPattern -Value $(
    '(0|[1-9]\d*)'
)
Write-Debug "NormalVersionElementPattern: $NormalVersionElementPattern"

New-Variable -Scope Script -Option Constant -Name NormalVersionPattern -Value $(
    $NormalVersionElementPattern +
    '(\.' + $NormalVersionElementPattern + '){2}'
)
Write-Debug "NormalVersionPattern: $NormalVersionPattern"

New-Variable -Scope Script -Option Constant -Name PreReleaseIdentifierPattern -Value $(
    '(0|(\d*[A-Z-]+|[1-9A-Z-])[\dA-Z-]*)'
)
Write-Debug "PreReleaseIdentifierPattern: $PreReleaseIdentifierPattern"

New-Variable -Scope Script -Option Constant -Name PreReleasePattern -Value $(
    $PreReleaseIdentifierPattern +
    '(\.' + $PreReleaseIdentifierPattern + ')*'
)
Write-Debug "PreReleasePattern: $PreReleasePattern"

New-Variable -Scope Script -Option Constant -Name BuildIdentifierPattern -Value $(
    '[\dA-Z-]+'
)
Write-Debug "BuildIdentifierPattern: $BuildIdentifierPattern"

New-Variable -Scope Script -Option Constant -Name BuildPattern -Value $(
    $BuildIdentifierPattern +
    '(\.' + $BuildIdentifierPattern + ')*'
)
Write-Debug "BuildPattern: $BuildPattern"

New-Variable -Scope Script -Option Constant -Name SemanticVersionPattern -Value $(
    $NormalVersionPattern +
    '(\-' + $PreReleasePattern + ')?' +
    '(\+' + $BuildPattern + ')?'
)
Write-Debug "`$SemanticVersionPattern: $SemanticVersionPattern"

New-Variable -Option Constant -Name NamedSemanticVersionPattern -Value $(
    '(?<major>' + $NormalVersionElementPattern + ')' +
    '\.(?<minor>' + $NormalVersionElementPattern + ')' +
    '\.(?<patch>' + $NormalVersionElementPattern + ')' +
    '(-(?<prerelease>' + $PreReleasePattern + '))?' +
    '(\+(?<build>' + $BuildPattern + '))?'
)
Write-Debug "`$NamedSemanticVersionPattern: $NamedSemanticVersionPattern"

[hashtable] $messages = data {
    ConvertFrom-StringData @'
    ValidSemanticVersion="{0}" is a valid Semantic Version.
    InvalidSemanticVersion="{0}" is not a valid Semantic Version.
    InvalidSemanticVersionRecommendedAction=Verify the value meets the Semantic Version specification.
    InvalidNormalVersion=A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative integers, and MUST NOT contain leading zeroes. X is the major version, Y is the minor version, and Z is the patch version.
    InvalidNormalVersionRecommendedAction=Verify the input string begins with three non-negative integers without leading zeros.
    InvalidNormalVersionElementCount=A normal version must have exactly 3 elements. The input normal version "{0}" has {1} element(s).
    InvalidNormalVersionElementCountRecommendedAction=Verify the input string has a normal version with 3 elements.
    NormalVersionElementIsEmpty={0} version element must not be empty.
    NormalVersionElementIsEmptyRecommendedAction=Verify the {0} version element is a non-negative integer value without leading zeros.
    CannotConvertNormalVersionElementToInt={0} version must be a non-negative integer and must not contain leading zeros.
    CannotConvertNormalVersionElementToIntRecommendedAction=Verify the {0} version element is a non-negative integer value without leading zeros.
    InvalidMetadataLabel={0} label is not valid.
    InvalidMetadataLabelRecommendedAction=Verify the {0} label is in the correct format.
    MetadataIdentifierIsEmpty={0} identifier at index {1} MUST not be empty.
    MetadataIdentifierIsEmptyRecommendedAction=Verify the {0} label has no empty identifiers.
    InvalidPreReleaseIdentifier=Pre-release indentifier at index {0} MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty. Numeric identifiers MUST NOT include leading zeroes.
    InvalidPreReleaseIdentifierRecommendedAction=Verify the pre-release label comprises only ASCII alphanumerics and hyphen and numeric indicators do not contain leading zeros.
    InvalidBuildIdentifier=Build indentifier at index {0} MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty.
    InvalidBuildIdentifierRecommendedAction=Verify the build label comprises only ASCII alphanumerics and hyphen.
    FileNotFoundError=The specified file was not found.
    PreReleaseLabelName=pre-release
    BuildLabelName=build
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

[System.Globalization.CultureInfo] $Script:cultureInfo = Get-Culture
[System.Globalization.TextInfo] $Script:textInfo = $cultureInfo.TextInfo

Remove-Variable privateScriptFiles, publicScriptFiles, file, localizedMessages, key
