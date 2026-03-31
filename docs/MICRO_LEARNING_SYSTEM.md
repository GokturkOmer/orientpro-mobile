# OrientPro Mikro-Ogrenme Sistemi — Teknik Dokuman

## 1. Nedir?

Mikro-ogrenme, calisanlara kisa bilgi kartlari ve quizler araciligiyla egitim veren bir sistemdir. Iki farkli modda calisir:

| | Onboarding (Otomatik) | Manager (Yonetici Atamasi) |
|---|---|---|
| **Tetikleme** | Calisan ilk giris yaptiginda otomatik | Yonetici admin panelinden atar |
| **Kapsam** | Genel oryantasyon rotasi (is_default_onboarding) | Herhangi bir rota veya tek modul |
| **Tempo** | Haftalik (7 gunde 1 konu) | Gunluk (her gun 1 konu) |
| **Bildirim/gun** | 1 (sabah slotu) | 3 (sabah/ogle/aksam) |
| **Quiz zamani** | Haftanin 7. gunu | Her gun sonunda |
| **Basarisizlik** | Gelecek hafta farkli aci ile tekrar | Yarin farkli aci ile tekrar |
| **Gecince ilerleme** | Rota ici otomatik sonraki modul | Kapsam ici otomatik sonraki modul |
| **Kapsam bitince** | Rota tamamlanir, durur | Atama biter, durur |

---

## 2. Taraflar Icin Akis

### 2.1 Calisan Akisi

```
Calisan giris yapar
    |
    ├── [Onboarding modu]
    |   Login hook (auth.py) → auto_assign_onboarding() cagirilir
    |   is_default_onboarding=true rotasinin ilk modulu atanir
    |   mode="onboarding", shift_type="A" (varsayilan)
    |
    ├── [Manager modu]
    |   Yonetici admin panelden atar
    |   mode="manager", shift_type yonetici secer
    |
    ▼
Calisan "Bugunku Egitimim" kartina tiklar (orientation_dashboard)
    |
    ▼
TodayScreen acilir → GET /micro-learning/today/{user_id}?mode=...
    |
    ├── Kartlar listelenir (3 kart: sabah/ogle/aksam)
    |   Karta tikla → icerik genisler → "okundu" isareti
    |
    ├── Tum kartlar okundu mu?
    |   Evet + quiz zamani geldi mi?
    |   (onboarding: haftanin 7. gunu, manager: her gun)
    |       |
    |       ▼
    |   "Quize Basla" butonu aktif olur
    |   Gunluk 3 deneme hakki gosterilir
    |       |
    |       ▼
    |   Quiz ekrani acilir (/quiz)
    |   Sorular cevaplanir → POST /micro-learning/quiz/{assignment_id}/submit
    |       |
    |       ├── GECTI
    |       |   assignment.status = "completed"
    |       |   Rozet verilir (rotadaki ilk modul ise)
    |       |   Kapsam ici sonraki modul otomatik atanir (mode korunur)
    |       |   MicroQuizResultScreen → "Tebrikler!" mesaji
    |       |
    |       └── KALDI
    |           assignment.status = "failed_retry"
    |           content_angle += 1 (farkli acidan icerik)
    |           MicroQuizResultScreen → "Neredeyse!" mesaji
    |           Onboarding: gelecek hafta tekrar
    |           Manager: yarin tekrar
    |
    └── Atama yoksa: "Henuz bir egitim atanmamis" mesaji
```

### 2.2 Yonetici (Admin) Akisi

```
Admin giris yapar → Admin Dashboard
    |
    ├── "Mikro-Ogrenme Ata" quick action
    |   MicroLearningAssignScreen acilir (4 adimli wizard)
    |   |
    |   ├── Adim 1: Rota sec → Modul sec (checkbox)
    |   ├── Adim 2: Calisan sec (departman filtresi, toplu secim)
    |   ├── Adim 3: Vardiya sec (A/B/C — bildirim saatleri gosterilir)
    |   └── Adim 4: Ozet + Onayla → POST /micro-learning/assign
    |       mode="manager" olarak kaydedilir
    |
    ├── "Egitim Sonuclari" quick action
    |   MicroLearningResultsScreen acilir
    |   |
    |   ├── Filtreleme: departman, durum (active/completed/failed_retry)
    |   ├── Istatistik satiri: toplam, aktif, tamamlanan, tekrar
    |   ├── Atama kartlari: kullanici, modul, durum, quiz sonucu, tarihler
    |   └── Karta tikla → Detay bottom sheet (acknowledgment gecmisi)
    |
    └── Genel oryantasyon atamalari da burada gorulur (mode="onboarding")
```

### 2.3 Sistem (Arka Plan)

```
Scheduler (her 6 saatte bir):
    |
    ├── generate_daily_drip_notifications()
    |   Tum aktif atamalara bildirim olusturur
    |   Onboarding: 1 bildirim/gun (sabah slotu)
    |   Manager: 3 bildirim/gun (sabah/ogle/aksam)
    |   Tekrar bildirim olusturmaz (ayni gun/slot)
    |
    └── (Gunluk) calculate_monthly_leaderboard()
        Onceki ayin top 3 calisanina rozet verir
```

---

## 3. Veritabani Yapisi

### 3.1 micro_learning_assignments
| Kolon | Tip | Aciklama |
|---|---|---|
| id | UUID PK | |
| organization_id | UUID FK | Tenant izolasyon |
| assigned_by | UUID FK | Atayan kisi (onboarding'de kendisi) |
| user_id | UUID FK | Atanan calisan |
| module_id | UUID FK | Egitim modulu |
| route_id | UUID FK (nullable) | Rota baglantisi |
| status | String(20) | active / completed / failed_retry |
| learning_day | int | Baslangic gunu (simdi dinamik hesaplaniyor) |
| quiz_passed | bool | Quiz gecildi mi |
| quiz_attempts | int | Toplam deneme sayisi |
| content_angle | int | 1=ilk icerik, 2+=farkli aci (basarisizlik sonrasi) |
| shift_type | String(1) | A, B, C vardiya |
| mode | String(20) | "onboarding" veya "manager" |
| started_date | Date | Atama baslangic tarihi |
| completed_date | Date (nullable) | Tamamlanma tarihi |
| **UniqueConstraint** | | (user_id, module_id, organization_id, mode) |

### 3.2 drip_content_cards
| Kolon | Tip | Aciklama |
|---|---|---|
| id | UUID PK | |
| organization_id | UUID FK | |
| module_id | UUID FK | Hangi module ait |
| card_type | String(20) | "content" veya "quiz" |
| day_number | int | Konu numarasi (hafta veya gun) |
| slot | String(10) | morning / noon / evening |
| content_angle | int | Icerik acisi (1=varsayilan) |
| title | String(200) | Kart basligi |
| body | Text | Icerik metni |
| card_order | int | Siralama |

### 3.3 monthly_leaderboard
Aylik en basarili 3 calisanin rozet kaydi.

---

## 4. API Endpoint Listesi

### Calisan
| Metod | Endpoint | Aciklama |
|---|---|---|
| GET | /micro-learning/today/{user_id}?mode= | Bugunku kartlar + quiz durumu |
| POST | /micro-learning/card/{card_id}/read | Karti okundu isaretle |
| POST | /micro-learning/quiz/{assignment_id}/submit | Quiz coz |
| GET | /micro-learning/progress/{user_id} | Tum ilerleme |

### Yonetici
| Metod | Endpoint | Aciklama |
|---|---|---|
| POST | /micro-learning/assign | Modul ata (mode=manager) |
| GET | /micro-learning/assignments?status=&department= | Atamalari listele |
| DELETE | /micro-learning/assignments/{id} | Atamayi iptal et |
| POST | /micro-learning/cards | Icerik karti olustur |
| GET | /micro-learning/cards/{module_id} | Modulu kartlarini listele |

---

## 5. Flutter Dosya Yapisi

```
lib/
  models/
    micro_learning.dart          # DripCard, MicroAssignment, TodayData, MicroQuizResult, MicroProgress
  providers/
    micro_learning_provider.dart # MicroLearningNotifier (Riverpod 3.x)
  screens/
    orientation/
      today_screen.dart          # Calisan: bugunku egitim ekrani
      micro_quiz_result_screen.dart # Quiz sonuc ekrani
      quiz_screen.dart           # Quiz cozme ekrani (training ile paylasimli)
    admin/
      micro_learning_assign_screen.dart  # 4 adimli atama wizard
      micro_learning_results_screen.dart # Sonuclar + detay
  services/
    local_notification_service.dart      # Bildirim (su an placeholder)
```

---

## 6. Backend Dosya Yapisi

```
app/
  models/
    micro_learning.py           # 3 tablo: assignments, drip_cards, leaderboard
  schemas/
    micro_learning.py           # Pydantic request/response
  services/
    micro_learning_service.py   # 2 modlu is mantigi (EN ONEMLI DOSYA)
  api/v1/routers/
    micro_learning.py           # 9 endpoint
    auth.py                     # Login hook (auto_assign_onboarding)
    training.py                 # Quiz submit hook (MicroLearningAssignment guncelleme)
  tasks/
    micro_learning_tasks.py     # Scheduler task sarmalayicilari
    scheduler.py                # Periyodik gorevler (6 saatte bir bildirim, gunluk liderlik)
alembic/versions/
    micro_001_*.py              # Migration: 3 tablo + is_default_onboarding kolonu
```

---

## 7. Tespit Edilen Sorunlar ve Riskler

### KRITIK

#### 7.1 Card Read Tracking Calismiyormark_card_read endpointi
**Dosya:** `micro_learning_service.py` satir ~170, `micro_learning.py` (router) satir ~178
**Sorun:** `cards_read` her zaman 0 donuyor. Backend'de kart okuma kaydi tutulmuyor.
```python
cards_read = 0  # TODO: card_reads tablosu ile takip
```
**Etki:**
- `quiz_available` hesabi backend'de her zaman `False` donuyor (`0 >= cards_total` = False)
- Flutter tarafinda `markCardRead` cagirildiginda lokal state guncelleniyor ama sayfa yenilenince sifirlanir
- Onboarding modunda sorun daha buyuk: `day_in_period >= 6` VE `cards_read >= cards_total` — ikisi de gecmeli
**Cozum:** Ya bir `card_reads` tablosu olusturup backend'de takip et, ya da quiz_available hesabini Flutter'a birak (su anki gibi).

#### 7.2 IDOR: /today/{user_id} ve /progress/{user_id}
**Dosya:** `micro_learning.py` (router) satir 162-168, 225-231
**Sorun:** Herhangi bir authenticated kullanici, ayni organizasyondaki baska bir calisanin verilerine erisebilir. `current_user.id == user_id` kontrolu yok.
**Etki:** Gizlilik ihlali — bir calisan baska bir calisanin egitim durumunu gorebilir.
**Cozum:** Endpoint'lere `if current_user.id != user_id and not RoleHelper.isAdmin(current_user.role)` kontrolu ekle.

#### 7.3 Quiz Ekrani Cift Yol Sorunu
**Dosya:** `quiz_screen.dart`, `training.py` (router)
**Sorun:** Mikro-ogrenme quizi `/quiz` rotasina gidiyor ve `trainingProvider.notifier.submitQuiz()` kullaniliyor — bu training endpoint'ine (`POST /training/quiz-results`) gidiyor. Training endpoint'indeki hook MicroLearningAssignment'i guncelliyor. Ancak `microLearningProvider.notifier.submitQuiz()` FARKLI bir endpoint'e (`POST /micro-learning/quiz/{assignment_id}/submit`) gidiyor.
**Etki:** Su an calisan akis training endpoint'ini kullaniyor, mikro-ogrenme endpoint'i kullanilmiyor. Iki endpoint farkli mantik isliyor:
- Training endpoint: sadece status degistirir, sonraki modulu atamaz
- Mikro-ogrenme endpoint: status + sonraki modul atamasi + rozet + mod bazli mesajlar
**Sonuc:** Calisan quiz'i gectiginde sonraki modul ATANMIYOR cunku yanlis endpoint kullaniliyor.
**Cozum:** quiz_screen.dart'ta mikro-ogrenme argumanlarini aldiginda `microLearningProvider.notifier.submitQuiz()` kullanan ayri bir submit akisi olustur.

#### 7.4 Multi-Org Login'de Onboarding Hook Eksik
**Dosya:** `auth.py`
**Sorun:** `auto_assign_onboarding` hook'u sadece 0-org ve 1-org login yollarinda var. Birden fazla organizasyonu olan kullanicilarin org secimi sonrasindaki login yolunda (`POST /auth/select-organization`) hook yok.
**Etki:** Multi-org kullanicilar icin onboarding atamasi yapilmaz.
**Cozum:** `select-organization` endpoint'ine de ayni hook'u ekle.

### ORTA

#### 7.5 learning_day Model vs Hesaplanan Deger Uyumsuzlugu
**Dosya:** `micro_learning_service.py`
**Sorun:** Model'de `learning_day` kolonu var (default 1) ama `get_today_cards` fonksiyonu `started_date`'ten dinamik hesapliyor (`current_period`). Model'deki deger hic guncellenmemiyor.
**Etki:** `get_progress` fonksiyonu model'deki `learning_day` (hep 1) dondurur, `get_today_cards` ise hesaplanan degeri dondurur. Tutarsizlik.
**Cozum:** Ya learning_day'i model'den kaldir (tamamen dinamik), ya da her quiz/kart isleminde guncelle.

#### 7.6 Content Angle Icerigi Olmayabilir
**Dosya:** `micro_learning_service.py`
**Sorun:** Basarisizlikta `content_angle += 1` yapiliyor. Ama `drip_content_cards` tablosunda o `content_angle` degeri icin icerik olmayabilir.
**Etki:** Calisan bosistemi gorebilir — kartlar gelmiyor, quiz yok.
**Cozum:** Fallback: content_angle icin icerik yoksa angle=1'e geri don.

#### 7.7 Audit Logging Eksikligi
**Dosya:** `micro_learning.py` (router)
**Sorun:** Sadece `POST /assign` endpoint'inde `log_action` var. Quiz submit, cancel assignment, card create gibi aksiyonlarda audit kaydedilmiyor.
**Etki:** Admin takibi eksik.
**Cozum:** Tum write endpoint'lerine `log_action` ekle.

#### 7.8 Admin Results Ekrani Dogrudan Dio Kullaniyor
**Dosya:** `micro_learning_results_screen.dart`
**Sorun:** Provider yerine dogrudan `ref.read(authDioProvider).get(...)` kullaniliyor.
**Etki:** Pattern tutarsizligi. State yonetimi, cache, hata yonetimi eksik.
**Cozum:** Provider'a `loadAssignments` metodu ekle, ekrandan cagir.

### DUSUK

#### 7.9 model_validator'da AttributeError Riski
**Dosya:** `training.py` (schemas)
**Sorun:** `data.module.title` ifadesi `title` attribute'u yoksa hata firlatabilir.
**Cozum:** `getattr(data.module, 'title', None)` kullan.

#### 7.10 AcknowledgmentWithUserResponse'da Duplicate module_title
**Dosya:** `training.py` (schemas)
**Sorun:** Parent class'a `module_title` eklendi ama child class'ta da ayni alan var.
**Etki:** Calisiyor ama gereksiz override.
**Cozum:** Child class'tan `module_title` satirini kaldir.

---

## 8. Kart Icerik Yapisi (drip_content_cards)

Kartlar soyle organize edilmelidir:

### Onboarding Modu (Haftalik)
```
day_number=1 (Hafta 1), content_angle=1:
  slot=morning, card_order=0: "Is Guvenligi Temelleri"
  slot=noon,    card_order=1: "Yangin Cikisi Nerede?"
  slot=evening, card_order=2: "Acil Durum Proseduru"

day_number=2 (Hafta 2), content_angle=1:
  slot=morning, card_order=0: "Hijyen Kurallari"
  ...
```

### Manager Modu (Gunluk)
```
day_number=1 (Gun 1), content_angle=1:
  slot=morning, card_order=0: "Sabah Karti"
  slot=noon,    card_order=1: "Ogle Karti"
  slot=evening, card_order=2: "Aksam Karti"

day_number=2 (Gun 2), content_angle=1:
  ...
```

### Basarisizlik Sonrasi (content_angle=2)
```
day_number=1, content_angle=2:
  slot=morning: "Is Guvenligi — Farkli Bakis"
  ...
```

---

## 9. Guvenlik Ozeti

| Alan | Durum | Not |
|---|---|---|
| Authentication | OK | Tum endpoint'lerde Depends(get_current_user) veya require_permission |
| Tenant Izolasyon | OK | Tum sorgularda organization_id filtresi |
| IDOR | SORUNLU | /today/{user_id} ve /progress/{user_id} acik (7.2) |
| SQL Injection | OK | SQLAlchemy ORM, raw SQL yok |
| Rate Limiting | OK | Tum endpoint'lerde (30-60/min) |
| Audit Trail | EKSIK | Sadece 1 endpoint'te log_action var (7.7) |
| Login Hook | EKSIK | Multi-org login yolunda hook yok (7.4) |
| Quiz Yolu | SORUNLU | Yanlis endpoint kullaniliyor (7.3) |

---

## 10. Oncelik Sirasi

1. **7.3 Quiz Cift Yol** — En kritik, gecen calisan icin sonraki modul atanmiyor
2. **7.1 Card Read Tracking** — Quiz butonu dogru calismasi icin gerekli
3. **7.2 IDOR** — Gizlilik ihlali
4. **7.4 Multi-Org Hook** — Bazi kullanicilar icin onboarding calismaz
5. **7.6 Content Angle Fallback** — Bos ekran onleme
6. **7.5 learning_day Tutarsizligi** — Veri tutarliligi
7. **7.7 Audit Logging** — Takip eksikligi
8. **7.8-7.10** — Kod kalitesi iyilestirmeleri
