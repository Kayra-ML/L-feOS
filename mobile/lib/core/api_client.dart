import 'dart:convert';
import 'package:http/http.dart' as http;

import 'app_settings.dart';

/// Backend'den (LifeOS FastAPI) dönen hatalar için.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Tüm `backend/api.py` endpoint'lerine erişimi tek yerden yöneten istemci.
///
/// Base URL, [AppSettings] üzerinden okunur — bu sayede kullanıcı Ayarlar
/// ekranından IP'yi değiştirdiğinde tüm istekler otomatik yeni adrese gider.
class ApiClient {
  ApiClient(this._settings);

  final AppSettings _settings;
  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${_settings.baseUrl}$path').replace(
      queryParameters: query,
    );
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Sunucudan geçersiz yanıt geldi (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final detail = body['detail'];
      throw ApiException(
        detail is String ? detail : 'İstek başarısız (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    try {
      final res = await http.get(_uri(path, query)).timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Sunucuya bağlanılamadı: $e');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Sunucuya bağlanılamadı: $e');
    }
  }

  Future<Map<String, dynamic>> _patch(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http
          .patch(
            _uri(path),
            headers: const {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Sunucuya bağlanılamadı: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final res = await http.delete(_uri(path)).timeout(_timeout);
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Sunucuya bağlanılamadı: $e');
    }
  }

  // ─── Görevler / Rutinler ───────────────────────────────────

  Future<List<dynamic>> getTasks({String? date, bool showCompleted = true}) async {
    final query = <String, String>{'show_completed': showCompleted.toString()};
    if (date != null) query['date'] = date;
    final body = await _get('/api/tasks', query);
    return body['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    String type = 'Görev',
    String priority = 'Orta',
    String? date,
  }) async {
    final body = await _post('/api/tasks', {
      'title': title,
      'type': type,
      'priority': priority,
      if (date != null) 'date': date,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleTask(String id) async {
    final body = await _patch('/api/tasks/$id/toggle');
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(
    String id, {
    String? title,
    String? priority,
    String? date,
    bool? done,
  }) async {
    final body = await _patch('/api/tasks/$id', {
      if (title != null) 'title': title,
      if (priority != null) 'priority': priority,
      if (date != null) 'date': date,
      if (done != null) 'done': done,
    });
    return body['data'] as Map<String, dynamic>;
  }

  // ─── Günlükler (Life) ───────────────────────────────────────

  Future<List<dynamic>> getJournals() async {
    final body = await _get('/api/journals');
    return body['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createJournal({
    required String content,
    String? category,
    String? date,
    String? time,
  }) async {
    final body = await _post('/api/journals', {
      'content': content,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (time != null) 'time': time,
    });
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> deleteJournal(String id) async {
    await _delete('/api/journals/$id');
  }

  // ─── Second Brain ───────────────────────────────────────────

  Future<List<dynamic>> getSecondBrainNotes() async {
    final body = await _get('/api/second-brain');
    return body['data'] as List<dynamic>? ?? [];
  }

  Future<Map<String, dynamic>> createSecondBrainNote({
    required String title,
    String? content,
    List<String>? tags,
    String? date,
  }) async {
    final body = await _post('/api/second-brain', {
      'title': title,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (date != null) 'date': date,
    });
    return body['data'] as Map<String, dynamic>;
  }

  // ─── Z-Asistan ────────────────────────────────────────────

  Future<String> sendChatMessage(String message) async {
    final body = await _post('/api/chat', {'message': message});
    return body['answer'] as String? ?? '';
  }

  Future<Map<String, dynamic>> healthCheck() => _get('/health');
}
