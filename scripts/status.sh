#!/bin/bash
# ============================================
# OrientPro Sistem Durum Kontrolu (WSL2)
# Kullanim: bash ~/orientpro_mobile/scripts/status.sh
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================"
echo "  OrientPro Sistem Durumu"
echo "========================================"

# Docker
echo ""
echo "--- Docker Konteynerlar ---"
if docker info > /dev/null 2>&1; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null
else
    echo -e "${RED}  Docker calismyor${NC}"
fi

# PostgreSQL
echo ""
echo -n "--- PostgreSQL: "
if docker exec orientpro-db pg_isready -U orientpro > /dev/null 2>&1; then
    echo -e "${GREEN}HAZIR${NC}"
else
    echo -e "${RED}KAPALI${NC}"
fi

# Redis
echo -n "--- Redis: "
if docker exec orientpro-redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo -e "${GREEN}HAZIR${NC}"
else
    echo -e "${RED}KAPALI${NC}"
fi

# Backend API
echo -n "--- Backend API: "
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}HAZIR (localhost:8000)${NC}"
else
    echo -e "${RED}KAPALI${NC}"
fi

# Ollama
echo -n "--- Ollama: "
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}HAZIR${NC}"
else
    echo -e "${RED}KAPALI${NC}"
fi

echo ""
echo "========================================"
