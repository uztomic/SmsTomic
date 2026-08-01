import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sms_log.dart';

class LogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('sms_logs');

  Future<void> addLog(SmsLog log) => _ref.add(log.toMap());

  Stream<List<SmsLog>> watchRecentLogs({int limit = 200}) {
    return _ref
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SmsLog.fromMap(d.id, d.data())).toList(),
        );
  }
}
