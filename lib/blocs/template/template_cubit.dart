import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/sms_template.dart';
import '../../repositories/template_repository.dart';

part 'template_state.dart';

class TemplateCubit extends Cubit<TemplateState> {
  final TemplateRepository _repository;
  StreamSubscription<List<SmsTemplate>>? _subscription;

  TemplateCubit(this._repository) : super(const TemplateState()) {
    _repository.seedDefaultsIfEmpty();
    _subscription = _repository.watchTemplates().listen(
      (templates) => emit(state.copyWith(templates: templates, loading: false)),
      onError: (_) =>
          emit(state.copyWith(loading: false, error: 'Shablonlarni yuklashda xatolik.')),
    );
  }

  Future<void> addTemplate({required String title, required String body}) async {
    try {
      await _repository.addTemplate(title: title, body: body);
    } catch (_) {
      emit(state.copyWith(error: 'Shablon qo\'shishda xatolik yuz berdi.'));
    }
  }

  Future<void> updateTemplate(SmsTemplate template) async {
    try {
      await _repository.updateTemplate(template);
    } catch (_) {
      emit(state.copyWith(error: 'Shablonni yangilashda xatolik yuz berdi.'));
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _repository.deleteTemplate(id);
    } catch (_) {
      emit(state.copyWith(error: 'Shablonni o\'chirishda xatolik yuz berdi.'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
