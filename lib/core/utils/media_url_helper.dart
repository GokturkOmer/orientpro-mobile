import '../config/api_config.dart';

class MediaUrlHelper {
  /// MinIO mediaUrl'den indirme URL'i oluşturur.
  /// mediaUrl: 'training-docs/abc123_file.pdf' → '{baseUrl}/files/download/training-docs/abc123_file.pdf'
  /// Zaten tam URL ise (http/https) oldugu gibi dondurur.
  static String? getDownloadUrl(String? mediaUrl) {
    if (mediaUrl == null || mediaUrl.isEmpty) return null;
    if (mediaUrl.startsWith('http://') || mediaUrl.startsWith('https://')) {
      return mediaUrl;
    }
    return '${ApiConfig.baseUrl}/files/download/$mediaUrl';
  }
}
