import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_environment.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String? email;
  final String? displayName;
}

abstract class AuthRepository {
  AuthUser? get currentUser;
  String? get currentUserId => currentUser?.id;
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser?> restoreSession();
  Future<AuthUser?> signInWithGoogle();
  Future<void> signOut();
}

class SupabaseGoogleAuthRepository implements AuthRepository {
  SupabaseGoogleAuthRepository({
    required AppEnvironment environment,
    SupabaseClient? supabaseClient,
    GoogleSignIn? googleSignIn,
  }) : _environment = environment,
       _supabaseClient = supabaseClient,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final AppEnvironment _environment;
  final SupabaseClient? _supabaseClient;
  final GoogleSignIn _googleSignIn;
  final _authController = StreamController<AuthUser?>.broadcast();
  bool _googleInitialized = false;
  AuthUser? _currentUser;

  SupabaseClient? get _client {
    if (!_environment.canInitializeSupabase) {
      return null;
    }
    return _supabaseClient ?? Supabase.instance.client;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  String? get currentUserId => _currentUser?.id;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  Future<AuthUser?> restoreSession() async {
    final client = _client;
    if (client == null) {
      _setCurrentUser(null);
      return null;
    }

    _setCurrentUser(_mapSupabaseUser(client.auth.currentUser));
    return _currentUser;
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Configura SUPABASE_URL, SUPABASE_ANON_KEY y ENABLE_REMOTE_SYNC=true.',
      );
    }

    await _initializeGoogleSignIn();
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );
    } catch (e) {
      throw StateError('Google Sign-In falló: $e');
    }

    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google no devolvió un idToken válido.');
    }

    final AuthResponse response;
    try {
      response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      final audience = _jwtClaim(idToken, 'aud');
      throw StateError(
        'Supabase rechazó el token de Google: $e. '
        'Audience del token: ${audience ?? 'no disponible'}. '
        'Configura ese Client ID en Supabase Auth > Google.',
      );
    }

    final user = _mapSupabaseUser(response.user ?? client.auth.currentUser);
    if (user == null) {
      throw StateError('Supabase no devolvió una sesión de usuario válida.');
    }
    _setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
    if (_googleInitialized) {
      await _googleSignIn.signOut();
    }
    _setCurrentUser(null);
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }
    await _googleSignIn.initialize(
      clientId: _optionalEnvironmentValue(_environment.googleClientId),
      serverClientId: _optionalEnvironmentValue(
        _environment.googleServerClientId,
      ),
    );
    _googleInitialized = true;
  }

  String? _optionalEnvironmentValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _jwtClaim(String token, String claim) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final values = jsonDecode(payload) as Map<String, dynamic>;
      final value = values[claim];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }

  AuthUser? _mapSupabaseUser(User? user) {
    if (user == null) {
      return null;
    }
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName:
          metadata['full_name'] as String? ??
          metadata['name'] as String? ??
          metadata['display_name'] as String?,
    );
  }

  void _setCurrentUser(AuthUser? user) {
    _currentUser = user;
    _authController.add(user);
  }
}

class LocalOnlyAuthRepository implements AuthRepository {
  LocalOnlyAuthRepository();

  final _authController = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => null;

  @override
  String? get currentUserId => null;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  @override
  Future<AuthUser?> restoreSession() async {
    _authController.add(null);
    return null;
  }

  @override
  Future<AuthUser?> signInWithGoogle() {
    throw StateError(
      'La app arrancó sin configuración remota. Ejecuta con '
      '--dart-define-from-file=.env o define ENABLE_REMOTE_SYNC, '
      'SUPABASE_URL y SUPABASE_ANON_KEY.',
    );
  }

  @override
  Future<void> signOut() async {
    _authController.add(null);
  }
}
