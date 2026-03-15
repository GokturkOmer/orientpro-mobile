# ============================================
# OrientPro Tum Sistemi Baslat (Tek Komut)
# Kullanim: .\scripts\start-all.ps1
# ============================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  OrientPro Tum Sistem Baslatiliyor" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# --- 1) WSL Backend baslat ---
Write-Host ""
Write-Host "[1/2] WSL Backend baslatiliyor..." -ForegroundColor Yellow

# WSL'de backend scriptini arka planda calistir
$wslProcess = Start-Process -FilePath "wsl" -ArgumentList "bash", "-c", "bash ~/orientpro_mobile/scripts/start-backend.sh" -PassThru -NoNewWindow

# Backend'in ayaga kalkmasini bekle
Write-Host "  Backend baslaması bekleniyor..." -ForegroundColor Yellow
$maxWait = 60
$waited = 0
$backendReady = $false

while ($waited -lt $maxWait) {
    Start-Sleep -Seconds 3
    $waited += 3
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 3 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $backendReady = $true
            break
        }
    } catch {
        Write-Host "  Bekleniyor... ($waited s)" -ForegroundColor Gray
    }
}

if ($backendReady) {
    Write-Host "  Backend hazir!" -ForegroundColor Green
} else {
    Write-Host "  UYARI: Backend $maxWait saniyede hazir olmadi." -ForegroundColor Red
    Write-Host "  WSL terminal acip kontrol edin: tail -f ~/orientpro/backend/backend.log" -ForegroundColor Yellow
    $continue = Read-Host "  Flutter yine de baslatilsin mi? (e/h)"
    if ($continue -ne "e") { exit 1 }
}

# --- 2) Flutter baslat ---
Write-Host ""
Write-Host "[2/2] Flutter baslatiliyor..." -ForegroundColor Yellow

& "$PSScriptRoot\start-flutter.ps1"
