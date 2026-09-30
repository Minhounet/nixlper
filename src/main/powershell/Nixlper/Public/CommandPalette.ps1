########################################################################################################################
# FILE: CommandPalette.ps1
# DESCRIPTION: command palette for PowerShell (CTRL+X+A / fa). Commands are discovered from the same
#              `# @cmd-palette` annotations the bash version uses, read from this module's own source files.
#
# Unlike bash there is no `bind -x` raw-mode constraint: every keybind submits a normal command line, so the palette
# runs in the regular prompt and can ask for arguments with Read-Host.
########################################################################################################################

#-----------------------------------------------------------------------------------------------------------------------
# Get-NixlperCommandRegistry: parse @cmd-palette annotations -> objects with Function, Name, Description, Category,
# Keybind, Args, Interactive. Bash-compat commands that are not active in this session are left out.
#-----------------------------------------------------------------------------------------------------------------------
function Get-NixlperCommandRegistry {
  $files = Get-ChildItem -Path (Join-Path -Path $script:NixlperModuleRoot -ChildPath 'Public') -Filter '*.ps1' |
    Sort-Object Name
  foreach ($file in $files) {
    $entry = $null
    foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
      if ($line -match '^\s*#\s*@cmd-palette') {
        $entry = @{ Description = ''; Category = ''; Keybind = ''; Alias = ''; Args = ''; Interactive = $false }
        continue
      }
      if ($null -eq $entry) { continue }
      if ($line -match '^\s*#\s*@description:\s*(.*)$') { $entry.Description = $Matches[1].Trim() }
      elseif ($line -match '^\s*#\s*@category:\s*(.*)$') { $entry.Category = $Matches[1].Trim() }
      elseif ($line -match '^\s*#\s*@keybind:\s*(.*)$') { $entry.Keybind = $Matches[1].Trim() }
      elseif ($line -match '^\s*#\s*@alias:\s*(.*)$') { $entry.Alias = $Matches[1].Trim() }
      elseif ($line -match '^\s*#\s*@args:\s*(.*)$') { $entry.Args = $Matches[1].Trim() }
      elseif ($line -match '^\s*#\s*@interactive') { $entry.Interactive = $true }
      elseif ($line -match '^\s*function\s+([A-Za-z0-9_-]+)') {
        $function = $Matches[1]
        $name = $function
        if ($entry.Alias) { $name = $entry.Alias }
        $active = ($entry.Category -ne 'Bash compat') -or $script:NixlperCompatActive.Contains($name)
        if ($active) {
          [pscustomobject]@{
            Function    = $function
            Name        = $name
            Description = $entry.Description
            Category    = $entry.Category
            Keybind     = $entry.Keybind
            Args        = $entry.Args
            Interactive = $entry.Interactive
          }
        }
        $entry = $null
      }
    }
  }
}

function Format-NixlperCommand {
  param($Command)
  $keybind = ''
  if ($Command.Keybind) { $keybind = "[$($Command.Keybind)]" }
  return ('{0,-8} {1,-14} {2,-18} {3}' -f $Command.Name, $keybind, "($($Command.Category))", $Command.Description)
}

#-----------------------------------------------------------------------------------------------------------------------
# Invoke-NixlperPaletteCommand: run a palette entry. Commands declaring @args ask for their arguments first; the
# resulting line runs in the caller's session exactly as if it had been typed.
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperPaletteCommand {
  param($Command)
  if ($Command.Args) {
    $arguments = Read-Host "$($Command.Name) $($Command.Args)"
    if ([string]::IsNullOrEmpty($arguments)) {
      Write-NixlperInfo 'Cancelled.'
      return
    }
    $line = "$($Command.Name) $arguments"
    Write-Host "> $line"
    & ([scriptblock]::Create($line))
    return
  }
  & $Command.Function
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: Search and select commands interactively
# @category: Command Palette
# @keybind: CTRL+X+A
# @alias: fa
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function Find-NixlperAction {
  $commands = @(Get-NixlperCommandRegistry | Sort-Object Category, Name)
  if ($commands.Count -eq 0) {
    Write-NixlperError 'No command found'
    return
  }
  $labels = @($commands | ForEach-Object { Format-NixlperCommand $_ })
  if (Test-NixlperFzf) {
    $index = Select-NixlperFzf -Items $labels -Prompt 'Nixlper' `
      -Header 'Type to filter by name, keybind, category or description | ENTER: run | ESC: cancel'
  } else {
    $index = Read-NixlperChoice -Items $labels -Prompt 'Run'
  }
  if ($index -lt 0) { return }
  Invoke-NixlperPaletteCommand -Command $commands[$index]
}
