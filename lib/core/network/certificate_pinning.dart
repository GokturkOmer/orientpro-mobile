import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:crypto/crypto.dart';

/// Production SSL Certificate Pinning yapilandirmasi.
///
/// Kullanim:
///   1. Domain alindiktan sonra SSL sertifika fingerprint'ini ekle
///   2. `CertificatePinning.apply(dio)` ile Dio instance'a uygula
///
/// Fingerprint alma:
///   openssl s_client -connect yourdomain.com:443 | openssl x509 -fingerprint -sha256
class CertificatePinning {
  // Production sertifika SHA-256 fingerprint'leri
  // Domain alindiktan sonra buraya eklenmeli
  static const List<String> _trustedFingerprints = [
    // 'XX:XX:XX:...' seklinde Let's Encrypt sertifika fingerprint'i
  ];

  /// Dio instance'a certificate pinning uygular.
  /// Sadece production (HTTPS) URL'lerde aktif olur.
  static void apply(Dio dio) {
    // Fingerprint tanimlanmamissa atla
    if (_trustedFingerprints.isEmpty) return;

    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      // ignore: deprecated_member_use
      adapter.onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) {
          // Dev/localhost icin her zaman kabul et
          if (host == 'localhost' ||
              host == '127.0.0.1' ||
              host == '10.0.2.2') {
            return true;
          }

          // Production: DER bytes'tan SHA-256 fingerprint hesapla
          final derBytes = cert.der;
          final digest = sha256.convert(derBytes);
          final fingerprint = digest.bytes
              .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
              .join(':');

          return _trustedFingerprints.any(
            (trusted) =>
                trusted.replaceAll(':', '').toLowerCase() ==
                fingerprint.replaceAll(':', '').toLowerCase(),
          );
        };
        return client;
      };
    }
  }
}
