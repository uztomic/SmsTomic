# Roses Kokand Flowers — SMS boshqaruv tizimi

Gul do'koni uchun mijozlar bazasi, tayyor SMS shablonlari va ommaviy SMS
yuborish ilovasi. Flutter + Firebase (Auth, Firestore) asosida qurilgan.

## Imkoniyatlar

- **Login** — admin va xodim (worker) hisoblari, granular ruxsatlar
  (mijozlar, shablonlar, SMS yuborish, tarix) admin tomonidan beriladi.
- **Mijozlar** — qo'lda yoki CSV fayldan ommaviy import qilish.
- **Tayyor shablonlar** — gul do'koni uchun tayyor SMS matnlari, `{ism}`
  o'rniga mijoz ismi (yoki ism kiritilmagan bo'lsa "Hurmatli mijoz")
  avtomatik qo'yiladi.
- **Ommaviy SMS yuborish** — Android qurilmaning o'z SIM kartasi orqali,
  SMS ilovasini ochmasdan, bir nechta (hattoki 100 ga yaqin) mijozga
  ketma-ket yuboradi.
- **Veb-sayt (boshqaruv paneli)** — kompyuterdan mijozlar, shablonlar,
  xodimlar va SMS tarixini boshqarish. SMS yuborishning o'zi faqat
  Android ilovadan amalga oshadi, chunki bu SIM kartaga bog'liq.

## Ishga tushirish

```bash
flutter pub get
flutter run                 # Android qurilmada
flutter build web --release # veb versiya uchun
```

Firebase konfiguratsiyasi `lib/firebase_options.dart` faylida
(`flutterfire configure` orqali generatsiya qilingan) va Firestore
xavfsizlik qoidalari `firestore.rules` faylida saqlanadi.
