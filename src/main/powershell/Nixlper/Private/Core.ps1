########################################################################################################################
# FILE: Core.ps1
# DESCRIPTION: shared helpers for the PowerShell port (logging, config flags, platform/fzf detection).
#
# Syntax is kept compatible with Windows PowerShell 5.1: no ternary, no `??`, no pipeline chain operators.
########################################################################################################################

function Write-NixlperInfo {
  param([string]$Message)
  Write-Host "INFO: $Message"
}

function Write-NixlperError {
  param([string]$Message)
  Write-Host "ERROR: $Message" -ForegroundColor Red
}

#-----------------------------------------------------------------------------------------------------------------------
# Test-NixlperFlag: read a boolean NIXLPER_* environment variable ("true"/"false"), with a default.
#-----------------------------------------------------------------------------------------------------------------------
function Test-NixlperFlag {
  param([string]$Name, [bool]$Default)
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrEmpty($value)) { return $Default }
  return ($value -eq 'true')
}

#-----------------------------------------------------------------------------------------------------------------------
# Test-NixlperWindows: $IsWindows does not exist in Windows PowerShell 5.1, which only runs on Windows.
#-----------------------------------------------------------------------------------------------------------------------
function Test-NixlperWindows {
  if ($PSVersionTable.PSEdition -eq 'Desktop') { return $true }
  return [bool]$IsWindows
}

function Test-NixlperFzf {
  return [bool](Get-Command -Name fzf -CommandType Application -ErrorAction SilentlyContinue)
}

#-----------------------------------------------------------------------------------------------------------------------
# Read-NixlperChoice: numbered picker used when fzf is missing or disabled. Returns the 0-based index of the chosen
# item, or -1 when cancelled / invalid.
#-----------------------------------------------------------------------------------------------------------------------
function Read-NixlperChoice {
  param([string[]]$Items, [string]$Prompt)
  Write-Host ''
  for ($i = 0; $i -lt $Items.Count; $i++) {
    Write-Host ('  {0,2}) {1}' -f ($i + 1), $Items[$i])
  }
  Write-Host ''
  $choice = Read-Host "$Prompt [1-$($Items.Count)] (Enter to cancel)"
  if ([string]::IsNullOrEmpty($choice)) {
    Write-NixlperInfo 'Cancelled.'
    return -1
  }
  $index = 0
  if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $Items.Count) {
    Write-NixlperError "Invalid selection: $choice"
    return -1
  }
  return ($index - 1)
}

#-----------------------------------------------------------------------------------------------------------------------
# Select-NixlperFzf: pipe "N  text" lines to fzf and return the 0-based index of the chosen line (-1 on cancel).
# Lines are prefixed with their number, so typing digits jumps to an entry - same hybrid as the bash `rd`/`bd`.
#-----------------------------------------------------------------------------------------------------------------------
function Select-NixlperFzf {
  param([string[]]$Items, [string]$Prompt, [string]$Header)
  $lines = for ($i = 0; $i -lt $Items.Count; $i++) { '{0}  {1}' -f ($i + 1), $Items[$i] }
  $selected = $lines | & fzf "--prompt=$Prompt > " --height=40% --reverse "--header=$Header"
  if ([string]::IsNullOrEmpty($selected)) {
    Write-NixlperInfo 'Cancelled.'
    return -1
  }
  return ([int]($selected -split ' ', 2)[0] - 1)
}
