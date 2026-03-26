import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web platformda byte'lari blob URL ile indirir
Future<void> saveFileWeb(List<int> bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final anchor = html.AnchorElement(href: 'data:application/pdf;base64,$base64Data')
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
