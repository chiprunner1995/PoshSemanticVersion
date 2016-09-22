# Design Notes for SemanticVersion Module

Need a way to initiate a specific change type. "Start-SemanticVersion"



    Change to Step-SemanticVersion...

    - x Increment pre-release if it is specified without Major/Minor/Patch
    - x Reset pre-release if it is specified with Major/Minor/Patch
    - x Clear pre-release if it is not specified with Major/Minor/Patch
        - Only increment Major/Minor/Patch if it is higher precidence than existing.
    - x Increment Major/Minor/Patch if it is specified without pre-release.


Complete-SemanticVersion : Remove pre-release identifier from semver.
Set-SemanticVersion      : Change a specific component of a semver object.

## Semantic Version workflow

New, uninitialized semantic version : 0.0.0
Lowest possible semantic version    : 0.0.0-0

### Between Releases

For an existing version of 1.2.3, if you are starting a new patch, the first development
version should be 1.2.4-0, not 1.2.4-alpha.0. This is because a numeric indicator is lower
in precidence than a non-numeric indicator. Terms such as "alpha" and "beta" are generally
used to indicate the initial development work is complete and the software is in its testing
phase.

## Definitions

- Version
- ChangeType
- ReleaseType = 'Development','Release'

## Module Design

### Public Functions

- New-SemanticVersion
    - Create new SemVer object.
- Test-SemanticVersion
    - Validate semantic version string.
- Start-SemanticVersion
    - Increment SemVer with planned change type and pre-release identifier
- Step-SemanticVersion
    - Increment SemVer with change type.
- Compare-SemanticVersion
    - Compare two semantic versions for precidence and compatibility
- Convert-SemanticVersionToSystemVersion
    - Convert a SemanticVersion object to a MS System.Version object
- Convert-SystemVersionToSemanticVersion
    - Convert a MS System.Version object to a SemanticVersion object



## Object Design

Object design should be done in a way that this can be easily replaced with a .NET class someday.

If no arguments are provided to the constructor, the initial version should be 0.0.0-0 because
this is the lowest possible value that SemVer can be expressed as.

The SemVer object's Major, Minor, Patch, and PreRelease properties cannot be modifed by default. 
Just like the System.Version object, the properites are read-only. Additionally, the Increment() 
method will not work if the version number is not a pre-release version number.
However by calling the Develop() method with a parameter specifying the type of change you are making.
The Develop() method will then increment the normal version, and add a pre-release number to the version. 
The Increment() method will then increment the pre-release number each time it is called. To remove the
Pre-Release indicator and prevent the Increment() method from changing the version number further,
call the Release() method.

### Public Properties
- Major
    - Indicates changes that are not compatible with the previous version.
- Minor
    - Indicates new features or changes that does not break compatibility with the previous version.
- Patch
    - Indicates a fix that does not break compatibility with the previous version.
- PreRelease
    - Indicates a development or testing version.
- Build
    - Build metadata
- IsPreRelease
    - True: if the pre-release value is not an empty string.
    - False: otherwise
- IsStable
    - False: if it is a pre-release
    - False: if it is below major version 1
    - True: otherwise

### Public Methods

- ToString()
- FromString()
- CompareTo()
    - Compare version to another version, following SemVer specification for precedence.
- Equals()
    - Compare version to another version, using CompareTo()
- CompatibleWith()
    - Determine if current version is backward compatible with another version.
- Develop(<major/minor/patch>, <pre-release-id>)
    - Starts a revision, which increments the specified core version and adds a pre-release identifier.
- Increment()
    - Increments the pre-release identifier only if it exists. Otherwise throws an error.
- Release()
    - Removes any pre-release identifiers
- GetStage()



## Formatting

