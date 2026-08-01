import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sms_template.dart';

/// Gul do'koni uchun tayyor shablonlar. Ilova birinchi marta ishga
/// tushganda, agar Firestore'da hali birorta ham shablon bo'lmasa, shu
/// ro'yxat avtomatik yuklanadi.
const List<({String title, String body})> defaultFlowerShopTemplates = [
  (
    title: 'Yangi kolleksiya',
    body:
        'Assalomu alaykum, hurmatli {ism}! Do\'konimizga yangi gullar kolleksiyasi keldi. Kutib qolamiz!'
  ),
  (
    title: 'Chegirma / aksiya',
    body:
        'Hurmatli {ism}, faqat shu hafta barcha buketlarga 20% gacha chegirma! Shoshiling, aksiya cheklangan.'
  ),
  (
    title: 'Bayram tabrigi',
    body:
        'Assalomu alaykum {ism}! Sizni bayram bilan chin qalbdan tabriklaymiz. Baxt-omad hamrohingiz bo\'lsin!'
  ),
  (
    title: 'Tug\'ilgan kun tabrigi',
    body:
        'Hurmatli {ism}, tug\'ilgan kuningiz muborak bo\'lsin! Sizga sog\'lik va baxt tilaymiz. Do\'konimizdan maxsus sovg\'a sizni kutmoqda.'
  ),
  (
    title: 'Minnatdorchilik',
    body:
        'Hurmatli {ism}, bizdan xarid qilganingiz uchun rahmat! Sizni yana ko\'rishdan mamnun bo\'lamiz.'
  ),
  (
    title: 'Buyurtma tayyor',
    body:
        'Assalomu alaykum {ism}, buyurtmangiz tayyor bo\'ldi. Iltimos, qulay vaqtda do\'konimizdan olib keting.'
  ),
];

class TemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('templates');

  Stream<List<SmsTemplate>> watchTemplates() {
    return _ref.orderBy('createdAt').snapshots().map(
          (snap) => snap.docs
              .map((d) => SmsTemplate.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> seedDefaultsIfEmpty() async {
    final snap = await _ref.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final t in defaultFlowerShopTemplates) {
      final docRef = _ref.doc();
      batch.set(
        docRef,
        SmsTemplate(id: docRef.id, title: t.title, body: t.body).toMap(),
      );
    }
    await batch.commit();
  }

  Future<void> addTemplate({required String title, required String body}) {
    return _ref.add(SmsTemplate(id: '', title: title, body: body).toMap());
  }

  Future<void> updateTemplate(SmsTemplate template) {
    return _ref.doc(template.id).update({
      'title': template.title,
      'body': template.body,
    });
  }

  Future<void> deleteTemplate(String id) => _ref.doc(id).delete();
}
