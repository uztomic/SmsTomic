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

  static const _networkTimeout = Duration(seconds: 12);

  Future<bool> addCustomer({
    required String name,
    required String phone,
    required String createdBy,
  }) async {
    try {
      await _repository
          .addCustomer(name: name, phone: phone, createdBy: createdBy)
          .timeout(_networkTimeout);
      emit(state.copyWith(actionMessage: 'Mijoz qo\'shildi.'));
      return true;
    } on TimeoutException {
      emit(state.copyWith(error: 'Internet aloqasi yo\'q yoki juda sekin. Qayta urinib ko\'ring.'));
      return false;
    } catch (e) {
      emit(state.copyWith(error: 'Mijoz qo\'shishda xatolik: ${e.toString()}'));
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer).timeout(_networkTimeout);
      emit(state.copyWith(actionMessage: 'Mijoz yangilandi.'));
      return true;
    } on TimeoutException {
      emit(state.copyWith(error: 'Internet aloqasi yo\'q yoki juda sekin. Qayta urinib ko\'ring.'));
      return false;
    } catch (e) {
      emit(state.copyWith(error: 'Mijozni yangilashda xatolik: ${e.toString()}'));
      return false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _repository.deleteCustomer(id).timeout(_networkTimeout);
    } on TimeoutException {
      emit(state.copyWith(error: 'Internet aloqasi yo\'q yoki juda sekin. Qayta urinib ko\'ring.'));
    } catch (_) {
      emit(state.copyWith(error: 'Mijozni o\'chirishda xatolik yuz berdi.'));
    }
  }

  Future<void> importBulk(
    List<({String name, String phone})> customers,
    String createdBy,
  ) async {
    try {
      final added = await _repository
          .addCustomersBulk(customers, createdBy)
          .timeout(_networkTimeout * 3);
      emit(state.copyWith(actionMessage: '$added ta mijoz import qilindi.'));
    } on TimeoutException {
      emit(state.copyWith(error: 'Internet aloqasi yo\'q yoki juda sekin. Qayta urinib ko\'ring.'));
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
