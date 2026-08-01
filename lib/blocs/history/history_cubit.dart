import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/sms_log.dart';
import '../../repositories/log_repository.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final LogRepository _repository;
  StreamSubscription<List<SmsLog>>? _subscription;

  HistoryCubit(this._repository) : super(const HistoryState()) {
    _subscription = _repository.watchRecentLogs().listen(
      (logs) => emit(state.copyWith(logs: logs, loading: false)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
