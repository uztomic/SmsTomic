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
  StreamSubscription<SmsSendResult>? _sendSubscription;
  Completer<void>? _sendCompleter;

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
    on<_SimsLoaded>(_onSimsLoaded);
    on<SimSelected>((e, emit) => emit(state.copyWith(selectedSubscriptionId: e.subscriptionId)));
    on<ToggleCustomerSelection>(_onToggleCustomer);
    on<SelectAllCustomers>(_onSelectAll);
    on<DeselectAllCustomers>(_onDeselectAll);
    on<TemplateSelected>(_onTemplateSelected);
    on<CustomMessageChanged>(_onCustomMessageChanged);
    on<SendRequested>(_onSendRequested);
    on<SendResetRequested>(_onSendReset);
    on<PauseSendRequested>(_onPauseSend);
    on<ResumeSendRequested>(_onResumeSend);
    on<StopSendRequested>(_onStopSend);
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
    _smsService.getAvailableSims().then((sims) => add(_SimsLoaded(sims)));
  }

  void _onSimsLoaded(_SimsLoaded event, Emitter<SendSmsState> emit) {
    emit(state.copyWith(
      availableSims: event.sims,
      selectedSubscriptionId: event.sims.isNotEmpty ? event.sims.first.subscriptionId : null,
    ));
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

    await _smsService.startSendProgress(selected.length);

    final template = state.messageTemplate;
    final jobs = selected
        .map((c) => MapEntry(c.phone, _renderMessage(template, c.smsGreeting)))
        .toList();

    final results = <SmsSendResult>[];
    var i = 0;
    final completer = Completer<void>();
    _sendCompleter = completer;

    _sendSubscription = _smsService
        .sendBulk(
          phoneAndMessage: jobs,
          subscriptionId: state.selectedSubscriptionId,
        )
        .listen(
      (result) {
        final customer = selected[i];
        results.add(result);
        unawaited(_logRepository.addLog(SmsLog(
          id: '',
          customerName: customer.displayName,
          phone: customer.phone,
          message: jobs[i].value,
          sentByEmail: event.senderEmail,
          success: result.success,
          error: result.error,
        )));
        i++;
        emit(state.copyWith(sentCount: i, results: List.of(results)));
        unawaited(_smsService.updateSendProgress(i, selected.length));
      },
      onDone: () {
        unawaited(_smsService.completeSendProgress(i, selected.length));
        emit(state.copyWith(phase: SendPhase.done));
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_) {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: false,
    );

    await completer.future;
    _sendSubscription = null;
    _sendCompleter = null;
  }

  void _onPauseSend(PauseSendRequested event, Emitter<SendSmsState> emit) {
    if (state.phase != SendPhase.sending) return;
    _sendSubscription?.pause();
    emit(state.copyWith(phase: SendPhase.paused));
  }

  void _onResumeSend(ResumeSendRequested event, Emitter<SendSmsState> emit) {
    if (state.phase != SendPhase.paused) return;
    _sendSubscription?.resume();
    emit(state.copyWith(phase: SendPhase.sending));
  }

  Future<void> _onStopSend(StopSendRequested event, Emitter<SendSmsState> emit) async {
    await _sendSubscription?.cancel();
    _sendSubscription = null;
    await _smsService.completeSendProgress(state.sentCount, state.totalToSend);
    emit(state.copyWith(phase: SendPhase.done));
    final completer = _sendCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _sendCompleter = null;
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
    _sendSubscription?.cancel();
    return super.close();
  }
}
