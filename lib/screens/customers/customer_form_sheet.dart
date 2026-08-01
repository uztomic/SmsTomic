import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/customer/customer_cubit.dart';
import '../../models/customer.dart';

Future<void> showCustomerFormSheet(BuildContext context, {Customer? customer}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => CustomerFormSheet(customer: customer),
  );
}

class CustomerFormSheet extends StatefulWidget {
  final Customer? customer;

  const CustomerFormSheet({super.key, this.customer});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<CustomerCubit>();
    if (widget.customer == null) {
      final authState = context.read<AuthBloc>().state;
      final createdBy = authState is AuthAuthenticated ? authState.user.email : '';
      cubit.addCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        createdBy: createdBy,
      );
    } else {
      cubit.updateCustomer(widget.customer!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              widget.customer == null ? 'Yangi mijoz' : 'Mijozni tahrirlash',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ism (ixtiyoriy)',
                helperText: 'Kiritilmasa SMS\'da "Hurmatli mijoz" deb murojaat qilinadi',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon raqami',
                hintText: '+998901234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 9) ? 'To\'g\'ri raqam kiriting' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.customer == null ? 'Qo\'shish' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
