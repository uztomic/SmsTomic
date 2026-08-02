import 'dart:html' as html;
import 'dart:typed_data';

/// Veb-brauzerda faylni to'g'ridan-to'g'ri yuklab olish (download) orqali
/// ishlaydi.
Future<bool> saveCsvBytes(String filename, Uint8List bytes) async {
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
