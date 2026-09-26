@{
  RootModule           = 'Nixlper.psm1'
  ModuleVersion        = '0.1.0'
  GUID                 = '6f1f7d0a-3c1e-4c55-9d2b-5a8e2f4b7c11'
  Author               = 'Minhounet'
  Description          = 'Nixlper for PowerShell (preview): Total Commander-style bookmarks, a command palette and bash-style commands (grep, ls -la, rm -rf, tail -f...) for people who know bash but not PowerShell.'
  PowerShellVersion    = '5.1'
  CompatiblePSEditions = @('Desktop', 'Core')
  FunctionsToExport    = @(
    'Find-NixlperAction', 'Show-NixlperBookmark', 'Switch-NixlperBookmark',
    'Invoke-NixlperGrep', 'Invoke-NixlperHead', 'Invoke-NixlperTail', 'Invoke-NixlperWc', 'Invoke-NixlperTouch',
    'Invoke-NixlperWhich', 'Invoke-NixlperExport', 'Invoke-NixlperLs', 'Invoke-NixlperRm', 'Invoke-NixlperCp',
    'Invoke-NixlperMv'
  )
  CmdletsToExport      = @()
  VariablesToExport    = @()
  AliasesToExport      = @('fa', 'bd', 'bm')
  PrivateData          = @{
    PSData = @{
      Tags       = @('bash', 'bookmarks', 'total-commander', 'productivity')
      ProjectUri = 'https://github.com/Minhounet/nixlper'
    }
  }
}
