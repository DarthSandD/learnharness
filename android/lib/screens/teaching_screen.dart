import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/chat_detail.dart';

/// Teaching: session list, then the selected session detail.
/// v1 does not yet render question docks, confidence rails, or the plan
/// tree as native widgets; those arrive as the server record is projected
/// in a follow-up.
class TeachingScreen extends StatefulWidget {
  const TeachingScreen({
    super.key,
    required this.client,
    required this.selectedChatId,
    required this.onSelectSession,
  });

  final ApiClient? client;
  final String? selectedChatId;
  final ValueChanged<String> onSelectSession;

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> {
  List<Map<String, dynamic>> _chats = [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TeachingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client?.baseUrl != widget.client?.baseUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    final client = widget.client;
    if (client == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chats = await client.listChats();
      if (mounted) {
        setState(() {
          _chats = chats;
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

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final selectedId = widget.selectedChatId;
    if (client == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Set your LearnHarness server in Settings first.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (selectedId != null) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: const Text('Back to sessions'),
            onTap: () => widget.onSelectSession(''),
          ),
          Expanded(child: ChatDetail(client: client, chatId: selectedId)),
        ],
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
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
    if (_chats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No sessions yet. Start one from Home.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final id = chat['id'] as String?;
        return ListTile(
          title: Text(
            (chat['title'] as String?) ?? 'Untitled session',
            style: const TextStyle(
              fontFamily: 'serif',
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text((chat['phase'] as String?) ?? ''),
          onTap: id == null ? null : () => widget.onSelectSession(id),
        );
      },
    );
  }
}
