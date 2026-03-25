# OrientPro Test Skill

Bu skill her calistirildginda projenin kapsamli testini yapar.

## Yapilacak Testler

### 1. Flutter Statik Analiz
`flutter analyze` calistir ve sonuclari raporla. Error ve warning varsa listele.

### 2. Backend API Kontrolu
Backend'in calisip calismadigini kontrol et:
- `curl -s http://localhost:8000/api/v1/health` endpoint'ini kontrol et
- Yanit 200 degilse "Backend calismiyoor" uyarisi ver

### 3. Kod Kalitesi Kontrolleri
Su dosyalari tara ve sorunlari raporla:
- `lib/` altinda kullanilmayan import'lari bul (grep "^import" ile)
- `setState` kullanan dosyalari bul (yasak pattern)
- `StateProvider` veya `ChangeNotifier` kullanan dosyalari bul (yasak pattern)
- `datetime.utcnow()` kullanan backend dosyalarini bul (yasak pattern)
- Manuel header ekleme yapan yerleri bul (`"Authorization"` string'i iceren dart dosyalari)

### 4. Guvenlik Kontrolleri
- Hardcoded sifre veya API key arla (grep "password.*=.*\"" ve "api_key.*=.*\"")
- `.env` dosyasinin `.gitignore`'da oldugundan emin ol
- CORS ayarlarini kontrol et (backend main.py'de allow_origins)

### 5. Build Testi
`flutter build web --no-tree-shake-icons` calistir ve basarili olup olmadigini raporla.

## Rapor Formati

Sonuclari su formatta raporla:

```
## OrientPro Test Raporu

### Statik Analiz: [BASARILI/BASARISIZ]
- X error, Y warning, Z info

### Backend API: [AKTIF/KAPALI]
- Health check durumu

### Kod Kalitesi: [TEMIZ/SORUNLU]
- Sorunlu dosya listesi (varsa)

### Guvenlik: [GUVENLI/RISKLI]
- Risk listesi (varsa)

### Build: [BASARILI/BASARISIZ]
- Hata detaylari (varsa)

### Genel Durum: [SAGLAM/DIKKAT GEREKIYOR/KRITIK]
```

Her test basarisiz oldugunda cozum onerisi de sun.
