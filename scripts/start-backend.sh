#!/bin/bash
# ============================================
# OrientPro Backend Baslat (WSL2 Ubuntu)
# Kullanim: bash ~/orientpro_mobile/scripts/start-backend.sh
# ============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  OrientPro Backend Baslatiliyor...${NC}"
echo -e "${GREEN}========================================${NC}"

BACKEND_DIR="$HOME/orientpro"
VENV_DIR="$BACKEND_DIR/backend/venv"

# --- 1) Docker servislerini kontrol et ve baslat ---
echo -e "\n${YELLOW}[1/4] Docker servisleri kontrol ediliyor...${NC}"

if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker calismyor! Baslatiliyor...${NC}"
    sudo service docker start
    sleep 3
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}HATA: Docker baslatlamadi. 'sudo service docker start' deneyin.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}  Docker OK${NC}"

# --- 2) Docker Compose konteynerlarini baslat ---
echo -e "\n${YELLOW}[2/4] Docker Compose baslatiliyor...${NC}"

cd "$BACKEND_DIR"

if [ -f "docker-compose.yml" ]; then
    docker compose up -d 2>&1
elif [ -f "docker-compose.yaml" ]; then
    docker compose up -d 2>&1
else
    echo -e "${RED}HATA: docker-compose dosyasi bulunamadi: $BACKEND_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}  Konteynerlar baslatildi${NC}"

# --- 3) Konteynerlarin hazir olmasini bekle ---
echo -e "\n${YELLOW}[3/4] Veritabani hazir olana kadar bekleniyor...${NC}"

MAX_WAIT=30
WAITED=0
until docker exec orientpro-db pg_isready -U orientpro > /dev/null 2>&1; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo -e "${RED}HATA: PostgreSQL $MAX_WAIT saniyede hazir olmadi${NC}"
        docker ps
        exit 1
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -e "  Bekleniyor... (${WAITED}s)"
done
echo -e "${GREEN}  PostgreSQL hazir${NC}"

# Redis kontrol
until docker exec orientpro-redis redis-cli ping 2>/dev/null | grep -q PONG; do
    sleep 1
done
echo -e "${GREEN}  Redis hazir${NC}"

# --- 4) FastAPI backend baslat ---
echo -e "\n${YELLOW}[4/4] FastAPI backend baslatiliyor...${NC}"

cd "$BACKEND_DIR/backend"

if [ ! -d "$VENV_DIR" ]; then
    echo -e "${RED}HATA: Python venv bulunamadi: $VENV_DIR${NC}"
    echo -e "  Olusturmak icin: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

source "$VENV_DIR/bin/activate"

# Eski uvicorn process varsa kapat
pkill -f "uvicorn app.main:app" 2>/dev/null || true
sleep 1

echo -e "${GREEN}  Backend port 8000'de baslatiliyor...${NC}"
nohup uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > "$BACKEND_DIR/backend/backend.log" 2>&1 &
BACKEND_PID=$!

# Backend'in ayaga kalkmasini bekle
sleep 3
MAX_WAIT=20
WAITED=0
until curl -s http://localhost:8000/health > /dev/null 2>&1; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo -e "${YELLOW}  UYARI: /health endpoint henuz yanit vermiyor, log kontrol edin:${NC}"
        echo -e "  tail -f $BACKEND_DIR/backend/backend.log"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
done

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}  Backend hazir!${NC}"
fi

# --- Ozet ---
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  SISTEM DURUMU${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
echo ""
echo -e "  Backend PID : $BACKEND_PID"
echo -e "  Backend Log : tail -f $BACKEND_DIR/backend/backend.log"
echo -e "  API URL     : http://localhost:8000/api/v1"
echo -e "  API Docs    : http://localhost:8000/docs"
echo ""
echo -e "${GREEN}Backend basariyla baslatildi!${NC}"
echo -e "${YELLOW}Flutter icin PowerShell'de: .\\scripts\\start-flutter.ps1${NC}"
