import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/user_management/user_cubit.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';

Future<void> showCreateWorkerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<UserCubit>(),
      child: const _UserFormSheet(),
    ),
  );
}

Future<void> showEditWorkerSheet(BuildContext context, AppUser worker) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<UserCubit>(),
      child: _UserFormSheet(worker: worker),
    ),
  );
}

class _UserFormSheet extends StatefulWidget {
  final AppUser? worker;

  const _UserFormSheet({this.worker});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final Set<Permission> _selectedPermissions;

  bool get _isEditing => widget.worker != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.worker?.name ?? '');
    _emailController = TextEditingController(text: widget.worker?.email ?? '');
    _passwordController = TextEditingController();
    _selectedPermissions = {...(widget.worker?.permissions ?? {Permission.manageCustomers})};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<UserCubit>();
    if (_isEditing) {
      cubit.updateWorker(
        uid: widget.worker!.uid,
        name: _nameController.text.trim(),
        permissions: _selectedPermissions,
      );
    } else {
      cubit.createWorker(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        permissions: _selectedPermissions,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: BlocListener<UserCubit, UserState>(
        listener: (context, state) {
          if (state.actionMessage != null && !state.creating) {
            Navigator.of(context).pop();
          }
        },
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
                _isEditing ? 'Xodimni tahrirlash' : 'Yangi xodim hisobi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ism-familiya'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                enabled: !_isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  helperText: _isEditing ? 'Email o\'zgartirib bo\'lmaydi' : null,
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email kiriting' : null,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Vaqtinchalik parol'),
                  validator: (v) => (v == null || v.length < 6) ? 'Kamida 6 belgi' : null,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Ruxsatlar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Bu xodim ilovada faqat belgilangan bo\'limlarni ko\'radi.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ...Permission.values.map(
                (p) => CheckboxListTile(
                  value: _selectedPermissions.contains(p),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedPermissions.add(p);
                    } else {
                      _selectedPermissions.remove(p);
                    }
                  }),
                  title: Text(p.label),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.rose,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<UserCubit, UserState>(
                builder: (context, state) {
                  return FilledButton(
                    onPressed: state.creating ? null : _submit,
                    child: state.creating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Saqlash' : 'Hisob yaratish'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
