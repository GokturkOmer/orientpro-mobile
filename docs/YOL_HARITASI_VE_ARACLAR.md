# OrientPro — Yol Haritasi ve Kullanilan Araclar Raporu

> Tarih: 2 Nisan 2026
> Hazirlayan: Claude AI + Gokturk Omer
> Proje: OrientPro — Calisan Egitim & Oryantasyon Platformu (SaaS)

---

## ICINDEKILER

1. [Proje Yasam Dongusu](#1-proje-yasam-dongusu)
2. [Faz 1 — Gelistirme](#2-faz-1--gelistirme)
3. [Faz 2 — Test ve Kalite](#3-faz-2--test-ve-kalite)
4. [Faz 3 — Production Yayinlama](#4-faz-3--production-yayinlama)
5. [Faz 4 — Izleme ve Operasyon](#5-faz-4--izleme-ve-operasyon)
6. [Faz 5 — Bakim ve Hata Giderme](#6-faz-5--bakim-ve-hata-giderme)
7. [Faz 6 — Gelistirme ve Buyume](#7-faz-6--gelistirme-ve-buyume)
8. [Tam Arac Listesi](#8-tam-arac-listesi)
9. [Maliyet Tablosu](#9-maliyet-tablosu)
10. [Ogrenim Yol Haritasi](#10-ogrenim-yol-haritasi)

---

## 1. Proje Yasam Dongusu

```
  GELISTIRME        TEST           YAYINLAMA        IZLEME          BAKIM          BUYUME
  ──────────  →  ──────────  →  ──────────  →  ──────────  →  ──────────  →  ──────────
  Kod yazma      Analiz         Build          Grafana        Hata takip     Yeni ozellik
  Lokal test     CI/CD          Deploy         Log izleme     Guncelleme     Olcekleme
  Debug          Guvenlik       SSL/Domain     Alarm          Yedekleme      Pazarlama
```

---

## 2. Faz 1 — Gelistirme

Bu faz suanda icinde oldugun faz. Kod yazma, ozellik ekleme, lokal test.

### 2.1 Programlama Dilleri

| Dil | Nerede | Neden |
|-----|--------|-------|
| **Dart** | Flutter frontend | Google'in UI dili, tek kodla web + mobil + masaustu |
| **Python 3.12** | FastAPI backend | Hizli API gelistirme, AI/ML ekosistemi genis |
| **SQL** | PostgreSQL sorgulari | Veritabani islemleri |
| **YAML** | Docker Compose, CI/CD | Konfigrasyon dosyalari |
| **Bash** | Scriptler, otomasyon | Linux/WSL komutlari |
| **PowerShell** | Windows scriptleri | Windows tarafinda otomasyon |

### 2.2 Framework ve Kutuphaneler

**Frontend (Flutter/Dart):**

| Arac | Versiyon | Gorevi |
|------|----------|--------|
| Flutter SDK | 3.x | UI framework (web + mobil) |
| Riverpod | 3.x | State management (NotifierProvider) |
| Dio | 5.9.1 | HTTP client (API istekleri) |
| GoRouter | — | Route yonetimi (tanimli ama kullanilmiyor) |
| fl_chart | — | Grafik ve chart gorsellesirme |
| flutter_secure_storage | — | Token ve hassas veri saklama |
| flutter_local_notifications | 20.1.0 | Lokal bildirim (mobil) |
| file_picker | — | Dosya secme (cross-platform) |
| path_provider | — | Platform-specific dosya yollari |

**Backend (Python/FastAPI):**

| Arac | Gorevi |
|------|--------|
| FastAPI | Web framework (async, otomatik API docs) |
| SQLAlchemy 2.x | ORM (veritabani islemleri) |
| Alembic | Veritabani migration (sema degisiklikleri) |
| Pydantic v2 | Veri dogrulama ve sema tanimlama |
| python-jose | JWT token olusturma/dogrulama |
| passlib + bcrypt | Sifre hashleme |
| httpx | Async HTTP client (dis API cagirilari) |
| minio (Python SDK) | Dosya yukleme/indirme |
| chromadb | Vektor veritabani (RAG icin) |
| google-generativeai | Gemini API istemcisi |

### 2.3 Gelistirme Ortami

| Arac | Gorevi | Platform |
|------|--------|----------|
| **VS Code** | Kod editoru | Windows |
| **WSL2 Ubuntu** | Linux ortami (backend) | Windows icinde |
| **Docker Desktop** | Konteyner yonetimi | Windows + WSL2 |
| **Git** | Versiyon kontrolu | Her iki platform |
| **GitHub** | Kod deposu (private repo) | Bulut |
| **GitHub CLI (gh)** | GitHub islemleri terminal'den | Windows |
| **Chrome DevTools** | Frontend debug | Tarayici |
| **Postman / Swagger** | API test | http://localhost:8000/docs |
| **Claude Code** | AI destekli gelistirme | Terminal |

### 2.4 Veritabani ve Depolama

| Arac | Versiyon | Gorevi |
|------|----------|--------|
| **PostgreSQL** | 16 (TimescaleDB) | Ana iliskisel veritabani |
| **Redis** | 7 Alpine | Onbellek, oturum, rate limit |
| **MinIO** | Latest | S3 uyumlu dosya deposu |
| **ChromaDB** | — | Vektor DB (AI embedding) |

### 2.5 AI ve Makine Ogrenimi

| Arac | Gorevi | Konum |
|------|--------|-------|
| **Gemini 2.5 Flash** | LLM — metin uretme, quiz olusturma, chatbot | Google API (bulut) |
| **nomic-embed-text** | Embedding modeli — metin vektorlesirme | Ollama (lokal GPU) |
| **Ollama** | Lokal LLM/embedding calistirma | WSL2 + NVIDIA GPU |
| **ChromaDB** | RAG — vektor arama | Docker konteyner |

---

## 3. Faz 2 — Test ve Kalite

Kod yazildiktan sonra kalite kontrolu.

### 3.1 Statik Analiz

| Arac | Komut | Gorevi |
|------|-------|--------|
| **flutter analyze** | `flutter analyze` | Dart kod analizi (tip hatalari, stil) |
| **Dart formatter** | `dart format .` | Kod biclendirme |
| **Python linter** | `flake8`, `ruff` | Python kod analizi |

### 3.2 CI/CD (Surekli Entegrasyon)

| Arac | Gorevi |
|------|--------|
| **GitHub Actions** | Otomatik test ve build (her push'ta) |

Mevcut CI workflow:
```
Push → flutter analyze → flutter test → flutter build web
```

### 3.3 Test Turleri

| Test Turu | Arac | Aciklama |
|-----------|------|----------|
| Unit test | `flutter test` | Tek fonksiyon/widget testi |
| API test | Swagger UI / Postman | Endpoint dogrulama |
| Manuel test | Chrome + DevTools | Kullanici senaryolari |
| Guvenlik testi | Manuel + OWASP kontrol | IDOR, XSS, injection kontrol |

### 3.4 Gelecekte Eklenebilecek Test Araclari

| Arac | Gorevi | Oncelik |
|------|--------|---------|
| **pytest** | Backend unit/integration test | Yuksek |
| **Flutter integration test** | Ucan uca UI testi | Orta |
| **Sentry** | Hata izleme (production) | Yuksek |
| **Lighthouse** | Web performans olcumu | Orta |

---

## 4. Faz 3 — Production Yayinlama

Kodu sunucuya deploy etme ve canli yayina alma.

### 4.1 Sunucu Altyapisi

| Arac | Detay | Gorevi |
|------|-------|--------|
| **Hetzner CCX13** | 46.224.208.137 | VPS sunucu (2 vCPU, 8GB RAM) |
| **Ubuntu** | 22.04 LTS | Sunucu isletim sistemi |
| **Docker** | 27.x | Konteyner ortami |
| **Docker Compose** | v2 | Coklu konteyner yonetimi |

### 4.2 Web Sunucu ve Guvenlik

| Arac | Gorevi |
|------|--------|
| **Nginx** | 1.27 Alpine — reverse proxy, statik dosya sunma, SSL termination |
| **Let's Encrypt** | Ucretsiz SSL sertifikasi (HTTPS) |
| **Certbot** | SSL sertifika otomatik yenileme |
| **UFW / iptables** | Sunucu guvenlik duvari |

### 4.3 Domain ve DNS

| Arac | Detay |
|------|-------|
| **orientpro.co** | Ana domain |
| **DNS saglayici** | Domain kayitcisi uzerinden A record → 46.224.208.137 |

### 4.4 Deploy Araclari

| Arac | Gorevi |
|------|--------|
| **SCP** | Dosya kopyalama (Flutter build → sunucu) |
| **SSH** | Sunucuya uzaktan erisim |
| **deploy.ps1** | Otomatik deploy scripti (PowerShell) |
| **deploy.sh** | Otomatik deploy scripti (Bash) |
| **Git** | Backend kodu sunucuya cekme |

### 4.5 Deploy Akisi

```
Lokal Gelistirme
      |
      v
flutter analyze (hata kontrolu)
      |
      v
git commit + git push (GitHub'a gonder)
      |
      v
GitHub Actions (CI — otomatik test)
      |
      v
.\scripts\deploy.ps1 (tek komut deploy)
      |
      ├── Frontend: flutter build web → SCP → sunucu
      └── Backend: SSH → git pull → docker compose up --build
      |
      v
Dogrulama: https://orientpro.co aciliyor mu?
```

---

## 5. Faz 4 — Izleme ve Operasyon

Sistem canli olduktan sonra sagligini izleme.

### 5.1 Metrik Toplama

| Arac | Gorevi | Erisim |
|------|--------|--------|
| **Prometheus** | Metrik toplama (CPU, istek sayisi, sure) | localhost:9090 (sunucuda) |
| **Grafana** | Metrik gorsellesirme (dashboard) | SSH tunel → localhost:3000 |

### 5.2 Log Yonetimi

| Yontem | Komut | Ne Gosterir |
|--------|-------|-------------|
| Docker logs | `docker compose logs -f backend` | Backend uygulama loglari |
| Nginx logs | `docker compose logs -f nginx` | HTTP istek loglari |
| Sistem logu | `journalctl -u docker` | Docker servis loglari |

### 5.3 Uptime ve Erisim Kontrolu

| Arac | Gorevi | Maliyet |
|------|--------|---------|
| **UptimeRobot** | Ucretsiz uptime izleme (5dk aralik) | Ucretsiz |
| **Better Stack** | Daha gelismis uptime + alarm | Ucretsiz plan var |
| **curl health check** | Manuel kontrol | Ucretsiz |

### 5.4 Gelecekte Eklenebilecek Izleme Araclari

| Arac | Gorevi | Oncelik |
|------|--------|---------|
| **Sentry** | Hata izleme ve raporlama (exception tracking) | Yuksek |
| **Node Exporter** | Sunucu metrikleri (CPU, RAM, disk) Grafana'da | Orta |
| **Loki** | Merkezi log toplama (Grafana ile) | Dusuk |
| **Alertmanager** | Otomatik alarm (disk dolu, CPU yuksek) | Orta |

---

## 6. Faz 5 — Bakim ve Hata Giderme

### 6.1 Rutin Bakim Islemleri

| Islem | Siklik | Komut/Yontem |
|-------|--------|--------------|
| Veritabani yedekleme | Gunluk | `pg_dump` (otomatik cron) |
| SSL sertifika yenileme | 90 gunde bir | `certbot renew` (otomatik) |
| Docker image guncelleme | Aylik | `docker compose pull && docker compose up -d` |
| Disk temizligi | Aylik | `docker system prune` |
| Log temizligi | Haftalik | Log rotation (otomatik) |
| Guvenlik guncellemeleri | Haftalik | `apt update && apt upgrade` |
| Dependency guncelleme | Aylik | `pip`, `flutter pub upgrade` |

### 6.2 Hata Giderme Araclari

| Arac | Gorevi |
|------|--------|
| **Docker logs** | Konteyner loglarini okuma |
| **pgAdmin** | Veritabani sorgulama ve veri kontrol |
| **Chrome DevTools** | Frontend hata ayiklama |
| **Swagger UI** | API endpoint test (localhost:8000/docs) |
| **SSH** | Sunucuya dogrudan erisim |

### 6.3 Veritabani Bakim

| Islem | Komut | Ne Zaman |
|-------|-------|----------|
| Yedekleme | `docker exec orientpro-db pg_dump -U orientpro orientpro > backup.sql` | Gunluk |
| Geri yukleme | `cat backup.sql \| docker exec -i orientpro-db psql -U orientpro orientpro` | Ihtiyac halinde |
| Migration | `docker compose exec backend alembic upgrade head` | Sema degistiginde |
| VACUUM | `docker exec orientpro-db psql -U orientpro -c "VACUUM ANALYZE;"` | Haftalik |
| Boyut kontrol | `docker exec orientpro-db psql -U orientpro -c "SELECT pg_size_pretty(pg_database_size('orientpro'));"` | Aylik |

---

## 7. Faz 6 — Gelistirme ve Buyume

### 7.1 Sonraki Ozellikler (Yol Haritasi)

| Ozellik | Durum | Araclari |
|---------|-------|----------|
| FCM Push Bildirim | Planli | Firebase Cloud Messaging, firebase_messaging (Flutter) |
| Mobil APK | Planli | Flutter build apk, Google Play Console |
| iOS Uygulama | Planli | Flutter build ios, Apple Developer, Xcode |
| E-posta Bildirimi | Ertelendi | SendGrid API (zaten .env'de var) |
| Multi-tenant Tam Izolasyon | Devam ediyor | PostgreSQL RLS, middleware |
| Dijital Donusum Asistani | Planli | Gemini function calling, chatbot upgrade |
| Odeme Entegrasyonu | Kismen hazir | iyzipay SDK |

### 7.2 FCM Push Bildirim Icin Gerekecek Araclar

| Arac | Gorevi |
|------|--------|
| **Firebase Console** | Proje olusturma, konfigrasyon |
| **firebase_core** (Flutter) | Firebase baglantisi |
| **firebase_messaging** (Flutter) | Push bildirim alma |
| **firebase-admin** (Python) | Backend'den push gonderme |

### 7.3 Mobil Uygulama Yayini Icin Gerekecek Araclar

**Android:**

| Arac | Gorevi |
|------|--------|
| **Android Studio** | APK build, emulator |
| **Google Play Console** | Magaza yayini |
| **Keystore** | APK imzalama |

**iOS (opsiyonel):**

| Arac | Gorevi |
|------|--------|
| **Xcode** | iOS build (Mac gerektirir) |
| **Apple Developer Account** | Magaza yayini ($99/yil) |
| **TestFlight** | Beta test dagiimi |

### 7.4 Olcekleme (Kullanici Arttikca)

| Ihtiyac | Cozum | Ne Zaman |
|---------|-------|----------|
| Daha fazla CPU/RAM | Hetzner sunucu upgrade | 100+ aktif kullanici |
| Veritabani performansi | PostgreSQL tuning, index optimizasyonu | 1000+ kayit |
| Dosya deposu buyumesi | MinIO ayrı sunucu veya S3 | 10GB+ dosya |
| CDN (statik dosyalar) | Cloudflare CDN | Global erisim gerekince |
| Load balancing | Nginx upstream, birden fazla backend | 500+ esanlik kullanici |
| Kubernetes | Container orkestrasyon | Cok buyuk olcek |

---

## 8. Tam Arac Listesi

### Programlama Dilleri (6)
| # | Dil | Kullanim Alani |
|---|-----|----------------|
| 1 | Dart | Frontend (Flutter) |
| 2 | Python | Backend (FastAPI) |
| 3 | SQL | Veritabani sorgulari |
| 4 | YAML | Konfigrasyon |
| 5 | Bash | Linux scriptleri |
| 6 | PowerShell | Windows scriptleri |

### Frameworkler (3)
| # | Framework | Kullanim |
|---|-----------|----------|
| 1 | Flutter 3.x | Cross-platform UI |
| 2 | FastAPI | Python web framework |
| 3 | SQLAlchemy 2.x | Python ORM |

### Veritabani ve Depolama (4)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | PostgreSQL 16 (TimescaleDB) | Ana veritabani |
| 2 | Redis 7 | Onbellek, oturum |
| 3 | MinIO | Dosya deposu (S3 uyumlu) |
| 4 | ChromaDB | Vektor veritabani (RAG) |

### AI Servisleri (3)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | Gemini 2.5 Flash | LLM (metin uretme, chatbot) |
| 2 | nomic-embed-text | Embedding (vektorlestirme) |
| 3 | Ollama | Lokal model calistirma |

### Altyapi ve DevOps (9)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | Docker | Konteyner |
| 2 | Docker Compose | Coklu konteyner yonetimi |
| 3 | Nginx | Web sunucu, reverse proxy |
| 4 | Let's Encrypt | SSL sertifika |
| 5 | GitHub | Kod deposu |
| 6 | GitHub Actions | CI/CD |
| 7 | SSH | Sunucu erisimi |
| 8 | SCP | Dosya transferi |
| 9 | Git | Versiyon kontrolu |

### Izleme (2)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | Prometheus | Metrik toplama |
| 2 | Grafana | Metrik gorsellesirme |

### Gelistirme Araclari (6)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | VS Code | Kod editoru |
| 2 | WSL2 Ubuntu | Linux gelistirme ortami |
| 3 | Chrome DevTools | Frontend debug |
| 4 | pgAdmin | Veritabani yonetimi |
| 5 | Swagger UI | API test |
| 6 | Claude Code | AI destekli gelistirme |

### Sunucu (1)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | Hetzner CCX13 | VPS (2 vCPU, 8GB RAM, Ubuntu) |

### Dis Servisler (3)
| # | Arac | Kullanim |
|---|------|----------|
| 1 | SendGrid | E-posta gonderimi |
| 2 | iyzipay | Odeme isleme |
| 3 | Google Gemini API | AI metin uretme |

**TOPLAM: 37 arac/servis**

---

## 9. Maliyet Tablosu

### Suanki Aylik Maliyetler

| Kalem | Maliyet | Not |
|-------|---------|-----|
| Hetzner CCX13 | ~€15/ay | Sunucu |
| orientpro.co domain | ~$12/yil (~$1/ay) | Domain |
| Gemini API | ~₺0.35/ay | Cok dusuk kullanim |
| GitHub | $0 | Private repo (ucretsiz) |
| Let's Encrypt | $0 | Ucretsiz SSL |
| SendGrid | $0 | Ucretsiz plan (100 mail/gun) |
| **TOPLAM** | **~€16/ay (~₺600/ay)** | |

### Buyume Maliyetleri (Gelecek)

| Kalem | Tahmini | Ne Zaman |
|-------|---------|----------|
| Firebase (FCM Push) | $0 (ucretsiz plan) | Yakin |
| Google Play Console | $25 (tek seferlik) | APK yayini |
| Apple Developer | $99/yil | iOS yayini |
| Sentry (hata izleme) | $0-26/ay | Production |
| Hetzner upgrade | €30-50/ay | 100+ kullanici |
| UptimeRobot | $0 | Uptime izleme |

---

## 10. Ogrenim Yol Haritasi

Arkadaşın veya yeni bir geliştirici için onerilen ogrenme sirasi:

### Seviye 1: Temel Isletme (1-2 hafta)
Sistemi baslatip durdurabilmek, temel yonetim.

| Konu | Kaynak |
|------|--------|
| Git temelleri | https://learngitbranching.js.org |
| Docker temelleri | https://docs.docker.com/get-started |
| Linux terminal (bash) | https://linuxjourney.com |
| SSH kullanimi | `ssh`, `scp` komutlari |
| pgAdmin kullanimi | Bu dokumandaki Bolum 7 |

### Seviye 2: Frontend Gelistirme (2-4 hafta)
Flutter'da degisiklik yapabilmek.

| Konu | Kaynak |
|------|--------|
| Dart dili temelleri | https://dart.dev/guides |
| Flutter temelleri | https://flutter.dev/docs/get-started |
| Riverpod state management | https://riverpod.dev/docs/introduction/getting-started |
| Widget yapisi | Flutter widget catalog |

### Seviye 3: Backend Gelistirme (2-4 hafta)
API'de degisiklik yapabilmek.

| Konu | Kaynak |
|------|--------|
| Python temelleri | https://docs.python.org/3/tutorial |
| FastAPI | https://fastapi.tiangolo.com/tutorial |
| SQLAlchemy | https://docs.sqlalchemy.org/en/20/tutorial |
| PostgreSQL/SQL | https://www.postgresqltutorial.com |

### Seviye 4: DevOps ve Operasyon (1-2 hafta)
Deploy, izleme, sorun giderme.

| Konu | Kaynak |
|------|--------|
| Docker Compose | https://docs.docker.com/compose |
| Nginx | https://nginx.org/en/docs/beginners_guide.html |
| Grafana | https://grafana.com/docs/grafana/latest/getting-started |
| CI/CD (GitHub Actions) | https://docs.github.com/en/actions |

---

## Sonuc

OrientPro, **37 farkli arac ve servis** kullanan, modern mikro-servis mimarisine sahip bir SaaS platformu. Sistem su anda:

- **Gelistirme fazinda** (Faz 1-2): Lokal ortamda aktif gelistirme
- **Production'da canli** (Faz 3): https://orientpro.co erisime acik
- **Temel izleme var** (Faz 4): Prometheus + Grafana kurulu
- **Bakim surecleri tanimli** (Faz 5): Deploy scriptleri, yedekleme komutlari hazir
- **Buyume planlari net** (Faz 6): FCM, mobil uygulama, dijital donusum asistani

Bu dokuman, sistemi baslatmak, yonetmek, sorun gidermek ve gelistirmek icin gereken tum bilgileri icerir.
