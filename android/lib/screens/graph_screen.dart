import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Knowledge graph: v1 lists the snapshot's nodes and edges as text.
/// A pinch-zoom canvas is a follow-up; the data source is already the
/// server's GET /api/graph snapshot.
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key, required this.client});

  final ApiClient? client;

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Map<String, dynamic>? _graph;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GraphScreen oldWidget) {
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
      final graph = await client.getGraph();
      if (mounted) {
        setState(() {
          _graph = graph;
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

  String _label(Map<String, dynamic> node) {
    final name = node['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    final statement = node['statement'] as String?;
    if (statement != null && statement.isNotEmpty) return statement;
    return (node['id'] as String?) ?? 'Proposition';
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
    final graph = _graph ?? <String, dynamic>{};
    final nodes = (graph['nodes'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    final edges = (graph['edges'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (nodes.isEmpty && edges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No graph content yet. Teach a session and extraction will '
            'add propositions and chains here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Propositions: ${nodes.length}'),
        const SizedBox(height: 8),
        Text('Chains: ${edges.length}'),
        const SizedBox(height: 16),
        for (final node in nodes)
          ListTile(title: Text(_label(node))),
      ],
    );
  }
}
