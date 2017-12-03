# Module / Class Structure

PowerShell classes are tricky...
  https://info.sapien.com/index.php/scripting/scripting-classes/import-powershell-classes-from-modules


PoshSemanticVersion/
  PoshSemanticVersion.psd1 ............ Main / Manifest
  PoshSemanticVersion.psm1 ............ Controller
  PoshSemanticVersion.format.ps1xml ... View
  PoshSemanticVersion.types.ps1xml .... Controller...and Model
  SemanticVersion.psm1 ................ Model
  en/ ................................. Resources


PoshSemanticVersion/ .................... Project base directory
  PoshSemanticVersion/ .................. Module base directory
    en/ ................................. Localized resources
      Messages.psd1 ..................... Loaded by Resources.psm1
    PoshSemanticVersion.psd1 ............ Manifest
    PoshSemanticVersion.psm1 ............ The root module (init); Exports user-facing module members
    PoshSemanticVersion.format.ps1xml ... The "View"
    PoshSemanticVersion.types.ps1xml .... Type extensions
    SemanticVersion.psm1 ................ SemanticVersion model module
    Validator.psm1 ...................... Validator model module
    Resources.psm1 ...................... Resources model module

using the "using module" statement creates a namespace named after the module.
dot-sourcing a ps1 script with a class does not create the namespace.


Each exported "Advanced Function" is an command, or action, accessible to the user.


Exported functions are the input part of the UI
The format.ps1xml is the output part of the UI

Validation should be part of the UI

PoshSemanticVersion/
  PoshSemanticVersion.psm1
    (public functions)
    Validation class
    Resources class


Classes
-------

PoshSemanticVersion/
  PoshSemanticVersion.format.ps1xml
  PoshSemanticVersion.types.ps1xml
  PoshSemanticVersion.psd1
  PoshSemanticVersion.psm1
  Shared/
    Shared.psm1
    Validation.ps1
  Commands/
    Commands.psm1
    New-SemanticVersion.ps1
    Test-SemanticVersion.ps1
    Compare-SemanticVersion.ps1
    Step-SemanticVersion.ps1
  Models/
    Models.psm1
    SemanticVersion.psm1



PoshSemanticVersion/
  en/ ................... Resources
  PoshSemanticVersion.psd1 ... Manifest
  RootModule.psm1 ............ Root module ... import classes into this module/namespace, export functions.
  SemanticVersion/SemanticVersion.psm1 ....... Model
  SharedModule/ .............................. Shared classes/functions
  New-SemanticVersion.ps1 .................... Class / exported function
  Test-SemanticVersion.ps1 ................... Class /exported function
  Compare-SemanticVersion.ps1 ................ Class / exported function
  Step-SemanticVersion.ps1 ................... Class / exported function
  ConvertTo-SemanticVersion.ps1 .............. Class /exported function
  ConvertFrom-SemanticVersion.ps1 ............ Class / exported function
