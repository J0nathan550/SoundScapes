import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeAuthService {
  static const _cookieKey = 'youtube.sessionCookie';

  final FlutterSecureStorage _storage;

  YoutubeAuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> loadCookie() => _storage.read(key: _cookieKey);

  Future<void> saveCookie(String cookie) => _storage.write(key: _cookieKey, value: cookie);

  Future<void> signOut() async {
    await _storage.delete(key: _cookieKey);
    await WebViewCookieManager().clearCookies();
  }
}
