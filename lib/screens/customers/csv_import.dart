import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/customer/customer_cubit.dart';
import '../../core/csv_picker/csv_picker.dart';

/// CSV fayldan (ism, telefon) ustunli mijozlar ro'yxatini o'qib,
/// ommaviy ravishda import qiladi. Ism ustuni bo'sh bo'lishi mumkin.
/// Fayl birinchi qatori sarlavha (masalan "ism,telefon" yoki "name,phone")
/// bo'lsa, avtomatik o'tkazib yuboriladi.
Future<void> pickAndImportCustomersCsv(BuildContext context) async {
  final bytes = await pickCsvBytes();
  if (bytes == null) return;

  String content;
  try {
    content = utf8.decode(bytes);
  } catch (_) {
    content = latin1.decode(bytes);
  }

  final rows = const CsvToListConverter(eol: '\n').convert(content, shouldParseNumbers: false);
  final customers = <({String name, String phone})>[];

  for (final row in rows) {
    if (row.isEmpty) continue;
    final first = row[0].toString().trim();
    final second = row.length > 1 ? row[1].toString().trim() : '';

    // Ustun tartibi "telefon,ism" bo'lishi ham mumkin — qaysi ustunda
    // telefon raqamiga o'xshash qiymat bo'lsa, o'shani telefon deb oladi.
    final firstLooksLikePhone = RegExp(r'^\+?\d[\d\s-]{6,}$').hasMatch(first);
    final phone = firstLooksLikePhone ? first : second;
    final name = firstLooksLikePhone ? second : first;

    if (phone.isEmpty) continue;

    final lowerFirst = first.toLowerCase();
    final lowerSecond = second.toLowerCase();
    final looksLikeHeader = (lowerFirst == 'ism' || lowerFirst == 'name' || lowerFirst == 'telefon' || lowerFirst == 'phone') &&
        (lowerSecond == 'telefon' || lowerSecond == 'phone' || lowerSecond == 'ism' || lowerSecond == 'name');
    if (looksLikeHeader) continue;

    customers.add((name: name, phone: phone));
  }

  if (customers.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faylda mos ma\'lumot topilmadi. Format: ism,telefon')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final authState = context.read<AuthBloc>().state;
  final createdBy = authState is AuthAuthenticated ? authState.user.email : '';
  context.read<CustomerCubit>().importBulk(customers, createdBy);
}
