import 'package:flutter/material.dart';

import 'screens/graph_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/teaching_screen.dart';
import 'services/api_client.dart';
import 'services/settings_store.dart';

/// LearnHarness Android v1.
///
/// Desktop tokens, adapted only for phone width:
/// background #141414, raised #1c1c1c, edge #434343, text #e6e6e6,
/// muted #8d8d8d. Titles use a serif face, chrome uses the default
/// sans face in this Flutter build (JetBrains Mono is not bundled yet).
/// The app is a client for the LearnHarness server in this fork; it does
/// not bundle the server, Electron, or the Claude Code CLI.
void main() {
  runApp(const LearnHarnessApp());
}

class LearnHarnessApp extends StatefulWidget {
  const LearnHarnessApp({super.key});

  @override
  State<LearnHarnessApp> createState() => _LearnHarnessAppState();
}

class _LearnHarnessAppState extends State<LearnHarnessApp> {
  final _settingsStore = SettingsStore();
  ApiClient? _client;
  int _tab = 0;
  String? _selectedChatId;

  @override
  void initState() {
    super.initState();
    _reloadClient();
  }

  Future<void> _reloadClient() async {
    final serverUrl = await _settingsStore.serverUrl();
    final token = await _settingsStore.accessToken();
    if (mounted) {
      setState(() {
        _client = serverUrl.isEmpty
            ? null
            : ApiClient(baseUrl: serverUrl, accessToken: token);
      });
    }
  }

  void _openSession(String id) {
    setState(() {
      _selectedChatId = id.isEmpty ? null : id;
      _tab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF141414);
    const raised = Color(0xFF1C1C1C);
    const edge = Color(0xFF434343);
    const foreground = Color(0xFFE6E6E6);
    const muted = Color(0xFF8D8D8D);
    return MaterialApp(
      title: 'LearnHarness',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: foreground,
          onPrimary: background,
          surface: background,
          surfaceContainer: raised,
          outline: edge,
          onSurface: foreground,
          onSurfaceVariant: muted,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('LearnHarness')),
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(client: _client, onOpenSession: _openSession),
            TeachingScreen(
              client: _client,
              selectedChatId: _selectedChatId,
              onSelectSession: _openSession,
            ),
            PracticeScreen(client: _client),
            GraphScreen(client: _client),
            SettingsScreen(store: _settingsStore, onSaved: _reloadClient),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            setState(() {
              _tab = index;
              if (index != 1) _selectedChatId = null;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Learn'),
            NavigationDestination(icon: Icon(Icons.school), label: 'Teach'),
            NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Practice'),
            NavigationDestination(icon: Icon(Icons.account_tree), label: 'Graph'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
