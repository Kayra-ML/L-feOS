import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı uygulama ayarları (şu an tek ayar: backend API base URL).
///
/// Telefon, backend'e (`backend/api.py`) aynı Wi-Fi ağı üzerinden erişir.
/// Kullanıcı Ayarlar ekranından bilgisayarının LAN IP'sini girmelidir,
/// örn: http://192.168.1.20:8000
class AppSettings extends ChangeNotifier {
  static const _kBaseUrlKey = 'api_base_url';
  static const defaultBaseUrl = 'http://192.168.1.2:8000';

  String _baseUrl = defaultBaseUrl;
  bool _loaded = false;

  String get baseUrl => _baseUrl;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_kBaseUrlKey) ?? defaultBaseUrl;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    var cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (cleaned.isEmpty) cleaned = defaultBaseUrl;
    _baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrlKey, cleaned);
    notifyListeners();
  }
}
