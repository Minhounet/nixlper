########################################################################################################################
# FILE: BashCompat.ps1
# DESCRIPTION: bash-style commands for people who know bash but not PowerShell (grep, head, tail, wc, touch, which,
#              export, ls, rm, cp, mv). Each one parses the usual bash flags and is backed by native PowerShell /
#              .NET - no external binary required.
#
# The functions are named Invoke-Nixlper<Cmd>; Nixlper.psm1 points the bash names (grep, ls, ...) at them with global
# aliases when the compat layer is enabled (see Register-NixlperBashCompat and INTERNALS.md).
#
# They are simple functions (no param block) on purpose: bash flags such as `-rn` arrive untouched in $args, and
# PowerShell-style parameters (`ls -Recurse`, `rm -Force`) are detected and passed straight to the original cmdlet, so
# scripts written for PowerShell keep working after `ls`/`rm`/`cp`/`mv` are redirected here.
########################################################################################################################

#***********************************************************************************************************************
# Shared helpers
#***********************************************************************************************************************

function Write-NixlperStdErr {
  param([string]$Message)
  $Host.UI.WriteErrorLine($Message)
}

#-----------------------------------------------------------------------------------------------------------------------
# Test-NixlperBashFlags: $true when every option-looking argument is a cluster of the allowed bash flag letters
# (case-sensitive, e.g. `-rf`). Anything else (`-Recurse`, `-Force`, `-Path`) means the caller wrote PowerShell, and the
# command should be passed through to the original cmdlet unchanged.
#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
# ConvertTo-NixlperPathList: turn pipeline input (FileInfo/DirectoryInfo objects or strings) into path strings, so
# `Get-ChildItem *.tmp | rm` keeps working once `rm` points here.
#-----------------------------------------------------------------------------------------------------------------------
function ConvertTo-NixlperPathList {
  param([object[]]$InputObject)
  foreach ($item in $InputObject) {
    if ($item -is [System.IO.FileSystemInfo]) { $item.FullName } else { [string]$item }
  }
}

function Test-NixlperBashFlags {
  param([object[]]$Arguments, [string]$Allowed)
  foreach ($arg in $Arguments) {
    $a = [string]$arg
    if ($a -eq '--' -or $a -eq '-' -or -not $a.StartsWith('-')) { continue }
    if ($a -cnotmatch '^-[A-Za-z0-9]+$') { return $false }
    foreach ($ch in $a.Substring(1).ToCharArray()) {
      if (-not $Allowed.Contains([string]$ch)) { return $false }
    }
  }
  return $true
}

#-----------------------------------------------------------------------------------------------------------------------
# Resolve-NixlperPath: expand one bash-style path argument into items. A literal path wins (so names containing `[`
# work); otherwise the argument is treated as a wildcard, like the shell glob bash would have expanded.
#-----------------------------------------------------------------------------------------------------------------------
function Resolve-NixlperPath {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    return @(Get-Item -LiteralPath $Path -Force)
  }
  return @(Get-Item -Path $Path -Force -ErrorAction SilentlyContinue)
}

#-----------------------------------------------------------------------------------------------------------------------
# ConvertTo-NixlperRegex: translate a grep pattern to a .NET regex.
# - Basic mode (grep without -E): `\|`, `\(`, `\)`, `\{`, `\}`, `\+`, `\?` are operators and their bare forms are
#   literals - the GNU BRE rules, so `grep 'foo\|bar'` behaves as in bash.
# - Both modes: POSIX classes (`[[:digit:]]`) and GNU word anchors (`\<`, `\>`) are converted; backslashes inside a
#   bracket expression are literal, as in POSIX.
#-----------------------------------------------------------------------------------------------------------------------
function ConvertTo-NixlperRegex {
  param([string]$Pattern, [bool]$Extended)
  $posixClasses = @{
    'alpha' = 'a-zA-Z'; 'digit' = '0-9'; 'alnum' = 'a-zA-Z0-9'; 'upper' = 'A-Z'; 'lower' = 'a-z'
    'space' = '\s'; 'blank' = ' \t'; 'punct' = '\p{P}\p{S}'; 'xdigit' = '0-9A-Fa-f'; 'word' = '\w'
  }
  $breOperators = '|(){}+?'
  $sb = New-Object System.Text.StringBuilder
  $inBracket = $false
  $i = 0
  while ($i -lt $Pattern.Length) {
    $c = $Pattern[$i]
    if ($inBracket) {
      if ($c -eq '[' -and $i + 1 -lt $Pattern.Length -and $Pattern[$i + 1] -eq ':') {
        $end = $Pattern.IndexOf(':]', $i + 2)
        if ($end -gt 0) {
          $name = $Pattern.Substring($i + 2, $end - $i - 2)
          if ($posixClasses.ContainsKey($name)) {
            [void]$sb.Append($posixClasses[$name])
            $i = $end + 2
            continue
          }
        }
      }
      if ($c -eq ']') { $inBracket = $false; [void]$sb.Append(']') }
      elseif ($c -eq '\') { [void]$sb.Append('\\') }
      elseif ($c -eq '[') { [void]$sb.Append('\[') }
      else { [void]$sb.Append($c) }
      $i++
      continue
    }
    if ($c -eq '[') {
      $inBracket = $true
      [void]$sb.Append('[')
      $i++
      if ($i -lt $Pattern.Length -and $Pattern[$i] -eq '^') { [void]$sb.Append('^'); $i++ }
      if ($i -lt $Pattern.Length -and $Pattern[$i] -eq ']') { [void]$sb.Append('\]'); $i++ }
      continue
    }
    if ($c -eq '\' -and $i + 1 -lt $Pattern.Length) {
      $n = $Pattern[$i + 1]
      if ($n -eq '<' -or $n -eq '>') { [void]$sb.Append('\b') }
      elseif (-not $Extended -and $breOperators.Contains([string]$n)) { [void]$sb.Append($n) }
      else { [void]$sb.Append($c).Append($n) }
      $i += 2
      continue
    }
    if (-not $Extended -and $breOperators.Contains([string]$c)) { [void]$sb.Append('\').Append($c) }
    else { [void]$sb.Append($c) }
    $i++
  }
  return $sb.ToString()
}

#***********************************************************************************************************************
# grep
#***********************************************************************************************************************

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: grep for PowerShell (-i -v -n -r -l -c -w -x -o -F -E -e --include), backed by .NET regex
# @category: Bash compat
# @alias: grep
# @args: [OPTIONS] PATTERN [FILE...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperGrep {
  $o = @{ i = $false; v = $false; n = $false; r = $false; l = $false; c = $false; fixed = $false; w = $false; x = $false
          o = $false; noName = $false; withName = $false; q = $false; E = $false; s = $false }
  $patterns = New-Object System.Collections.Generic.List[string]
  $paths = New-Object System.Collections.Generic.List[string]
  $includes = New-Object System.Collections.Generic.List[string]
  $endOfOptions = $false
  $global:LASTEXITCODE = 2

  for ($idx = 0; $idx -lt $args.Count; $idx++) {
    $a = [string]$args[$idx]
    if (-not $endOfOptions -and $a -eq '--') { $endOfOptions = $true; continue }
    if (-not $endOfOptions -and $a.StartsWith('--') -and $a.Length -gt 2) {
      $parts = $a.Substring(2) -split '=', 2
      $value = $null
      if ($parts.Count -gt 1) { $value = $parts[1] }
      switch -Exact ($parts[0]) {
        'ignore-case'           { $o.i = $true }
        'invert-match'          { $o.v = $true }
        'line-number'           { $o.n = $true }
        'recursive'             { $o.r = $true }
        'dereference-recursive' { $o.r = $true }
        'files-with-matches'    { $o.l = $true }
        'count'                 { $o.c = $true }
        'fixed-strings'         { $o.fixed = $true }
        'word-regexp'           { $o.w = $true }
        'line-regexp'           { $o.x = $true }
        'only-matching'         { $o.o = $true }
        'no-filename'           { $o.noName = $true }
        'with-filename'         { $o.withName = $true }
        'quiet'                 { $o.q = $true }
        'silent'                { $o.q = $true }
        'extended-regexp'       { $o.E = $true }
        'no-messages'           { $o.s = $true }
        'color'                 { }
        'colour'                { }
        'include' {
          if ($null -eq $value) { $idx++; $value = [string]$args[$idx] }
          $includes.Add($value)
        }
        'regexp' {
          if ($null -eq $value) { $idx++; $value = [string]$args[$idx] }
          $patterns.Add($value)
        }
        default {
          Write-NixlperStdErr "grep: unrecognized option '$a'"
          return
        }
      }
      continue
    }
    if (-not $endOfOptions -and $a -cmatch '^-[A-Za-z]+$') {
      $letters = $a.Substring(1)
      for ($j = 0; $j -lt $letters.Length; $j++) {
        $ch = [string]$letters[$j]
        if ($ch -ceq 'e') {
          # -e takes the rest of the cluster (-efoo) or the next argument as a pattern.
          $rest = $letters.Substring($j + 1)
          if ($rest) { $patterns.Add($rest) } else { $idx++; $patterns.Add([string]$args[$idx]) }
          break
        }
        switch -CaseSensitive ($ch) {
          'i' { $o.i = $true }
          'y' { $o.i = $true }
          'v' { $o.v = $true }
          'n' { $o.n = $true }
          'r' { $o.r = $true }
          'R' { $o.r = $true }
          'l' { $o.l = $true }
          'c' { $o.c = $true }
          'F' { $o.fixed = $true }
          'w' { $o.w = $true }
          'x' { $o.x = $true }
          'o' { $o.o = $true }
          'h' { $o.noName = $true }
          'H' { $o.withName = $true }
          'q' { $o.q = $true }
          'E' { $o.E = $true }
          'P' { $o.E = $true }
          'G' { $o.E = $false }
          's' { $o.s = $true }
          default {
            Write-NixlperStdErr "grep: invalid option -- '$ch'"
            return
          }
        }
      }
      continue
    }
    if ($patterns.Count -eq 0) { $patterns.Add($a) } else { $paths.Add($a) }
  }

  if ($patterns.Count -eq 0) {
    Write-NixlperStdErr 'Usage: grep [OPTION]... PATTERN [FILE]...'
    return
  }

  $regexParts = foreach ($p in $patterns) {
    if ($o.fixed) { [regex]::Escape($p) } else { ConvertTo-NixlperRegex -Pattern $p -Extended $o.E }
  }
  $body = '(?:' + ($regexParts -join ')|(?:') + ')'
  if ($o.w) { $body = '(?<!\w)' + $body + '(?!\w)' }
  if ($o.x) { $body = '^' + $body + '$' }
  $options = [System.Text.RegularExpressions.RegexOptions]::None
  if ($o.i) { $options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
  try {
    $re = New-Object System.Text.RegularExpressions.Regex -ArgumentList $body, $options
  } catch {
    Write-NixlperStdErr "grep: invalid regular expression: $($patterns -join ', ')"
    return
  }

  # Build the list of sources: pipeline text, or files (expanded from wildcards / recursion).
  $fromPipeline = $MyInvocation.ExpectingInput -and $paths.Count -eq 0
  $implicitDir = $false
  if (-not $fromPipeline -and $paths.Count -eq 0) {
    if ($o.r) {
      $paths.Add('.')
      $implicitDir = $true
    } else {
      Write-NixlperStdErr 'grep: no FILE given (pass a file, or pipe text into grep)'
      return
    }
  }

  $hadError = $false
  $sep = [System.IO.Path]::DirectorySeparatorChar
  $files = New-Object System.Collections.Generic.List[object]
  foreach ($p in $paths) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) {
      if (-not $o.s) { Write-NixlperStdErr "grep: ${p}: No such file or directory" }
      $hadError = $true
      continue
    }
    $isWildcard = -not (Test-Path -LiteralPath $p)
    foreach ($item in $items) {
      if ($item.PSIsContainer) {
        if (-not $o.r) {
          if (-not $o.s) { Write-NixlperStdErr "grep: ${p}: Is a directory" }
          continue
        }
        $root = $item.FullName.TrimEnd('\', '/')
        $prefix = ''
        if (-not $implicitDir) {
          if ($isWildcard) { $prefix = $item.Name } else { $prefix = $p.TrimEnd('\', '/') }
        }
        foreach ($child in (Get-ChildItem -LiteralPath $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue)) {
          if ($includes.Count -gt 0) {
            $keep = $false
            foreach ($glob in $includes) { if ($child.Name -like $glob) { $keep = $true } }
            if (-not $keep) { continue }
          }
          $relative = $child.FullName.Substring($root.Length + 1)
          if ($prefix) { $display = $prefix + $sep + $relative } else { $display = $relative }
          $files.Add(@{ Display = $display; Full = $child.FullName })
        }
      } else {
        $display = $p
        if ($isWildcard) {
          $parent = Split-Path -Path $p -Parent
          if ($parent) { $display = $parent + $sep + $item.Name } else { $display = $item.Name }
        }
        $files.Add(@{ Display = $display; Full = $item.FullName })
      }
    }
  }

  $showName = $o.withName -or (-not $o.noName -and ($files.Count -gt 1 -or $o.r))
  $anyMatch = $false

  $sources = New-Object System.Collections.Generic.List[object]
  if ($fromPipeline) {
    # Objects are rendered to text first, so `Get-Process | grep pwsh` greps the table you would see on screen.
    $sources.Add(@{ Display = '(standard input)'; Lines = @($input | Out-String -Stream -Width 4096); Binary = $false })
  } else {
    foreach ($f in $files) {
      $binary = $false
      try {
        $stream = [System.IO.File]::OpenRead($f.Full)
        try {
          $buffer = New-Object byte[] 1024
          $read = $stream.Read($buffer, 0, $buffer.Length)
          for ($b = 0; $b -lt $read; $b++) { if ($buffer[$b] -eq 0) { $binary = $true; break } }
        } finally { $stream.Dispose() }
        $sources.Add(@{ Display = $f.Display; Lines = [System.IO.File]::ReadLines($f.Full); Binary = $binary })
      } catch {
        $reason = $_.Exception
        if ($reason.InnerException) { $reason = $reason.InnerException }
        if (-not $o.s) { Write-NixlperStdErr "grep: $($f.Display): $($reason.Message)" }
        $hadError = $true
      }
    }
  }

  foreach ($src in $sources) {
    $count = 0
    $lineNumber = 0
    $namePrefix = ''
    if ($showName) { $namePrefix = $src.Display + ':' }
    try {
      foreach ($line in $src.Lines) {
        $lineNumber++
        if ($re.IsMatch($line) -eq $o.v) { continue }
        $count++
        $anyMatch = $true
        if ($o.q) { break }
        if ($o.l) { break }
        if ($o.c) { continue }
        if ($src.Binary) { break }
        $prefix = $namePrefix
        if ($o.n) { $prefix += "${lineNumber}:" }
        if ($o.o -and -not $o.v) {
          foreach ($m in $re.Matches($line)) { if ($m.Value) { $prefix + $m.Value } }
        } else {
          $prefix + $line
        }
      }
    } catch {
      if (-not $o.s) { Write-NixlperStdErr "grep: $($src.Display): $($_.Exception.Message)" }
      $hadError = $true
    }
    if ($o.q -and $anyMatch) { break }
    if ($o.l) {
      if ($count -gt 0) { $src.Display }
    } elseif ($o.c) {
      $namePrefix + $count
    } elseif ($src.Binary -and $count -gt 0) {
      "Binary file $($src.Display) matches"
    }
  }

  if ($anyMatch -and ($o.q -or -not $hadError)) { $global:LASTEXITCODE = 0 }
  elseif ($hadError) { $global:LASTEXITCODE = 2 }
  else { $global:LASTEXITCODE = 1 }
}

#***********************************************************************************************************************
# head / tail / wc
#***********************************************************************************************************************

#-----------------------------------------------------------------------------------------------------------------------
# Read-NixlperLineCountArgs: shared parser for `head`/`tail` -> @{ Count; FromStart; Follow; Paths; Error }.
# Accepts -n N, -nN, -N, --lines=N, and (tail only) -n +N, -f, -F, --follow.
#-----------------------------------------------------------------------------------------------------------------------
function Read-NixlperLineCountArgs {
  param([string]$Command, [object[]]$Arguments, [bool]$AllowFollow)
  $result = @{ Count = 10; FromStart = $false; Follow = $false; Paths = @(); Error = $null }
  $paths = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $Arguments.Count; $i++) {
    $a = [string]$Arguments[$i]
    $number = $null
    if ($a -eq '-n') { $i++; $number = [string]$Arguments[$i] }
    elseif ($a -match '^-n(\+?\d+)$') { $number = $Matches[1] }
    elseif ($a -match '^--lines=(\+?\d+)$') { $number = $Matches[1] }
    elseif ($a -match '^-(\d+)$') { $number = $Matches[1] }
    elseif ($AllowFollow -and ($a -eq '-f' -or $a -eq '-F' -or $a -eq '--follow')) { $result.Follow = $true; continue }
    elseif ($a.StartsWith('-') -and $a.Length -gt 1) { $result.Error = "${Command}: invalid option '$a'"; return $result }
    else { $paths.Add($a); continue }

    if ($number -notmatch '^\+?\d+$' -or ($number.StartsWith('+') -and -not $AllowFollow)) {
      $result.Error = "${Command}: invalid number of lines: '$number'"
      return $result
    }
    $result.FromStart = $number.StartsWith('+')
    $result.Count = [int]$number.TrimStart('+')
  }
  $result.Paths = $paths.ToArray()
  return $result
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: head for PowerShell: first N lines of files or of the pipeline (-n N, -N)
# @category: Bash compat
# @alias: head
# @args: [-n N] [FILE...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperHead {
  $opts = Read-NixlperLineCountArgs -Command 'head' -Arguments $args -AllowFollow $false
  if ($opts.Error) { Write-NixlperStdErr $opts.Error; return }
  if ($opts.Paths.Count -eq 0) {
    if ($MyInvocation.ExpectingInput) { $input | Select-Object -First $opts.Count }
    else { Write-NixlperStdErr 'head: no FILE given (pass a file, or pipe into head)' }
    return
  }
  $files = foreach ($p in $opts.Paths) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) { Write-NixlperStdErr "head: cannot open '$p' for reading: No such file or directory" }
    $items
  }
  $files = @($files)
  for ($k = 0; $k -lt $files.Count; $k++) {
    if ($files.Count -gt 1) {
      if ($k -gt 0) { '' }
      "==> $($files[$k].Name) <=="
    }
    Get-Content -LiteralPath $files[$k].FullName -TotalCount $opts.Count
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: tail for PowerShell: last N lines, -n +N from line N, -f to follow a growing file
# @category: Bash compat
# @alias: tail
# @args: [-n N] [-f] [FILE...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperTail {
  $opts = Read-NixlperLineCountArgs -Command 'tail' -Arguments $args -AllowFollow $true
  if ($opts.Error) { Write-NixlperStdErr $opts.Error; return }
  if ($opts.Paths.Count -eq 0) {
    if (-not $MyInvocation.ExpectingInput) {
      Write-NixlperStdErr 'tail: no FILE given (pass a file, or pipe into tail)'
    } elseif ($opts.FromStart) {
      $input | Select-Object -Skip ([Math]::Max($opts.Count - 1, 0))
    } else {
      $input | Select-Object -Last $opts.Count
    }
    return
  }
  $files = @(foreach ($p in $opts.Paths) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) { Write-NixlperStdErr "tail: cannot open '$p' for reading: No such file or directory" }
    $items
  })
  if ($opts.Follow) {
    if ($files.Count -ne 1) { Write-NixlperStdErr 'tail: -f follows exactly one file'; return }
    Get-Content -LiteralPath $files[0].FullName -Tail $opts.Count -Wait
    return
  }
  for ($k = 0; $k -lt $files.Count; $k++) {
    if ($files.Count -gt 1) {
      if ($k -gt 0) { '' }
      "==> $($files[$k].Name) <=="
    }
    if ($opts.FromStart) {
      Get-Content -LiteralPath $files[$k].FullName | Select-Object -Skip ([Math]::Max($opts.Count - 1, 0))
    } else {
      Get-Content -LiteralPath $files[$k].FullName -Tail $opts.Count
    }
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: wc for PowerShell: count lines/words/bytes (-l -w -c); `ls | wc -l` counts items
# @category: Bash compat
# @alias: wc
# @args: [-l] [-w] [-c] [FILE...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperWc {
  $show = @{ l = $false; w = $false; c = $false }
  $paths = New-Object System.Collections.Generic.List[string]
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -cmatch '^-[lwcm]+$') {
      foreach ($ch in $a.Substring(1).ToCharArray()) { if ($ch -eq 'm') { $show.c = $true } else { $show[[string]$ch] = $true } }
    } elseif ($a.StartsWith('-') -and $a.Length -gt 1) {
      Write-NixlperStdErr "wc: invalid option '$a'"
      return
    } else { $paths.Add($a) }
  }
  if (-not ($show.l -or $show.w -or $show.c)) { $show.l = $true; $show.w = $true; $show.c = $true }

  $format = {
    param($counts, $name)
    $cols = @()
    if ($show.l) { $cols += '{0,7}' -f $counts.Lines }
    if ($show.w) { $cols += '{0,7}' -f $counts.Words }
    if ($show.c) { $cols += '{0,7}' -f $counts.Bytes }
    (($cols -join ' ') + ' ' + $name).TrimEnd()
  }
  $measure = {
    param([string[]]$lines)
    $words = 0
    $bytes = 0
    foreach ($line in $lines) {
      $words += @($line -split '\s+' | Where-Object { $_ }).Count
      $bytes += [System.Text.Encoding]::UTF8.GetByteCount($line) + 1
    }
    @{ Lines = $lines.Count; Words = $words; Bytes = $bytes }
  }

  if ($paths.Count -eq 0) {
    if (-not $MyInvocation.ExpectingInput) { Write-NixlperStdErr 'wc: no FILE given (pass a file, or pipe into wc)'; return }
    # Strings are counted as text; any other object (files from ls, processes...) counts as one line each, which is
    # what a bash user means by `ls | wc -l`.
    $items = @($input)
    $lines = @(foreach ($item in $items) { "$item" })
    $counts = & $measure $lines
    # Like GNU wc reading stdin: a single count is printed bare (`ls | wc -l` -> 2), several are padded columns.
    (& $format $counts '').Trim()
    return
  }

  $total = @{ Lines = 0; Words = 0; Bytes = 0 }
  $shown = 0
  foreach ($p in $paths) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) { Write-NixlperStdErr "wc: ${p}: No such file or directory"; continue }
    foreach ($item in $items) {
      if ($item.PSIsContainer) { Write-NixlperStdErr "wc: $($item.Name): Is a directory"; continue }
      $counts = & $measure @([System.IO.File]::ReadAllLines($item.FullName))
      $counts.Bytes = $item.Length
      & $format $counts $item.Name
      $total.Lines += $counts.Lines; $total.Words += $counts.Words; $total.Bytes += $counts.Bytes
      $shown++
    }
  }
  if ($shown -gt 1) { & $format $total 'total' }
}

#***********************************************************************************************************************
# touch / which / export
#***********************************************************************************************************************

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: touch for PowerShell: create empty files or update their modification time (-c: do not create)
# @category: Bash compat
# @alias: touch
# @args: [-c] FILE...
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperTouch {
  $noCreate = $false
  $paths = New-Object System.Collections.Generic.List[string]
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '-c' -or $a -eq '--no-create') { $noCreate = $true }
    elseif ($a.StartsWith('-') -and $a.Length -gt 1) { Write-NixlperStdErr "touch: invalid option '$a'"; return }
    else { $paths.Add($a) }
  }
  if ($paths.Count -eq 0) { Write-NixlperStdErr 'touch: missing file operand'; return }
  foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p) {
      (Get-Item -LiteralPath $p -Force).LastWriteTime = Get-Date
    } elseif (-not $noCreate) {
      try {
        New-Item -ItemType File -Path $p -ErrorAction Stop | Out-Null
      } catch {
        Write-NixlperStdErr "touch: cannot touch '$p': No such file or directory"
      }
    }
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: which for PowerShell: show where a command comes from (-a: all matches)
# @category: Bash compat
# @alias: which
# @args: [-a] COMMAND...
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperWhich {
  $all = $false
  $names = New-Object System.Collections.Generic.List[string]
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '-a') { $all = $true } else { $names.Add($a) }
  }
  $global:LASTEXITCODE = 0
  foreach ($name in $names) {
    $found = @(Get-Command -Name $name -All -ErrorAction SilentlyContinue)
    if ($found.Count -eq 0) {
      Write-NixlperStdErr "which: no $name in (`$env:PATH, aliases, functions, cmdlets)"
      $global:LASTEXITCODE = 1
      continue
    }
    if (-not $all) { $found = @($found[0]) }
    foreach ($cmd in $found) {
      switch ([string]$cmd.CommandType) {
        'Application' { $cmd.Source }
        'Alias'       { "${name}: aliased to $($cmd.Definition)" }
        'Function'    { "${name}: PowerShell function" }
        'Cmdlet'      { "${name}: PowerShell cmdlet ($($cmd.Source))" }
        default       { "${name}: $($cmd.CommandType)" }
      }
    }
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: export for PowerShell: set environment variables (NAME=VALUE), list them with no argument
# @category: Bash compat
# @alias: export
# @args: [-n] [NAME=VALUE...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperExport {
  $unset = $false
  $assignments = New-Object System.Collections.Generic.List[string]
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '-n') { $unset = $true }
    elseif ($a -eq '-p') { }
    else { $assignments.Add($a) }
  }
  if ($assignments.Count -eq 0) {
    Get-ChildItem -Path Env: | Sort-Object Name | ForEach-Object { 'declare -x {0}="{1}"' -f $_.Name, $_.Value }
    return
  }
  foreach ($assignment in $assignments) {
    $parts = $assignment -split '=', 2
    $name = $parts[0]
    if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
      Write-NixlperStdErr "export: '$assignment': not a valid identifier"
      continue
    }
    if ($unset) {
      [Environment]::SetEnvironmentVariable($name, $null)
    } elseif ($parts.Count -eq 2) {
      [Environment]::SetEnvironmentVariable($name, $parts[1])
    }
  }
}

#***********************************************************************************************************************
# ls / rm / cp / mv - these shadow built-in PowerShell aliases, so PowerShell-style calls are passed through.
#***********************************************************************************************************************

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: ls for PowerShell (-a -l -R -t -S -r -1 -d); PowerShell parameters still work (ls -Recurse)
# @category: Bash compat
# @alias: ls
# @args: [-alRtSr1d] [PATH...]
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperLs {
  if (-not (Test-NixlperBashFlags -Arguments $args -Allowed 'aAlRtSr1dh')) {
    if ($MyInvocation.ExpectingInput) { $input | Microsoft.PowerShell.Management\Get-ChildItem @args }
    else { Microsoft.PowerShell.Management\Get-ChildItem @args }
    return
  }
  $flags = ''
  $paths = New-Object System.Collections.Generic.List[string]
  if ($MyInvocation.ExpectingInput) { foreach ($piped in (ConvertTo-NixlperPathList @($input))) { $paths.Add($piped) } }
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '--') { continue }
    if ($a.StartsWith('-') -and $a.Length -gt 1) { $flags += $a.Substring(1) } else { $paths.Add($a) }
  }
  if ($paths.Count -eq 0) { $paths.Add('.') }
  $force = $flags.Contains('a') -or $flags.Contains('A')

  $items = foreach ($p in $paths) {
    $resolved = Resolve-NixlperPath -Path $p
    if ($resolved.Count -eq 0) {
      Write-NixlperStdErr "ls: cannot access '$p': No such file or directory"
      continue
    }
    foreach ($item in $resolved) {
      if ($flags.Contains('d') -or -not $item.PSIsContainer) { $item }
      else { Microsoft.PowerShell.Management\Get-ChildItem -LiteralPath $item.FullName -Force:$force -Recurse:($flags.Contains('R')) }
    }
  }
  $items = @($items)
  if ($flags.Contains('t')) { $items = @($items | Sort-Object LastWriteTime -Descending) }
  elseif ($flags.Contains('S')) { $items = @($items | Sort-Object { if ($_.PSIsContainer) { -1 } else { $_.Length } } -Descending) }
  if ($flags.Contains('r')) { [array]::Reverse($items) }
  if ($flags.Contains('1')) { $items | ForEach-Object { $_.Name } } else { $items }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: rm for PowerShell (-r -f -i -v); PowerShell parameters still work (rm -Recurse)
# @category: Bash compat
# @alias: rm
# @args: [-rfiv] PATH...
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperRm {
  if (-not (Test-NixlperBashFlags -Arguments $args -Allowed 'rRfiv')) {
    if ($MyInvocation.ExpectingInput) { $input | Microsoft.PowerShell.Management\Remove-Item @args }
    else { Microsoft.PowerShell.Management\Remove-Item @args }
    return
  }
  $flags = ''
  $paths = New-Object System.Collections.Generic.List[string]
  if ($MyInvocation.ExpectingInput) { foreach ($piped in (ConvertTo-NixlperPathList @($input))) { $paths.Add($piped) } }
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '--') { continue }
    if ($a.StartsWith('-') -and $a.Length -gt 1) { $flags += $a.Substring(1) } else { $paths.Add($a) }
  }
  $recurse = $flags.Contains('r') -or $flags.Contains('R')
  $force = $flags.Contains('f')
  if ($paths.Count -eq 0) {
    if (-not $force) { Write-NixlperStdErr 'rm: missing operand' }
    return
  }
  foreach ($p in $paths) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) {
      if (-not $force) { Write-NixlperStdErr "rm: cannot remove '$p': No such file or directory" }
      continue
    }
    foreach ($item in $items) {
      if ($item.PSIsContainer -and -not $recurse) {
        Write-NixlperStdErr "rm: cannot remove '$p': Is a directory"
        continue
      }
      if ($flags.Contains('i')) {
        $answer = Read-Host "rm: remove '$($item.Name)'? (y/n)"
        if ($answer -notmatch '^[yY]') { continue }
      }
      Microsoft.PowerShell.Management\Remove-Item -LiteralPath $item.FullName -Recurse:$recurse -Force -Confirm:$false
      if ($flags.Contains('v')) { "removed '$($item.Name)'" }
    }
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# Invoke-NixlperCopyOrMove: shared implementation of cp/mv (bash argument order: SOURCE... DEST).
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperCopyOrMove {
  param([string]$Command, [string]$Flags, [string[]]$Paths)
  $recurse = ($Command -eq 'mv') -or $Flags.Contains('r') -or $Flags.Contains('R') -or $Flags.Contains('a')
  if ($Paths.Count -lt 2) {
    Write-NixlperStdErr "${Command}: missing destination file operand"
    return
  }
  $destination = $Paths[$Paths.Count - 1]
  $sources = $Paths[0..($Paths.Count - 2)]
  $destIsDir = Test-Path -LiteralPath $destination -PathType Container
  # Expand every source first: several sources (or a wildcard matching several items) need a directory target,
  # otherwise each copy would silently overwrite the previous one.
  $resolved = New-Object System.Collections.Generic.List[object]
  foreach ($p in $sources) {
    $items = Resolve-NixlperPath -Path $p
    if ($items.Count -eq 0) {
      Write-NixlperStdErr "${Command}: cannot stat '$p': No such file or directory"
      continue
    }
    foreach ($item in $items) { $resolved.Add($item) }
  }
  if ($resolved.Count -gt 1 -and -not $destIsDir) {
    Write-NixlperStdErr "${Command}: target '$destination' is not a directory"
    return
  }
  foreach ($item in $resolved) {
    if ($item.PSIsContainer -and -not $recurse) {
      Write-NixlperStdErr "${Command}: -r not specified; omitting directory '$($item.Name)'"
      continue
    }
    $target = $destination
    if ($destIsDir) { $target = Join-Path -Path $destination -ChildPath $item.Name }
    if ($Flags.Contains('i') -and (Test-Path -LiteralPath $target)) {
      $answer = Read-Host "${Command}: overwrite '$target'? (y/n)"
      if ($answer -notmatch '^[yY]') { continue }
    }
    if ($Command -eq 'cp') {
      Microsoft.PowerShell.Management\Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse:$recurse -Force
    } else {
      Microsoft.PowerShell.Management\Move-Item -LiteralPath $item.FullName -Destination $destination -Force
    }
    if ($Flags.Contains('v')) { "'$($item.Name)' -> '$target'" }
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: cp for PowerShell (-r -f -i -v); PowerShell parameters still work (cp -Destination)
# @category: Bash compat
# @alias: cp
# @args: [-rfiv] SOURCE... DEST
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperCp {
  if (-not (Test-NixlperBashFlags -Arguments $args -Allowed 'rRafivp')) {
    if ($MyInvocation.ExpectingInput) { $input | Microsoft.PowerShell.Management\Copy-Item @args }
    else { Microsoft.PowerShell.Management\Copy-Item @args }
    return
  }
  $flags = ''
  $paths = New-Object System.Collections.Generic.List[string]
  if ($MyInvocation.ExpectingInput) { foreach ($piped in (ConvertTo-NixlperPathList @($input))) { $paths.Add($piped) } }
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '--') { continue }
    if ($a.StartsWith('-') -and $a.Length -gt 1) { $flags += $a.Substring(1) } else { $paths.Add($a) }
  }
  Invoke-NixlperCopyOrMove -Command 'cp' -Flags $flags -Paths $paths.ToArray()
}

#-----------------------------------------------------------------------------------------------------------------------
# @cmd-palette
# @description: mv for PowerShell (-f -i -v); PowerShell parameters still work (mv -Destination)
# @category: Bash compat
# @alias: mv
# @args: [-fiv] SOURCE... DEST
#-----------------------------------------------------------------------------------------------------------------------
function Invoke-NixlperMv {
  if (-not (Test-NixlperBashFlags -Arguments $args -Allowed 'fiv')) {
    if ($MyInvocation.ExpectingInput) { $input | Microsoft.PowerShell.Management\Move-Item @args }
    else { Microsoft.PowerShell.Management\Move-Item @args }
    return
  }
  $flags = ''
  $paths = New-Object System.Collections.Generic.List[string]
  if ($MyInvocation.ExpectingInput) { foreach ($piped in (ConvertTo-NixlperPathList @($input))) { $paths.Add($piped) } }
  foreach ($arg in $args) {
    $a = [string]$arg
    if ($a -eq '--') { continue }
    if ($a.StartsWith('-') -and $a.Length -gt 1) { $flags += $a.Substring(1) } else { $paths.Add($a) }
  }
  Invoke-NixlperCopyOrMove -Command 'mv' -Flags $flags -Paths $paths.ToArray()
}
