function Debug-SemanticVersion {
    <#
     .SYNOPSIS
        Finds problems with a Semantic Version string and recommends solutions.

     .DESCRIPTION
        The Debug-SemanticVersion function finds problems with a Semantic Version string and recommends solutions.

        It is used by other functions in the SemanticVersion module to get the appropriate error message when a
        Semantic Version string is invalid.

     .EXAMPLE
        An example

     .NOTES
        General notes
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        # The object to debug. Object will be converted to a string for evaluation.
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [object[]]
        [Alias('Version')]
        $InputObject,

        # The name of the parameter that is being debugged/validated. If specified, the name will be added to the returned exception and error details objects.
        [string]
        $ParameterName = 'InputObject'
    )

    begin {
        # Default values.
        [System.Management.Automation.ErrorCategory] $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
    }

    process {
        foreach ($item in $InputObject) {
            [string] $version = $item -as [string]
            [bool] $isValid = $version -match ('^' + $SemanticVersionPattern + '$')
            [string] $messageId = ''
            [string] $message = ''
            [string] $recommendedAction = ''
            [hashtable] $outputHash = @{
                Message = ''
            }

            if ($isValid) {
                $messageId = 'ValidSemanticVersion'
                $message = $messages[$messageId] -f $version
                $outputHash['Message'] = $message
                $outputHash['RecommendedAction'] = $recommendedAction
            }
            else {
                $messageId = 'InvalidSemanticVersion'
                $message = $messages[$messageId] -f $version
                $recommendedAction = $messages[$messageId + 'RecommendedAction']

                [System.ArgumentException] $ex = New-Object -TypeName System.ArgumentException -ArgumentList @($message, $ParameterName)
                $outputHash['Exception'] = $ex
                $outputHash['Category'] = $errorCategory
                $outputHash['TargetObject'] = $item
                $outputHash['CategoryActivity'] = 'Debug-SemanticVersion'
                $outputHash['CategoryTargetName'] = $ParameterName
                $outputHash['CategoryTargetType'] = $item.GetType()
                $outputHash['CategoryReason'] = $messageId

                [string] $normalVersion = ''
                [string] $prereleaseLabel = ''
                [string] $buildLabel = ''

                # Try to split the string into the standard semver parts in order to find out why it is invalid.
                # normalVersion-preRelease+build
                $elementCountSplit = $version -split '\.'
                if ($elementCountSplit.Length -eq 3) {
                    $normalVersion = $version
                    $prereleaseLabel = ''
                    $buildLabel = ''
                }
                elseif ($version.Contains('-') -and $version.Contains('+')) {
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
                if ($normalVersion -notmatch ('^' + $NormalVersionPattern + '$')) {
                    $messageId = 'InvalidNormalVersion'
                    $message = $messages[$messageId]
                    $recommendedAction = $messages[$messageId + 'RecommendedAction']

                    [string[]] $normalVersionElements = @($normalVersion -split '\.')
                    if ($normalVersionElements.Length -ne 3) {
                        $messageId = 'InvalidNormalVersionElementCount'
                        $message = $messages[$messageId] -f $normalVersion, $normalVersionElements.Length
                        $recommendedAction = $messages[$messageId + 'RecommendedAction']
                    }
                    else {
                        for ($i = 0; $i -lt $normalVersionElements.Length; $i++) {
                            switch ($i) {
                                0 {$elementName = 'Major'}
                                1 {$elementName = 'Minor'}
                                2 {$elementName = 'Patch'}
                            }

                            if ($normalVersionElements[$i] -match ('^' + $NormalVersionElementPattern + '$')) {
                                continue
                            }
                            elseif ($normalVersionElements[$i].Trim() -eq '') {
                                $messageId = 'NormalVersionElementIsEmpty'
                                $message = $messages[$messageId] -f $elementName
                                $recommendedAction = $messages[$messageId + 'RecommendedAction'] -f $elementName
                                break
                            }
                            #elseif ($normalVersionElements[$i] -as [int] -as [string] -ne $normalVersionElements[$i]) {
                            else {
                                #$message = '{0} version must not contain leading zeros.' -f $elementName
                                $messageId = 'CannotConvertNormalVersionElementToInt'
                                $message = $messages[$messageId] -f $elementName
                                $recommendedAction = $messages[$messageId + 'RecommendedAction']
                                break
                            }
                        }
                    }
                }
                # Validate pre-release.
                elseif ($prereleaseLabel.Length -ne 0 -and $prereleaseLabel -notmatch ('^' + $PreReleasePattern + '$')) {
                    $messageId = 'InvalidMetadataLabel'
                    $message = $messages[$messageId] -f $textInfo.ToTitleCase($messages['PreReleaseLabelName'])
                    $recommendedAction = $messages[$messageId + 'RecommendedAction'] -f $messages['PreReleaseLabelName']

                    [string[]] $prereleaseIdentifers = @($prereleaseLabel -split '\.')
                    for ($i = 0; $i -lt $prereleaseIdentifers.Length; $i++) {
                        if ($prereleaseIdentifers[$i] -match ('^' + $PreReleaseIdentifierPattern + '$')) {
                            continue
                        }
                        elseif ($prereleaseIdentifers[$i].Trim() -eq '') {
                            $messageId = 'MetadataIdentifierIsEmpty'
                            $message = $messages[$messageId] -f $textInfo.ToTitleCase($messages['PreReleaseLabelName']), $i
                            $recommendedAction = $messages[$messageId + 'RecommendedAction'] -f $messages['PreReleaseLabelName']
                        }
                        else {
                            $messageId = 'InvalidPreReleaseIdentifier'
                            $message = $messages[$messageId] -f $i
                            $recommendedAction = $messages[$messageId + 'RecommendedAction']
                        }
                    }
                }
                # Validate build.
                elseif ($buildLabel.Length -ne 0 -and $buildLabel -notmatch ('^' + $BuildPattern + '$')) {
                    $messageId = 'InvalidMetadataLabel'
                    $message = $messages[$messageId] -f $textInfo.ToTitleCase($messages['BuildLabelName'])
                    $recommendedAction = $messages[$messageId + 'RecommendedAction'] -f $messages['BuildLabelName']

                    [string[]] $buildIdentifers = @($buildLabel -split '\.')
                    for ($i = 0; $i -lt $buildIdentifers.Length; $i++) {
                        if ($buildIdentifers[$i] -match ('^' + $BuildIdentifierPattern + '$')) {
                            continue
                        }
                        elseif ($buildIdentifers[$i].Trim() -eq '') {
                            $messageId = 'MetadataIdentifierIsEmpty'
                            $message = $messages[$messageId] -f $textInfo.ToTitleCase($messages['BuildLabelName']), $i
                            $recommendedAction = $messages[$messageId + 'RecommendedAction'] -f $messages['BuildLabelName']
                        }
                        else {
                            $messageId = 'InvalidBuildIdentifier'
                            $message = $messages[$messageId] -f $i
                            $recommendedAction = $messages[$messageId + 'RecommendedAction']
                        }
                    }
                }

                $outputHash['CategoryReason'] = $messageId
                $outputHash['ErrorId'] = $messageId
                $outputHash['Message'] = $message
                $outputHash['RecommendedAction'] = $recommendedAction
            }

            $outputHash
        }
    }
}
