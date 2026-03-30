#!/bin/bash
# ============================================
# OrientPro Deploy Script
# Kullanim: bash scripts/deploy.sh [frontend|backend|all]
# Default: all (hem frontend hem backend)
# ============================================

set -euo pipefail

# --- Konfigrasyon ---
SERVER="root@46.224.208.137"
SERVER_PATH="/opt/orientpro"
FRONTEND_PATH="$SERVER_PATH/frontend/web"
FLUTTER_DIR="C:/Users/omera/orientpro_mobile"
SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"

# --- Renkli output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[HATA]${NC} $1"; exit 1; }

# --- Parametre ---
TARGET="${1:-all}"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  OrientPro Deploy — $TARGET${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# --- 1) Flutter Analyze ---
deploy_frontend() {
    info "Flutter analyze calisiyor..."
    cd "$FLUTTER_DIR"

    if ! flutter analyze --no-fatal-infos 2>&1 | tail -5; then
        error "Flutter analyze hatasi! Deploy iptal."
    fi
    ok "Analyze temiz"

    # --- 2) Flutter Web Build ---
    info "Flutter web build calisiyor..."
    if ! flutter build web --release --dart-define=TUNNEL=true 2>&1 | tail -5; then
        error "Flutter build hatasi! Deploy iptal."
    fi
    ok "Web build tamamlandi"

    # --- 3) Upload to Server ---
    info "Frontend sunucuya yukleniyor..."

    # Backup mevcut frontend
    ssh $SSH_OPTS "$SERVER" "cp -r $FRONTEND_PATH ${FRONTEND_PATH}_backup_\$(date +%Y%m%d_%H%M%S) 2>/dev/null || true"

    # Upload
    if ! scp -r $SSH_OPTS "$FLUTTER_DIR/build/web/"* "$SERVER:$FRONTEND_PATH/"; then
        error "SCP hatasi! Frontend yuklenemedi."
    fi
    ok "Frontend yuklendi"

    # --- 4) Nginx reload ---
    info "Nginx reload ediliyor..."
    ssh $SSH_OPTS "$SERVER" "cd $SERVER_PATH && docker compose exec -T nginx nginx -s reload 2>/dev/null || docker compose restart nginx"
    ok "Nginx reload edildi"
}

deploy_backend() {
    info "Backend deploy basliyor..."

    # Backend git pull + rebuild
    ssh $SSH_OPTS "$SERVER" "cd $SERVER_PATH && git pull origin main && docker compose up -d --build backend"
    ok "Backend deploy tamamlandi"

    # Health check
    info "Backend health check..."
    sleep 5
    if ssh $SSH_OPTS "$SERVER" "curl -sf http://localhost:8000/health > /dev/null 2>&1"; then
        ok "Backend saglikli"
    else
        warn "Backend henuz hazir degil — birkac saniye bekleyin ve kontrol edin"
    fi
}

# --- 5) Deploy sonrasi dogrulama ---
verify() {
    echo ""
    info "Deploy sonrasi dogrulama..."

    # HTTPS check
    if curl -sf "https://orientpro.co/health" > /dev/null 2>&1; then
        ok "https://orientpro.co/health — OK"
    else
        warn "Health check basarisiz — sunucuyu kontrol edin"
    fi

    # Frontend check
    HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "https://orientpro.co/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        ok "https://orientpro.co/ — HTTP $HTTP_CODE"
    else
        warn "Frontend HTTP $HTTP_CODE — kontrol edin"
    fi

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}  Deploy tamamlandi!${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
}

# --- Calistir ---
case "$TARGET" in
    frontend|f)
        deploy_frontend
        verify
        ;;
    backend|b)
        deploy_backend
        verify
        ;;
    all|a)
        deploy_frontend
        deploy_backend
        verify
        ;;
    *)
        echo "Kullanim: deploy.sh [frontend|backend|all]"
        echo "  frontend (f) — Sadece Flutter web build + upload"
        echo "  backend  (b) — Sadece backend git pull + rebuild"
        echo "  all      (a) — Her ikisi (default)"
        exit 1
        ;;
esac
