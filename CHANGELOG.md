# Release Notes for PoshSemanticVersion

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) for
official project tracking. For technical reasons, the module version
number cannot be expressed using Semantic Versioning.

## 1.4.0 - 2017-12-03
### Features
- Added aliases for exported commands
- Added alias properties "PreReleaseLabel" and "BuildLabel" to match PowerShell v6.x native SemanticVersion type.

## 1.3.0 - 2017-11-12
### Features
- Compare-SemanticVersion now takes pipeline input.
- Improved feedback messages provided by Test-SemanticVersion when using -Verbose.
- Improved error messages on all functions.

### Fixes
- New-SemanticVersion: multiple objects can now be piped to this function.

### Deprecated
- Compare-SemanticVersion: The "AreCompatible" property is now an alias to "IsCompatible". The "AreCompatible"
  property will be removed when the next major version of this module is released.

## 1.2.0 - 2017-11-01
### Features
- Test-SemanticVersion provides useful feedback messages if a Semantic Version is invalid and the -Verbose switch
  is used.

### Fixes
- Test-SemanticVersion correctly accepts pipeline input of more than one string.

## 1.1.0 - 2017-10-30
### Features
- Step-SemanticVersion can increment prerelease and build using optional label parameter.

## 1.0.0 - 2017-10-10
### Features
- New-SemanticVersion: Creates a new semantic version.
- Test-SemanticVersion: Test if a input value is a valid semantic version string.
- Compare-SemanticVersion: Compare two semantic versions to determine precedence.
- Step-SemanticVersion: Increment a semantic version number based on a type of change.
