import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('customers');

  Stream<List<Customer>> watchCustomers() {
    return _ref.orderBy('name').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Customer.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String createdBy,
  }) {
    return _ref.add(
      Customer(id: '', name: name, phone: phone, createdBy: createdBy)
          .toMap(),
    );
  }

  Future<void> updateCustomer(Customer customer) {
    return _ref.doc(customer.id).update({
      'name': customer.name,
      'phone': customer.phone,
    });
  }

  Future<void> deleteCustomer(String id) => _ref.doc(id).delete();

  /// Ko'p mijozni bir vaqtda qo'shadi (CSV/Excel import uchun).
  /// Firestore bitta batch'da eng ko'p 500 ta yozuvni qo'llab-quvvatlaydi,
  /// shuning uchun ro'yxat 500 talik bo'laklarga bo'lib yuboriladi.
  Future<int> addCustomersBulk(
    List<({String name, String phone})> customers,
    String createdBy,
  ) async {
    const chunkSize = 450;
    var added = 0;
    for (var i = 0; i < customers.length; i += chunkSize) {
      final chunk = customers.sublist(
        i,
        i + chunkSize > customers.length ? customers.length : i + chunkSize,
      );
      final batch = _firestore.batch();
      for (final c in chunk) {
        final docRef = _ref.doc();
        batch.set(
          docRef,
          Customer(
            id: docRef.id,
            name: c.name,
            phone: c.phone,
            createdBy: createdBy,
          ).toMap(),
        );
      }
      await batch.commit();
      added += chunk.length;
    }
    return added;
  }
}
