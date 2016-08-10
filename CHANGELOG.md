# Release Notes for SemanticVersion PowerShell Module

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/) for 
official project tracking. For technical reasons, the module version 
number cannot be expressed using Semantic Versioning.

## 0.5.0 - 2016-08-10
### Added
- Added Test-SemanticVersion function to validate a semantic version string.

## 0.4.0 - 2016-08-09
### Added
- Added Convert-SemanticVersionToSystemVersion
- Added Convert-SystemVersionToSemanticVersion

### Changed
- Updated regular expression to evaluate semver string better.
- Moved this module back to a standalone project.

### Removed
- Removed object methods to convert to and from MS System.Version
  because this functionality is handled by external functions.

## 0.3.0 - 2016-07-26
### Added
- Completed method to convert string to Semantic Version object.
- Added method to convert Semantic Version to and from Microsoft 
  System.Version object.

## 0.2.0 - 2016-07-18
### Added
- Added functions to increment version numbers and cascade lower version 
  numbers based on SemVer spec.

## 0.1.0 - 2016-07-14
### Added
- Initial development
- Added New-SemanticVersion function for constructing version objects.
