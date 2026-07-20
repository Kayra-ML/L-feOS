import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme.dart';
import '../providers/journal_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/journal_tile.dart';
import '../widgets/task_tile.dart';

/// Kısayoldan açılan tam ekran aylık takvim.
///
/// Web sürümündeki `renderCalendar()` mantığının karşılığı: her günün
/// altında o güne ait görev/günlük sayısını nokta olarak gösterir,
/// seçili günün detayları altta listelenir.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().load();
      context.read<JournalProvider>().load();
    });
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final journalProvider = context.watch<JournalProvider>();

    final selectedIso = _iso(_selectedDay);
    final dayTasks = taskProvider.tasks.where((t) => t.date == selectedIso).toList();
    final dayJournals = journalProvider.journals.where((j) => j.date == selectedIso).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: RefreshIndicator(
        onRefresh: () async {
          await taskProvider.load();
          await journalProvider.load();
        },
        child: ListView(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) => _focusedDay = focused,
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: AppColors.line, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: AppColors.aiPurple, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  outsideDaysVisible: false,
                ),
                eventLoader: (day) {
                  final iso = _iso(day);
                  final count = taskProvider.tasks.where((t) => t.date == iso).length +
                      journalProvider.journals.where((j) => j.date == iso).length;
                  return List.filled(count > 3 ? 3 : count, 1);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Text(
                '$selectedIso · Görevler',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDim),
              ),
            ),
            if (dayTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text('Bu tarihte görev yok.', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
              ),
            for (final t in dayTasks) TaskTile(task: t, onToggle: () => taskProvider.toggle(t)),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Text(
                '$selectedIso · Life',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDim),
              ),
            ),
            if (dayJournals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text('Bu tarihte günlük kaydı yok.', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
              ),
            for (final j in dayJournals)
              JournalTile(journal: j, onDelete: () => journalProvider.deleteJournal(j.id)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
