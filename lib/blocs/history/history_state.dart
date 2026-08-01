part of 'history_cubit.dart';

class HistoryState extends Equatable {
  final List<SmsLog> logs;
  final bool loading;

  const HistoryState({this.logs = const [], this.loading = true});

  HistoryState copyWith({List<SmsLog>? logs, bool? loading}) {
    return HistoryState(
      logs: logs ?? this.logs,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [logs, loading];
}
