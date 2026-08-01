part of 'send_sms_bloc.dart';

enum SendPhase { idle, sending, done }

class SendSmsState extends Equatable {
  final List<Customer> customers;
  final List<SmsTemplate> templates;
  final Set<String> selectedIds;
  final String? selectedTemplateId;
  final String customMessage;
  final SendPhase phase;
  final int sentCount;
  final int totalToSend;
  final List<SmsSendResult> results;
  final String? error;

  const SendSmsState({
    this.customers = const [],
    this.templates = const [],
    this.selectedIds = const {},
    this.selectedTemplateId,
    this.customMessage = '',
    this.phase = SendPhase.idle,
    this.sentCount = 0,
    this.totalToSend = 0,
    this.results = const [],
    this.error,
  });

  String get messageTemplate {
    if (selectedTemplateId == null) return customMessage;
    final match = templates.where((t) => t.id == selectedTemplateId);
    return match.isEmpty ? customMessage : match.first.body;
  }

  bool get allSelected =>
      customers.isNotEmpty && selectedIds.length == customers.length;

  SendSmsState copyWith({
    List<Customer>? customers,
    List<SmsTemplate>? templates,
    Set<String>? selectedIds,
    String? selectedTemplateId,
    bool clearSelectedTemplateId = false,
    String? customMessage,
    SendPhase? phase,
    int? sentCount,
    int? totalToSend,
    List<SmsSendResult>? results,
    String? error,
  }) {
    return SendSmsState(
      customers: customers ?? this.customers,
      templates: templates ?? this.templates,
      selectedIds: selectedIds ?? this.selectedIds,
      selectedTemplateId: clearSelectedTemplateId
          ? null
          : (selectedTemplateId ?? this.selectedTemplateId),
      customMessage: customMessage ?? this.customMessage,
      phase: phase ?? this.phase,
      sentCount: sentCount ?? this.sentCount,
      totalToSend: totalToSend ?? this.totalToSend,
      results: results ?? this.results,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        customers,
        templates,
        selectedIds,
        selectedTemplateId,
        customMessage,
        phase,
        sentCount,
        totalToSend,
        results,
        error,
      ];
}
