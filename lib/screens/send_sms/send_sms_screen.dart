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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _customMessageController.dispose();
    _searchController.dispose();
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
        if (state.phase == SendPhase.sending || state.phase == SendPhase.paused) {
          return Scaffold(body: _SendingView(state: state));
        }
        return Scaffold(
          body: _SelectionView(
            state: state,
            customMessageController: _customMessageController,
            searchController: _searchController,
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
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
    final isPaused = state.phase == SendPhase.paused;
    final bloc = context.read<SendSmsBloc>();

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
                    color: isPaused ? Colors.grey : AppColors.rose,
                    backgroundColor: AppColors.roseLight,
                  ),
                  Icon(
                    isPaused ? Icons.pause_rounded : Icons.sms_rounded,
                    color: isPaused ? Colors.grey.shade600 : AppColors.rose,
                    size: 28,
                  ),
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
              isPaused
                  ? 'To\'xtatib turildi. Davom ettirish uchun tugmani bosing.'
                  : 'Iltimos kuting, SMS ketma-ket yuborilmoqda...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => bloc.add(
                    isPaused ? const ResumeSendRequested() : const PauseSendRequested(),
                  ),
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(isPaused ? 'Davom ettirish' : 'To\'xtatib turish'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmStop(context, bloc),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('To\'xtatish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context, SendSmsBloc bloc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yuborishni to\'xtatish'),
        content: const Text(
          'Qolgan mijozlarga SMS yuborilmaydi. Hozirgacha yuborilganlar tarixda saqlanadi. Davom etilsinmi?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('To\'xtatish'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const StopSendRequested());
    }
  }
}

class _SelectionView extends StatelessWidget {
  final SendSmsState state;
  final TextEditingController customMessageController;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;

  const _SelectionView({
    required this.state,
    required this.customMessageController,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SendSmsBloc>();
    final filteredCustomers = query.isEmpty
        ? state.customers
        : state.customers
            .where((c) =>
                c.displayName.toLowerCase().contains(query.toLowerCase()) ||
                c.phone.contains(query))
            .toList();
    final previewName =
        state.customers.isNotEmpty ? state.customers.first.smsGreeting : 'Hurmatli mijoz';
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
        if (state.availableSims.length > 1)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(Icons.sim_card_rounded, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'SIM karta:',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final sim in state.availableSims)
                          ChoiceChip(
                            label: Text(sim.label),
                            selected: state.selectedSubscriptionId == sim.subscriptionId,
                            onSelected: (_) => bloc.add(SimSelected(sim.subscriptionId)),
                            selectedColor: AppColors.roseLight,
                            labelStyle: TextStyle(
                              color: state.selectedSubscriptionId == sim.subscriptionId
                                  ? AppColors.roseDark
                                  : null,
                              fontWeight: state.selectedSubscriptionId == sim.subscriptionId
                                  ? FontWeight.w600
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
                  helperText:
                      'Murojaat uchun {ism} yozing — "Hurmatli" so\'zi avtomatik qo\'shiladi',
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
            child: TextField(
              controller: searchController,
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Ism yoki telefon bo\'yicha qidirish',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          onQueryChanged('');
                        },
                      ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
        if (filteredCustomers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                state.customers.isEmpty ? 'Mijozlar ro\'yxati bo\'sh' : 'Mijoz topilmadi',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList.builder(
              itemCount: filteredCustomers.length,
              itemBuilder: (context, i) {
                final c = filteredCustomers[i];
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
