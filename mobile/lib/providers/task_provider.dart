import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._api);

  final ApiClient _api;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Task> tasksForDate(String isoDate) =>
      _tasks.where((t) => t.date == isoDate).toList();

  List<Task> get todayTasks {
    final today = DateTime.now();
    final iso =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return tasksForDate(iso);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.getTasks(showCompleted: true);
      _tasks = raw.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String title, {String type = 'Görev', String priority = 'Orta', String? date}) async {
    await _api.createTask(title: title, type: type, priority: priority, date: date);
    await load();
  }

  Future<void> toggle(Task task) async {
    // Optimistic update — anında geri bildirim için.
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task.copyWith(isDone: !task.isDone);
      notifyListeners();
    }
    try {
      await _api.toggleTask(task.id);
    } catch (e) {
      // Hata olursa geri al.
      if (idx != -1) {
        _tasks[idx] = task;
        notifyListeners();
      }
      rethrow;
    }
  }
}
