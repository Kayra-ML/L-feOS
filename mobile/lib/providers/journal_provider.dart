import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/journal.dart';

class JournalProvider extends ChangeNotifier {
  JournalProvider(this._api);

  final ApiClient _api;

  List<Journal> _journals = [];
  bool _isLoading = false;
  String? _error;

  List<Journal> get journals => _journals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.getJournals();
      _journals = raw.map((e) => Journal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addJournal({
    required String content,
    String? category,
    String? date,
    String? time,
  }) async {
    await _api.createJournal(content: content, category: category, date: date, time: time);
    await load();
  }

  Future<void> deleteJournal(String id) async {
    _journals = _journals.where((j) => j.id != id).toList();
    notifyListeners();
    try {
      await _api.deleteJournal(id);
    } finally {
      await load();
    }
  }
}
