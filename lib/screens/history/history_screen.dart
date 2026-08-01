import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/history/history_cubit.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.logs.isEmpty) {
            return Center(
              child: Text('Hali SMS tarixi yo\'q', style: TextStyle(color: Colors.grey.shade500)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: state.logs.length,
            itemBuilder: (context, i) {
              final log = state.logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.roseLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            log.success ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                        child: Icon(
                          log.success ? Icons.check_rounded : Icons.close_rounded,
                          color: log.success ? Colors.green.shade700 : Colors.red.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    log.customerName.isEmpty ? log.phone : log.customerName,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  log.sentAt != null ? dateFormat.format(log.sentAt!) : '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Text(log.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              log.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
