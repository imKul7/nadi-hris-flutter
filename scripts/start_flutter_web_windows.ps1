$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal' }
flutter run -d chrome --dart-define=NADI_API_URL=http://localhost:3000
