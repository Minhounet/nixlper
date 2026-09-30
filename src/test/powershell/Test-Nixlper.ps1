########################################################################################################################
# FILE: Test-Nixlper.ps1
# DESCRIPTION: Offline unit tests for the PowerShell port (src/main/powershell/Nixlper).
#
# Pure PowerShell, no Pester — same spirit as the bash suites in src/test/bash. Interactive prompts are answered by
# replacing Read-Host inside the module scope with a queue of scripted answers, and fzf is forced off.
# Run locally with:  pwsh -NoProfile -File src/test/powershell/Test-Nixlper.ps1
########################################################################################################################
$ErrorActionPreference = 'Stop'
Set-StrictMode -Off

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$manifest = Join-Path $repoRoot 'src/main/powershell/Nixlper/Nixlper.psd1'
$work = Join-Path ([System.IO.Path]::GetTempPath()) ("nixlper-ps-test-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$originalLocation = Get-Location

$env:NIXLPER_BASH_COMPAT = 'true'
$env:NIXLPER_BOOKMARKS_FILE = Join-Path $work 'bookmarks'
$env:NIXLPER_BOOKMARKS_FUZZY = 'false'

#-----------------------------------------------------------------------------------------------------------------------
# Tiny assertion helpers
#-----------------------------------------------------------------------------------------------------------------------
$script:Pass = 0
$script:Fail = 0

function Expect-Eq {
  param([string]$Name, $Got, $Want)
  $g = (@($Got) | ForEach-Object { "$_" }) -join "`n"
  $w = (@($Want) | ForEach-Object { "$_" }) -join "`n"
  if ($g -ceq $w) {
    Write-Host "  ✅ $Name"
    $script:Pass++
  } else {
    Write-Host "  ❌ ${Name}: got [$g] want [$w]"
    $script:Fail++
  }
}

function Expect-True {
  param([string]$Name, [bool]$Condition)
  Expect-Eq $Name $Condition $true
}

# Queue answers for Read-Host calls made inside the module.
function Set-Answers {
  $global:NixlperTestAnswers = New-Object System.Collections.Generic.Queue[string]
  foreach ($a in $args) { $global:NixlperTestAnswers.Enqueue([string]$a) }
}

# Run a command, swallowing stderr lines written through $Host.UI.WriteErrorLine and Write-Host noise.
function Quiet {
  param([scriptblock]$Block)
  & $Block 6>$null 2>$null
}

function Write-File {
  param([string]$Path, [string[]]$Lines)
  [System.IO.File]::WriteAllText($Path, (($Lines -join "`n") + "`n"))
}

Import-Module $manifest -Force
$module = Get-Module Nixlper
& $module {
  function script:Read-Host {
    param([string]$Prompt)
    if ($global:NixlperTestAnswers.Count -eq 0) { return '' }
    return $global:NixlperTestAnswers.Dequeue()
  }
  function script:Test-NixlperFzf { return $false }
}

try {
  Set-Location $work
  Write-File (Join-Path $work 'a.txt') @('alpha', 'Beta', 'gamma 42', 'f(x) = a.c', 'abc', 'foo|bar')
  Write-File (Join-Path $work 'b.txt') @('beta', 'delta')
  New-Item -ItemType Directory -Path (Join-Path $work 'src/sub') | Out-Null
  Write-File (Join-Path $work 'src/one.java') @('class One {}', 'TODO java')
  Write-File (Join-Path $work 'src/sub/two.txt') @('TODO txt')

  #=====================================================================================================================
  Write-Host '== compat registration =='
  Expect-Eq 'grep alias points at Invoke-NixlperGrep' (Get-Alias -Name grep).Definition 'Invoke-NixlperGrep'
  Expect-Eq 'ls alias points at Invoke-NixlperLs' (Get-Alias -Name ls).Definition 'Invoke-NixlperLs'
  Expect-Eq 'palette alias fa' (Get-Alias -Name fa).Definition 'Find-NixlperAction'

  #=====================================================================================================================
  Write-Host '== regex translation =='
  $toRegex = { param($p, $e) & $module { param($p, $e) ConvertTo-NixlperRegex -Pattern $p -Extended $e } $p $e }
  Expect-Eq 'BRE \| is alternation' (& $toRegex 'foo\|bar' $false) 'foo|bar'
  Expect-Eq 'BRE bare parens are literal' (& $toRegex 'f(x)' $false) 'f\(x\)'
  Expect-Eq 'ERE parens are groups' (& $toRegex '(a|b)+' $true) '(a|b)+'
  Expect-Eq 'POSIX class converted' (& $toRegex '[[:digit:]]+' $true) '[0-9]+'
  Expect-Eq 'backslash literal inside brackets' (& $toRegex '[\n]' $true) '[\\n]'
  Expect-Eq 'GNU word anchors' (& $toRegex '\<abc\>' $false) '\babc\b'

  #=====================================================================================================================
  Write-Host '== grep =='
  Expect-Eq 'basic match is case-sensitive' (grep beta a.txt) @()
  Expect-Eq '-i ignores case' (grep -i beta a.txt) 'Beta'
  Expect-Eq '-v inverts' (grep -v a b.txt) @()
  Expect-Eq '-n adds line numbers' (grep -n gamma a.txt) '3:gamma 42'
  Expect-Eq '-c counts' (grep -c a b.txt) '2'
  Expect-Eq 'multiple files are prefixed' (grep -i beta a.txt b.txt) @('a.txt:Beta', 'b.txt:beta')
  Expect-Eq '-h hides file names' (grep -ih beta a.txt b.txt) @('Beta', 'beta')
  Expect-Eq '-l lists files' (grep -l beta a.txt b.txt) 'b.txt'
  Expect-Eq '-o prints only the match' (grep -o '[0-9][0-9]*' a.txt) '42'
  Expect-Eq '-w whole words only' (grep -w a a.txt) 'f(x) = a.c'
  Expect-Eq '-x whole line only' (grep -x abc a.txt) 'abc'
  Expect-Eq '-F literal dot' (grep -F 'a.c' a.txt) 'f(x) = a.c'
  Expect-Eq 'BRE literal parens' (grep 'f(x)' a.txt) 'f(x) = a.c'
  Expect-Eq 'BRE \| alternation' (grep 'alpha\|delta' a.txt b.txt) @('a.txt:alpha', 'b.txt:delta')
  Expect-Eq '-E alternation' (grep -E 'alpha|abc' a.txt) @('alpha', 'abc')
  Expect-Eq 'BRE bare | is literal' (grep 'foo|bar' a.txt) 'foo|bar'
  Expect-Eq 'POSIX class' (grep '[[:digit:]]' a.txt) 'gamma 42'
  Expect-Eq 'several -e patterns' (grep -e alpha -e abc a.txt) @('alpha', 'abc')
  Expect-Eq 'clustered -ie pattern' (grep -ie BETA a.txt) 'Beta'
  # PowerShell swallows a bare `--` before the function sees it, so -e is the way to grep for a dash pattern.
  Expect-Eq '-e allows a pattern starting with a dash' (Write-Output '-x' 'y' | grep -e -x) '-x'
  Expect-Eq 'wildcard file names' (grep -l -i beta *.txt) @('a.txt', 'b.txt')
  $sep = [System.IO.Path]::DirectorySeparatorChar
  Expect-Eq '-r shows paths relative to the given dir' (grep -r TODO src | Sort-Object) `
    @("src${sep}one.java:TODO java", "src${sep}sub${sep}two.txt:TODO txt")
  Expect-Eq '-r without path searches .' (grep -rl 'TODO txt') "src${sep}sub${sep}two.txt"
  Expect-Eq '--include filters recursive files' (grep -r TODO --include=*.java src) "src${sep}one.java:TODO java"
  Expect-Eq 'pipeline strings' ('one', 'two', 'three' | grep t) @('two', 'three')
  Expect-True 'pipeline objects are rendered to text' ([bool](Get-Item a.txt | grep 'a\.txt'))
  grep -q alpha a.txt | Out-Null
  Expect-Eq 'exit code 0 on match' $LASTEXITCODE 0
  Expect-Eq '-q prints nothing' (grep -q alpha a.txt) @()
  grep zzz a.txt | Out-Null
  Expect-Eq 'exit code 1 without match' $LASTEXITCODE 1
  Quiet { grep alpha missing.txt } | Out-Null
  Expect-Eq 'exit code 2 on missing file' $LASTEXITCODE 2
  Expect-Eq 'directory without -r is skipped' (Quiet { grep TODO src }) @()
  Expect-Eq 'unknown option is refused' (Quiet { grep -Z x a.txt }) @()
  [System.IO.File]::WriteAllBytes((Join-Path $work 'bin.dat'), [byte[]](0x61, 0x00, 0x62, 0x0A))
  Expect-Eq 'binary files are summarised' (grep a bin.dat) 'Binary file bin.dat matches'
  Remove-Item bin.dat

  #=====================================================================================================================
  Write-Host '== head / tail =='
  Expect-Eq 'head -n 2' (head -n 2 a.txt) @('alpha', 'Beta')
  Expect-Eq 'head -2' (head -2 a.txt) @('alpha', 'Beta')
  Expect-Eq 'head from pipeline' (1..5 | head -n 2) @('1', '2')
  Expect-Eq 'head headers for several files' (head -n 1 a.txt b.txt) @('==> a.txt <==', 'alpha', '', '==> b.txt <==', 'beta')
  Expect-Eq 'tail -n 2' (tail -n 2 a.txt) @('abc', 'foo|bar')
  Expect-Eq 'tail -1' (tail -1 b.txt) 'delta'
  Expect-Eq 'tail -n +5 starts at line 5' (tail -n +5 a.txt) @('abc', 'foo|bar')
  Expect-Eq 'tail from pipeline' (1..5 | tail -n 2) @('4', '5')
  Expect-Eq 'head -n +2 is refused' (Quiet { head -n +2 a.txt }) @()
  Expect-Eq 'tail -f with two files is refused' (Quiet { tail -f a.txt b.txt }) @()

  #=====================================================================================================================
  Write-Host '== wc =='
  Expect-Eq 'wc -l file' (wc -l b.txt) '      2 b.txt'
  Expect-Eq 'wc default columns' (wc b.txt) '      2       2      11 b.txt'
  Expect-Eq 'wc -l with total' (wc -l a.txt b.txt) @('      6 a.txt', '      2 b.txt', '      8 total')
  Expect-Eq 'ls | wc -l counts items' (ls a.txt b.txt | wc -l) '2'
  Expect-Eq 'wc -w from pipeline strings' ('a b', 'c' | wc -w) '3'

  #=====================================================================================================================
  Write-Host '== touch / which / export =='
  touch new.txt
  Expect-True 'touch creates a file' (Test-Path new.txt)
  (Get-Item new.txt).LastWriteTime = (Get-Date).AddDays(-3)
  touch new.txt
  Expect-True 'touch updates the timestamp' ((Get-Item new.txt).LastWriteTime -gt (Get-Date).AddMinutes(-1))
  touch -c absent.txt
  Expect-True 'touch -c does not create' (-not (Test-Path absent.txt))
  Expect-Eq 'which reports a cmdlet' (which Get-ChildItem) 'Get-ChildItem: PowerShell cmdlet (Microsoft.PowerShell.Management)'
  Expect-Eq 'which reports an alias' (which grep) 'grep: aliased to Invoke-NixlperGrep'
  Quiet { which definitely-not-a-command } | Out-Null
  Expect-Eq 'which exit code 1 when missing' $LASTEXITCODE 1
  export NIXLPER_TEST_VAR=hello
  Expect-Eq 'export sets an environment variable' $env:NIXLPER_TEST_VAR 'hello'
  export NIXLPER_TEST_VAR=a=b
  Expect-Eq 'export keeps = in the value' $env:NIXLPER_TEST_VAR 'a=b'
  export -n NIXLPER_TEST_VAR
  Expect-True 'export -n removes it' ([string]::IsNullOrEmpty($env:NIXLPER_TEST_VAR))
  Quiet { export '1BAD=x' }
  Expect-True 'export refuses invalid names' ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable('1BAD')))

  #=====================================================================================================================
  Write-Host '== ls =='
  Expect-Eq 'ls -1 prints names' (ls -1 a.txt b.txt) @('a.txt', 'b.txt')
  Expect-Eq 'ls -1 of a directory' (ls -1 src) @('sub', 'one.java')
  Expect-Eq 'ls -1r reverses' (ls -1r src) @('one.java', 'sub')
  Expect-Eq 'ls -1d lists the directory itself' (ls -1d src) 'src'
  (Get-Item b.txt).LastWriteTime = (Get-Date).AddDays(1)
  Expect-Eq 'ls -1t sorts newest first' (ls -1t a.txt b.txt) @('b.txt', 'a.txt')
  Write-File (Join-Path $work 'src/.hidden') @('x')
  if ($IsWindows) { (Get-Item -Force src/.hidden).Attributes = 'Hidden' }
  Expect-True 'ls hides dotfiles without -a' (-not ((ls -1 src) -contains '.hidden'))
  Expect-True 'ls -a shows them' ((ls -1a src) -contains '.hidden')
  Expect-Eq 'PowerShell parameters pass through (ls -Name)' (ls -Name -Path src/sub) 'two.txt'
  Expect-Eq 'ls -la returns objects' ((ls -la src/sub) | ForEach-Object { $_.GetType().Name }) 'FileInfo'

  #=====================================================================================================================
  Write-Host '== rm / cp / mv =='
  touch del.txt
  rm del.txt
  Expect-True 'rm removes a file' (-not (Test-Path del.txt))
  New-Item -ItemType Directory -Path d1/inner | Out-Null
  Quiet { rm d1 }
  Expect-True 'rm without -r keeps a directory' (Test-Path d1)
  rm -rf d1
  Expect-True 'rm -rf removes a directory tree' (-not (Test-Path d1))
  touch p1.tmp p2.tmp
  Get-ChildItem *.tmp | rm
  Expect-True 'pipeline input is removed (Get-ChildItem | rm)' (-not (Test-Path p1.tmp) -and -not (Test-Path p2.tmp))
  touch p3.tmp
  Get-ChildItem p3.tmp | rm -Force
  Expect-True 'pipeline input with PowerShell parameters' (-not (Test-Path p3.tmp))
  Expect-Eq 'rm -f is silent on a missing file' (rm -f missing.txt) @()
  touch keep.txt
  Set-Answers 'n'
  rm -i keep.txt
  Expect-True 'rm -i answered n keeps the file' (Test-Path keep.txt)
  Set-Answers 'y'
  rm -iv keep.txt | Out-Null
  Expect-True 'rm -i answered y removes it' (-not (Test-Path keep.txt))
  New-Item -ItemType Directory -Path d2/inner | Out-Null
  rm -Recurse -Force d2
  Expect-True 'PowerShell parameters pass through (rm -Recurse -Force)' (-not (Test-Path d2))

  cp a.txt copy.txt
  Expect-Eq 'cp copies a file' (Get-Content copy.txt -TotalCount 1) 'alpha'
  Quiet { cp a.txt b.txt notadir }
  Expect-True 'cp with several sources needs a directory' (-not (Test-Path notadir))
  Quiet { cp src srccopy }
  Expect-True 'cp without -r omits directories' (-not (Test-Path srccopy))
  cp -r src srccopy
  Expect-True 'cp -r copies a tree' (Test-Path (Join-Path 'srccopy' 'sub/two.txt'))
  New-Item -ItemType Directory -Path dest | Out-Null
  cp a.txt b.txt dest
  Expect-True 'cp several files into a directory' ((Test-Path dest/a.txt) -and (Test-Path dest/b.txt))
  Write-File (Join-Path $work 'dest/a.txt') @('old')
  Set-Answers 'n'
  cp -i a.txt dest
  Expect-Eq 'cp -i answered n does not overwrite' (Get-Content dest/a.txt) 'old'
  Expect-Eq 'cp -v reports the copy' (cp -v a.txt dest) "'a.txt' -> '$(Join-Path 'dest' 'a.txt')'"

  mv copy.txt moved.txt
  Expect-True 'mv renames' ((Test-Path moved.txt) -and -not (Test-Path copy.txt))
  mv moved.txt dest
  Expect-True 'mv into a directory' (Test-Path dest/moved.txt)

  #=====================================================================================================================
  Write-Host '== bookmarks =='
  $project = Join-Path $work 'my project'
  New-Item -ItemType Directory -Path $project | Out-Null
  Set-Location $project
  Set-Answers '' 'proj'
  Quiet { bm }
  $line = (Get-Content $env:NIXLPER_BOOKMARKS_FILE)
  Expect-Eq 'bookmark line uses the bash format' $line "alias proj='cd $project && echo `"INFO: Jump into folder $project`"'"
  Expect-True 'a jump function is defined' ([bool](Get-Command proj -CommandType Function -ErrorAction SilentlyContinue))
  Set-Location $work
  Quiet { proj }
  Expect-Eq 'typing the bookmark name jumps there' (Get-Location).ProviderPath $project

  Set-Location $work
  Set-Answers '' 'proj' ''
  Quiet { bm }
  Expect-Eq 'a duplicate name is refused' @(Get-Content $env:NIXLPER_BOOKMARKS_FILE).Count 1
  Set-Answers '' 'Get-ChildItem' 'ls' 'work_dir'
  Quiet { bm }
  Expect-Eq 'names that are commands are refused' (@(Get-Content $env:NIXLPER_BOOKMARKS_FILE) | ForEach-Object { ($_ -split '=')[0] }) @('alias proj', 'alias work_dir')

  Set-Location $work
  Set-Answers '1'
  Quiet { bd }
  Expect-Eq 'bd jumps to the chosen bookmark' (Get-Location).ProviderPath $project
  Set-Answers ''
  Quiet { bd }
  Expect-Eq 'bd cancelled stays in place' (Get-Location).ProviderPath $project

  if (Get-Command bash -CommandType Application -ErrorAction SilentlyContinue) {
    # The file must stay readable by the bash version (shared bookmarks).
    $env:NIXLPER_TEST_REPO = $repoRoot
    $bashView = & bash -c 'source "$NIXLPER_TEST_REPO/src/main/bash/functions_logging.sh"; source "$NIXLPER_TEST_REPO/src/main/bash/functions_bookmarks.sh"; _i_bookmarks_valid_entries'
    Expect-Eq 'bash parses the PowerShell-written file' $bashView @("proj`t$project", "work_dir`t$work")
  }

  Set-Location $project
  Set-Answers 'y'
  Quiet { bm }
  Expect-Eq 'bm on a bookmarked folder deletes it' (@(Get-Content $env:NIXLPER_BOOKMARKS_FILE) | ForEach-Object { ($_ -split '=')[0] }) 'alias work_dir'
  Expect-True 'its jump function is removed' (-not (Get-Command proj -ErrorAction SilentlyContinue))

  # A folder name containing PowerShell code must never be evaluated by the generated jump function.
  $evil = Join-Path $work 'x$(Set-Content -Path injected -Value 1)y'
  New-Item -ItemType Directory -Path $evil | Out-Null
  Add-Content -Path $env:NIXLPER_BOOKMARKS_FILE -Value "alias evil='cd $evil && echo x'"
  & $module { Register-NixlperBookmarkFunction }
  Set-Location $work
  Quiet { evil }
  Expect-Eq 'jump function treats the path literally' (Get-Location).ProviderPath $evil
  Expect-True 'no code from the folder name ran' (-not (Test-Path (Join-Path $work 'injected')) -and -not (Test-Path (Join-Path $evil 'injected')))
  Set-Location $work

  Add-Content -Path $env:NIXLPER_BOOKMARKS_FILE -Value "alias ls='cd $work && echo x'"
  & $module { Register-NixlperBookmarkFunction }
  Expect-Eq 'a bookmark never shadows an existing command' (Get-Command ls).CommandType 'Alias'

  #=====================================================================================================================
  Write-Host '== command palette =='
  $registry = @(& $module { Get-NixlperCommandRegistry })
  $names = @($registry | ForEach-Object { $_.Name })
  Expect-True 'registry lists fa, bd and bm' (($names -contains 'fa') -and ($names -contains 'bd') -and ($names -contains 'bm'))
  Expect-True 'registry lists active compat commands' (($names -contains 'grep') -and ($names -contains 'mv'))
  $bd = $registry | Where-Object { $_.Name -eq 'bd' }
  Expect-Eq 'bd keybind is parsed' $bd.Keybind 'CTRL+X+D'
  Expect-Eq 'bd is interactive' $bd.Interactive $true
  $grepEntry = $registry | Where-Object { $_.Name -eq 'grep' }
  Expect-Eq 'grep args are parsed' $grepEntry.Args '[OPTIONS] PATTERN [FILE...]'
  Expect-Eq 'display line shows name, keybind and category' (& $module { param($c) Format-NixlperCommand $c } $bd).Substring(0, 34) 'bd       [CTRL+X+D]     (Bookmarks'

  Set-Location $work
  $sorted = @($registry | Sort-Object Category, Name)
  $touchIndex = [array]::IndexOf(@($sorted | ForEach-Object { $_.Name }), 'touch') + 1
  Set-Answers "$touchIndex" 'from-palette.txt'
  Quiet { fa }
  Expect-True 'palette asks for arguments and runs the command' (Test-Path from-palette.txt)
  $before = @(Get-ChildItem -Force).Count
  Set-Answers "$touchIndex" ''
  Quiet { fa }
  Expect-Eq 'palette without arguments cancels' @(Get-ChildItem -Force).Count $before

  & $module { $script:NixlperCompatActive.Remove('grep') } | Out-Null
  Expect-True 'inactive compat commands are hidden' (-not (@(& $module { Get-NixlperCommandRegistry } | ForEach-Object { $_.Name }) -contains 'grep'))
  & $module { $script:NixlperCompatActive.Add('grep') }

  #=====================================================================================================================
  Write-Host '== keybindings =='
  Import-Module PSReadLine -ErrorAction SilentlyContinue
  if (Get-Module PSReadLine) {
    $bound = $true
    try { & $module { Register-NixlperKeybinding } } catch { $bound = $false }
    if ($bound) {
      $handlers = @(Get-PSReadLineKeyHandler -Bound | Where-Object { $_.Function -like 'nixlper:*' } | ForEach-Object { $_.Key })
      Expect-True 'CTRL+X chords are bound' ($handlers.Count -eq 3)
    } else {
      Write-Host '  ⚠️  PSReadLine cannot bind keys in this non-interactive host, skipped'
    }
  }

  #=====================================================================================================================
  Write-Host '== unload =='
  Set-Location $work
  Remove-Module Nixlper
  Expect-True 'Remove-Module removes the compat aliases' (-not (Get-Alias -Name grep -ErrorAction SilentlyContinue))
  Expect-True 'Remove-Module removes bookmark functions' (-not (Get-Command work_dir -ErrorAction SilentlyContinue))

  $env:NIXLPER_BASH_COMPAT = 'false'
  Import-Module $manifest -Force
  Expect-True 'NIXLPER_BASH_COMPAT=false leaves grep alone' (-not (Get-Alias -Name grep -ErrorAction SilentlyContinue))
  Remove-Module Nixlper
} finally {
  Set-Location $originalLocation
  Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host "Passed: $script:Pass  Failed: $script:Fail"
if ($script:Fail -gt 0) { exit 1 }
exit 0
