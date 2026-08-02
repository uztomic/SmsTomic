import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsSendResult {
  final String phone;
  final bool success;
  final String? error;

  const SmsSendResult({required this.phone, required this.success, this.error});
}

/// Qurilmadagi bitta faol SIM karta haqida ma'lumot (dual-SIM
/// qurilmalarda qaysi SIMdan yuborishni tanlash uchun).
class SimInfo {
  final int subscriptionId;
  final int slotIndex;
  final String displayName;
  final String carrierName;

  const SimInfo({
    required this.subscriptionId,
    required this.slotIndex,
    required this.displayName,
    required this.carrierName,
  });

  factory SimInfo.fromMap(Map<Object?, Object?> map) {
    return SimInfo(
      subscriptionId: map['subscriptionId'] as int? ?? -1,
      slotIndex: map['slotIndex'] as int? ?? 0,
      displayName: map['displayName'] as String? ?? '',
      carrierName: map['carrierName'] as String? ?? '',
    );
  }

  String get label => 'SIM ${slotIndex + 1}${carrierName.isNotEmpty ? ' ($carrierName)' : ''}';
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

  /// Dual-SIM qurilmalarda SIM ro'yxatini olish uchun READ_PHONE_STATE
  /// ruxsatini so'raydi.
  Future<bool> ensurePhoneStatePermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) return true;
    final result = await Permission.phone.request();
    return result.isGranted;
  }

  /// Qurilmadagi faol SIM kartalar ro'yxatini qaytaradi. Bitta SIM bo'lsa
  /// yoki ruxsat berilmasa, bo'sh ro'yxat qaytishi mumkin.
  Future<List<SimInfo>> getAvailableSims() async {
    final hasPermission = await ensurePhoneStatePermission();
    if (!hasPermission) return const [];
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getSimList');
      if (result == null) return const [];
      return result
          .map((e) => SimInfo.fromMap(Map<Object?, Object?>.from(e as Map)))
          .toList();
    } on PlatformException {
      return const [];
    }
  }

  Future<SmsSendResult> sendOne({
    required String phone,
    required String message,
    int? subscriptionId,
  }) async {
    try {
      await _channel.invokeMethod<bool>('sendSms', {
        'phone': phone,
        'message': message,
        if (subscriptionId != null) 'subscriptionId': subscriptionId,
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
    int? subscriptionId,
    Duration delayBetween = const Duration(milliseconds: 1200),
  }) async* {
    for (var i = 0; i < phoneAndMessage.length; i++) {
      final entry = phoneAndMessage[i];
      final result = await sendOne(
        phone: entry.key,
        message: entry.value,
        subscriptionId: subscriptionId,
      );
      yield result;
      if (i != phoneAndMessage.length - 1) {
        await Future.delayed(delayBetween);
      }
    }
  }
}
