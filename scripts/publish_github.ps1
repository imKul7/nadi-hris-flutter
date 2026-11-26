# Publikasi NADI HRIS dari folder root setelah GitHub CLI login.
# Tidak mengubah repo lain dan tidak memaksa push (no --force).
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git belum terpasang.' }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI belum ada. Instal dari https://cli.github.com/' }
gh auth status
if ($LASTEXITCODE -ne 0) { throw 'Login GitHub CLI: gh auth login' }
$forbidden = @('server/data/nadi.sqlite', 'android/local.properties', 'server/.env')
foreach ($p in $forbidden) {
  if (git ls-files --error-unmatch $p 2>$null) { throw "File sensitif tracked: $p" }
}
if (-not (Test-Path '.git')) { git init -b main }
git add .
git status --short
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -m 'feat: NADI HRIS Flutter frontend and local role-based HR API' }
$repo = 'imKul7/nadi-hris-flutter'
$exists = gh repo view $repo --json name -q '.name' 2>$null
if (-not $exists) {
  Write-Host 'Membuat repo publik baru di GitHub imKul7...'
  gh repo create nadi-hris-flutter --public --source=. --remote=origin --push
} else {
  if (-not (git remote get-url origin 2>$null)) { git remote add origin "https://github.com/$repo.git" }
  git branch -M main
  git push -u origin main
}
Write-Host "Selesai: https://github.com/$repo"
