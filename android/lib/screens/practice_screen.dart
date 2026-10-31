import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/chat_detail.dart';

/// Practice: start a practice session, then work it in the same detail
/// view as teaching. Practice problems, hints, and conclusions are driven
/// by the server's practitioner agent; v1 does not yet render the
/// practice dock as a separate native widget.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.client});

  final ApiClient? client;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _goalController = TextEditingController();
  String? _chatId;
  String? _error;
  bool _creating = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final client = widget.client;
    final goal = _goalController.text.trim();
    if (client == null || goal.isEmpty) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final chat = await client.createChat(title: goal, kind: 'practice');
      if (mounted) {
        setState(() => _chatId = chat['id'] as String?);
      }
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
    final client = widget.client;
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
    final chatId = _chatId;
    if (chatId != null) {
      return ChatDetail(client: client, chatId: chatId);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'What do you want to practice?',
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
        FilledButton(
          onPressed: _creating ? null : _start,
          child: const Text('Start practice'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!),
        ],
        const SizedBox(height: 12),
        const Text(
          'Practice problems adapt to your reasoning. The solution stays '
          'hidden until you conclude the problem.',
        ),
      ],
    );
  }
}
