# Publish GitHub Release v5.0.0 for Zixir-lang/Zixir
# Requires: GitHub CLI (gh) installed and authenticated: gh auth login
# Run from repo root: .\scripts\publish-release-v5.ps1

$ErrorActionPreference = "Stop"
$tag = "v5.0.0"
$notesFile = "RELEASE_NOTES_v5.0.0.md"

if (-not (Test-Path $notesFile)) {
    Write-Error "Run from repo root. Not found: $notesFile"
}

# Check gh is installed and logged in
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host "GitHub CLI (gh) not found. Install: https://cli.github.com/"
    Write-Host ""
    Write-Host "Or create the release manually:"
    Write-Host "  1. Open https://github.com/Zixir-lang/Zixir/releases/new"
    Write-Host "  2. Choose tag: v5.0.0"
    Write-Host "  3. Title: v5.0.0 — Portable CLI, setup fixes, and redeploy"
    Write-Host "  4. Paste contents of RELEASE_NOTES_v5.0.0.md"
    Write-Host "  5. Publish release"
    exit 1
}

Write-Host "Creating GitHub Release $tag..."
gh release create $tag `
  --repo Zixir-lang/Zixir `
  --title "v5.0.0 — Portable CLI, setup fixes, and redeploy" `
  --notes-file $notesFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Done. Release: https://github.com/Zixir-lang/Zixir/releases/tag/v5.0.0"
} else {
    Write-Host "If tag already has a release, use: gh release edit v5.0.0 --repo Zixir-lang/Zixir --notes-file $notesFile"
}
