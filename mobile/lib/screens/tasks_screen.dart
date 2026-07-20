import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/task_tile.dart';

/// "Görevler" ekranı: tüm görev/rutin listesi, ekleme ve tamamlama.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().load();
    });
  }

  Future<void> _addTask() async {
    final result = await showAddTaskSheet(context);
    if (result == null || !mounted) return;
    try {
      await context.read<TaskProvider>().addTask(
            result.title,
            type: result.type,
            priority: result.priority,
            date: result.date,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görev eklenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = _showCompleted ? provider.tasks : provider.tasks.where((t) => !t.isDone).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text('${tasks.length} görev', style: const TextStyle(color: AppColors.textDim)),
                const Spacer(),
                const Text('Tamamlananlar', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                Switch(
                  value: _showCompleted,
                  onChanged: (v) => setState(() => _showCompleted = v),
                ),
              ],
            ),
          ),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'Görevler yüklenemedi: ${provider.error}',
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: tasks.isEmpty && !provider.isLoading
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text('Henüz görev yok.', style: TextStyle(color: AppColors.textDim)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 90, top: 4),
                      itemCount: tasks.length,
                      itemBuilder: (context, i) => TaskTile(
                        task: tasks[i],
                        onToggle: () => provider.toggle(tasks[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Yeni görev ekle',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
