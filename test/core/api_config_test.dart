import 'package:flutter_test/flutter_test.dart';
import 'package:orientpro_mobile/core/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl varsayilan deger', () {
      expect(ApiConfig.baseUrl, isNotNull);
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl, contains('/api/v1'));
    });

    test('webUrl varsayilan deger', () {
      expect(ApiConfig.webUrl, isNotNull);
      expect(ApiConfig.webUrl, contains('localhost'));
    });
  });
}
