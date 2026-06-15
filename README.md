# PUCKET Flutter

Orijinal web uygulamasının (`pucket-final`) Flutter sürümü.

## Özellikler

- 🎯 Disk fırlatma oyunu (Canvas/CustomPainter fizik motoru)
- 🌐 Online çok oyunculu (WebSocket — orijinal `server.js` ile uyumlu)
- 🏆 Ranked ELO eşleştirme
- 🤖 Bot modu (Kolay / Orta / Zor)
- 🔑 Oda kodu ile arkadaşla oynama
- 🔐 Firebase Google giriş + misafir modu
- 🏅 Lig sistemi ve sıralama tablosu

## Gereksinimler

- Flutter 3.44+
- Node.js (backend sunucusu için)

## Hızlı başlangıç

### 1. Sunucuyu başlat (online mod için)

```bash
cd "/Users/ismail/Downloads/pucket-final 17"
npm start
```

### 2. Uygulamayı çalıştır

**macOS / iOS simülatör:**
```bash
cd ~/Projects/pucket_flutter
flutter run
```

**Android emülatör** (sunucu adresi otomatik `10.0.2.2`):
```bash
flutter run
```

**Gerçek telefon** (aynı Wi-Fi):
```bash
flutter run --dart-define=WS_URL=ws://192.168.x.x:8080
```

### Sunucu olmadan oynama

Menüden **🤖 BİLGİSAYARA KARŞI** seç — sunucu gerekmez.

Hızlı eşleştir / ranked: sunucu yoksa otomatik bot moduna geçer.

## Google ile giriş (Firebase)

Mobil (iOS/Android) için Firebase yapılandırması gerekir. **Tek seferlik kurulum:**

```bash
cd ~/Projects/pucket_flutter
bash tool/setup_firebase.sh
```

Bu script:
1. Firebase CLI ile giriş yapar (tarayıcı açılır)
2. `pucket-9413c` projesine iOS + Android uygulamalarını ekler
3. `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` oluşturur
4. iOS `Info.plist` URL scheme'lerini ayarlar

Kurulumdan sonra:

```bash
flutter run
```

**Web** (`flutter run -d chrome`) Google girişi Firebase web config ile doğrudan çalışır.

**Misafir modu** Firebase olmadan her zaman kullanılabilir.

## Proje yapısı

```
lib/
├── game/           # Fizik, AI bot, oyun kontrolcüsü
├── models/         # Disc, UserProfile, RankTier
├── screens/        # Auth, Menu, Game, Queue, Lobby...
├── services/       # Auth, WebSocket, Settings
└── widgets/        # GameBoard, GamePainter, PucketButton
```

## Oyun kuralları

- Kendi renkli disklerini rakibin sahasına geçir
- **Best of 3**: 2 round kazanan maçı alır
- Ranked maçlarda ELO puanı güncellenir
