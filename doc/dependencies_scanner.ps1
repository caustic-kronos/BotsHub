<#
.SYNOPSIS
    AutoIt (.au3) dependency analyser.

.DESCRIPTION
    Pass 1 – collects every Global/Global Const variable and every Func
             definition across all .au3 files in the target folder tree.
    Pass 2 – scans every file for usages of those known names and flags
             cross-file references as dependencies.

.PARAMETER Path
    Root folder to scan (recurses into sub-folders).

.PARAMETER OutputFile
    Optional. Write the results report to this file (UTF-8).
    Progress logs are always written to the console only.

.PARAMETER Relative
    Show file paths relative to -Path instead of just the filename.
    Useful when the same filename exists in multiple sub-folders.

.EXAMPLE
    .\Get-Au3Dependencies.ps1 -Path "C:\MyProject"
    .\Get-Au3Dependencies.ps1 -Path "C:\MyProject" -OutputFile "deps.txt" -Relative
#>
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [string]$OutputFile = '',

    [switch]$Relative
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── helpers ──────────────────────────────────────────────────────────────────

# Log  → console only, never written to the output file
function Log([string]$msg, [string]$color = 'DarkGray') {
    $ts = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$ts] $msg" -ForegroundColor $color
}

# Out → buffered; written to file + console at the end
$resultLines = [System.Collections.Generic.List[string]]::new()

function Out([string]$line = '', [string]$color = 'White') {
    $resultLines.Add($line)
    Write-Host $line -ForegroundColor $color
}

function Label([string]$full) {
    if ($Relative) { return [System.IO.Path]::GetRelativePath($Path, $full) }
    return [System.IO.Path]::GetFileName($full)
}

# ─── discover files ───────────────────────────────────────────────────────────

Log "Scanning for .au3 files in: $Path" 'Cyan'
$files = @(Get-ChildItem -Path $Path -Filter '*.au3' -Recurse -File)
Log "$($files.Count) file(s) found." 'Cyan'

if ($files.Count -eq 0) {
    Log 'Nothing to do.' 'Yellow'
    exit
}

# ─── Pass 1 : collect definitions ─────────────────────────────────────────────

Log ''
Log '── Pass 1: collecting definitions ──────────────────────────────' 'Yellow'

# name -> defining file  (first definition wins for cross-file lookup)
$funcDefs = [System.Collections.Generic.Dictionary[string,string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
$varDefs  = [System.Collections.Generic.Dictionary[string,string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)

# file -> list of names defined in that file
$fileFuncs = @{}
$fileVars  = @{}

$reFuncDef   = [regex]'(?i)^\s*Func\s+(\w+)\s*\('
$reGlobalVar = [regex]'(?i)^\s*Global\s+(?:Const\s+)?(?:Enum\s+)?(?:Step\s+\S+\s+)?\$(\w+)'

$p1i = 0
foreach ($file in $files) {
    $p1i++
    $fn = $file.FullName
    Log "  [$p1i/$($files.Count)] $(Label $fn)"

    $fileFuncs[$fn] = [System.Collections.Generic.List[string]]::new()
    $fileVars[$fn]  = [System.Collections.Generic.List[string]]::new()

    foreach ($line in [System.IO.File]::ReadLines($fn)) {
        $bare = ($line -split ';')[0]

        $m = $reFuncDef.Match($bare)
        if ($m.Success) {
            $name = $m.Groups[1].Value
            if (-not $funcDefs.ContainsKey($name)) { $funcDefs[$name] = $fn }
            if (-not $fileFuncs[$fn].Contains($name)) { $fileFuncs[$fn].Add($name) }
        }

        $m = $reGlobalVar.Match($bare)
        if ($m.Success) {
            $name = $m.Groups[1].Value
            if (-not $varDefs.ContainsKey($name)) { $varDefs[$name] = $fn }
            if (-not $fileVars[$fn].Contains($name)) { $fileVars[$fn].Add($name) }
        }
    }

    Log "       $($fileVars[$fn].Count) var(s), $($fileFuncs[$fn].Count) func(s) found"
}

Log ''
Log "Pass 1 done — $($varDefs.Count) unique global var(s), $($funcDefs.Count) unique func(s) across all files." 'Green'

if ($funcDefs.Count -eq 0 -and $varDefs.Count -eq 0) {
    Log 'No definitions found – check path or file contents.' 'Red'
    exit
}

# ─── Pass 2 : find cross-file usages ──────────────────────────────────────────

Log ''
Log '── Pass 2: resolving usages ─────────────────────────────────────' 'Yellow'

# Strategy: two global patterns per line, then O(1) hashtable lookup per match.
# This replaces the previous O(names × lines) iteration with O(matches × lines),
# where matches per line is typically 5–15, not 8000+.
#
#   $reAllVars  → finds every  $Word  token in the line
#   $reAllFuncs → finds every  Word(  token in the line
#
# Each hit is looked up in the definition dictionaries; unknown names are skipped.

$reAllVars  = [regex]'\$(\w+)'
$reAllFuncs = [regex]'(?i)\b(\w+)\s*\('

Log "  Using global-scan + hashtable strategy ($($varDefs.Count) vars, $($funcDefs.Count) funcs indexed)."

# deps[$file][$depFile] = @{ Vars=[List]; Funcs=[List] }
$deps = @{}
foreach ($file in $files) { $deps[$file.FullName] = @{} }

# Inline helper — records a dependency hit without duplicates
function RecordDep($depTable, $depFile, $kind, $name) {
    if (-not $depTable.ContainsKey($depFile)) {
        $depTable[$depFile] = @{
            Vars  = [System.Collections.Generic.List[string]]::new()
            Funcs = [System.Collections.Generic.List[string]]::new()
        }
    }
    if (-not $depTable[$depFile][$kind].Contains($name)) {
        $depTable[$depFile][$kind].Add($name)
    }
}

$reIsFuncDef   = [regex]'(?i)^\s*Func\s+'
$reIsGlobalDef = [regex]'(?i)^\s*Global\s+'

$p2i = 0
foreach ($file in $files) {
    $p2i++
    $fn = $file.FullName
    Log "  [$p2i/$($files.Count)] $(Label $fn)"

    foreach ($line in [System.IO.File]::ReadLines($fn)) {
        $bare = ($line -split ';')[0]
        if ([string]::IsNullOrWhiteSpace($bare)) { continue }

        $isFuncDef   = $reIsFuncDef.IsMatch($bare)
        $isGlobalDef = $reIsGlobalDef.IsMatch($bare)

        # ── variable usages: find all $Word tokens, look each up in varDefs
        if (-not $isGlobalDef) {
            foreach ($m in $reAllVars.Matches($bare)) {
                $vname = $m.Groups[1].Value
                if (-not $varDefs.ContainsKey($vname)) { continue }   # not a known global
                if ($fileVars[$fn].Contains($vname))   { continue }   # defined in this file – not a dep
                $defFile = $varDefs[$vname]
                RecordDep $deps[$fn] $defFile 'Vars' $vname
            }
        }

        # ── function call usages: find all Word( tokens, look each up in funcDefs
        if (-not $isFuncDef) {
            foreach ($m in $reAllFuncs.Matches($bare)) {
                $fname = $m.Groups[1].Value
                if (-not $funcDefs.ContainsKey($fname)) { continue }  # not a known func
                if ($fileFuncs[$fn].Contains($fname))   { continue }  # defined in this file – not a dep
                $defFile = $funcDefs[$fname]
                RecordDep $deps[$fn] $defFile 'Funcs' $fname
            }
        }
    }

    $depCount = $deps[$fn].Keys.Count
    Log "       $depCount dependency file(s) detected"
}

Log ''
Log 'Pass 2 done.' 'Green'

# ─── Output ───────────────────────────────────────────────────────────────────

Log ''
Log '── Writing results ──────────────────────────────────────────────' 'Yellow'

$divider = '─' * 72

Out ''
Out $divider

foreach ($file in $files | Sort-Object FullName) {
    $fn   = $file.FullName
    $lbl  = Label $fn

    $vars  = $fileVars[$fn]
    $funcs = $fileFuncs[$fn]
    $fdeps = $deps[$fn]

    Out "FILE  $lbl" 'Cyan'

    if ($vars.Count -gt 0) {
        Out "  vars  : $(($vars | ForEach-Object { "`$$_" }) -join ', ')"
    } else {
        Out "  vars  : (none)"
    }

    if ($funcs.Count -gt 0) {
        Out "  funcs : $($funcs -join ', ')"
    } else {
        Out "  funcs : (none)"
    }

    if ($fdeps.Count -gt 0) {
        Out "  deps  :"
        foreach ($depFile in $fdeps.Keys | Sort-Object) {
            $depLbl = Label $depFile
            $parts  = @()
            if ($fdeps[$depFile].Vars.Count -gt 0) {
                $vlist = ($fdeps[$depFile].Vars | Sort-Object | ForEach-Object { "`$$_" }) -join ', '
                $parts += "vars:$vlist"
            }
            if ($fdeps[$depFile].Funcs.Count -gt 0) {
                $flist = ($fdeps[$depFile].Funcs | Sort-Object) -join ', '
                $parts += "funcs:$flist"
            }
            Out "    → $depLbl  [$($parts -join '  |  ')]"
        }
    } else {
        Out "  deps  : (none)"
    }

    Out $divider
}

$summary = "Summary: $($files.Count) files  |  $($varDefs.Count) global vars  |  $($funcDefs.Count) functions"
Out ''
Out $summary 'DarkGray'
Out ''

# ─── Save to file ─────────────────────────────────────────────────────────────

if ($OutputFile -ne '') {
    $resolved = [System.IO.Path]::GetFullPath($OutputFile)
    $resultLines | Set-Content -Path $resolved -Encoding UTF8
    Log "Results written to: $resolved" 'Cyan'
}