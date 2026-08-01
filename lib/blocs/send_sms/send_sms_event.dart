part of 'send_sms_bloc.dart';

sealed class SendSmsEvent extends Equatable {
  const SendSmsEvent();

  @override
  List<Object?> get props => [];
}

class SendSmsStarted extends SendSmsEvent {
  const SendSmsStarted();
}

class _CustomersUpdated extends SendSmsEvent {
  final List<Customer> customers;

  const _CustomersUpdated(this.customers);

  @override
  List<Object?> get props => [customers];
}

class _TemplatesUpdated extends SendSmsEvent {
  final List<SmsTemplate> templates;

  const _TemplatesUpdated(this.templates);

  @override
  List<Object?> get props => [templates];
}

class ToggleCustomerSelection extends SendSmsEvent {
  final String customerId;

  const ToggleCustomerSelection(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class SelectAllCustomers extends SendSmsEvent {
  const SelectAllCustomers();
}

class DeselectAllCustomers extends SendSmsEvent {
  const DeselectAllCustomers();
}

class TemplateSelected extends SendSmsEvent {
  final String? templateId;

  const TemplateSelected(this.templateId);

  @override
  List<Object?> get props => [templateId];
}

class CustomMessageChanged extends SendSmsEvent {
  final String message;

  const CustomMessageChanged(this.message);

  @override
  List<Object?> get props => [message];
}

class SendRequested extends SendSmsEvent {
  final String senderEmail;

  const SendRequested(this.senderEmail);

  @override
  List<Object?> get props => [senderEmail];
}

class SendResetRequested extends SendSmsEvent {
  const SendResetRequested();
}
