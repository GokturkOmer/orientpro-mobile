# OrientPro Projesi

## Tech Stack
- **Backend**: FastAPI (Python 3.12), PostgreSQL 16 (TimescaleDB), Redis 7, Docker
- **Frontend**: Flutter 3.x (Web + cross-platform ready), Dart
- **State Management**: Riverpod 3.x (NotifierProvider kullan, StateProvider/ChangeNotifier YASAK)
- **HTTP Client**: Dio 5.9.1 — auth gerektiren istekler `authDioProvider` uzerinden yapilir
- **AI**: Gemini 2.5 Flash (API) + nomic-embed-text (Ollama, lokal GPU), ChromaDB (RAG)
- **Ortam**: Backend WSL2 Ubuntu (Docker), Frontend Windows

## Dosya Konumlari
- **Backend**: `~/orientpro/backend/` (WSL2 icinden) veya `\\wsl.localhost\Ubuntu\home\orientpro\orientpro\backend\`
- **Flutter**: `C:\Users\omera\orientpro_mobile\`
- **ChromaDB verisi**: `~/orientpro/backend/data/chromadb/` (/tmp DEGIL)
- **Proje dokumani**: `C:\Users\omera\Downloads\OrientPro_Proje_Ozeti.md`

## GitHub
- **Repo:** https://github.com/GokturkOmer/orientpro-mobile (private)
- **Push:** `"/c/Program Files/GitHub CLI/gh.exe" auth setup-git && git push origin main`

## Production
- **URL**: https://orientpro.co (Hetzner CCX13, 46.224.208.137)
- **Deploy path**: `/opt/orientpro/` (backend + frontend + docker-compose)
- **Web deploy path**: `/opt/orientpro/frontend/web/` (nginx serves this)
- **Web build**: `flutter build web --release --dart-define=TUNNEL=true` (TUNNEL=true zorunlu — relative `/api/v1` kullanir)

## Development & Deploy Kurallari

### TEMEL KURAL: Production sunucusunda ASLA dogrudan kod duzenleme yapma!
1. Tum gelistirme LOKAL ortamda yapilir
2. Test edilir, commit edilir, push edilir
3. Deploy SADECE git'ten cekilir veya build artifact kopyalanir

### Deploy Checklist
- [ ] Lokal test gecti mi?
- [ ] `flutter analyze` temiz mi?
- [ ] Git commit + push yapildi mi?
- [ ] Web build: `flutter build web --release --dart-define=TUNNEL=true`
- [ ] Backend: SSH ile sunucuda `cd /opt/orientpro && git pull && docker-compose up -d --build`
- [ ] Frontend: `scp -r build/web/* root@46.224.208.137:/opt/orientpro/frontend/web/`
- [ ] Deploy sonrasi dogrulama yapildi mi?

### Acil Durumda (Hotfix)
- Sunucuda SADECE tek satirlik degisiklik yapilabilir
- Hemen lokal repoya da ayni degisiklik yapilip commit edilmeli
- Bir sonraki deploy'da tekrar uzerine yazilmasini onle

## Komutlar

### Backend
```bash
# WSL2 terminalinde:
cd ~/orientpro && docker-compose up -d          # Tum servisleri baslat
docker-compose logs -f backend                   # Backend loglarini izle
docker-compose down                              # Servisleri durdur
docker-compose restart backend                   # Sadece backend restart
```

### Frontend
```powershell
# Windows PowerShell/CMD:
cd C:\Users\omera\orientpro_mobile
flutter run -d chrome                            # Web debug modunda calistir
flutter analyze                                  # Statik analiz
flutter build web --release --dart-define=TUNNEL=true  # Production web build
```

## API Yapilandirmasi
- **Web (development)**: `http://localhost:8000/api/v1`
- **Mobile (emulator)**: `http://10.0.2.2:8000/api/v1`
- CORS: `allow_origin_regex` ile localhost/127.0.0.1 tum portlari kabul eder
- JWT Bearer authentication — tum endpoint'ler `get_current_user` veya `get_admin_user` ile korunur

## Kodlama Kurallari

### Python (Backend)
- `datetime.now(timezone.utc)` kullan — `datetime.utcnow()` **YASAK**
- API response'larda Turkce hata mesajlari kullan
- Auth: `from app.core.security import get_current_user, get_admin_user`
- Admin roller: `admin`, `facility_manager`, `chief_technician`

### Flutter (Frontend)
- Riverpod 3.x: `NotifierProvider` kullan (StateProvider/ChangeNotifier DEGIL)
- Auth gerektiren HTTP isteklerinde `ref.read(authDioProvider)` kullan, manuel header ekleme
- 401 hatasi otomatik logout tetikler (auth_dio.dart interceptor)
- Dosya islemleri icin `file_picker` paketi kullan (dart:html DEGIL — cross-platform APK destegi icin)
- UI dili: Turkce (tum ekranlar, butonlar, mesajlar)
- Tema: SCADA theme — koyu (ScadaColors, primary cyan #00d4ff) + acik tema (toggle + persist)
- Navigation: Named routes (GoRouter bagimlilik var ama kullanilmiyor)

## Moduller
1. SCADA Monitoring (Modbus TCP, 5 unite, 24 sensor)
2. AI Fault Prediction (Z-Score, trend, health score)
3. QR Tour System (3 rota, 18 checkpoint)
4. Digital Twin (5 zone, canli sensor renk kodlamasi)
5. Notification/Alarm System (6 kategori, 3 seviye)
6. Equipment & Work Order Management (284 ekipman, 9 kategori, SLA)
7. AI Chatbot (RAG, Gemini 2.5 Flash API + nomic-embed-text lokal, ChromaDB)
8. Orientation/Training Platform (yeni ana modul — egitim, quiz, rota, dashboard)

## Stratejik Not
- SCADA modulleri "premium add-on" olarak korunuyor
- Ana odak: Orientation/training platformu
- Hedef sektorler: Oteller, hastaneler, fabrikalar, restoranlar
