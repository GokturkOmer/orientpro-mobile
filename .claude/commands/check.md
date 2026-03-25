# Hizli Kontrol

Kod degisikliginden sonra hizli kontrol yapar. Tam test icin `/test` kullan.

## Yapilacaklar

1. `flutter analyze` calistir — sadece error ve warning'leri goster
2. Son degisen dosyalari kontrol et (`git diff --name-only`)
3. Degisen dosyalarda yasak pattern var mi kontrol et:
   - `setState` kullanimi
   - `StateProvider` / `ChangeNotifier`
   - Hardcoded renk degerleri (Color(0x ile baslayan, theme kullanilmali)
   - Kullanilmayan import
4. Sonucu kisa ve net raporla:

```
## Hizli Kontrol Sonucu
- Analiz: X error, Y warning
- Degisen dosya: Z adet
- Yasak pattern: [YOK / liste]
- Durum: [OK / DUZELTME GEREKLI]
```

Sorun varsa duzeltme onerisi sun. Sorun yoksa "Degisiklikler temiz, devam edebilirsin" de.
