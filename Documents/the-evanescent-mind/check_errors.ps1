<#
.SYNOPSIS
    Simulate-runs the project via Godot headless and reports all script errors.
.DESCRIPTION
    Launches Godot 4 in headless mode with --quit, captures all output,
    filters known false-positive cleanup messages, then prints a colour-coded
    summary of parse errors, compile errors, script errors, and runtime errors.
.EXAMPLE
    .\check_errors.ps1
    .\check_errors.ps1 -Verbose
    .\check_errors.ps1 -GodotPath "D:\Godot\Godot.exe"
#>

param(
    [switch]$Verbose,
    [string]$GodotPath   = "C:\Users\jakes\Downloads\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64_console.exe",
    [string]$ProjectPath = "C:\Users\jakes\Documents\the-evanescent-mind"
)

if (-not (Test-Path $GodotPath)) {
    Write-Host "ERROR: Godot executable not found at: $GodotPath" -ForegroundColor Red
    Write-Host "Set -GodotPath to the correct location." -ForegroundColor Yellow
    exit 1
}
if (-not (Test-Path $ProjectPath)) {
    Write-Host "ERROR: Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}

$border = "=" * 63
Write-Host ""
Write-Host $border -ForegroundColor Cyan
Write-Host "  THE EVANESCENT MIND -- Script Error Checker" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor DarkGray
Write-Host $border -ForegroundColor Cyan
Write-Host ""
Write-Host "  Running Godot headless (this takes ~5 seconds)..." -ForegroundColor DarkGray

$rawOutput = & $GodotPath --headless --quit --path $ProjectPath 2>&1

$falsePositives = @(
    "Cannot get path of node as it is not in a scene tree",
    "resources still in use at exit",
    "ObjectDB instances leaked at exit",
    "Orphan StringName",
    "Loading resource:",
    "Godot Engine v"
)

$parseErrors   = [System.Collections.Generic.List[string]]::new()
$compileErrors = [System.Collections.Generic.List[string]]::new()
$scriptErrors  = [System.Collections.Generic.List[string]]::new()
$runtimeErrors = [System.Collections.Generic.List[string]]::new()
$warnings      = [System.Collections.Generic.List[string]]::new()
$kept          = [System.Collections.Generic.List[string]]::new()

$prevLine = ""
foreach ($raw in $rawOutput) {
    $line = $raw.ToString().Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $skip = $false
    foreach ($fp in $falsePositives) {
        if ($line -match [regex]::Escape($fp)) { $skip = $true; break }
    }
    if ($skip) { continue }
    $kept.Add($line)
    if     ($line -match "Parse Error")    { $parseErrors.Add("  context: $prevLine`n    >> $line") }
    elseif ($line -match "Compile Error")  { $compileErrors.Add("  context: $prevLine`n    >> $line") }
    elseif ($line -match "^SCRIPT ERROR:") { $scriptErrors.Add("  $line") }
    elseif ($line -match "^ERROR:")        { $runtimeErrors.Add("  $line") }
    elseif ($line -match "^WARNING:")      { $warnings.Add("  $line") }
    $prevLine = $line
}

function Write-ErrorSection([string]$title, $items, [ConsoleColor]$colour) {
    if ($items.Count -eq 0) { return }
    Write-Host ""
    Write-Host "  [ $title ($($items.Count)) ]" -ForegroundColor $colour
    Write-Host ("  " + ("-" * 55)) -ForegroundColor DarkGray
    foreach ($item in $items) { Write-Host $item -ForegroundColor $colour }
}

Write-ErrorSection "PARSE ERRORS"   $parseErrors   Red
Write-ErrorSection "COMPILE ERRORS" $compileErrors Red
Write-ErrorSection "SCRIPT ERRORS"  $scriptErrors  Red
Write-ErrorSection "RUNTIME ERRORS" $runtimeErrors Yellow
Write-ErrorSection "WARNINGS"       $warnings      DarkYellow

$totalErrors   = $parseErrors.Count + $compileErrors.Count + $scriptErrors.Count + $runtimeErrors.Count
$totalWarnings = $warnings.Count

Write-Host ""
Write-Host $border -ForegroundColor Cyan
if ($totalErrors -eq 0 -and $totalWarnings -eq 0) {
    Write-Host "  PASS -- No errors or warnings found." -ForegroundColor Green
} elseif ($totalErrors -eq 0) {
    Write-Host "  PASS (with warnings) -- $totalWarnings warning(s), 0 errors." -ForegroundColor Yellow
} else {
    Write-Host "  FAIL -- $totalErrors error(s), $totalWarnings warning(s)." -ForegroundColor Red
}
Write-Host $border -ForegroundColor Cyan
Write-Host ""

if ($Verbose) {
    Write-Host "  [ RAW OUTPUT ]" -ForegroundColor DarkGray
    Write-Host ("  " + ("-" * 55)) -ForegroundColor DarkGray
    foreach ($line in $kept) { Write-Host "  $line" -ForegroundColor DarkGray }
    Write-Host ""
}

exit $totalErrors
