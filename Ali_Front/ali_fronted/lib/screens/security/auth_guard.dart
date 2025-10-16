// lib/security/auth_guard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGuard {
  /// Lee el access token guardado
  static Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Decodifica payload del JWT (sin validar firma)
  static Map<String, dynamic> _decodeJWT(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  /// ¿Está expirado por el claim `exp`?
  static bool _isExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp is int) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= exp;
    }
    return false; // si no hay exp, asumimos válido para no romper flujo
  }

  /// ¿Hay sesión válida?
  static Future<bool> isLoggedIn() async {
    final tok = await _readToken();
    if (tok == null || tok.isEmpty) return false;
    final payload = _decodeJWT(tok);
    if (_isExpired(payload)) return false;
    return true;
  }

  /// Devuelve rol (si existe en el JWT)
  static Future<String?> getRole() async {
    final tok = await _readToken();
    if (tok == null) return null;
    final payload = _decodeJWT(tok);
    return payload['rol']?.toString();
  }

  /// Verifica acceso por rol (si no pasas roles, basta con estar logeado)
  static Future<bool> canAccess({List<String>? roles}) async {
    if (!await isLoggedIn()) return false;
    if (roles == null || roles.isEmpty) return true;
    final r = await getRole();
    return r != null && roles.contains(r);
  }

  /// Úsalo en pantallas (post-frame) para redirigir si no cumple
  static Future<void> redirectIfNotAllowed(
    BuildContext context, {
    List<String>? roles,
    String loginRouteName = '/login',
  }) async {
    if (!await canAccess(roles: roles)) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(loginRouteName, (_) => false);
    }
  }
}

/// Wrapper de comodidad para rutas protegidas con Navigator 1.0
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final List<String>? requireRoles;
  final String loginRouteName;

  const ProtectedRoute({
    super.key,
    required this.child,
    this.requireRoles,
    this.loginRouteName = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthGuard.canAccess(roles: requireRoles),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) return child;

        // No permitido → fuera
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(loginRouteName, (_) => false);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}
