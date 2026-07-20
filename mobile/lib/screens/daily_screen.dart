import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/journal_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';

/// "Daily" ekranı: bugünün görevleri + son günlük kayıtları için hızlı özet.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().load();
      context.read<JournalProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final journalProvider = context.watch<JournalProvider>();
    final todayTasks = taskProvider.todayTasks;
    final today = intl.DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: () async {
        await taskProvider.load();
        await journalProvider.load();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
            child: Text(
              today,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
            child: Text(
              'Bugün ${todayTasks.length} görev',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          if (taskProvider.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (taskProvider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'Görevler yüklenemedi: ${taskProvider.error}',
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          if (!taskProvider.isLoading && todayTasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Text(
                'Bugün için planlanmış bir görev yok. 🎉',
                style: TextStyle(color: AppColors.textDim),
              ),
            ),
          for (final task in todayTasks)
            TaskTile(
              task: task,
              onToggle: () => taskProvider.toggle(task),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 10),
            child: Text(
              'Son Günlük Kayıtları',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          if (journalProvider.journals.isEmpty && !journalProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text('Henüz günlük kaydı yok.', style: TextStyle(color: AppColors.textDim)),
            ),
          for (final j in journalProvider.journals.take(5))
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: ListTile(
                leading: const Icon(Icons.menu_book_rounded, color: AppColors.aiPurple),
                title: Text(j.content),
                subtitle: Text(
                  [j.category, j.date, j.time].where((e) => e != null && e.isNotEmpty).join(' · '),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
