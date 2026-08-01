import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final DateTime? createdAt;
  final String createdBy;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.createdAt,
    this.createdBy = '',
  });

  /// Ism kiritilmagan mijozlarga murojaat qilish uchun ishlatiladi
  /// (ro'yxatda ko'rsatish va SMS matnida {ism} o'rniga qo'yish).
  String get displayName => name.trim().isEmpty ? 'Hurmatli mijoz' : name.trim();

  Customer copyWith({String? name, String? phone}) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, name, phone];
}
