import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.tomicsms/files');

/// Android'ning o'z fayl tanlash oynasi (Storage Access Framework) orqali
/// ishlaydi — uchinchi tomon paketlariga bog'liq emas.
Future<Uint8List?> pickCsvBytes() async {
  return _channel.invokeMethod<Uint8List>('pickCsv');
}
