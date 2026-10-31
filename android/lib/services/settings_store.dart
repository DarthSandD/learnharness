import 'package:shared_preferences/shared_preferences.dart';

/// Server connection settings only. No provider keys are stored here.
class SettingsStore {
  static const _serverUrlKey = 'server_url';
  static const _accessTokenKey = 'access_token';

  Future<String> serverUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? '';
  }

  Future<String?> accessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<void> save({
    required String serverUrl,
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, serverUrl.trim());
    if (accessToken == null || accessToken.trim().isEmpty) {
      await prefs.remove(_accessTokenKey);
    } else {
      await prefs.setString(_accessTokenKey, accessToken.trim());
    }
  }
}
