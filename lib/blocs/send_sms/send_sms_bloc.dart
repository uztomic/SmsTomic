import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/sms_service.dart';
import '../../models/customer.dart';
import '../../models/sms_log.dart';
import '../../models/sms_template.dart';
import '../../repositories/customer_repository.dart';
import '../../repositories/log_repository.dart';
import '../../repositories/template_repository.dart';

part 'send_sms_event.dart';
part 'send_sms_state.dart';

class SendSmsBloc extends Bloc<SendSmsEvent, SendSmsState> {
  final CustomerRepository _customerRepository;
  final TemplateRepository _templateRepository;
  final LogRepository _logRepository;
  final SmsService _smsService;

  StreamSubscription<List<Customer>>? _customersSub;
  StreamSubscription<List<SmsTemplate>>? _templatesSub;

  SendSmsBloc({
    required CustomerRepository customerRepository,
    required TemplateRepository templateRepository,
    required LogRepository logRepository,
    required SmsService smsService,
  })  : _customerRepository = customerRepository,
        _templateRepository = templateRepository,
        _logRepository = logRepository,
        _smsService = smsService,
        super(const SendSmsState()) {
    on<SendSmsStarted>(_onStarted);
    on<_CustomersUpdated>((e, emit) => emit(state.copyWith(customers: e.customers)));
    on<_TemplatesUpdated>((e, emit) => emit(state.copyWith(templates: e.templates)));
    on<ToggleCustomerSelection>(_onToggleCustomer);
    on<SelectAllCustomers>(_onSelectAll);
    on<DeselectAllCustomers>(_onDeselectAll);
    on<TemplateSelected>(_onTemplateSelected);
    on<CustomMessageChanged>(_onCustomMessageChanged);
    on<SendRequested>(_onSendRequested);
    on<SendResetRequested>(_onSendReset);
  }

  void _onStarted(SendSmsStarted event, Emitter<SendSmsState> emit) {
    _customersSub?.cancel();
    _templatesSub?.cancel();
    _customersSub = _customerRepository
        .watchCustomers()
        .listen((customers) => add(_CustomersUpdated(customers)));
    _templatesSub = _templateRepository
        .watchTemplates()
        .listen((templates) => add(_TemplatesUpdated(templates)));
  }

  void _onToggleCustomer(ToggleCustomerSelection event, Emitter<SendSmsState> emit) {
    final selected = Set<String>.from(state.selectedIds);
    if (!selected.remove(event.customerId)) {
      selected.add(event.customerId);
    }
    emit(state.copyWith(selectedIds: selected));
  }

  void _onSelectAll(SelectAllCustomers event, Emitter<SendSmsState> emit) {
    emit(state.copyWith(selectedIds: state.customers.map((c) => c.id).toSet()));
  }

  void _onDeselectAll(DeselectAllCustomers event, Emitter<SendSmsState> emit) {
    emit(state.copyWith(selectedIds: {}));
  }

  void _onTemplateSelected(TemplateSelected event, Emitter<SendSmsState> emit) {
    if (event.templateId == null) {
      emit(state.copyWith(clearSelectedTemplateId: true));
    } else {
      emit(state.copyWith(selectedTemplateId: event.templateId));
    }
  }

  void _onCustomMessageChanged(CustomMessageChanged event, Emitter<SendSmsState> emit) {
    emit(state.copyWith(customMessage: event.message, clearSelectedTemplateId: true));
  }

  Future<void> _onSendRequested(
      SendRequested event, Emitter<SendSmsState> emit) async {
    final selected =
        state.customers.where((c) => state.selectedIds.contains(c.id)).toList();
    if (selected.isEmpty || state.messageTemplate.trim().isEmpty) return;

    final hasPermission = await _smsService.ensurePermission();
    if (!hasPermission) {
      emit(state.copyWith(error: 'SMS yuborish uchun ruxsat berilmadi.'));
      return;
    }

    emit(state.copyWith(
      phase: SendPhase.sending,
      sentCount: 0,
      totalToSend: selected.length,
      results: const [],
      error: null,
    ));

    final template = state.messageTemplate;
    final jobs = selected
        .map((c) => MapEntry(c.phone, _renderMessage(template, c.smsGreeting)))
        .toList();

    final results = <SmsSendResult>[];
    var i = 0;
    await for (final result in _smsService.sendBulk(phoneAndMessage: jobs)) {
      final customer = selected[i];
      results.add(result);
      await _logRepository.addLog(SmsLog(
        id: '',
        customerName: customer.displayName,
        phone: customer.phone,
        message: jobs[i].value,
        sentByEmail: event.senderEmail,
        success: result.success,
        error: result.error,
      ));
      i++;
      emit(state.copyWith(sentCount: i, results: List.of(results)));
    }

    emit(state.copyWith(phase: SendPhase.done));
  }

  String _renderMessage(String template, String customerName) {
    return template.replaceAll('{ism}', customerName);
  }

  void _onSendReset(SendResetRequested event, Emitter<SendSmsState> emit) {
    emit(state.copyWith(
      phase: SendPhase.idle,
      sentCount: 0,
      totalToSend: 0,
      results: const [],
      selectedIds: {},
      error: null,
    ));
  }

  @override
  Future<void> close() {
    _customersSub?.cancel();
    _templatesSub?.cancel();
    return super.close();
  }
}
