part of 'customer_cubit.dart';

class CustomerState extends Equatable {
  final List<Customer> customers;
  final bool loading;
  final String? error;
  final String? actionMessage;

  const CustomerState({
    this.customers = const [],
    this.loading = true,
    this.error,
    this.actionMessage,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? loading,
    String? error,
    String? actionMessage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      loading: loading ?? this.loading,
      error: error,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [customers, loading, error, actionMessage];
}
