$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..\server'))
Write-Host 'NADI HRIS — Development backend (http://localhost:3000)' -ForegroundColor Cyan
Write-Host 'Tekan Ctrl+C untuk menghentikan. Gunakan jaringan privat saja.'
npm start
