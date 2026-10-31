import 'package:flutter/material.dart';

import '../services/settings_store.dart';

/// Settings: server connection only. Provider keys live on the server,
/// never in this app, and are never entered here.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.onSaved,
  });

  final SettingsStore store;
  final VoidCallback onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final serverUrl = await widget.store.serverUrl();
    final token = await widget.store.accessToken();
    if (mounted) {
      setState(() {
        _serverController.text = serverUrl;
        _tokenController.text = token ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await widget.store.save(
      serverUrl: _serverController.text,
      accessToken: _tokenController.text.isEmpty
          ? null
          : _tokenController.text,
    );
    widget.onSaved();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Server',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serverController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://192.168.1.10:3000',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            labelText: 'Access token (optional)',
            hintText: 'Only if your server requires one',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _save, child: const Text('Save server')),
        const SizedBox(height: 16),
        const Text(
          'Run the server from this fork with npm install, then npm run '
          'dev or npm start. Point this app at that server on the same '
          'network. Provider keys stay on the server.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Not in v1: Claude Code CLI, desktop demo builder, offline '
          'teaching, and local file access. See android/README.md.',
        ),
      ],
    );
  }
}
