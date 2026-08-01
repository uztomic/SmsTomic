import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final firebaseUser = _authRepository.currentFirebaseUser;
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    final appUser = await _authRepository.fetchAppUser(firebaseUser.uid);
    if (appUser == null) {
      await _authRepository.logout();
      emit(const AuthUnauthenticated(
        message: 'Hisobingiz topilmadi, admin bilan bog\'laning.',
      ));
      return;
    }
    emit(AuthAuthenticated(appUser));
  }

  Future<void> _onLoginRequested(
      LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await _authRepository.login(email: event.email, password: event.password);
      final firebaseUser = _authRepository.currentFirebaseUser!;
      final appUser = await _authRepository.fetchAppUser(firebaseUser.uid);
      if (appUser == null) {
        await _authRepository.logout();
        emit(const AuthUnauthenticated(
          message: 'Hisobingiz topilmadi, admin bilan bog\'laning.',
        ));
        return;
      }
      emit(AuthAuthenticated(appUser));
    } on FirebaseAuthException catch (e) {
      emit(AuthUnauthenticated(message: _mapAuthError(e)));
    } catch (_) {
      emit(const AuthUnauthenticated(message: 'Kirishda xatolik yuz berdi.'));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email yoki parol noto\'g\'ri.';
      case 'email-already-in-use':
        return 'Bu email allaqachon ro\'yxatdan o\'tgan.';
      case 'weak-password':
        return 'Parol juda oddiy, kamida 6 ta belgi kiriting.';
      case 'invalid-email':
        return 'Email manzil noto\'g\'ri.';
      case 'network-request-failed':
        return 'Internet aloqasi yo\'q.';
      default:
        return e.message ?? 'Xatolik yuz berdi.';
    }
  }
}
