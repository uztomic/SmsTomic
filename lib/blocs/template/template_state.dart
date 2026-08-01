part of 'template_cubit.dart';

class TemplateState extends Equatable {
  final List<SmsTemplate> templates;
  final bool loading;
  final String? error;

  const TemplateState({
    this.templates = const [],
    this.loading = true,
    this.error,
  });

  TemplateState copyWith({
    List<SmsTemplate>? templates,
    bool? loading,
    String? error,
  }) {
    return TemplateState(
      templates: templates ?? this.templates,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [templates, loading, error];
}
