import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SmsLog extends Equatable {
  final String id;
  final String customerName;
  final String phone;
  final String message;
  final DateTime? sentAt;
  final String sentByEmail;
  final bool success;
  final String? error;

  const SmsLog({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.message,
    this.sentAt,
    required this.sentByEmail,
    required this.success,
    this.error,
  });

  factory SmsLog.fromMap(String id, Map<String, dynamic> map) {
    return SmsLog(
      id: id,
      customerName: map['customerName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      message: map['message'] as String? ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
      sentByEmail: map['sentByEmail'] as String? ?? '',
      success: map['success'] as bool? ?? false,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'phone': phone,
      'message': message,
      'sentAt': FieldValue.serverTimestamp(),
      'sentByEmail': sentByEmail,
      'success': success,
      'error': error,
    };
  }

  @override
  List<Object?> get props => [id, customerName, phone, sentAt, success];
}
