import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/template/template_cubit.dart';
import '../../core/theme.dart';
import '../../models/sms_template.dart';
import 'template_form_sheet.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TemplateCubit, TemplateState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.templates.isEmpty) {
            return Center(
              child: Text('Hali shablon yo\'q', style: TextStyle(color: Colors.grey.shade500)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: state.templates.length,
            itemBuilder: (context, i) {
              final template = state.templates[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.roseLight),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.roseLight,
                      child: Icon(Icons.description_rounded, color: AppColors.roseDark),
                    ),
                    title: Text(template.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(template.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    onTap: () => showTemplateFormSheet(context, template: template),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(context, template),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTemplateFormSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SmsTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text('"${template.title}" shabloni o\'chirilsinmi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor qilish')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('O\'chirish')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<TemplateCubit>().deleteTemplate(template.id);
    }
  }
}
