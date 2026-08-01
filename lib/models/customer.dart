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
  /// (ro'yxatda ko'rsatish uchun).
  String get displayName => name.trim().isEmpty ? 'Hurmatli mijoz' : name.trim();

  /// SMS matnida {ism} o'rniga qo'yiladigan murojaat. "Hurmatli" so'zi
  /// shu yerning o'zida bir marta qo'shiladi (ismi bo'lsa ham, bo'lmasa
  /// ham) — shablon matnlarida alohida "hurmatli" so'zi yozilmaydi,
  /// aks holda takrorlanib qolar edi.
  String get smsGreeting =>
      name.trim().isEmpty ? 'Hurmatli mijoz' : 'Hurmatli ${name.trim()}';

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
