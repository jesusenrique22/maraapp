import 'dart:html' as html;

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
  static const _tokenKey = 'farmaexpress_admin_token';
  static const _emailKey = 'farmaexpress_admin_email';
  static const _nameKey = 'farmaexpress_admin_name';
  static const _userIdKey = 'farmaexpress_admin_user_id';
  static const _roleKey = 'farmaexpress_admin_role';
  static const _avatarUrlKey = 'farmaexpress_admin_avatar_url';

  Future<void> saveSession({
    required String token,
    required String email,
    required String name,
    required String userId,
    required String role,
    String? avatarUrl,
  }) async {
    html.window.localStorage[_tokenKey] = token;
    html.window.localStorage[_emailKey] = email;
    html.window.localStorage[_nameKey] = name;
    html.window.localStorage[_userIdKey] = userId;
    html.window.localStorage[_roleKey] = role;
    if (avatarUrl != null) {
      html.window.localStorage[_avatarUrlKey] = avatarUrl;
    } else {
      html.window.localStorage.remove(_avatarUrlKey);
    }
  }

  Future<StoredSession?> readSession() async {
    final token = html.window.localStorage[_tokenKey];
    final email = html.window.localStorage[_emailKey];
    final name = html.window.localStorage[_nameKey];
    final userId = html.window.localStorage[_userIdKey];
    final role = html.window.localStorage[_roleKey];
    final avatarUrl = html.window.localStorage[_avatarUrlKey];

    if (token == null || token.isEmpty || email == null || name == null) {
      return null;
    }

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
    html.window.localStorage.remove(_tokenKey);
    html.window.localStorage.remove(_emailKey);
    html.window.localStorage.remove(_nameKey);
    html.window.localStorage.remove(_userIdKey);
    html.window.localStorage.remove(_roleKey);
    html.window.localStorage.remove(_avatarUrlKey);
  }
}
