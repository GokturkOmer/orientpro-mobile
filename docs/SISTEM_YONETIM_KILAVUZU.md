# OrientPro Sistem Yonetim Kilavuzu

> Bu kilavuz, OrientPro sistemini baslatmak, durdurmak, yonetmek ve guncellemek icin gereken tum bilgileri icerir.

---

## ICINDEKILER

1. [Sistem Mimarisi](#1-sistem-mimarisi)
2. [Gereksinimler](#2-gereksinimler)
3. [Lokal Sistemi Baslatma](#3-lokal-sistemi-baslatma)
4. [Lokal Sistemi Durdurma](#4-lokal-sistemi-durdurma)
5. [Production Sunucu Yonetimi](#5-production-sunucu-yonetimi)
6. [Deploy (Yayinlama)](#6-deploy-yayinlama)
7. [Veritabani Yonetimi (pgAdmin)](#7-veritabani-yonetimi-pgadmin)
8. [Dosya Deposu (MinIO)](#8-dosya-deposu-minio)
9. [Izleme (Grafana)](#9-izleme-grafana)
10. [Kullanici ve Veri Yonetimi](#10-kullanici-ve-veri-yonetimi)
11. [Yedekleme ve Geri Yukleme](#11-yedekleme-ve-geri-yukleme)
12. [Sorun Giderme](#12-sorun-giderme)
13. [Ortam Degiskenleri (.env)](#13-ortam-degiskenleri)
14. [Onemli Dosya Konumlari](#14-onemli-dosya-konumlari)

---

## 1. Sistem Mimarisi

```
Kullanici (Tarayici/Mobil)
        |
        v
   [Nginx] -----> /api/* ----> [Backend (FastAPI)] ----> [PostgreSQL]
     :443                            |                       |
     :80                             |----> [Redis]          |----> Tum yapisal veriler
                                     |----> [MinIO]                 (kullanicilar, egitimler,
                                     |----> [ChromaDB]               quizler, bildirimler...)
                                     |
                               [Prometheus] ----> [Grafana]
```

### Servisler ve Gorevleri

| Servis | Container Adi | Port | Gorevi |
|--------|--------------|------|--------|
| PostgreSQL | orientpro-db | 5432 | Ana veritabani (kullanici, egitim, quiz, bildirim...) |
| Redis | orientpro-redis | 6379 | Onbellek, oturum, rate limiting |
| MinIO | orientpro-minio | 9000/9001 | Dosya deposu (PDF, resim, dokumanlar) |
| Backend | orientpro-backend | 8000 | FastAPI uygulama sunucusu |
| Nginx | orientpro-nginx | 80/443 | Web sunucu, SSL, reverse proxy |
| Prometheus | orientpro-prometheus | 9090 | Metrik toplama |
| Grafana | orientpro-grafana | 3000 | Metrik gorsellesirme |

### Veri Nerede Depolaniyor?

| Veri Tipi | Depo | Erisim |
|-----------|------|--------|
| Kullanicilar, roller, organizasyonlar | PostgreSQL | pgAdmin |
| Egitim rotalari, moduller, quizler | PostgreSQL | pgAdmin |
| Quiz sonuclari, ilerlemeler | PostgreSQL | pgAdmin |
| Mikro-ogrenme atamalari | PostgreSQL | pgAdmin |
| Bildirimler | PostgreSQL | pgAdmin |
| Is emirleri, ekipman | PostgreSQL | pgAdmin |
| PDF ve egitim dokumanlari | MinIO (training-docs) | MinIO Console |
| Icerik kutuphanesi dosyalari | MinIO (shared-library) | MinIO Console |
| Kisisel dokumanlar | MinIO (personal-docs) | MinIO Console |
| Duyuru ekleri | MinIO (announcements) | MinIO Console |
| Chatbot embedding vektorleri | ChromaDB | Backend uzerinden |
| Oturum ve gecici veriler | Redis | Otomatik yonetilir |

---

## 2. Gereksinimler

### Lokal Gelistirme Ortami
- **Windows 10/11** (Flutter icin)
- **WSL2 Ubuntu** (Backend icin)
- **Docker Desktop** (WSL2 entegreli)
- **Flutter SDK 3.x** (Windows'ta)
- **Git** + GitHub CLI (`gh`)
- **SSH anahtari** (sunucuya erisim icin)

### Production Sunucu
- **Hetzner CCX13** (46.224.208.137)
- **Ubuntu** + Docker + Docker Compose
- **Domain:** orientpro.co (SSL Let's Encrypt)

---

## 3. Lokal Sistemi Baslatma

### Yontem 1: Tek Komut (Onerilen)

PowerShell ac:
```powershell
cd C:\Users\omera\orientpro_mobile
.\scripts\start-all.ps1
```

Bu komut siratasiyla:
1. WSL'de Docker servislerini baslatir (PostgreSQL, Redis, MinIO)
2. Backend'i baslatir (FastAPI, port 8000)
3. Backend hazir olana kadar bekler
4. Flutter web'i Chrome'da acar (port 8080)

### Yontem 2: Adim Adim

**Adim 1 — Docker servislerini baslat (WSL terminalinde):**
```bash
cd ~/orientpro
docker compose up -d
```

**Adim 2 — Servislerin hazir olmasini bekle:**
```bash
docker exec orientpro-db pg_isready -U orientpro    # "accepting connections" yazmalı
docker exec orientpro-redis redis-cli ping           # "PONG" yazmalı
```

**Adim 3 — Backend'i baslat (WSL terminalinde):**
```bash
cd ~/orientpro/backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Adim 4 — Flutter'i baslat (PowerShell'de):**
```powershell
cd C:\Users\omera\orientpro_mobile
flutter run -d chrome
```

### Sistem Durumu Kontrolu

WSL terminalinde:
```bash
bash ~/orientpro_mobile/scripts/status.sh
```

Tarayicide:
- Backend API: http://localhost:8000/api/v1/health
- API Dokumantasyonu: http://localhost:8000/docs
- pgAdmin: http://localhost:5050
- MinIO Console: http://localhost:9001

---

## 4. Lokal Sistemi Durdurma

### Tek Komut
WSL terminalinde:
```bash
bash ~/orientpro_mobile/scripts/stop-all.sh
```

### Manuel
```bash
# Backend kapat
pkill -f "uvicorn app.main:app"

# Docker kapat
cd ~/orientpro
docker compose down
```

> **NOT:** `docker compose down` veritabani verilerini SILMEZ. Veriler Docker volume'larda kalir. Verileri de silmek icin `docker compose down -v` kullan (DIKKAT: tum veriler gider!)

---

## 5. Production Sunucu Yonetimi

### Sunucuya Baglanma
```powershell
ssh root@46.224.208.137
```

### Servisleri Goruntuleme
```bash
cd /opt/orientpro
docker compose ps
```

### Servisleri Yeniden Baslatma
```bash
# Tum servisleri yeniden baslat
docker compose restart

# Sadece backend'i yeniden baslat
docker compose restart backend

# Sadece nginx'i yeniden baslat
docker compose restart nginx
```

### Loglari Izleme
```bash
# Backend loglari (canli)
docker compose logs -f backend

# Son 100 satir
docker compose logs --tail=100 backend

# Nginx loglari
docker compose logs -f nginx

# Tum servisler
docker compose logs -f
```

### Sunucu Disk/RAM Kontrolu
```bash
df -h          # Disk kullanimi
free -h        # RAM kullanimi
htop           # CPU ve islem listesi (q ile cik)
```

---

## 6. Deploy (Yayinlama)

### Onerilen Yol: Deploy Script

PowerShell'de:
```powershell
cd C:\Users\omera\orientpro_mobile

# Sadece frontend deploy
.\scripts\deploy.ps1 -Target frontend

# Sadece backend deploy
.\scripts\deploy.ps1 -Target backend

# Her ikisini de deploy
.\scripts\deploy.ps1 -Target all
```

### Frontend Deploy (Manuel)

```powershell
# 1. Build
cd C:\Users\omera\orientpro_mobile
flutter build web --release --dart-define=TUNNEL=true

# 2. Sunucuya yukle
scp -r build\web\* root@46.224.208.137:/opt/orientpro/frontend/web/

# 3. Nginx reload (sunucuda)
ssh root@46.224.208.137 "cd /opt/orientpro && docker compose exec nginx nginx -s reload"
```

### Backend Deploy (Manuel)

```bash
# Sunucuya baglan
ssh root@46.224.208.137

# Kodu cek ve yeniden build et
cd /opt/orientpro
git pull origin main
docker compose up -d --build backend

# Health check
curl http://localhost:8000/health
```

### Deploy Kontrol Listesi

- [ ] Lokal test gecti mi?
- [ ] `flutter analyze` hata var mi?
- [ ] Git commit + push yapildi mi?
- [ ] Deploy scripti basarili tamamlandi mi?
- [ ] https://orientpro.co aciliyor mu?
- [ ] Giris yapilabiliyor mu?

---

## 7. Veritabani Yonetimi (pgAdmin)

### Lokal Erisim
- **URL:** http://localhost:5050
- **E-posta:** admin@orientpro.com
- **Sifre:** admin_dev_2026

### Ilk Kez Sunucu Ekleme
1. pgAdmin'e giris yap
2. Sol panelde "Add New Server" tikla
3. **General** sekmesi: Ad = `OrientPro`
4. **Connection** sekmesi:
   - Host: `orientpro-db`
   - Port: `5432`
   - Database: `orientpro`
   - Username: `orientpro`
   - Password: `testpass123`
5. Save tikla

### Tablo Gorme
Sol panel → OrientPro → Databases → orientpro → Schemas → public → Tables

Herhangi bir tabloya sag tik → View/Edit Data → All Rows

### Onemli Tablolar

| Tablo | Icerigi |
|-------|---------|
| users | Tum kullanicilar |
| organizations | Sirketler/kurumlar |
| user_organizations | Kullanici-kurum iliskisi |
| training_routes | Egitim rotalari |
| training_modules | Egitim modulleri |
| module_contents | Modul icerikleri |
| quizzes | Quizler |
| quiz_questions | Quiz sorulari |
| quiz_results | Quiz sonuclari |
| user_progress | Kullanici ilerlemeleri |
| micro_learning_assignments | Mikro-ogrenme atamalari |
| drip_content_cards | Mikro-ogrenme kartlari |
| notifications | Bildirimler |
| training_reminders | Egitim hatirlticilari |
| announcements | Duyurular |
| equipment | Ekipmanlar |
| work_orders | Is emirleri |
| audit_logs | Kullanici aksiyonlari kaydi |
| subscriptions | Abonelikler |
| invoices | Faturalar |

### Sik Kullanilan SQL Sorgulari

pgAdmin → Tools → Query Tool ile SQL calistirabilirsin:

```sql
-- Tum kullanicilari listele
SELECT id, email, full_name, role, is_active, created_at FROM users ORDER BY created_at DESC;

-- Organizasyon bazli kullanici sayisi
SELECT o.name, COUNT(uo.user_id) as kullanici_sayisi
FROM organizations o
LEFT JOIN user_organizations uo ON o.id = uo.organization_id
GROUP BY o.name;

-- Mikro-ogrenme durumu
SELECT u.full_name, m.title as modul, a.status, a.mode, a.quiz_passed, a.learning_day
FROM micro_learning_assignments a
JOIN users u ON a.user_id = u.id
JOIN training_modules m ON a.module_id = m.id
ORDER BY a.created_at DESC;

-- Okunmamis bildirimler
SELECT u.full_name, n.title, n.category, n.created_at
FROM notifications n
JOIN users u ON n.user_id::uuid = u.id
WHERE n.is_read = false
ORDER BY n.created_at DESC;

-- Quiz basari oranlari
SELECT q.title, COUNT(*) as toplam, SUM(CASE WHEN passed THEN 1 ELSE 0 END) as gecen,
       ROUND(AVG(score::numeric / NULLIF(max_score, 0) * 100), 1) as ort_puan
FROM quiz_results qr
JOIN quizzes q ON qr.quiz_id = q.id
GROUP BY q.title;
```

---

## 8. Dosya Deposu (MinIO)

### Lokal Erisim
- **URL:** http://localhost:9001
- **Username:** orientpro
- **Password:** testminio123456

### Bucket'lar (Dosya Klasorleri)

| Bucket | Icerigi |
|--------|---------|
| training-docs | Egitim PDF ve dokumanlari |
| shared-library | Paylasimli icerik kutuphanesi |
| personal-docs | Kisisel dokumanlar |
| announcements | Duyuru dosya ekleri |

### Dosya Islemleri
- **Gorme:** Bucket'a tikla → dosyalari gorursun
- **Indirme:** Dosyaya tikla → Download
- **Yukleme:** Bucket ac → Upload → dosya sec
- **Silme:** Dosyaya tikla → Delete

---

## 9. Izleme (Grafana)

### Erisim (Sadece SSH Tuneli ile)
```powershell
# PowerShell'de SSH tuneli ac (acik kalmali)
ssh -L 3000:127.0.0.1:3000 root@46.224.208.137
```

Sonra tarayicide: http://localhost:3000
- **Username:** admin
- **Password:** .env dosyasindaki GRAFANA_PASSWORD degeri

### Ne Izlenir?
- Backend HTTP istek sayisi ve sureleri
- Backend RAM kullanimi
- Hata oranlari

### Dashboard Olusturma
1. Sol menu → Dashboards → New → New Dashboard
2. Add visualization
3. Data source: Prometheus
4. Metrik sec (ornek: `http_requests_total`)
5. Save

---

## 10. Kullanici ve Veri Yonetimi

### Yeni Kullanici Ekleme
**Yontem 1 — Uygulama uzerinden (Onerilen):**
1. Admin hesabiyla giris yap
2. Yonetim Paneli → Uyelik Yonetimi
3. Yeni kullanici ekle

**Yontem 2 — API uzerinden:**
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "yeni@ornek.com",
    "full_name": "Yeni Kullanici",
    "password": "guvenli_sifre_123",
    "role": "staff",
    "department": "genel"
  }'
```

**Yontem 3 — pgAdmin ile dogrudan DB:**
```sql
-- DIKKAT: Sifre hash'lenmeli, dogrudan INSERT onerilmez.
-- Uygulama veya API uzerinden ekleme tercih edin.
```

### Kullanici Rollerini Degistirme
pgAdmin'de:
```sql
UPDATE users SET role = 'admin' WHERE email = 'kullanici@ornek.com';
```

Gecerli roller: `admin`, `facility_manager`, `chief_technician`, `technician`, `staff`, `intern`

### Egitim Rotasi Olusturma
1. Admin giris → Yonetim Paneli → Icerik Yonetimi
2. "Yeni Rota" butonu → Rota adi + departman sec
3. Rotaya modul ekle → modul adi + icerik yaz/yukle
4. Modullere quiz ekle → sorulari tanimla

### Mikro-Ogrenme Atama
1. Admin giris → Yonetim Paneli → Mikro-Ogrenme
2. Calisan sec → modul sec → mod sec (yonetici/genel)
3. Ata

### Duyuru Yayinlama
1. Admin giris → Yonetim Paneli → Duyuru Yonetimi
2. Yeni duyuru olustur → baslik + icerik + departman
3. Yayinla

---

## 11. Yedekleme ve Geri Yukleme

### Veritabani Yedekleme

**Lokal:**
```bash
docker exec orientpro-db pg_dump -U orientpro orientpro > backup_$(date +%Y%m%d).sql
```

**Production (sunucuda):**
```bash
ssh root@46.224.208.137
docker exec orientpro-db pg_dump -U orientpro orientpro > /opt/orientpro/backups/backup_$(date +%Y%m%d).sql
```

### Veritabani Geri Yukleme

```bash
# DIKKAT: Mevcut verilerin uzerine yazar!
cat backup_20260401.sql | docker exec -i orientpro-db psql -U orientpro orientpro
```

### MinIO (Dosya) Yedekleme

```bash
# Sunucuda MinIO verileri Docker volume icinde
# Volume yedekle:
docker run --rm -v orientpro_minio_data:/data -v /opt/orientpro/backups:/backup \
  alpine tar czf /backup/minio_backup_$(date +%Y%m%d).tar.gz /data
```

### Tam Sistem Sifirlama (DIKKAT!)

```bash
# TUM VERILERI SILER — geri alinamaz!
cd ~/orientpro  # veya /opt/orientpro (sunucuda)
docker compose down -v
docker compose up -d
```

Bu komut:
- Tum konteynerlari durdurur
- Tum Docker volume'lari siler (veritabani, dosyalar, her sey)
- Konteynerlari sifirdan baslatir (bos veritabani)

---

## 12. Sorun Giderme

### Backend Acilmiyor

```bash
# Loglara bak
docker compose logs --tail=50 backend

# Veritabani baglantisi var mi?
docker exec orientpro-db pg_isready -U orientpro

# Redis baglantisi var mi?
docker exec orientpro-redis redis-cli ping

# Backend'i yeniden baslat
docker compose restart backend
```

### Frontend Acilmiyor (Lokal)

```powershell
# Flutter paketleri temizle ve yeniden kur
cd C:\Users\omera\orientpro_mobile
flutter clean
flutter pub get
flutter run -d chrome
```

### "Connection Refused" Hatasi (Lokal)

WSL ile Windows arasinda port forwarding gerekebilir:
```powershell
# Admin PowerShell'de:
# Oncelikle WSL IP'yi ogren
wsl hostname -I

# Port forwarding kur
netsh interface portproxy add v4tov4 listenport=8000 listenaddress=0.0.0.0 connectport=8000 connectaddress=<WSL_IP>
```

### Sunucu Disk Dolu

```bash
ssh root@46.224.208.137

# Disk kontrolu
df -h

# Docker temizlik (kullanilmayan image/volume sil)
docker system prune -a --volumes
# DIKKAT: Sadece kullanilmayan kaynaklari siler, aktif verilere dokunmaz
```

### Veritabani Migration Hatasi

```bash
# Sunucuda
ssh root@46.224.208.137
cd /opt/orientpro
docker compose exec backend alembic upgrade head
```

### SSL Sertifika Yenileme

Let's Encrypt sertifikasi 90 gun gecerli. Yenileme:
```bash
ssh root@46.224.208.137
# Certbot auto-renew genellikle cron'da ayarli
certbot renew
docker compose restart nginx
```

---

## 13. Ortam Degiskenleri

### Production (.env) Degiskenleri

| Degisken | Aciklama |
|----------|----------|
| POSTGRES_DB | Veritabani adi |
| POSTGRES_USER | Veritabani kullanicisi |
| POSTGRES_PASSWORD | Veritabani sifresi |
| REDIS_HOST | Redis adresi |
| REDIS_PASSWORD | Redis sifresi |
| MINIO_ROOT_USER | MinIO kullanicisi |
| MINIO_ROOT_PASSWORD | MinIO sifresi |
| JWT_SECRET_KEY | JWT imzalama anahtari (ASLA paylasma!) |
| JWT_ACCESS_TOKEN_EXPIRE_MINUTES | Access token suresi (dk) |
| GEMINI_API_KEY | Google Gemini API anahtari |
| GEMINI_MODEL | Kullanilan Gemini modeli |
| LLM_PROVIDER | LLM saglayicisi (gemini) |
| CHROMA_PATH | ChromaDB veri yolu |
| SENDGRID_API_KEY | E-posta API anahtari |
| IYZICO_API_KEY | Odeme API anahtari |
| IYZICO_SECRET_KEY | Odeme gizli anahtari |
| GRAFANA_PASSWORD | Grafana admin sifresi |
| SCADA_ENABLED | SCADA modulu acik/kapali |

### .env Degistirme

```bash
# Sunucuda
ssh root@46.224.208.137
nano /opt/orientpro/.env

# Degisiklik sonrasi backend'i yeniden baslat
cd /opt/orientpro
docker compose up -d --build backend
```

> **ONEMLI:** JWT_SECRET_KEY degistirirsen tum kullanicilarin oturumu kapanir!

---

## 14. Onemli Dosya Konumlari

### Lokal (Gelistirme)

| Konum | Aciklama |
|-------|----------|
| `C:\Users\omera\orientpro_mobile\` | Flutter projesi |
| `C:\Users\omera\orientpro_mobile\lib\` | Flutter kaynak kodu |
| `C:\Users\omera\orientpro_mobile\scripts\` | Baslatma/deploy scriptleri |
| WSL: `~/orientpro/` | Docker Compose + backend |
| WSL: `~/orientpro/backend/` | FastAPI kaynak kodu |
| WSL: `~/orientpro/backend/app/` | API, modeller, servisler |
| WSL: `~/orientpro/.env` | Lokal ortam degiskenleri |

### Production (Sunucu)

| Konum | Aciklama |
|-------|----------|
| `/opt/orientpro/` | Ana proje dizini |
| `/opt/orientpro/.env` | Ortam degiskenleri |
| `/opt/orientpro/docker-compose.yml` | Servis tanimlari |
| `/opt/orientpro/backend/` | Backend kaynak kodu |
| `/opt/orientpro/frontend/web/` | Flutter web build |
| `/opt/orientpro/docker/nginx/` | Nginx konfigurasyonu |
| `/opt/orientpro/docker/prometheus/` | Prometheus konfigurasyonu |

### Erisim Bilgileri Ozet

| Servis | Lokal URL | Kullanici | Sifre |
|--------|-----------|-----------|-------|
| Uygulama | http://localhost:8080 | (kullanici hesabi) | (kullanici sifresi) |
| API Docs | http://localhost:8000/docs | — | — |
| pgAdmin | http://localhost:5050 | admin@orientpro.com | admin_dev_2026 |
| MinIO | http://localhost:9001 | orientpro | testminio123456 |
| Production | https://orientpro.co | (kullanici hesabi) | (kullanici sifresi) |
| Grafana | SSH tunel → localhost:3000 | admin | (.env'deki GRAFANA_PASSWORD) |
| Sunucu SSH | ssh root@46.224.208.137 | root | (SSH key) |

---

## Hizli Referans Kartlari

### Lokal Sistem
```
BASLAT:  .\scripts\start-all.ps1          (PowerShell)
DURDUR:  bash ~/orientpro_mobile/scripts/stop-all.sh  (WSL)
DURUM:   bash ~/orientpro_mobile/scripts/status.sh     (WSL)
```

### Production Deploy
```
FRONTEND: .\scripts\deploy.ps1 -Target frontend   (PowerShell)
BACKEND:  .\scripts\deploy.ps1 -Target backend    (PowerShell)
HEPSI:    .\scripts\deploy.ps1 -Target all         (PowerShell)
```

### Acil Durumda (Sunucu)
```
ssh root@46.224.208.137
cd /opt/orientpro

# Loglara bak
docker compose logs --tail=100 backend

# Backend'i yeniden baslat
docker compose restart backend

# Tum sistemi yeniden baslat
docker compose restart

# Veritabani yedekle
docker exec orientpro-db pg_dump -U orientpro orientpro > backup.sql
```
