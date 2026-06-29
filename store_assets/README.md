# PUCKET — Store Screenshots

## Hazır dosyalar

| Klasör | Boyut | Kullanım |
|--------|-------|----------|
| `final/iphone_6.7/` | 1290×2796 | App Store — iPhone 6.7" (15 Pro Max, 16 Pro Max…) |
| `final/iphone_6.5/` | 1284×2778 | App Store — iPhone 6.5" |
| `final/android/` | 1080×1920 | Google Play — telefon ekran görüntüleri |
| `final/screens_only/` | 1170×2532 | Sadece uygulama ekranı (çerçevesiz) |
| `final/feature_graphic/` | 1024×500 | Google Play — Feature Graphic |

## İçerik (6 ekran)

1. **01_hero** — Logo + marka tanıtımı
2. **02_menu** — Ana menü, dereceli/hızlı maç
3. **03_gameplay** — Oyun tahtası, disk fırlatma
4. **04_ranked** — ELO / lig sistemi
5. **05_match** — Rakip eşleşmesi
6. **06_login** — Google / Apple / misafir giriş

## Yeniden üretmek

```bash
./tools/generate_store_assets.sh
```

## Store yükleme notları

- **App Store Connect:** En az 3 ekran görüntüsü, `iphone_6.7` klasöründen yükle.
- **Google Play Console:** En az 2 telefon SS (`android/`) + Feature Graphic (`feature_graphic/`).
- Sıralama önerisi: hero → gameplay → ranked → match → menu → login
