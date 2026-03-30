# ============================================
# OrientPro Deploy Script (PowerShell)
# Kullanim: .\scripts\deploy.ps1 [-Target frontend|backend|all]
# Default: all
# ============================================

param(
    [ValidateSet("frontend", "backend", "all", "f", "b", "a")]
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

$Server = "root@46.224.208.137"
$ServerPath = "/opt/orientpro"
$FrontendPath = "$ServerPath/frontend/web"
$FlutterDir = "C:\Users\omera\orientpro_mobile"

function Write-Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-Warn($msg)  { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "[HATA] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  OrientPro Deploy - $Target" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

function Deploy-Frontend {
    Set-Location $FlutterDir

    # 1) Analyze
    Write-Info "Flutter analyze calisiyor..."
    flutter analyze --no-fatal-infos
    if ($LASTEXITCODE -ne 0) { Write-Err "Flutter analyze hatasi! Deploy iptal." }
    Write-Ok "Analyze temiz"

    # 2) Build
    Write-Info "Flutter web build calisiyor..."
    flutter build web --release --dart-define=TUNNEL=true
    if ($LASTEXITCODE -ne 0) { Write-Err "Flutter build hatasi! Deploy iptal." }
    Write-Ok "Web build tamamlandi"

    # 3) Upload
    Write-Info "Frontend sunucuya yukleniyor..."
    ssh $Server "cp -r $FrontendPath ${FrontendPath}_backup_`$(date +%Y%m%d_%H%M%S) 2>/dev/null || true"
    scp -r "$FlutterDir\build\web\*" "${Server}:${FrontendPath}/"
    if ($LASTEXITCODE -ne 0) { Write-Err "SCP hatasi! Frontend yuklenemedi." }
    Write-Ok "Frontend yuklendi"

    # 4) Nginx reload
    Write-Info "Nginx reload ediliyor..."
    ssh $Server "cd $ServerPath && docker compose exec -T nginx nginx -s reload 2>/dev/null || docker compose restart nginx"
    Write-Ok "Nginx reload edildi"
}

function Deploy-Backend {
    Write-Info "Backend deploy basliyor..."
    ssh $Server "cd $ServerPath && git pull origin main && docker compose up -d --build backend"
    Write-Ok "Backend deploy tamamlandi"

    Write-Info "Health check bekleniyor..."
    Start-Sleep -Seconds 5
    try {
        $resp = Invoke-WebRequest -Uri "https://orientpro.co/health" -TimeoutSec 10 -UseBasicParsing
        if ($resp.StatusCode -eq 200) { Write-Ok "Backend saglikli" }
    } catch {
        Write-Warn "Health check basarisiz — birkac saniye bekleyin"
    }
}

function Verify-Deploy {
    Write-Host ""
    Write-Info "Deploy sonrasi dogrulama..."
    try {
        $resp = Invoke-WebRequest -Uri "https://orientpro.co/" -TimeoutSec 10 -UseBasicParsing
        Write-Ok "https://orientpro.co/ — HTTP $($resp.StatusCode)"
    } catch {
        Write-Warn "Site erisilemedi — kontrol edin"
    }

    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "  Deploy tamamlandi!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
}

# --- Calistir ---
switch -Regex ($Target) {
    "^(frontend|f)$" { Deploy-Frontend; Verify-Deploy }
    "^(backend|b)$"  { Deploy-Backend; Verify-Deploy }
    "^(all|a)$"      { Deploy-Frontend; Deploy-Backend; Verify-Deploy }
}
