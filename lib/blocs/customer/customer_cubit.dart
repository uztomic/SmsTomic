import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

part 'customer_state.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final CustomerRepository _repository;
  StreamSubscription<List<Customer>>? _subscription;

  CustomerCubit(this._repository) : super(const CustomerState()) {
    _subscription = _repository.watchCustomers().listen(
      (customers) => emit(state.copyWith(customers: customers, loading: false)),
      onError: (_) =>
          emit(state.copyWith(loading: false, error: 'Mijozlarni yuklashda xatolik.')),
    );
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String createdBy,
  }) async {
    try {
      await _repository.addCustomer(name: name, phone: phone, createdBy: createdBy);
    } catch (_) {
      emit(state.copyWith(error: 'Mijoz qo\'shishda xatolik yuz berdi.'));
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
    } catch (_) {
      emit(state.copyWith(error: 'Mijozni yangilashda xatolik yuz berdi.'));
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id);
    } catch (_) {
      emit(state.copyWith(error: 'Mijozni o\'chirishda xatolik yuz berdi.'));
    }
  }

  Future<void> importBulk(
    List<({String name, String phone})> customers,
    String createdBy,
  ) async {
    try {
      final added = await _repository.addCustomersBulk(customers, createdBy);
      emit(state.copyWith(actionMessage: '$added ta mijoz import qilindi.'));
    } catch (_) {
      emit(state.copyWith(error: 'Import qilishda xatolik yuz berdi.'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
