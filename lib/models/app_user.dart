import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AppRole { admin, worker }

AppRole appRoleFromString(String value) {
  return AppRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => AppRole.worker,
  );
}

/// Xodim (worker) hisobiga admin tomonidan beriladigan alohida ruxsatlar.
/// Admin hisobi bu ro'yxatdan qat'i nazar har doim hammasiga ega bo'ladi.
/// Foydalanuvchilarni boshqarish (xodim qo'shish/o'chirish) hech qachon
/// ushbu ro'yxatga kiritilmaydi — u faqat adminga tegishli.
enum Permission {
  manageCustomers,
  manageTemplates,
  sendSms,
  viewHistory;

  String get label {
    switch (this) {
      case Permission.manageCustomers:
        return 'Mijozlarni boshqarish';
      case Permission.manageTemplates:
        return 'Shablonlarni boshqarish';
      case Permission.sendSms:
        return 'SMS yuborish';
      case Permission.viewHistory:
        return 'Tarixni ko\'rish';
    }
  }
}

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String name;
  final AppRole role;
  final Set<Permission> permissions;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.permissions = const {},
    this.createdAt,
  });

  bool get isAdmin => role == AppRole.admin;

  bool can(Permission permission) => isAdmin || permissions.contains(permission);

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final rawPermissions = (map['permissions'] as List?)?.cast<String>() ?? const [];
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: appRoleFromString(map['role'] as String? ?? 'worker'),
      permissions: rawPermissions
          .map((p) => Permission.values.where((v) => v.name == p))
          .expand((it) => it)
          .toSet(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'permissions': permissions.map((p) => p.name).toList(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  @override
  List<Object?> get props => [uid, email, name, role, permissions, createdAt];
}
