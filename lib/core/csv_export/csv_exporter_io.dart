import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.tomicsms/files');

/// Android'ning o'z fayl saqlash oynasi (Storage Access Framework) orqali
/// ishlaydi — uchinchi tomon paketlariga bog'liq emas.
Future<bool> saveCsvBytes(String filename, Uint8List bytes) async {
  final result = await _channel.invokeMethod<bool>('saveCsv', {
    'filename': filename,
    'bytes': bytes,
  });
  return result ?? false;
}
