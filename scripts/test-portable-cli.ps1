# Test portable CLI: run test_task.zixir from project (mix) and optionally from release.
# Run from repo root: .\scripts\test-portable-cli.ps1

$repoRoot = if ($PSScriptRoot) { Resolve-Path (Join-Path $PSScriptRoot "..") } else { Resolve-Path ".." }
Set-Location $repoRoot.Path
# Don't use Stop so mix compile warnings on stderr don't fail the script
$ErrorActionPreference = "Continue"

$testFile = Join-Path $repoRoot "examples\test_task.zixir"
$testFileAbs = (Resolve-Path $testFile).Path

Write-Host "=== Test task sample: run from PowerShell ===" -ForegroundColor Cyan
Write-Host "Test file: $testFileAbs" -ForegroundColor Gray
Write-Host ""

# 1. Run with mix from project root (relative path)
Write-Host "1. mix zixir.run (from repo root, relative path):" -ForegroundColor Yellow
Set-Location $repoRoot.Path
$mixResult = cmd /c "mix zixir.run examples\test_task.zixir 2>&1"
$mixExit = $LASTEXITCODE
$resultLine = ($mixResult | Select-Object -Last 1)
Write-Host "   Output (last line): $resultLine"
if ($mixExit -eq 0) {
    Write-Host "   OK (exit 0)" -ForegroundColor Green
} else {
    Write-Host "   FAIL (exit $mixExit)" -ForegroundColor Red
}

Write-Host ""

# 2. Run with mix from project root using absolute path (file path can be anywhere)
Write-Host "2. mix zixir.run (from repo root, absolute path to file):" -ForegroundColor Yellow
Set-Location $repoRoot.Path
$mixAbs = cmd /c "mix zixir.run `"$testFileAbs`" 2>&1"
$exitAbs = $LASTEXITCODE
$lastAbs = ($mixAbs | Select-Object -Last 1)
Write-Host "   Output (last line): $lastAbs"
if ($exitAbs -eq 0) {
    Write-Host "   OK (exit 0) - absolute path works" -ForegroundColor Green
} else {
    Write-Host "   FAIL (exit $exitAbs)" -ForegroundColor Red
}

Write-Host ""

# 3. If release exists, run zixir_run.bat from another directory (true portable: any cwd)
$otherDir = $env:TEMP
# mix release builds to _build/dev/rel by default; mix release --env prod uses _build/prod/rel
$relBin = if (Test-Path (Join-Path $repoRoot "_build\dev\rel\zixir\bin\zixir_run.bat")) {
    Join-Path $repoRoot "_build\dev\rel\zixir\bin"
} else {
    Join-Path $repoRoot "_build\prod\rel\zixir\bin"
}
$zixirRunBat = Join-Path $relBin "zixir_run.bat"
if (Test-Path $zixirRunBat) {
    Write-Host "3. Release portable runner (cwd = $otherDir, zixir_run.bat <path>):" -ForegroundColor Yellow
    Push-Location $otherDir
    & $zixirRunBat $testFileAbs 2>&1
    $releaseExit = $LASTEXITCODE
    Pop-Location
    if ($releaseExit -eq 0) {
        Write-Host "   OK (exit 0) - ran from different directory" -ForegroundColor Green
    } else {
        Write-Host "   Exit code: $releaseExit" -ForegroundColor Red
    }
} else {
    Write-Host "3. Release not built (skip). Run: mix release" -ForegroundColor Gray
    Write-Host "   Then re-run this script to test zixir_run.bat from any cwd." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Done. Expected result from test_task.zixir: 22.0" -ForegroundColor Cyan
