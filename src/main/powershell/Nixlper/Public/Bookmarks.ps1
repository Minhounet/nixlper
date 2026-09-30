########################################################################################################################
# FILE: Bookmarks.ps1
# DESCRIPTION: Total Commander-style bookmarks for PowerShell (CTRL+X+D to jump, CTRL+X+B to add/remove).
#
# The bookmarks file uses the exact same line format as the bash version:
#     alias NAME='cd PATH && echo "INFO: Jump into folder PATH"'
# so one file can be shared by bash and PowerShell (same machine, WSL, or Linux pwsh). Every bookmark also becomes a
# global function NAME that jumps to the folder, like the bash aliases.
########################################################################################################################

# Same rule as the bash parser (_i_bookmarks_valid_entries): greedy path capture up to the rightmost " &&".
$script:NixlperBookmarkLinePattern = "^alias\s+([A-Za-z0-9_]+)='cd\s+(.*)\s&&"
$script:NixlperBookmarkFunctions = New-Object System.Collections.Generic.List[string]

function Get-NixlperBookmarksFile {
  if ($env:NIXLPER_BOOKMARKS_FILE) { return $env:NIXLPER_BOOKMARKS_FILE }
  return (Join-Path -Path $HOME -ChildPath '.local/share/nixlper/bookmarks')
}

#-----------------------------------------------------------------------------------------------------------------------
# Get-NixlperBookmarkEntry: parse the bookmarks file -> objects with Name, Path, Exists.
#-----------------------------------------------------------------------------------------------------------------------
function Get-NixlperBookmarkEntry {
  $file = Get-NixlperBookmarksFile
  if (-not (Test-Path -LiteralPath $file)) { return }
  foreach ($line in [System.IO.File]::ReadAllLines($file)) {
    if ($line -match $script:NixlperBookmarkLinePattern) {
      [pscustomobject]@{
        Name   = $Matches[1]
        Path   = $Matches[2]
        Exists = (Test-Path -LiteralPath $Matches[2] -PathType Container)
      }
    }
  }
}

function Test-NixlperSamePath {
  param([string]$Left, [string]$Right)
  $a = $Left.TrimEnd('\', '/')
  $b = $Right.TrimEnd('\', '/')
  if (Test-NixlperWindows) { return ($a -eq $b) }
  return ($a -ceq $b)
}

#-----------------------------------------------------------------------------------------------------------------------
# Test-NixlperBookmarkName: validate a new bookmark name; prints the reason and returns $false when refused.
#-----------------------------------------------------------------------------------------------------------------------
function Test-NixlperBookmarkName {
  param([string]$Name)
  if ([string]::IsNullOrEmpty($Name)) {
    Write-NixlperError 'Bookmark cannot be empty, please enter a value'
    return $false
  }
  if ($Name -notmatch '^[A-Za-z0-9_]+$') {
    Write-NixlperError "Bookmark name $Name is invalid: use letters, digits and _ only"
    return $false
  }
  if (@(Get-NixlperBookmarkEntry | Where-Object { $_.Name -eq $Name }).Count -gt 0) {
    Write-NixlperError "Bookmark name $Name is already used!"
    return $false
  }
  # Reserved by the bash navigate feature (n1, v2...) - keep the shared file usable from bash.
  if ($Name -match '^[nv][0-9]+$') {
    Write-NixlperError "Cannot use $Name because these names are reserved for the navigate feature"
    return $false
  }
  if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
    Write-NixlperError "Cannot use $Name because it is already a command"
    return $false
  }
  return $true
}

function Add-NixlperBookmarkEntry {
  param([string]$Name, [string]$Path)
  if ($Path.Contains("'")) {
    Write-NixlperError "Cannot bookmark a path containing a single quote: $Path"
    return $false
  }
  $file = Get-NixlperBookmarksFile
  $parent = Split-Path -Path $file -Parent
  if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  # LF line endings on purpose: bash reads this file too, and a CR would end up inside the path.
  $line = "alias $Name='cd $Path && echo `"INFO: Jump into folder $Path`"'`n"
  [System.IO.File]::AppendAllText($file, $line)
  return $true
}

function Remove-NixlperBookmarkEntry {
  param([string]$Name)
  $file = Get-NixlperBookmarksFile
  if (-not (Test-Path -LiteralPath $file)) { return }
  $kept = @([System.IO.File]::ReadAllLines($file) | Where-Object { $_ -notmatch ('^alias\s+' + [regex]::Escape($Name) + '=') })
  $content = ''
  if ($kept.Count -gt 0) { $content = ($kept -join "`n") + "`n" }
  [System.IO.File]::WriteAllText($file, $content)
}

#-----------------------------------------------------------------------------------------------------------------------
# Register-NixlperBookmarkFunction: define a global function per bookmark (typing its name jumps there). A bookmark
# whose name is already taken by another command is skipped, so a bookmark can never shadow a real command.
#-----------------------------------------------------------------------------------------------------------------------
function Register-NixlperBookmarkFunction {
  foreach ($entry in @(Get-NixlperBookmarkEntry)) {
    $mine = $script:NixlperBookmarkFunctions.Contains($entry.Name)
    if (-not $mine -and (Get-Command -Name $entry.Name -ErrorAction SilentlyContinue)) { continue }
    # Single-quoted literals only, so a folder named like `$(...)` can never be evaluated. The escaper also doubles
    # the typographic quotes PowerShell accepts as single quotes.
    $escaped = [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($entry.Path)
    $body = "Set-Location -LiteralPath '$escaped'; Write-Host 'INFO: Jump into folder $escaped'"
    Set-Item -Path "Function:\global:$($entry.Name)" -Value ([scriptblock]::Create($body))
    if (-not $mine) { $script:NixlperBookmarkFunctions.Add($entry.Name) }
  }
}

function Unregister-NixlperBookmarkFunction {
  param([string]$Name)
  if ($script:NixlperBookmarkFunctions.Remove($Name)) {
    # No scope qualifier: from the module scope the lookup walks up to the global function. (Removing
    # "Function:\global:NAME" silently does nothing.)
    Remove-Item -Path "Function:\$Name" -ErrorAction SilentlyContinue
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: Display bookmarks and jump to one (number-jump or fuzzy search via fzf)
# @category: Bookmarks
# @keybind: CTRL+X+D
# @alias: bd
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function Show-NixlperBookmark {
  $entries = @(Get-NixlperBookmarkEntry)
  $valid = @($entries | Where-Object { $_.Exists })
  Write-NixlperInfo 'Current bookmarks are:'
  foreach ($entry in $entries) {
    $suffix = ''
    if (-not $entry.Exists) { $suffix = '  [missing]' }
    Write-Host "$($entry.Path) ($($entry.Name))$suffix"
  }
  Write-Host ''
  $here = (Get-Location).ProviderPath
  $current = @($entries | Where-Object { Test-NixlperSamePath $_.Path $here })
  if ($current.Count -eq 0) {
    Write-Host "-> $here (not bookmarked)"
    Write-Host 'HINT: use "CTRL + X THEN B" to bookmark it'
  } else {
    Write-Host "currently in $($current[0].Path) ($($current[0].Name))"
  }
  if ($valid.Count -eq 0) { return }

  $labels = @($valid | ForEach-Object { '{0,-20} {1}' -f $_.Name, $_.Path })
  if ((Test-NixlperFlag -Name 'NIXLPER_BOOKMARKS_FUZZY' -Default $true) -and (Test-NixlperFzf)) {
    $index = Select-NixlperFzf -Items $labels -Prompt 'Bookmarks' `
      -Header 'Type a number to jump, or letters to fuzzy-filter by name/path | ENTER: jump | ESC: cancel'
  } else {
    $index = Read-NixlperChoice -Items $labels -Prompt 'Jump to'
  }
  if ($index -lt 0) { return }
  $target = $valid[$index]
  Set-Location -LiteralPath $target.Path
  Write-NixlperInfo "Jumped to $($target.Name) ($($target.Path))"
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: Add or remove bookmark for current folder
# @category: Bookmarks
# @keybind: CTRL+X+B
# @alias: bm
# @interactive
#-----------------------------------------------------------------------------------------------------------------------
function Switch-NixlperBookmark {
  $location = Get-Location
  if ($location.Provider.Name -ne 'FileSystem') {
    Write-NixlperError "Only folders can be bookmarked (current location is $($location.Path))"
    return
  }
  $here = $location.ProviderPath
  $current = @(Get-NixlperBookmarkEntry | Where-Object { Test-NixlperSamePath $_.Path $here })

  if ($current.Count -eq 0) {
    Write-Host "-> $here not bookmarked"
    $answer = Read-Host 'Bookmark this folder? (y/n default y)'
    if ($answer -and $answer -ne 'y') {
      Write-NixlperInfo 'Action is cancelled'
      return
    }
    $default = (Split-Path -Path $here -Leaf) -replace '[^A-Za-z0-9_]', '_'
    $name = Read-Host "Enter bookmark name (default: $default)"
    if ([string]::IsNullOrEmpty($name)) { $name = $default }
    while (-not (Test-NixlperBookmarkName -Name $name)) {
      $name = Read-Host 'Enter bookmark name (Enter to cancel)'
      if ([string]::IsNullOrEmpty($name)) {
        Write-NixlperInfo 'Action is cancelled'
        return
      }
    }
    if (Add-NixlperBookmarkEntry -Name $name -Path $here) {
      Register-NixlperBookmarkFunction
      Write-NixlperInfo "Bookmark saved: type $name to jump here"
    }
  } else {
    Write-Host "current bookmark -> $($current[0].Path) ($($current[0].Name))"
    $answer = Read-Host 'Delete bookmark? (y/n default n)'
    if ($answer -ne 'y') {
      Write-NixlperInfo 'Action is cancelled'
      return
    }
    Remove-NixlperBookmarkEntry -Name $current[0].Name
    Unregister-NixlperBookmarkFunction -Name $current[0].Name
    Write-NixlperInfo "Bookmark $($current[0].Name) is deleted"
  }
}
