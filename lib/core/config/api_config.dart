class ApiConfig {
  // Default dev URL'ler
  static const String _defaultWebUrl = 'http://localhost:8000/api/v1';

  // Build-time override: flutter run --dart-define=API_BASE_URL=https://api.orientpro.com/api/v1
  static const String? _overrideUrl = bool.hasEnvironment('API_BASE_URL')
      ? String.fromEnvironment('API_BASE_URL')
      : null;

  // Tunnel/production modunda relative URL kullan
  static const bool _isTunnel = bool.fromEnvironment('TUNNEL', defaultValue: false);

  static String get url {
    if (_overrideUrl != null) return _overrideUrl!;
    if (_isTunnel) return '/api/v1';
    return _defaultWebUrl;
  }

  // Geriye uyumluluk
  static String get webUrl => url;
  static String get baseUrl => url;
}
