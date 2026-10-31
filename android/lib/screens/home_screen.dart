import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Home: the desktop "What do you want to learn?" composer, plus recent
/// sessions from GET /api/chats. Tapping a session opens it in Teaching.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.client,
    required this.onOpenSession,
  });

  final ApiClient? client;
  final ValueChanged<String> onOpenSession;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _goalController = TextEditingController();
  List<Map<String, dynamic>> _chats = [];
  String? _error;
  bool _loading = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client?.baseUrl != widget.client?.baseUrl) {
      _load();
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
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

  Future<void> _start({String? kind}) async {
    final client = widget.client;
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;
    if (client == null) {
      setState(() {
        _error = 'Set your LearnHarness server in Settings first.';
      });
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final chat = await client.createChat(title: goal, kind: kind);
      final id = chat['id'] as String?;
      if (id != null && mounted) {
        widget.onOpenSession(id);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'What do you want to learn?',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _goalController,
          decoration: const InputDecoration(
            hintText: 'Gradient descent',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _creating ? null : () => _start(),
                child: const Text('Teach'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _creating ? null : () => _start(kind: 'practice'),
                child: const Text('Practice'),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!),
        ],
        const SizedBox(height: 24),
        const Text('Sessions', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_chats.isEmpty)
          const Text('No sessions yet.')
        else
          for (final chat in _chats)
            ListTile(
              title: Text(
                (chat['title'] as String?) ?? 'Untitled session',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                (chat['phase'] as String?) ?? '',
              ),
              onTap: () {
                final id = chat['id'] as String?;
                if (id != null) widget.onOpenSession(id);
              },
            ),
      ],
    );
  }
}
