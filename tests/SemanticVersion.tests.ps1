Set-StrictMode -Version Latest

Import-Module -Name '..\SemanticVersion'

Describe 'PowerShell 2.0 compatibility check' {
    It 'Make sure the test is done with PowerShell 2.0' {
        $PSVersionTable.PSVersion.Major | Should Be 2
    }
}

InModuleScope SemanticVersion {
    Describe 'Testing module private function access' {
        It 'Returns True' {
            TestPesterModuleImport | Should Be $true
        }
    }

    Describe 'CustomSemanticVersion object, Major property' {
        It 'Calls SetMajor()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.Major++

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should be $prerelease
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, Minor property' {
        It 'Calls SetMinor()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.Minor++

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should be ''
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, Patch property' {
        It 'Calls SetPatch()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.Patch++

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should be ''
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, PreRelease property' {
        It 'Calls SetPreRelease()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.PreRelease = 'alpha.1'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be 'alpha.1'
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, Build property' {
        It 'Calls SetBuild()' {
            $semver = New-SemanticVersion -String '1.1.1-1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetBuild('build.1')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be $prerelease
            $semver.Build | Should Be 'build.1'
        }
    }

    Describe 'CustomSemanticVersion object, CompareTo(value) method' {
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

    Describe 'CustomSemanticVersion object, CompatibleWith() method' {
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

    Describe 'CustomSemanticVersion object, Equals() method' {
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

    Describe 'CustomSemanticVersion object, FromString() method' {
        It 'Converts a valid Semantic Version string to the properties of the object.' {
            $semver = New-SemanticVersion -String '1.2.3'

            $semver.FromString('2.3.4-5+6')

            $semver.Major | Should Be 2
            $semver.Minor | Should Be 3
            $semver.Patch | Should Be 4
            $semver.PreRelease | Should Be 5
            $semver.Build | Should Be 6
        }
    }

    Describe 'CustomSemanticVersion object, GetBuild() method' {
        It 'Returns the value of the Build property' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'

            $semver.Build | Should Be 6
        }
    }

    Describe 'CustomSemanticVersion object, GetMajor() method' {
        It 'Returns the value of the Major property' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'

            $semver.Major | Should Be 2
        }
    }

    Describe 'CustomSemanticVersion object, GetMinor() method' {
        It 'Returns the value of the Minor property' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'

            $semver.Minor | Should Be 3
        }
    }

    Describe 'CustomSemanticVersion object, GetPatch() method' {
        It 'Returns the value of the Patch property' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'

            $semver.Patch | Should Be 4
        }
    }

    Describe 'CustomSemanticVersion object, GetPreRelease() method' {
        It 'Returns the value of the PreRelease property' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'

            $semver.PreRelease | Should Be 5
        }
    }

    Describe 'CustomSemanticVersion object, Increment() method' {
        BeforeEach {
            $semver = New-SemanticVersion -String '2.3.4+5'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build
        }

        It 'Calls IncrementPreRelease() by default' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.Increment()

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be (([int] $prerelease) + 1)
            $semver.Build | Should Be $build
        }

        It 'Calls IncrementPreRelease() when argument is ''PreRelease''' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.Increment('PreRelease')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be (([int] $prerelease) + 1)
            $semver.Build | Should Be $build
        }

        It 'Calls IncrementBuild() when argument is ''Build''' {
            $semver.Increment('Build')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be $prerelease
            $semver.Build | Should Be (([int] $build) + 1)
        }


        It 'Calls IncrementPatch() when argument is ''Patch''' {
            $semver.Increment('Patch')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Calls IncrementMinor() when argument is ''Minor''' {
            $semver.Increment('Minor')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Calls IncrementMajor() when argument is ''Major''' {
            $semver.Increment('Major')

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and calls IncrementPatch() when argument is ''PrePatch''' {
            $semver.Increment('PrePatch')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and calls IncrementMinor() when argument is ''PreMinor''' {
            $semver.Increment('PreMinor')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and calls IncrementMajor() when argument is ''PreMajor''' {
            $semver.Increment('PreMajor')

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, IncrementBuild() method' {
        It 'Increments Build or sets Build to 0 if Build does not have a value. Major, Minor, Patch, and PreRelease are not changed.' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.IncrementBuild()

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be $prerelease
            $semver.Build | Should Be (([int] $build) + 1)
        }
    }

    Describe 'CustomSemanticVersion object, IncrementMajor() method' {
        Context 'PreRelease is not set' {
            It 'Increments Major by 1 and sets Minor and Patch to 0. PreRelease and Build do not change.' {
                $semver = New-SemanticVersion -String '1.1.1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build
                
                $semver.IncrementMajor()

                $semver.Major | Should Be ($major + 1)
                $semver.Minor | Should Be 0
                $semver.Patch | Should Be 0
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }

        }

        Context 'PreRelease is set. Minor or Patch are greater than 0.' {
            It 'Increments Major by 1, clears PreRelease, and sets Minor and Patch to 0. Build does not change.' {
                $semver = New-SemanticVersion -String '1.1.1-1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementMajor()

                $semver.Major | Should Be ($major + 1)
                $semver.Minor | Should Be 0
                $semver.Patch | Should Be 0
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }

        Context 'PreRelease is set. Minor and Patch are 0.' {
            It 'Does not increment Major but clears PreRelease. Major, Minor, Patch, and Build do not change.' {
                $semver = New-SemanticVersion -String '1.0.0-1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementMajor()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be $minor
                $semver.Patch | Should Be $patch
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }
    }

    Describe 'CustomSemanticVersion object, IncrementMinor() method' {
        Context 'PreRelease is not set' {
            It 'Increments Minor by 1 and sets Patch to zero. Major and Build do not change.' {
                $semver = New-SemanticVersion -String '1.1.1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementMinor()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be ($minor + 1)
                $semver.Patch | Should Be 0
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }

        Context 'PreRelease is set. Patch is greater than 0.' {
            It 'Increments Minor by 1, clears PreRelease, and sets Patch to 0. Major and Build do not change.' {
                $semver = New-SemanticVersion -String '1.1.1-1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementMinor()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be ($minor + 1)
                $semver.Patch | Should Be 0
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }

        Context 'PreRelease is set. Patch is 0.' {
            It 'Does not increment but clears PreRelease. Major, Minor, Patch and Build do not change.' {
                $semver = New-SemanticVersion -String '1.1.0-1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementMinor()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be $minor
                $semver.Patch | Should Be $patch
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }
    }

    Describe 'CustomSemanticVersion object, IncrementPatch() method' {
        Context 'PreRelease is not set' {
            It 'Increments Patch by 1. Major, Minor and Build are not changed.' {
                $semver = New-SemanticVersion -String '1.1.1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementPatch()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be $minor
                $semver.Patch | Should Be ($patch + 1)
                $semver.PreRelease | Should be $prerelease
                $semver.Build | Should Be $build
            }
        }

        Context 'PreRelease is set' {
            It 'Does not increment but clears PreRelease. Major, Minor, Patch, and Build are not changed.' {
                $semver = New-SemanticVersion -String '1.1.1-1+1'
                $major = $semver.Major
                $minor = $semver.Minor
                $patch = $semver.Patch
                $prerelease = $semver.PreRelease
                $build = $semver.Build

                $semver.IncrementPatch()

                $semver.Major | Should Be $major
                $semver.Minor | Should Be $minor
                $semver.Patch | Should Be $patch
                $semver.PreRelease | Should be ''
                $semver.Build | Should Be $build
            }
        }
    }

    Describe 'CustomSemanticVersion object, IncrementPreRelease() method' {
        It 'Increments Patch and sets PreRelease to 0 if PreRelease does not have a value. Major, Minor and Build are not changed.' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.IncrementPreRelease()

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should be '0'
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, SetBuild() method' {
        It 'Can be set to an empty string without changing any other values.' {
            $semver = New-SemanticVersion -String '1.1.1-1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetBuild('')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be $prerelease
            $semver.Build | Should Be ''
        }

        It 'Can be set to a valid build string without changing any other values.' {
            $semver = New-SemanticVersion -String '1.1.1-1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetBuild('build.1')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be $prerelease
            $semver.Build | Should Be 'build.1'
        }

        It 'Can only contain an empty string or a valid semantic version build string. Other values are not changed.' {
            $semver = New-SemanticVersion -String '1.1.1-1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetBuild('build.1')
            $semver.Build | Should be 'build.1'

            $semver.SetBuild('')
            $semver.Build | Should Be ''

            $semver.SetBuild('a.b.c.d.e1.0f.-.0.1.2.3')
            $semver.Build | Should Be 'a.b.c.d.e1.0f.-.0.1.2.3'

            $semver.SetBuild('00')
            $semver.Build | Should Be '00'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be $prerelease
        }
    }

    Describe 'CustomSemanticVersion object, SetMajor() method' {
        It 'Only accepts a value that is equal to existing value + 1' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            {$semver.SetMajor($Major)} | Should Throw
            {$semver.SetMajor($Major + 2)} | Should Throw
            {$semver.SetMajor($Major + 10)} | Should Throw
            {$semver.SetMajor($Major - 1)} | Should Throw
            {$semver.SetMajor($Major - 10)} | Should Throw
            {$semver.SetMajor($major + 1)} | Should Not Throw
        }

        It 'Increments Major by 1 by calling IncrementMajor()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetMajor($major + 1)

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be $prerelease
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, SetMinor() method' {
        It 'Only accepts a value that is equal to existing value + 1' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            {$semver.SetMinor($minor)} | Should Throw
            {$semver.SetMinor($minor + 2)} | Should Throw
            {$semver.SetMinor($minor + 10)} | Should Throw
            {$semver.SetMinor($minor - 1)} | Should Throw
            {$semver.SetMinor($minor - 10)} | Should Throw
            {$semver.SetMinor($minor + 1)} | Should Not Throw
        }

        It 'Increments Minor by 1 by calling IncrementMinor()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetMinor($minor + 1)

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be $prerelease
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, SetPatch() method' {
        It 'Only accepts a value that is equal to existing value + 1' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            {$semver.SetPatch($patch)} | Should Throw
            {$semver.SetPatch($patch + 2)} | Should Throw
            {$semver.SetPatch($patch + 10)} | Should Throw
            {$semver.SetPatch($patch - 1)} | Should Throw
            {$semver.SetPatch($patch - 10)} | Should Throw
            {$semver.SetPatch($patch + 1)} | Should Not Throw
        }

        It 'Increments Patch by 1 by calling IncrementPatch()' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetPatch($patch + 1)

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should Be $prerelease
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, SetPreRelease() method' {
        It 'Can be set to an empty string without changing any other values.' {
            $semver = New-SemanticVersion -String '1.1.1-1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetPreRelease('')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be ''
            $semver.Build | Should Be $build
        }

        It 'Can be set to a valid pre-release string without changing any other values.' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetPreRelease('alpha.1')

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should be 'alpha.1'
            $semver.Build | Should Be $build
        }

        It 'Can only contain an empty string or a valid semantic version pre-release string. Other values are not changed.' {
            $semver = New-SemanticVersion -String '1.1.1+1'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver.SetPreRelease('alpha.1')
            $semver.PreRelease | Should be 'alpha.1'

            $semver.SetPreRelease('')
            $semver.PreRelease | Should Be ''

            $semver.SetPreRelease('a.b.c.d.e1.0f.-.0.1.2.3')
            $semver.PreRelease | Should Be 'a.b.c.d.e1.0f.-.0.1.2.3'

            {$semver.SetPreRelease('00')} | Should Throw

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.Build | Should Be $build
        }
    }

    Describe 'CustomSemanticVersion object, ToString() method' {
        It 'Converts the relevant properties to a Semantic Version string.' {
            $semver = New-SemanticVersion -Major 2 -Minor 3 -Patch 4 -PreRelease 5 -Build 6

            $semver.ToString() | Test-SemanticVersion | Should Be $true

            $semver.ToString() | Should Be '2.3.4-5+6'
        }
    }

    Describe 'New-SemanticVersion function' {
        It 'Outputs a ''CustomSemanticVersion'' object' {
            $semver = New-SemanticVersion -String '1.2.3'

            @($semver.psobject.TypeNames) -contains 'CustomSemanticVersion' | Should Be $true 
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

    Describe 'Test-SemanticVersion function' {
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

    Describe 'Compare-SemanticVersion function' {
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

    Describe 'Step-SemanticVersion function' {
        BeforeEach {
            $semver = New-SemanticVersion -String '2.3.4+5'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build
        }

        It 'Increments PreRelease by default' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver = $semver | Step-SemanticVersion

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be (([int] $prerelease) + 1)
            $semver.Build | Should Be $build
        }

        It 'Increments PreRelease when -Element is ''PreRelease''' {
            $semver = New-SemanticVersion -String '2.3.4-5+6'
            $major = $semver.Major
            $minor = $semver.Minor
            $patch = $semver.Patch
            $prerelease = $semver.PreRelease
            $build = $semver.Build

            $semver = $semver | Step-SemanticVersion -Element 'PreRelease'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be (([int] $prerelease) + 1)
            $semver.Build | Should Be $build
        }

        It 'Increments Build when -Element is ''Build''' {
            $semver = $semver | Step-SemanticVersion -Element 'Build'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be $patch
            $semver.PreRelease | Should Be $prerelease
            $semver.Build | Should Be (([int] $build) + 1)
        }

        It 'Increments Patch when -Element is ''Patch''' {
            $semver = $semver | Step-SemanticVersion -Element 'Patch'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Increments Minor when -Element is ''Minor''' {
            $semver = $semver | Step-SemanticVersion -Element 'Minor'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Increments Major when -Element is ''Major''' {
            $semver = $semver | Step-SemanticVersion -Element 'Major'

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be ''
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and increments Patch when -Element is ''PrePatch''' {
            $semver = $semver | Step-SemanticVersion -Element 'PrePatch'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be $minor
            $semver.Patch | Should Be ($patch + 1)
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and increments Minor when -Element is ''PreMinor''' {
            $semver = $semver | Step-SemanticVersion -Element 'PreMinor'

            $semver.Major | Should Be $major
            $semver.Minor | Should Be ($minor + 1)
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }

        It 'Sets PreRelease to 0 and increments Major when -Element is ''PreMajor''' {
            $semver = $semver | Step-SemanticVersion -Element 'PreMajor'

            $semver.Major | Should Be ($major + 1)
            $semver.Minor | Should Be 0
            $semver.Patch | Should Be 0
            $semver.PreRelease | Should Be 0
            $semver.Build | Should Be $build
        }
    }

    Describe 'Convert-SemanticVersionToSystemVersion function' {
        Context 'Without -KeepSemanticVersion switch' {
            It 'Converts Semantic Version ''1.2.3'' to System.Version ''1.2.0.3''' {
                $sysver = '1.2.3' | Convert-SemanticVersionToSystemVersion

                $sysver.ToString() | Should Be '1.2.0.3'
            }

            It 'Converts Semantic Version ''1.2.3+4'' to System.Version ''1.2.4.3''' {
                $sysver = '1.2.3+4' | Convert-SemanticVersionToSystemVersion

                $sysver.ToString() | Should Be '1.2.4.3'
            }

            It 'Converts Semantic Version ''1.2.0+4'' to System.Version ''1.2.4.0''' {
                $sysver = '1.2.0+4' | Convert-SemanticVersionToSystemVersion

                $sysver.ToString() | Should Be '1.2.4.0'
            }

            It 'Converts Semantic Version ''1.2.3+0'' to System.Version ''1.2.0.3''' {
                $sysver = '1.2.3+0' | Convert-SemanticVersionToSystemVersion

                $sysver.ToString() | Should Be '1.2.0.3'
            }
        }

        Context 'With -KeepSemanticVersion switch' {
            It 'Converts Semantic Version ''1.2.3'' to System.Version ''1.2.3''' {
                $sysver = '1.2.3' | Convert-SemanticVersionToSystemVersion -KeepSemanticVersion

                $sysver.ToString() | Should Be '1.2.3'
            }

            It 'Converts Semantic Version ''1.2.3+4'' to System.Version ''1.2.3''' {
                $sysver = '1.2.3+4' | Convert-SemanticVersionToSystemVersion -KeepSemanticVersion

                $sysver.ToString() | Should Be '1.2.3'
            }

            It 'Converts Semantic Version ''1.2.0+4'' to System.Version ''1.2.4''' {
                $sysver = '1.2.0+4' | Convert-SemanticVersionToSystemVersion -KeepSemanticVersion

                $sysver.ToString() | Should Be '1.2.4'
            }

            It 'Converts Semantic Version ''1.2.3+0'' to System.Version ''1.2.3''' {
                $sysver = '1.2.3+0' | Convert-SemanticVersionToSystemVersion -KeepSemanticVersion

                $sysver.ToString() | Should Be '1.2.3'
            }
        }
    }

    Describe 'Convert-SystemVersionToSemanticVersion function' {
        It 'Converts System.Version ''1.2.3.4'' to Semantic Version ''1.2.4+3''' {
            $semver = '1.2.3.4' | Convert-SystemVersionToSemanticVersion

            $semver.ToString() | Should Be '1.2.4+3'
        }

        It 'Converts System.Version ''1.2.3'' to Semantic Version ''1.2.3''' {
            $semver = '1.2.3' | Convert-SystemVersionToSemanticVersion

            $semver.ToString() | Should Be '1.2.3'
        }

        It 'Converts System.Version ''1.2.0.3'' to Semantic Version ''1.2.3''' {
            $semver = '1.2.0.3' | Convert-SystemVersionToSemanticVersion

            $semver.ToString() | Should Be '1.2.3'
        }
    }
}

Remove-Module -Name SemanticVersion