PoshSemanticVersion
===================

Functions for working with Semantic Version numbers in PowerShell.

Read more about Semantic Versioning at http://semver.org

Features
--------

This module aims to provide basic Semantic Version tools for the PowerShell community. There are functions for
creating, validating, comparing, and incrementing Semantic Versions.

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

Available Functions:

- New-SemanticVersion: Creates a new semantic version number.
- Test-SemanticVersion: Test if a string is a valid semantic version.
- Compare-SemanticVersion: Compare two semantic versions to determine precedence.
- Step-SemanticVersion: Increment a semantic version based on the specified change type.

License
-------

Licensed under an MIT license. Read the LICENSE file for more information.