import 'package:shared_preferences/shared_preferences.dart';

class StoredSession {
  const StoredSession({
    required this.token,
    required this.email,
    required this.name,
    this.userId,
    this.role,
    this.avatarUrl,
  });

  final String token;
  final String email;
  final String name;
  final String? userId;
  final String? role;
  final String? avatarUrl;
}

class AuthStorageImpl {
  static const _tokenKey = 'maraplus_admin_token';
  static const _emailKey = 'maraplus_admin_email';
  static const _nameKey = 'maraplus_admin_name';
  static const _userIdKey = 'maraplus_admin_user_id';
  static const _roleKey = 'maraplus_admin_role';
  static const _avatarUrlKey = 'maraplus_admin_avatar_url';

  Future<void> saveSession({
    required String token,
    required String email,
    required String name,
    required String userId,
    required String role,
    String? avatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_roleKey, role);
    if (avatarUrl != null) {
      await prefs.setString(_avatarUrlKey, avatarUrl);
    } else {
      await prefs.remove(_avatarUrlKey);
    }
  }

  Future<StoredSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final email = prefs.getString(_emailKey);
    final name = prefs.getString(_nameKey);
    final userId = prefs.getString(_userIdKey);
    final role = prefs.getString(_roleKey);
    final avatarUrl = prefs.getString(_avatarUrlKey);

    if (token == null || email == null || name == null) return null;

    return StoredSession(
      token: token,
      email: email,
      name: name,
      userId: userId,
      role: role,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_avatarUrlKey);
  }
}
