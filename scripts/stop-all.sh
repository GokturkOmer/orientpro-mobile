#!/bin/bash
# ============================================
# OrientPro Tum Servisleri Durdur (WSL2)
# Kullanim: bash ~/orientpro_mobile/scripts/stop-all.sh
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}OrientPro servisleri durduruluyor...${NC}"

# Backend kapat
pkill -f "uvicorn app.main:app" 2>/dev/null && echo -e "${GREEN}  Backend durduruldu${NC}" || echo "  Backend zaten kapali"

# Docker konteynerlarini durdur
cd ~/orientpro 2>/dev/null
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    docker compose down 2>/dev/null && echo -e "${GREEN}  Docker konteynerlar durduruldu${NC}" || echo "  Docker zaten kapali"
fi

echo -e "${GREEN}Tum servisler durduruldu.${NC}"
