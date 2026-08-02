import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/user_management/user_cubit.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import 'user_form_sheet.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.users.isEmpty) {
            return const Center(child: Text('Foydalanuvchi topilmadi'));
          }
          final currentUid =
              (context.read<AuthBloc>().state as AuthAuthenticated).user.uid;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: state.users.length,
            itemBuilder: (context, i) {
              final user = state.users[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: user.isAdmin
                      ? null
                      : () => showEditWorkerSheet(context, user),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.isAdmin
                            ? AppColors.rose.withValues(alpha: 0.3)
                            : AppColors.roseLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: user.isAdmin
                                  ? AppColors.rose
                                  : AppColors.roseLight,
                              child: Icon(
                                user.isAdmin
                                    ? Icons.shield_rounded
                                    : Icons.person_rounded,
                                color: user.isAdmin
                                    ? Colors.white
                                    : AppColors.roseDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isEmpty ? user.email : user.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    user.email,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            if (user.uid != currentUid && !user.isAdmin)
                              IconButton(
                                icon: const Icon(Icons.person_remove_outlined),
                                tooltip: 'Hisobni bekor qilish',
                                onPressed: () => _confirmRevoke(context, user),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: user.isAdmin
                              ? [
                                  Chip(
                                    label: const Text('To\'liq huquq'),
                                    backgroundColor: AppColors.rose.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ]
                              : user.permissions.isEmpty
                              ? [const Chip(label: Text('Ruxsat yo\'q'))]
                              : user.permissions
                                    .map((p) => Chip(label: Text(p.label)))
                                    .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateWorkerSheet(context),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Xodim qo\'shish'),
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hisobni bekor qilish'),
        content: Text(
          '${user.name.isEmpty ? user.email : user.name} ilovaga kira olmay qoladi. Davom etilsinmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<UserCubit>().revokeUser(user.uid);
    }
  }
}
