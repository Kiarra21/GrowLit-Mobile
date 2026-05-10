import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  const UserSession({required this.username, required this.email});

  final String username;
  final String email;
}

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  static const String _usernameKey = 'session_username';
  static const String _emailKey = 'session_email';
  static const String _lastActiveKey = 'session_last_active_at';
  static const Duration _sessionTimeout = Duration(days: 7);

  Future<void> saveSession({
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<UserSession?> getValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final email = prefs.getString(_emailKey);
    final lastActive = prefs.getInt(_lastActiveKey);

    if (username == null || email == null || lastActive == null) {
      return null;
    }

    final lastActiveAt = DateTime.fromMillisecondsSinceEpoch(lastActive);
    final isExpired = DateTime.now().difference(lastActiveAt) > _sessionTimeout;

    if (isExpired) {
      await clearSession();
      return null;
    }

    await refreshSession();
    return UserSession(username: username, email: email);
  }

  Future<void> refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_usernameKey) && prefs.containsKey(_emailKey)) {
      await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_lastActiveKey);
  }
}
