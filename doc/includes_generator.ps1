<#
.SYNOPSIS
    Generates AutoIt #include statements from a Get-Au3Dependencies report.

.PARAMETER ReportFile
    Path to the .txt report produced by Get-Au3Dependencies.ps1.

.PARAMETER OutputFile
    Optional. Write the includes report to this file instead of (only) the console.

.EXAMPLE
    .\Get-Au3Includes.ps1 -ReportFile "deps.txt"
    .\Get-Au3Includes.ps1 -ReportFile "deps.txt" -OutputFile "includes.txt"
#>
param(
    [Parameter(Mandatory)]
    [string]$ReportFile,

    [string]$OutputFile = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── helpers ──────────────────────────────────────────────────────────────────

$resultLines = [System.Collections.Generic.List[string]]::new()

function Out([string]$line = '', [string]$color = 'White') {
    $resultLines.Add($line)
    Write-Host $line -ForegroundColor $color
}

# ─── parse report ─────────────────────────────────────────────────────────────

$lines      = [System.IO.File]::ReadAllLines($ReportFile)
$currentFile = $null
# file -> ordered list of dep filenames
$includes   = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[string]]]::new()

foreach ($line in $lines) {
    if ($line -match '^FILE\s+(.+)$') {
        $currentFile = $Matches[1].Trim()
        if (-not $includes.ContainsKey($currentFile)) {
            $includes[$currentFile] = [System.Collections.Generic.List[string]]::new()
        }
        continue
    }

    if ($currentFile -and $line -match '^\s+→\s+(.+?)\s+\[') {
        $dep = $Matches[1].Trim()
        if (-not $includes[$currentFile].Contains($dep)) {
            $includes[$currentFile].Add($dep)
        }
    }
}

if ($includes.Count -eq 0) {
    Write-Warning "No FILE entries found in report. Check -ReportFile path."
    exit
}

# ─── output ───────────────────────────────────────────────────────────────────

$divider = '─' * 72

Out ''
Out $divider

foreach ($file in $includes.Keys | Sort-Object) {
    Out "FILE  $file" 'Cyan'

    $deps = $includes[$file]
    if ($deps.Count -eq 0) {
        Out "  (no dependencies)"
    } else {
        foreach ($dep in $deps) {
            Out "  #include '$dep'"
        }
    }

    Out $divider
}

Out ''
Out "Summary: $($includes.Count) file(s) processed." 'DarkGray'
Out ''

# ─── save to file ─────────────────────────────────────────────────────────────

if ($OutputFile -ne '') {
    $resolved = [System.IO.Path]::GetFullPath($OutputFile)
    $resultLines | Set-Content -Path $resolved -Encoding UTF8
    Write-Host "Results written to: $resolved" -ForegroundColor Cyan
}
