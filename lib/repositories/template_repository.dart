import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sms_template.dart';

/// Gul do'koni uchun tayyor shablonlar. Ilova birinchi marta ishga
/// tushganda, agar Firestore'da hali birorta ham shablon bo'lmasa, shu
/// ro'yxat avtomatik yuklanadi.
///
/// {ism} o'rniga mijozga murojaat avtomatik qo'yiladi va "Hurmatli"
/// so'zini allaqachon o'z ichiga oladi (masalan "Hurmatli Malika" yoki,
/// ismi bo'lmasa, "Hurmatli mijoz") — shuning uchun matn ichida
/// alohida "hurmatli" so'zini yozish shart emas.
const List<({String title, String body})> defaultFlowerShopTemplates = [
  (
    title: '🎂 Tug\'ilgan kun tabrigi',
    body:
        '{ism}, tug\'ilgan kuningiz muborak bo\'lsin! 🎉 Ushbu maxsus kun sharafiga sizga 15% chegirma taqdim etamiz. Roses Kokand Flowers jamoasidan baxt, sog\'lik va gullardek go\'zallik tilaymiz!'
  ),
  (
    title: '🎂 Tug\'ilgan kunga maxsus buket',
    body:
        '{ism}, tug\'ilgan kuningiz bilan chin qalbdan tabriklaymiz! 🌹 Aynan shu ajoyib kun uchun eng nafis buketlarimizni tayyorladik. Kelib, o\'zingiz uchun eng go\'zalini tanlang!'
  ),
  (
    title: '🌷 8-mart bayrami',
    body:
        '{ism}, 8-mart Xalqaro xotin-qizlar kuni bilan tabriklaymiz! 🌷 Bahorning eng nafis gullari Roses Kokand Flowers\'da sizni kutmoqda. Bayramingiz baxt va tabassumga to\'la bo\'lsin!'
  ),
  (
    title: '🌸 Navro\'z bayrami',
    body:
        '{ism}, Navro\'z bayramingiz muborak bo\'lsin! 🌸 Yangilanish va bahor nafasini uyingizga olib kelish uchun eng yangi gullarimiz tayyor. Sizni kutamiz!'
  ),
  (
    title: '🎄 Yangi yil tabrigi',
    body:
        '{ism}, Yangi yilingiz muborak bo\'lsin! 🎄✨ Yaqinlaringizni bayramona buketlar bilan xursand qiling. Roses Kokand Flowers doim sizning yoningizda!'
  ),
  (
    title: '💐 Yangi, zo\'r buket keldi!',
    body:
        '{ism}, xushxabar! 💐 Do\'konimizga juda ajoyib, yangi buketlar kelib tushdi. Miqdori cheklangan — birinchilardan bo\'lib kelib, o\'z ko\'zingiz bilan ko\'ring!'
  ),
  (
    title: '🌹 Chegirma / aksiya',
    body:
        '{ism}, faqat shu hafta barcha buketlarga 20% gacha chegirma! 🌹 Fursatni boy bermang — Roses Kokand Flowers sizni kutmoqda.'
  ),
  (
    title: '💍 To\'y / nikoh tabrigi',
    body:
        '{ism}, turmush qurishingiz muborak bo\'lsin! 💍🌸 Baxtli va totuv oilaviy hayot tilab, eng chiroyli buketlarimizni sizga taqdim etishga tayyormiz.'
  ),
  (
    title: '🙏 Minnatdorchilik',
    body:
        '{ism}, bizdan xarid qilganingiz uchun katta rahmat! 🙏 Sizga yana xizmat qilishdan mamnunmiz. Roses Kokand Flowers jamoasi.'
  ),
  (
    title: '✅ Buyurtma tayyor',
    body:
        '{ism}, buyurtmangiz tayyor bo\'ldi! 💐 Qulay vaqtda do\'konimizdan olib ketishingiz mumkin. Kutib qolamiz!'
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
