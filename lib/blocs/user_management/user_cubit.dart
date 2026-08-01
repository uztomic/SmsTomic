import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final AuthRepository _repository;
  StreamSubscription<List<AppUser>>? _subscription;

  UserCubit(this._repository) : super(const UserState()) {
    _subscription = _repository.watchUsers().listen(
      (users) => emit(state.copyWith(users: users, loading: false)),
      onError: (_) =>
          emit(state.copyWith(loading: false, error: 'Foydalanuvchilarni yuklashda xatolik.')),
    );
  }

  Future<void> createWorker({
    required String email,
    required String password,
    required String name,
    required Set<Permission> permissions,
  }) async {
    emit(state.copyWith(creating: true, error: null));
    try {
      await _repository.createWorker(
        email: email,
        password: password,
        name: name,
        permissions: permissions,
      );
      emit(state.copyWith(creating: false, actionMessage: 'Xodim hisobi yaratildi.'));
    } catch (e) {
      emit(state.copyWith(creating: false, error: 'Hisob yaratishda xatolik: ${e.toString()}'));
    }
  }

  Future<void> revokeUser(String uid) async {
    try {
      await _repository.revokeUser(uid);
    } catch (_) {
      emit(state.copyWith(error: 'Hisobni bekor qilishda xatolik yuz berdi.'));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
