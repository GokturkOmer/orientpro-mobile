# OrientPro Projesi

## Tech Stack
- **Backend**: FastAPI (Python 3.11), PostgreSQL 16 (TimescaleDB), Redis 7, Docker
- **Frontend**: Flutter 3.x (Web + cross-platform ready), Dart
- **State Management**: Riverpod 3.x (NotifierProvider kullan, StateProvider/ChangeNotifier YASAK)
- **HTTP Client**: Dio 5.9.1 — auth gerektiren istekler `authDioProvider` uzerinden yapilir
- **AI**: Ollama + Gemma3 4B (GPU), ChromaDB (RAG)
- **Ortam**: Backend WSL2 Ubuntu (Docker), Frontend Windows

## Dosya Konumlari
- **Backend**: `~/orientpro/backend/` (WSL2 icinden) veya `\\wsl.localhost\Ubuntu\home\orientpro\orientpro\backend\`
- **Flutter**: `C:\Users\omera\orientpro_mobile\`
- **ChromaDB verisi**: `~/orientpro/backend/data/chromadb/` (/tmp DEGIL)
- **Proje dokumani**: `C:\Users\omera\Downloads\OrientPro_Proje_Ozeti.md`

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
- Dosya islemleri icin `dart:html` kullan (file_picker DEGIL)
- UI dili: Turkce (tum ekranlar, butonlar, mesajlar)
- Tema: Dark SCADA theme (primary green #1B5E20)
- Navigation: Named routes (GoRouter bagimlilik var ama kullanilmiyor)

## Moduller
1. SCADA Monitoring (Modbus TCP, 5 unite, 24 sensor)
2. AI Fault Prediction (Z-Score, trend, health score)
3. QR Tour System (3 rota, 18 checkpoint)
4. Digital Twin (5 zone, canli sensor renk kodlamasi)
5. Notification/Alarm System (6 kategori, 3 seviye)
6. Equipment & Work Order Management (284 ekipman, 9 kategori, SLA)
7. AI Chatbot (RAG, Gemma3 4B, PDF datasheet arama)
8. Orientation/Training Platform (yeni ana modul — egitim, quiz, rota, dashboard)

## Stratejik Not
- SCADA modulleri "premium add-on" olarak korunuyor
- Ana odak: Orientation/training platformu
- Hedef sektorler: Oteller, hastaneler, fabrikalar, restoranlar
