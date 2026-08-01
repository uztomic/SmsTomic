import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsSendResult {
  final String phone;
  final bool success;
  final String? error;

  const SmsSendResult({required this.phone, required this.success, this.error});
}

/// Qurilmaning o'z SIM kartasi orqali, SMS ilovasini ochmasdan,
/// to'g'ridan-to'g'ri SMS yuboradi (Android MethodChannel orqali).
class SmsService {
  static const MethodChannel _channel = MethodChannel('com.tomicsms/sms');

  /// SEND_SMS ruxsatini so'raydi. Ruxsat berilgan bo'lsa true qaytaradi.
  Future<bool> ensurePermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;
    final result = await Permission.sms.request();
    return result.isGranted;
  }

  Future<SmsSendResult> sendOne({
    required String phone,
    required String message,
  }) async {
    try {
      await _channel.invokeMethod<bool>('sendSms', {
        'phone': phone,
        'message': message,
      });
      return SmsSendResult(phone: phone, success: true);
    } on PlatformException catch (e) {
      return SmsSendResult(phone: phone, success: false, error: e.message);
    }
  }

  /// Bir nechta mijozga ketma-ket SMS yuboradi. Har bir xabar orasida
  /// qisqa kutish qo'yiladi — Android tizimi ko'p sonli SMS'ni bir vaqtda
  /// yuborishni "shubhali faoliyat" deb hisoblab, ogohlantirish oynasini
  /// chiqarishi mumkin, shu sababli oraliqdagi kutish shu xavfni kamaytiradi.
  Stream<SmsSendResult> sendBulk({
    required List<MapEntry<String, String>> phoneAndMessage,
    Duration delayBetween = const Duration(milliseconds: 1200),
  }) async* {
    for (var i = 0; i < phoneAndMessage.length; i++) {
      final entry = phoneAndMessage[i];
      final result = await sendOne(phone: entry.key, message: entry.value);
      yield result;
      if (i != phoneAndMessage.length - 1) {
        await Future.delayed(delayBetween);
      }
    }
  }
}
