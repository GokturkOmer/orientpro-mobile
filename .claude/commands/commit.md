# Guvenli Commit

Commit atmadan once kontrol yapar, sorun yoksa commit atar.

## Adimlar

1. Once `/check` mantigini calistir (flutter analyze + yasak pattern kontrolu)
2. Eger error varsa commit YAPMA, hatalari listele
3. Error yoksa:
   - `git status` ile degisiklikleri goster
   - `git diff --stat` ile degisen dosya ozetini goster
   - Degisiklikleri analiz edip Turkce commit mesaji olustur
   - Kullaniciya commit mesajini goster ve onay iste
   - Onay gelirse commit at
   - `git log --oneline -1` ile dogrulamanistir

## Commit Mesaji Kurallari
- Turkce yaz
- Kisa ve aciklayici ol
- Basinda tur belirt: feat:, fix:, refactor:, docs:, style:, test:, chore:
- Ornek: "feat: kullanim analitigi ekrani eklendi"
