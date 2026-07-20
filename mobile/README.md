# LifeOS Mobile (Flutter)

LifeOS web uygulamasının iPhone/Android karşılığı. Sol tarafta gizlenebilir bir
sidebar (Drawer) üzerinden **Daily**, **Görevler**, **Life**, **Second Brain**
kategorilerine geçilir; her ekrandan tek dokunuşla **Z-Asistan** (ayrı sohbet
ekranı) ve **Takvim**'e (aylık görünüm) ulaşılabilir. Tüm veriler mevcut
FastAPI backend'i (`backend/api.py`) üzerinden Notion'a bağlanır.

## 1) Flutter SDK kurulumu

Bu proje kodu (`lib/`, `pubspec.yaml`) hazır, ama platforma özgü klasörler
(`ios/`, `android/`) Flutter CLI olmadan üretilemedi. Kuruluma buradan devam
edin:

1. https://docs.flutter.dev/get-started/install adresinden Flutter SDK'yı
   kurun (Windows için) ve `flutter doctor` ile doğrulayın.
2. Bu klasörde (`mobile/`) şu komutu çalıştırın:

   ```bash
   flutter create --org com.lifeos --project-name lifeos_mobile .
   ```

   Bu komut mevcut `lib/`, `pubspec.yaml` dosyalarınıza dokunmaz; sadece
   eksik olan `ios/`, `android/`, `web/` gibi platform klasörlerini
   oluşturur.
3. Bağımlılıkları indirin:

   ```bash
   flutter pub get
   ```

## 2) iOS için önemli not

Gerçek bir iPhone'a kurulum ya da TestFlight/App Store dağıtımı için Apple,
**macOS + Xcode** zorunlu tutar — Windows'tan doğrudan `.ipa` derlenemez.

- Geliştirme/test bu Windows makineden mümkün: Android emülatör, Chrome
  (`flutter run -d chrome`) veya Windows masaüstü (`flutter run -d windows`).
- Gerçek iPhone'da denemek/TestFlight'a yüklemek için ileride: bir Mac'e
  erişim ya da bulut CI (Codemagic, GitHub Actions macOS runner) kullanılabilir.
  Kod tamamen platform bağımsız yazıldığı için o adımda ek geliştirme gerekmez.

## 3) Backend'e bağlanma

1. Backend'i bilgisayarınızda başlatın:

   ```bash
   uvicorn backend.api:app --host 0.0.0.0 --port 8000 --reload
   ```

2. Telefon/emülatör ile bilgisayar **aynı Wi-Fi ağında** olmalı.
3. Bilgisayarınızın LAN IP'sini bulun (Windows: `ipconfig`, "IPv4 Address").
4. Uygulamayı açın → sidebar altındaki **Ayarlar**'a girin → API Base URL'i
   `http://<LAN-IP>:8000` olarak girip "Bağlantıyı Test Et" ile doğrulayın.

   Android emülatöründe bilgisayarın kendisine bağlanmak isterseniz
   `http://10.0.2.2:8000` kullanabilirsiniz.

## Klasör yapısı

```
lib/
  main.dart                 # Provider kurulumu, tema, giriş noktası
  core/                      # api_client, app_settings (LAN IP), theme
  models/                    # Task, Journal, SecondBrainNote, ChatMessage
  providers/                 # ChangeNotifier tabanlı state yönetimi
  screens/                   # HomeShell + Daily/Görevler/Life/Second Brain/Takvim/Chat/Ayarlar
  widgets/                   # Drawer, kart/tile bileşenleri, sohbet balonu
```

## Çalıştırma

```bash
flutter run
```
