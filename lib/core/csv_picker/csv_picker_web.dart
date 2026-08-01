import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Veb-brauzerning o'z fayl tanlash oynasi orqali ishlaydi.
Future<Uint8List?> pickCsvBytes() async {
  final input = html.FileUploadInputElement()..accept = '.csv,text/csv';
  input.click();

  await input.onChange.first;
  final files = input.files;
  if (files == null || files.isEmpty) return null;

  final reader = html.FileReader();
  reader.readAsArrayBuffer(files[0]);
  await reader.onLoad.first;
  return reader.result as Uint8List?;
}
