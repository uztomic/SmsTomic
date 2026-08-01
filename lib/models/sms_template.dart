import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SmsTemplate extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;

  const SmsTemplate({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
  });

  /// Mijoz ismini shablon matniga joylashtiradi. Shablon ichida {ism}
  /// yozilgan joyga mijozning ismi qo'yiladi.
  String render(String customerName) {
    return body.replaceAll('{ism}', customerName);
  }

  factory SmsTemplate.fromMap(String id, Map<String, dynamic> map) {
    return SmsTemplate(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [id, title, body];
}
