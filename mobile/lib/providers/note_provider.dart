import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/second_brain_note.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider(this._api);

  final ApiClient _api;

  List<SecondBrainNote> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<SecondBrainNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final raw = await _api.getSecondBrainNotes();
      _notes = raw.map((e) => SecondBrainNote.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote({
    required String title,
    String? content,
    List<String>? tags,
    String? date,
  }) async {
    await _api.createSecondBrainNote(title: title, content: content, tags: tags, date: date);
    await load();
  }
}
