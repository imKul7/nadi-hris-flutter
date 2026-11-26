$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Write-Host 'NADI HRIS — Verification' -ForegroundColor Cyan
Push-Location $root
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal' }
  flutter analyze
  if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal' }
  flutter test
  if ($LASTEXITCODE -ne 0) { throw 'flutter test gagal' }
  Push-Location (Join-Path $root 'server')
  try {
    node --version
    npm run check
    if ($LASTEXITCODE -ne 0) { throw 'Backend syntax check gagal' }
    npm test
    if ($LASTEXITCODE -ne 0) { throw 'Backend tests gagal' }
  } finally { Pop-Location }
  Write-Host 'Analyzer & tests PASS pada perangkat ini.' -ForegroundColor Green
} finally { Pop-Location }
