import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// v1 session detail: loads the server record and sends one turn.
///
/// The server record's messages are native agent history. v1 renders a
/// best-effort text line per message: assistant text when present, otherwise
/// a short label for the message kind. Live SSE streaming, question docks,
/// confidence rails, and plan rendering are follow-ups, not claimed here.
class ChatDetail extends StatefulWidget {
  const ChatDetail({super.key, required this.client, required this.chatId});

  final ApiClient client;
  final String chatId;

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final _inputController = TextEditingController();
  Map<String, dynamic>? _record;
  String? _error;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ChatDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId ||
        oldWidget.client.baseUrl != widget.client.baseUrl) {
      _load();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await widget.client.getChat(widget.chatId);
      if (mounted) {
        setState(() {
          _record = record;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.client.sendChat(chatId: widget.chatId, text: text);
      _inputController.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final record = _record ?? <String, dynamic>{};
    final messages = (record['messages'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No messages yet. Send your first message below.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MessageLine(message: message);
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: 'Explain your reasoning',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 4,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageLine extends StatelessWidget {
  const _MessageLine({required this.message});

  final Map<String, dynamic> message;

  String _text() {
    final content = message['content'];
    if (content is String && content.isNotEmpty) return content;
    if (content is List) {
      final parts = content
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join('\n');
    }
    final kind = message['kind'] ?? message['role'] ?? 'message';
    return '[$kind]';
  }

  @override
  Widget build(BuildContext context) {
    final role = (message['role'] as String?) ?? 'assistant';
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Text(_text(), style: const TextStyle(fontSize: 16, height: 1.5)),
      ),
    );
  }
}
