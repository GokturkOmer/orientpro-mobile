# ============================================
# OrientPro Flutter Web Baslat (Windows PowerShell)
# Kullanim: .\scripts\start-flutter.ps1
# ============================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  OrientPro Flutter Web Baslatiliyor..." -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$ProjectDir = "C:\Users\omera\orientpro_mobile"

# --- 1) Backend erisimi kontrol ---
Write-Host ""
Write-Host "[1/3] Backend baglantisi kontrol ediliyor..." -ForegroundColor Yellow

$backendReady = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        $backendReady = $true
    }
} catch {
    # Sessiz devam
}

if ($backendReady) {
    Write-Host "  Backend OK (localhost:8000)" -ForegroundColor Green
} else {
    Write-Host "  UYARI: Backend erisilemiyor!" -ForegroundColor Red
    Write-Host "  WSL'de once backend'i baslatin:" -ForegroundColor Yellow
    Write-Host "    wsl bash ~/orientpro_mobile/scripts/start-backend.sh" -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Backend olmadan devam edilsin mi? (e/h)"
    if ($continue -ne "e") {
        exit 1
    }
}

# --- 2) Flutter pub get ---
Write-Host ""
Write-Host "[2/3] Flutter paketleri kontrol ediliyor..." -ForegroundColor Yellow

Set-Location $ProjectDir

if (-not (Test-Path "pubspec.lock")) {
    Write-Host "  pubspec.lock bulunamadi, flutter pub get calistiriliyor..." -ForegroundColor Yellow
    flutter pub get
} else {
    # pubspec.yaml, pubspec.lock'tan yeni mi?
    $pubspecTime = (Get-Item "pubspec.yaml").LastWriteTime
    $lockTime = (Get-Item "pubspec.lock").LastWriteTime
    if ($pubspecTime -gt $lockTime) {
        Write-Host "  pubspec.yaml degismis, flutter pub get calistiriliyor..." -ForegroundColor Yellow
        flutter pub get
    } else {
        Write-Host "  Paketler guncel" -ForegroundColor Green
    }
}

# --- 3) Flutter run ---
Write-Host ""
Write-Host "[3/3] Flutter web baslatiliyor..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Durdurmak icin: Ctrl+C" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

flutter run -d chrome --web-port=8080
