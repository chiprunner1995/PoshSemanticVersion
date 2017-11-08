# Release Notes for PoshSemanticVersion

## 1.3.0 - 2017-11-08
### Features
- Test-SemanticVersion has a 'AsErrorRecord' parameter that will return a PowerShell ErrorRecord object
  if the input string is not a valid Semantic Version string. The ErrorRecord object contains detail on why
  the string was invalid and can thrown from other functions for validation.
- Improved feedback messages provided by Test-SemanticVersion.
