import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/template/template_cubit.dart';
import '../../models/sms_template.dart';

Future<void> showTemplateFormSheet(BuildContext context, {SmsTemplate? template}) {
  // showModalBottomSheet ochgan yangi qatlam sahifadagi TemplateCubit'ni
  // avtomatik ko'rmaydi, shuning uchun uni shu yerda ushlab, yangi
  // qatlamga qayta uzatamiz.
  final templateCubit = context.read<TemplateCubit>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: templateCubit,
      child: TemplateFormSheet(template: template),
    ),
  );
}

class TemplateFormSheet extends StatefulWidget {
  final SmsTemplate? template;

  const TemplateFormSheet({super.key, this.template});

  @override
  State<TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template?.title ?? '');
    _bodyController = TextEditingController(text: widget.template?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<TemplateCubit>();
    if (widget.template == null) {
      cubit.addTemplate(title: _titleController.text.trim(), body: _bodyController.text.trim());
    } else {
      cubit.updateTemplate(SmsTemplate(
        id: widget.template!.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
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
        top: 20,
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
              widget.template == null ? 'Yangi shablon' : 'Shablonni tahrirlash',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Sarlavha'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Sarlavha kiriting' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Matn',
                helperText:
                    'Murojaat uchun {ism} yozing — "Hurmatli" so\'zi avtomatik qo\'shiladi, alohida yozmang',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Matnni kiriting' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.template == null ? 'Qo\'shish' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
