import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/customer/customer_cubit.dart';
import '../../core/theme.dart';
import '../../models/customer.dart';
import 'csv_import.dart';
import 'customer_form_sheet.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CustomerCubit, CustomerState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _query.isEmpty
              ? state.customers
              : state.customers
                  .where((c) =>
                      c.displayName.toLowerCase().contains(_query.toLowerCase()) ||
                      c.phone.contains(_query))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Ism yoki telefon bo\'yicha qidirish',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      '${state.customers.length} ta mijoz',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => pickAndImportCustomersCsv(context),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('CSV import'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Mijozlar topilmadi',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final customer = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey(customer.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete_outline_rounded),
                              ),
                              confirmDismiss: (_) => _confirmDelete(context, customer),
                              onDismissed: (_) =>
                                  context.read<CustomerCubit>().deleteCustomer(customer.id),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.roseLight),
                                ),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.roseLight,
                                    child: Text(
                                      customer.name.trim().isNotEmpty
                                          ? customer.name.trim()[0].toUpperCase()
                                          : '🌸',
                                      style: const TextStyle(color: AppColors.roseDark),
                                    ),
                                  ),
                                  title: Text(customer.displayName),
                                  subtitle: Text(customer.phone),
                                  onTap: () =>
                                      showCustomerFormSheet(context, customer: customer),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomerFormSheet(context),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Customer customer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('${customer.displayName} o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('O\'chirish')),
        ],
      ),
    );
    return result ?? false;
  }
}
