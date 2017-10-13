param (
    [string]
    $ModuleName = 'PoshSemanticVersion'
)

#Import-Module -Name "..\$moduleName"

InModuleScope $moduleName {
    Describe 'New-SemanticVersion' {
        It 'Creates an object using component parameters' {
            $inputMajor = 2
            $inputMinor = 3
            $inputPatch = 4
            $inputPreRelease = 'alpha.5'
            $inputBuild = 'feat.6'

            $semver = New-SemanticVersion -Major $inputMajor -Minor $inputMinor -Patch $inputPatch -PreRelease $inputPreRelease -Build $inputBuild

            $semver.Major | Should Be $inputMajor
            $semver.Minor | Should Be $inputMinor
            $semver.Patch | Should Be $inputPatch
            $semver.PreRelease | Should Be $inputPreRelease
            $semver.Build | Should Be $inputBuild
        }

        It 'Creates an object using an input string' {
            $inputMajor = 2
            $inputMinor = 3
            $inputPatch = 4
            $inputPreRelease = 'alpha.5'
            $inputBuild = 'feat.6'
            $inputString = '{0}.{1}.{2}-{3}+{4}' -f $inputMajor, $inputMinor, $inputPatch, $inputPreRelease, $inputBuild

            $semver = New-SemanticVersion $inputString

            $semver.Major | Should Be $inputMajor
            $semver.Minor | Should Be $inputMinor
            $semver.Patch | Should Be $inputPatch
            $semver.PreRelease | Should Be $inputPreRelease
            $semver.Build | Should Be $inputBuild
        }

        It 'Accepts arrays for PreRelease and Build parameters' {
            $inputPreRelease = @('alpha', '5')
            $inputBuild = @('feat', '6')

            $semver = New-SemanticVersion -Major 2 -Minor 3 -Patch 4 -PreRelease $inputPreRelease -Build $inputBuild

            $semver.PreRelease | Should Be ($inputPreRelease -join '.')
            $semver.Build | Should Be ($inputBuild -join '.')
        }

        It 'Outputs a ''PoshSemanticVersion'' object' {
            $semver = New-SemanticVersion -String '1.2.3'

            @($semver.psobject.TypeNames) -contains 'PoshSemanticVersion' | Should Be $true
        }

        It 'Accepts pipeline input' {
            {'1.2.3-a.1+b.2' | New-SemanticVersion} | Should Not Throw
        }

        It 'Accepts positional input' {
            New-SemanticVersion '1.2.3-a.1+b.2' | Should Not BeNullOrEmpty
        }

        It 'Fails without input' {
            {New-SemanticVersion $null} | Should Throw
        }

        It 'Converts a valid semantic version string into a semantic version object' {
            $semVerString = '1.2.3-alpha.test.1.2.3+build.it.test.01.02.4'

            $semver = New-SemanticVersion -String $semVerString

            $semver.Major | Should Be 1
            $semver.Minor | Should Be 2
            $semver.Patch | Should Be 3
            $semver.PreRelease | Should Be 'alpha.test.1.2.3'
            $semver.Build | Should Be 'build.it.test.01.02.4'
        }
    }

    Describe 'Test-SemanticVersion' {
        It 'Accepts pipeline input' {
            '1.2.3' | Test-SemanticVersion | Should Be $true
        }

        It 'Accepts positional input' {
            Test-SemanticVersion '1.2.3' | Should Be $true
        }

        It 'Succeeds if a valid semantic version string is specified.' {
            Test-SemanticVersion -Version '0.0.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0.0.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-a.0.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0.a.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0.-.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-0+0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3+0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3+0.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3+0.00' | Should Be $true
            Test-SemanticVersion -Version '1.2.3+a.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3+a.-.00.0' | Should Be $true
            Test-SemanticVersion -Version '1.2.3-alpha.test.1.2.3+build.it.test.01.02.4' | Should Be $true
        }

        It 'Fails if an invalid semantic version string is specified.' {
            Test-SemanticVersion -Version '1' | Should Be $false
            Test-SemanticVersion -Version '1.2' | Should Be $false
            Test-SemanticVersion -Version '.1' | Should Be $false
            Test-SemanticVersion -Version '1.2.' | Should Be $false
            Test-SemanticVersion -Version '.1.2.3' | Should Be $false
            Test-SemanticVersion -Version ' 1.2.3' | Should Be $false
            Test-SemanticVersion -Version '1..3' | Should Be $false
            Test-SemanticVersion -Version '1.2.3.4' | Should Be $false
            Test-SemanticVersion -Version '1.a.3' | Should Be $false
            Test-SemanticVersion -Version '-1.2.3' | Should Be $false
            Test-SemanticVersion -Version '01.2.3' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-00' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-a..0' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-+' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-0+' | Should Be $false
            Test-SemanticVersion -Version '1.2.3-0+0+' | Should Be $false
            Test-SemanticVersion -Version '1.2.3+a..0' | Should Be $false
        }

    }

    Describe 'Compare-SemanticVersion' {
        It 'Ignores Build property when comparing versions.' {
            $compareOutput = Compare-SemanticVersion -ReferenceVersion 2.2.2 -DifferenceVersion 2.2.2+BUILD.999

            $compareOutput.Precedence | Should Be '='
        }

        It 'Accepts the ReferenceVersion parameter from the pipeline' {
            {'1.2.3' | Compare-SemanticVersion -DifferenceVersion '1.2.4'} | Should Not Throw
        }

        It 'Accepts a string or calls an object''s ToString() method' {
            $semver1 = New-SemanticVersion '1.2.3'
            $semver2 = New-SemanticVersion '1.2.4'

            {Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2} | Should Not Throw

            {Compare-SemanticVersion -ReferenceVersion '1.2.3' -DifferenceVersion '1.2.4'} | Should Not Throw

        }

        It 'Returns an object with ReferenceVersion, DifferenceVersion, Precedence, and AreCompatible properties' {
            $propertyNames = @(Compare-SemanticVersion -ReferenceVersion '1.2.3' -DifferenceVersion '1.2.4' |
                               Get-Member |
                               Where-Object {$_.MemberType -like '*Property'} |
                               Select-Object -ExpandProperty Name)

            $propertyNames -contains 'ReferenceVersion' | Should Be $true
            $propertyNames -contains 'DifferenceVersion' | Should Be $true
            $propertyNames -contains 'Precedence' | Should Be $true
            $propertyNames -contains 'AreCompatible' | Should Be $true
        }

        It 'Calls the ReferenceVersion object''s CompareTo() method to set the Precedence property.' {
            $semver1 = New-SemanticVersion '1.2.3'
            $semver2 = New-SemanticVersion '1.2.4'

            $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

            $compareOutput.Precedence | Should Be '<'
        }

        It 'Calls the ReferenceVersion object''s CompatibleWith() method to set the AreCompatible property.' {
            $semver1 = New-SemanticVersion '1.2.3'
            $semver2 = New-SemanticVersion '1.2.4'

            $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

            $compareOutput.AreCompatible | Should Be $true
        }

        Context 'When the ReferenceVersion has equal precedence to the DifferenceVersion' {
            It 'Sets the Precedence property to the equals symbol.' {
                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '1.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '='

                $semver1 = New-SemanticVersion '1.2.3-4'
                $semver2 = New-SemanticVersion '1.2.3-4'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '='

                $semver1 = New-SemanticVersion '1.2.3-4+5'
                $semver2 = New-SemanticVersion '1.2.3-4+5'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '='

                $semver1 = New-SemanticVersion '1.2.3-4+1'
                $semver2 = New-SemanticVersion '1.2.3-4+9'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '='
            }
        }

        Context 'When the ReferenceVersion has higher precedence than the DifferenceVersion' {
            It 'Sets the Precedence property to the greater than symbol.' {
                $semver1 = New-SemanticVersion '1.2.4'
                $semver2 = New-SemanticVersion '1.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '1.3.0'
                $semver2 = New-SemanticVersion '1.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '2.0.0'
                $semver2 = New-SemanticVersion '1.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '1.2.3-0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '1.2.3-1'
                $semver2 = New-SemanticVersion '1.2.3-0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '1.2.3-a'
                $semver2 = New-SemanticVersion '1.2.3-0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'

                $semver1 = New-SemanticVersion '1.2.3-0.0'
                $semver2 = New-SemanticVersion '1.2.3-0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '>'
            }
        }

        Context 'When the ReferenceVersion has lower precedence than the DifferenceVersion' {
            It 'Sets the Precedence property to the less than symbol.' {
                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '1.2.4'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '1.3.0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '2.0.0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3-0'
                $semver2 = New-SemanticVersion '1.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3-0'
                $semver2 = New-SemanticVersion '1.2.3-1'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3-0'
                $semver2 = New-SemanticVersion '1.2.3-a'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'

                $semver1 = New-SemanticVersion '1.2.3-0'
                $semver2 = New-SemanticVersion '1.2.3-0.0'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.Precedence | Should Be '<'
            }
        }

        Context 'When the ReferenceVersion and DifferenceVersion are compatible' {
            It 'Sets the AreCompatible property to true.' {
                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '1.2.4'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.AreCompatible | Should Be $true
            }
        }

        Context 'When the ReferenceVersion and DifferenceVersion are not compatible' {
            It 'Sets the AreCompatible property to false.' {
                $semver1 = New-SemanticVersion '1.2.3'
                $semver2 = New-SemanticVersion '2.2.3'

                $compareOutput = Compare-SemanticVersion -ReferenceVersion $semver1 -DifferenceVersion $semver2

                $compareOutput.AreCompatible | Should Be $false
            }
        }
    }

    Describe 'Step-SemanticVersion' {
        It 'Increments prerelease by default' {
            (Step-SemanticVersion 1.2.3).ToString() | Should Be '1.2.4-0'
        }

        It 'Increments or appends Build ' {
            (Step-SemanticVersion 0.0.0-0 Build).ToString() | Should Be '0.0.0-0+0'
            (Step-SemanticVersion 0.0.0-0+0 Build).ToString() | Should Be '0.0.0-0+1'
            (Step-SemanticVersion 0.0.0-0+exp Build).ToString() | Should Be '0.0.0-0+exp.0'
        }

        It 'Increments or appends PreRelease' {
            (Step-SemanticVersion 0.0.0+0 PreRelease).ToString() | Should Be '0.0.1-0+0'
            (Step-SemanticVersion 0.0.0-0+0 PreRelease).ToString() | Should Be '0.0.0-1+0'
            (Step-SemanticVersion 0.0.0-a+0 PreRelease).ToString() | Should Be '0.0.0-a.0+0'
        }

        Context 'Input: 0.0.0-0' {
            BeforeEach {
                $inputString = '0.0.0-0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '0.0.0-0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '0.0.0-1'  }
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '0.0.1-0'  }
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '0.1.0-0'  }
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '1.0.0-0'  }
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '0.0.0'    }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '0.0.0'    }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '0.0.0'    }
        }

        Context 'Input: 0.0.0' {
            BeforeEach {
                $inputString = '0.0.0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '0.0.0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '0.0.1-0'}
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '0.0.1-0'}
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '0.1.0-0'}
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '1.0.0-0'}
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '0.0.1'  }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '0.1.0'  }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '1.0.0'  }
        }

        Context 'Input: 1.0.0-0' {
            BeforeEach {
                $inputString = '1.0.0-0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.0.0-0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.0.0-1'  }
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.0.1-0'  }
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.1.0-0'  }
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'  }
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.0.0'    }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.0.0'    }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '1.0.0'    }
        }

        Context 'Input: 1.0.0' {
            BeforeEach {
                $inputString = '1.0.0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.0.0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.0.1-0'}
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.0.1-0'}
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.1.0-0'}
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'}
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.0.1'  }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.1.0'  }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'  }
        }

        Context 'Input: 1.0.1-0' {
            BeforeEach {
                $inputString = '1.0.1-0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.0.1-0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.0.1-1'  }
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.0.2-0'  }
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.1.0-0'  }
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'  }
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.0.1'    }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.1.0'    }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'    }
        }

        Context 'Input: 1.0.1' {
            BeforeEach {
                $inputString = '1.0.1'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.0.1+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.0.2-0'}
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.0.2-0'}
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.1.0-0'}
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'}
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.0.2'  }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.1.0'  }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'  }
        }

        Context 'Input: 1.1.0-0' {
            BeforeEach {
                $inputString = '1.1.0-0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.1.0-0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.1.0-1'  }
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.1.1-0'  }
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.2.0-0'  }
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'  }
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.1.0'    }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.1.0'    }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'    }
        }

        Context 'Input: 1.1.0' {
            BeforeEach {
                $inputString = '1.1.0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.1.0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.1.1-0'}
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.1.1-0'}
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.2.0-0'}
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'}
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.1.1'  }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.2.0'  }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'  }
        }

        Context 'Input: 1.1.1-0' {
            BeforeEach {
                $inputString = '1.1.1-0'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.1.1-0+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.1.1-1'  }
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.1.2-0'  }
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.2.0-0'  }
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'  }
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.1.1'    }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.2.0'    }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'    }
        }

        Context 'Input: 1.1.1' {
            BeforeEach {
                $inputString = '1.1.1'
            }

            It 'Increments Build'            {(Step-SemanticVersion $inputString Build     ).ToString() | Should Be '1.1.1+0'}
            It 'Increments PreRelease'       {(Step-SemanticVersion $inputString PreRelease).ToString() | Should Be '1.1.2-0'}
            It 'Increments PreRelease Patch' {(Step-SemanticVersion $inputString PrePatch  ).ToString() | Should Be '1.1.2-0'}
            It 'Increments PreRelease Minor' {(Step-SemanticVersion $inputString PreMinor  ).ToString() | Should Be '1.2.0-0'}
            It 'Increments PreRelease Major' {(Step-SemanticVersion $inputString PreMajor  ).ToString() | Should Be '2.0.0-0'}
            It 'Increments Patch'            {(Step-SemanticVersion $inputString Patch     ).ToString() | Should Be '1.1.2'  }
            It 'Increments Minor'            {(Step-SemanticVersion $inputString Minor     ).ToString() | Should Be '1.2.0'  }
            It 'Increments Major'            {(Step-SemanticVersion $inputString Major     ).ToString() | Should Be '2.0.0'  }
        }
    }

    Describe '(output object).CompareTo(value) method' {
        Context 'The current version has the same precedence as value' {
            It 'Returns 0 if two versions are the same' {
                $semver1 = New-SemanticVersion -String '1.2.3-4+5'
                $semver2 = New-SemanticVersion -String '1.2.3-4+5'

                $semver1.CompareTo($semver2) | Should Be 0
            }

            It 'Returns 0 if two versions differ only in build metadata' {
                $semver1 = New-SemanticVersion -String '1.2.3-4+5'
                $semver2 = New-SemanticVersion -String '1.2.3-4'

                $semver1.CompareTo($semver2) | Should Be 0

                $semver1 = New-SemanticVersion -String '1.2.3-4+5'
                $semver2 = New-SemanticVersion -String '1.2.3-4+exp.sha.5114f85'

                $semver1.CompareTo($semver2) | Should Be 0
            }
        }

        Context 'The current version has higher precedence as value' {
            It 'Returns value greater than 0 if object has higher precedance than compared version' {
                $semver1 = New-SemanticVersion -String '0.0.2'
                $semver2 = New-SemanticVersion -String '0.0.1'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '0.1.0'
                $semver2 = New-SemanticVersion -String '0.0.1'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0'
                $semver2 = New-SemanticVersion -String '0.0.1'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0'
                $semver2 = New-SemanticVersion -String '0.1.0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '2.0.0'
                $semver2 = New-SemanticVersion -String '1.0.0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0'
                $semver2 = New-SemanticVersion -String '1.0.0-0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-1'
                $semver2 = New-SemanticVersion -String '1.0.0-0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-a'
                $semver2 = New-SemanticVersion -String '1.0.0-0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-a'
                $semver2 = New-SemanticVersion -String '1.0.0-0.0'

                $semver1.CompareTo($semver2) | Should BeGreaterThan 0
            }
        }

        Context 'The current version has lower precedence as value' {
            It 'Returns value less than 0 if object has lower precedance than compared version' {
                $semver1 = New-SemanticVersion -String '0.0.1'
                $semver2 = New-SemanticVersion -String '0.0.2'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '0.0.1'
                $semver2 = New-SemanticVersion -String '0.1.0'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '0.0.1'
                $semver2 = New-SemanticVersion -String '1.0.0'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '0.1.0'
                $semver2 = New-SemanticVersion -String '1.0.0'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '1.0.0'
                $semver2 = New-SemanticVersion -String '2.0.0'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-0'
                $semver2 = New-SemanticVersion -String '1.0.0'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-0'
                $semver2 = New-SemanticVersion -String '1.0.0-1'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-0'
                $semver2 = New-SemanticVersion -String '1.0.0-a'

                $semver1.CompareTo($semver2) | Should BeLessThan 0

                $semver1 = New-SemanticVersion -String '1.0.0-0.0'
                $semver2 = New-SemanticVersion -String '1.0.0-a'

                $semver1.CompareTo($semver2) | Should BeLessThan 0
            }
        }
    }

    Describe '(output object).CompatibleWith(value) method' {
        It 'Returns true if two versions are compatible' {
            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-4+5'

            $semver1.CompatibleWith($semver2) | Should Be $true

            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-4+6.7.8.9'

            $semver1.CompatibleWith($semver2) | Should Be $true
        }

        It 'Returns false if two versions are are not compatible' {
            $semver1 = New-SemanticVersion '1.2.3+5'
            $semver2 = New-SemanticVersion '2.2.3+5'

            $semver1.CompatibleWith($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '0.0.1+5'
            $semver2 = New-SemanticVersion '0.0.2+5'

            $semver1.CompatibleWith($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-5+5'

            $semver1.CompatibleWith($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.4-4+5'

            $semver1.CompatibleWith($semver2) | Should Be $false
        }
    }

    Describe '(output object).Equals(value) method' {
        It 'Returns true if both versions have the same precedance' {
            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-4+5'

            $semver1.Equals($semver2) | Should Be $true

            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-4+6.7.8.9'

            $semver1.Equals($semver2) | Should Be $true
        }

        It 'Returns false if both versions do not have the same precedance' {
            $semver1 = New-SemanticVersion '1.2.3-4+5'
            $semver2 = New-SemanticVersion '1.2.3-5+5'

            $semver1.Equals($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '1.2.3-5+5'
            $semver2 = New-SemanticVersion '1.2.4-5+5'

            $semver1.Equals($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '1.3.3-5+5'
            $semver2 = New-SemanticVersion '1.2.3-5+5'

            $semver1.Equals($semver2) | Should Be $false

            $semver1 = New-SemanticVersion '1.2.3-5+5'
            $semver2 = New-SemanticVersion '2.2.3-5+5'

            $semver1.Equals($semver2) | Should Be $false
        }
    }
}