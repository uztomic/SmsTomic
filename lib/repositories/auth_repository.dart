import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  /// Admin yangi xodim hisobini, unga bergan ruxsatlari bilan yaratadi.
  /// Buning uchun vaqtinchalik ikkinchi Firebase App instance ishlatiladi,
  /// aks holda createUserWithEmailAndPassword joriy (admin) sessiyasini
  /// yangi foydalanuvchi bilan almashtirib qo'yar edi.
  Future<void> createWorker({
    required String email,
    required String password,
    required String name,
    required Set<Permission> permissions,
  }) async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = Firebase.app('secondary');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await _usersRef.doc(uid).set(
            AppUser(
              uid: uid,
              email: email,
              name: name,
              role: AppRole.worker,
              permissions: permissions,
            ).toMap(),
          );
    } finally {
      await secondaryAuth.signOut();
    }
  }

  Stream<List<AppUser>> watchUsers() {
    return _usersRef.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => AppUser.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Faqat Firestore hujjatini o'chiradi (ilovaga kirish huquqi yo'qoladi).
  /// Firebase Auth hisobining o'zini o'chirish uchun Firebase konsoli yoki
  /// Admin SDK kerak bo'ladi, chunki mijoz (client) SDK boshqa
  /// foydalanuvchining Auth hisobini o'chira olmaydi.
  Future<void> revokeUser(String uid) => _usersRef.doc(uid).delete();
}
