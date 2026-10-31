import 'dart:convert';

import 'package:http/http.dart' as http;

/// Minimal HTTP client for the LearnHarness server API.
///
/// The server is the upstream Next.js app in this fork. It is not bundled
/// in the APK. The user points the app at a server they control in
/// Settings, for example a server on their own machine or local network.
/// No provider keys are stored in this client: provider keys live on the
/// server, exactly as they do on desktop.
///
/// Verified against the upstream routes in this fork:
/// - GET /api/chats -> {"chats": [...]}
/// - POST /api/chats {"title", "kind"} -> {"id", "title"}
/// - GET /api/chats/:id -> the chat record, including "messages"
/// - POST /api/chat {"chatId", "input"} -> turn acceptance
/// - GET /api/graph -> the graph snapshot (nodes, edges)
class ApiClient {
  ApiClient({required this.baseUrl, this.accessToken});

  final String baseUrl;
  final String? accessToken;

  Uri _uri(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path');
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = accessToken;
    if (token?.isNotEmpty ?? false) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Map<String, dynamic>>> listChats() async {
    final response = await http.get(_uri('/api/chats'), headers: _headers);
    _check(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final chats = body['chats'] as List<dynamic>? ?? <dynamic>[];
    return chats.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createChat({
    required String title,
    String? kind,
  }) async {
    final response = await http.post(
      _uri('/api/chats'),
      headers: _headers,
      body: jsonEncode({'title': title, 'kind': kind}),
    );
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getChat(String id) async {
    final response = await http.get(_uri('/api/chats/$id'), headers: _headers);
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Starts a turn. The desktop route accepts the input and the client
  /// then attaches to GET /api/chats/:id/stream for live events.
  /// v1 sends the turn and reloads the record; live SSE streaming is a
  /// follow-up, not claimed here.
  Future<void> sendChat({
    required String chatId,
    required String text,
  }) async {
    final response = await http.post(
      _uri('/api/chat'),
      headers: _headers,
      body: jsonEncode({
        'chatId': chatId,
        'input': {'text': text},
      }),
    );
    _check(response);
  }

  Future<Map<String, dynamic>> getGraph() async {
    final response = await http.get(_uri('/api/graph'), headers: _headers);
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Server returned ${response.statusCode} for ${response.request?.url.path}',
      );
    }
  }
}
