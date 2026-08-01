part of 'user_cubit.dart';

class UserState extends Equatable {
  final List<AppUser> users;
  final bool loading;
  final bool creating;
  final String? error;
  final String? actionMessage;

  const UserState({
    this.users = const [],
    this.loading = true,
    this.creating = false,
    this.error,
    this.actionMessage,
  });

  UserState copyWith({
    List<AppUser>? users,
    bool? loading,
    bool? creating,
    String? error,
    String? actionMessage,
  }) {
    return UserState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      creating: creating ?? this.creating,
      error: error,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [users, loading, creating, error, actionMessage];
}
