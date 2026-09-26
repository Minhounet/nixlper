########################################################################################################################
# FILE: Nixlper.psm1
# DESCRIPTION: entry point of the PowerShell port of nixlper (preview). Loads the helpers, activates the bash-compat
#              layer, defines bookmark jump functions and binds the CTRL+X chords through PSReadLine.
#
# Settings are read from environment variables (set them in $PROFILE before Import-Module):
#   NIXLPER_BASH_COMPAT       auto (default: on for Windows only) | true | false
#   NIXLPER_BOOKMARKS_FILE    bookmarks file (default ~/.local/share/nixlper/bookmarks, same format as bash)
#   NIXLPER_BOOKMARKS_FUZZY   true (default) | false - use fzf for the bookmark picker when installed
#   NIXLPER_PS_KEYBINDINGS    true (default) | false - bind the CTRL+X chords
########################################################################################################################

$script:NixlperModuleRoot = $PSScriptRoot

foreach ($folder in @('Private', 'Public')) {
  foreach ($file in (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath $folder) -Filter '*.ps1' | Sort-Object Name)) {
    . $file.FullName
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Bash-compat layer: point the bash command names at the Invoke-Nixlper* functions with global aliases.
#
# Global aliases (not exported functions) are used because on Windows `ls`, `rm`, `cp` and `mv` already exist as
# AllScope aliases, and an alias always wins over a function of the same name. The previous alias definitions are
# remembered and restored by Remove-Module (see OnRemove below).
#
# In `auto` mode a command is skipped when a real executable of that name is on PATH (Git for Windows, uutils,
# busybox...): a genuine grep beats an emulation. Linux/macOS pwsh already has the real tools, so `auto` is off there.
#-----------------------------------------------------------------------------------------------------------------------
$script:NixlperCompatCommands = [ordered]@{
  grep   = 'Invoke-NixlperGrep'
  head   = 'Invoke-NixlperHead'
  tail   = 'Invoke-NixlperTail'
  wc     = 'Invoke-NixlperWc'
  touch  = 'Invoke-NixlperTouch'
  which  = 'Invoke-NixlperWhich'
  export = 'Invoke-NixlperExport'
  ls     = 'Invoke-NixlperLs'
  rm     = 'Invoke-NixlperRm'
  cp     = 'Invoke-NixlperCp'
  mv     = 'Invoke-NixlperMv'
}
$script:NixlperCompatActive = New-Object System.Collections.Generic.List[string]
$script:NixlperPreviousAliases = @{}

function Register-NixlperBashCompat {
  $mode = $env:NIXLPER_BASH_COMPAT
  if ([string]::IsNullOrEmpty($mode)) { $mode = 'auto' }
  if ($mode -eq 'false') { return }
  if ($mode -eq 'auto' -and -not (Test-NixlperWindows)) { return }

  foreach ($name in $script:NixlperCompatCommands.Keys) {
    if ($mode -eq 'auto' -and (Get-Command -Name $name -CommandType Application -ErrorAction SilentlyContinue)) {
      continue
    }
    $previous = Get-Alias -Name $name -Scope Global -ErrorAction SilentlyContinue
    if ($previous) { $script:NixlperPreviousAliases[$name] = $previous.Definition }
    Set-Alias -Name $name -Value $script:NixlperCompatCommands[$name] -Scope Global -Force
    $script:NixlperCompatActive.Add($name)
  }
}

function Unregister-NixlperBashCompat {
  foreach ($name in $script:NixlperCompatActive) {
    if ($script:NixlperPreviousAliases.ContainsKey($name)) {
      Set-Alias -Name $name -Value $script:NixlperPreviousAliases[$name] -Scope Global -Force
    } elseif (Get-Command -Name Remove-Alias -ErrorAction SilentlyContinue) {
      Remove-Alias -Name $name -Scope Global -Force
    } else {
      Remove-Item -Path "Alias:\$name" -Force -ErrorAction SilentlyContinue
    }
  }
  $script:NixlperCompatActive.Clear()
}

#-----------------------------------------------------------------------------------------------------------------------
# Keybindings: the same CTRL+X chords as bash. Each one replaces the current line with a command and submits it -
# the equivalent of bash's `bind '"\C-x\C-d": "bookmark_dirs\15"'` - so the command runs in the normal prompt where
# Read-Host and fzf work.
#-----------------------------------------------------------------------------------------------------------------------
$script:NixlperKeybindings = [ordered]@{
  'Ctrl+x,Ctrl+a' = 'fa'
  'Ctrl+x,Ctrl+d' = 'bd'
  'Ctrl+x,Ctrl+b' = 'bm'
}

function Register-NixlperKeybinding {
  if (-not (Test-NixlperFlag -Name 'NIXLPER_PS_KEYBINDINGS' -Default $true)) { return }
  # PSReadLine is only loaded in interactive sessions; scripts and CI have nothing to bind.
  if (-not (Get-Module -Name PSReadLine)) { return }
  foreach ($chord in $script:NixlperKeybindings.Keys) {
    $command = $script:NixlperKeybindings[$chord]
    $handler = {
      [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
      [Microsoft.PowerShell.PSConsoleReadLine]::Insert($command)
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }.GetNewClosure()
    try {
      Set-PSReadLineKeyHandler -Chord $chord -ScriptBlock $handler -BriefDescription "nixlper: $command" `
        -Description "nixlper: run $command"
    } catch {
      Write-NixlperError "Could not bind $chord to ${command}: $($_.Exception.Message)"
    }
  }
}

Set-Alias -Name fa -Value Find-NixlperAction
Set-Alias -Name bd -Value Show-NixlperBookmark
Set-Alias -Name bm -Value Switch-NixlperBookmark

Register-NixlperBashCompat
Register-NixlperBookmarkFunction
Register-NixlperKeybinding

$ExecutionContext.SessionState.Module.OnRemove = {
  Unregister-NixlperBashCompat
  foreach ($name in @($script:NixlperBookmarkFunctions)) { Unregister-NixlperBookmarkFunction -Name $name }
}

Export-ModuleMember -Function @(
  'Find-NixlperAction', 'Show-NixlperBookmark', 'Switch-NixlperBookmark',
  'Invoke-NixlperGrep', 'Invoke-NixlperHead', 'Invoke-NixlperTail', 'Invoke-NixlperWc', 'Invoke-NixlperTouch',
  'Invoke-NixlperWhich', 'Invoke-NixlperExport', 'Invoke-NixlperLs', 'Invoke-NixlperRm', 'Invoke-NixlperCp',
  'Invoke-NixlperMv'
) -Alias @('fa', 'bd', 'bm')
