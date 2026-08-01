import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/send_sms/send_sms_bloc.dart';
import '../../core/theme.dart';

class SendSmsScreen extends StatefulWidget {
  const SendSmsScreen({super.key});

  @override
  State<SendSmsScreen> createState() => _SendSmsScreenState();
}

class _SendSmsScreenState extends State<SendSmsScreen> {
  final _customMessageController = TextEditingController();

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SendSmsBloc, SendSmsState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        if (state.phase == SendPhase.done) {
          final success = state.results.where((r) => r.success).length;
          final failed = state.results.length - success;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Yuborish yakunlandi'),
              content: Text('Muvaffaqiyatli: $success ta\nXato: $failed ta'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.read<SendSmsBloc>().add(const SendResetRequested());
                  },
                  child: const Text('Yaxshi'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.phase == SendPhase.sending) {
          return Scaffold(body: _SendingView(state: state));
        }
        return Scaffold(
          body: _SelectionView(
            state: state,
            customMessageController: _customMessageController,
          ),
          bottomNavigationBar: const _SendSmsBottomBar(),
        );
      },
    );
  }
}

class _SendingView extends StatelessWidget {
  final SendSmsState state;

  const _SendingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = state.totalToSend == 0 ? 0.0 : state.sentCount / state.totalToSend;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: AppColors.rose,
                    backgroundColor: AppColors.roseLight,
                  ),
                  const Icon(Icons.sms_rounded, color: AppColors.rose, size: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${state.sentCount} / ${state.totalToSend} yuborildi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Iltimos kuting, SMS ketma-ket yuborilmoqda...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionView extends StatelessWidget {
  final SendSmsState state;
  final TextEditingController customMessageController;

  const _SelectionView({required this.state, required this.customMessageController});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SendSmsBloc>();
    final previewName =
        state.customers.isNotEmpty ? state.customers.first.displayName : 'Hurmatli mijoz';
    final preview = state.messageTemplate.isEmpty
        ? ''
        : state.messageTemplate.replaceAll('{ism}', previewName);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverToBoxAdapter(
            child: DropdownButtonFormField<String>(
              initialValue: state.selectedTemplateId,
              decoration: const InputDecoration(
                labelText: 'Tayyor shablon tanlang',
                prefixIcon: Icon(Icons.auto_awesome_rounded),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('— O\'zim yozaman —')),
                ...state.templates.map(
                  (t) => DropdownMenuItem(value: t.id, child: Text(t.title)),
                ),
              ],
              onChanged: (id) => bloc.add(TemplateSelected(id)),
            ),
          ),
        ),
        if (state.selectedTemplateId == null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: customMessageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Xabar matni',
                  helperText: 'Ism uchun {ism} yozing',
                ),
                onChanged: (v) => bloc.add(CustomMessageChanged(v)),
              ),
            ),
          ),
        if (preview.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.roseLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.visibility_outlined, size: 18, color: AppColors.roseDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        preview,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: AppColors.roseDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Checkbox(
                  value: state.allSelected,
                  onChanged: (_) => bloc.add(state.allSelected
                      ? const DeselectAllCustomers()
                      : const SelectAllCustomers()),
                ),
                const Text('Hammasini tanlash'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.roseLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${state.selectedIds.length}/${state.customers.length}',
                    style: const TextStyle(
                      color: AppColors.roseDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.customers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Mijozlar ro\'yxati bo\'sh', style: TextStyle(color: Colors.grey.shade500)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList.builder(
              itemCount: state.customers.length,
              itemBuilder: (context, i) {
                final c = state.customers[i];
                final selected = state.selectedIds.contains(c.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.roseLight.withValues(alpha: 0.45)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.rose : AppColors.roseLight,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (_) => bloc.add(ToggleCustomerSelection(c.id)),
                      title: Text(c.displayName),
                      subtitle: Text(c.phone),
                      activeColor: AppColors.rose,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SendSmsBottomBar extends StatelessWidget {
  const _SendSmsBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendSmsBloc, SendSmsState>(
      builder: (context, state) {
        final bloc = context.read<SendSmsBloc>();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.selectedIds.isEmpty || state.messageTemplate.trim().isEmpty
                  ? null
                  : () {
                      final authState = context.read<AuthBloc>().state;
                      final email = authState is AuthAuthenticated ? authState.user.email : '';
                      bloc.add(SendRequested(email));
                    },
              icon: const Icon(Icons.send_rounded),
              label: Text('Yuborish (${state.selectedIds.length} ta)'),
            ),
          ),
        );
      },
    );
  }
}
