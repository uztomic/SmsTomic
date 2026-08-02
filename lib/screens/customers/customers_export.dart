import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

import '../../core/csv_export/csv_exporter.dart';
import '../../models/customer.dart';

/// Mijozlar ro'yxatini (tartib raqami, ismi, telefon raqami) Excel'da
/// ochiladigan CSV fayl sifatida yuklab beradi.
Future<void> exportCustomersToExcel(BuildContext context, List<Customer> customers) async {
  if (customers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Eksport qilish uchun mijoz yo\'q.')),
    );
    return;
  }

  final rows = <List<String>>[
    ['№', 'Ism', 'Telefon raqami'],
    for (var i = 0; i < customers.length; i++)
      ['${i + 1}', customers[i].name, customers[i].phone],
  ];

  final csv = const ListToCsvConverter().convert(rows);
  // Excel'da UTF-8 harflar (masalan o', g') to'g'ri ko'rinishi uchun BOM.
  final bytes = utf8.encode('﻿$csv');

  final filename = 'mijozlar_${DateTime.now().millisecondsSinceEpoch}.csv';
  final saved = await saveCsvBytes(filename, Uint8List.fromList(bytes));

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(saved ? 'Mijozlar ro\'yxati yuklab olindi.' : 'Fayl saqlanmadi.'),
    ),
  );
}
