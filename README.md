PoshSemanticVersion
===================

Functions for working with Semantic Version numbers in PowerShell.

Read more about Semantic Versioning at http://semver.org

Features
--------

This module aims to provide basic Semantic Version tools for the PowerShell community. There are functions for
creating, validating, comparing, and incrementing Semantic Versions.

Available Functions:

* New-SemanticVersion: Creates a new semantic version number.
* Test-SemanticVersion: Test if a string is a valid semantic version.
* Compare-SemanticVersion: Compare two semantic versions to determine precedence.
* Step-SemanticVersion: Increment a semantic version based on the specified change type.

System Requirements
-------------------

* PowerShell version 3 or later. (For PowerShell version 2 compatibility, use version 1.4.2 of this module.)

Installation
------------

Install with PowerShellGet:

```powershell
Install-Module -Name PoshSemanticVersion
```

Or copy the "PoshSemanticVersion" subdirectory from this repository into a directory in your PSModulePath path.

Usage
-----

All exported functions are documented. Use Get-Help *function-name* to read the help for the respective function.

Examples
--------

New-SemanticVersion accepts a full string or you can specify each component with specific paramters

```powershell
PS C:\> New-SemanticVersion 1.2.3-alpha.3+dev.1344ab


Major      : 1
Minor      : 2
Patch      : 3
PreRelease : alpha.3
Build      : dev.1344ab
```

```powershell
PS C:\> New-SemanticVersion -Major 1 -Minor 2 -Patch 3 -PreRelease alpha.3 -Build dev.1344ab


Major      : 1
Minor      : 2
Patch      : 3
PreRelease : alpha.3
Build      : dev.1344ab
```

Calling the ToString() method of the resulting output object shows the properly formatted Semantic Version string.

```powershell
PS C:\> $semver = New-SemanticVersion 1.2.3-alpha.3+dev.1344ab
PS C:\> $semver.ToString()
1.2.3-alpha.3+dev.1344ab
```

*Test-SemanticVersion* returns true or false depending on if the input version is a valid Semantic Version string.
Use the -Verbose switch to get additional feedback on why a string was invalid.

```powershell
PS C:\> Test-SemanticVersion 1.4.7-beta.03 -Verbose
VERBOSE: Pre-release indentifier at index 1 MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].
Identifiers MUST NOT be empty. Numeric identifiers MUST NOT include leading zeroes. Verify the pre-release label
comprises only ASCII alphanumerics and hyphen and numeric indicators do not contain leading zeros.
False
```

```powershell
PS C:\> Test-SemanticVersion 1.4.7-beta.3 -Verbose
VERBOSE: "1.4.7-beta.3" is a valid Semantic Version.
True
```

*Compare-SemanticVersion* can be used to show if two Semantic Version objects are compatible, as well as which has
higher precedence.

```powershell
PS C:\> Compare-SemanticVersion 1.2.3 1.2.0

ReferenceVersion Precedence DifferenceVersion IsCompatible
---------------- ---------- ----------------- ------------
1.2.3            >          1.2.0                     True
```

*Step-SemanticVersion* increments a Semantic Version object based on the Semver 2.0 specification.

```powershell
PS C:\> '1.3.5' | Step-SemanticVersion -Type Minor


Major      : 1
Minor      : 4
Patch      : 0
PreRelease :
Build      :
```


License
-------

Licensed under an MIT license. Read the LICENSE file for more information.