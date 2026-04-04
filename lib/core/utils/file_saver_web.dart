import 'dart:convert';
import 'package:web/web.dart' as web;

/// Web platformda byte'lari blob URL ile indirir
Future<void> saveFileWeb(List<int> bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'data:application/pdf;base64,$base64Data'
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
