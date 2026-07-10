import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth/auth_repository.dart';
import '../data/sync/sync_coordinator.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required SyncCoordinator syncCoordinator,
  }) : _authRepository = authRepository,
       _syncCoordinator = syncCoordinator {
    _subscription = _authRepository.authStateChanges.listen((user) async {
      _user = user;
      _error = null;
      notifyListeners();
      await _syncCoordinator.setCurrentUserId(user?.id);
    });
  }

  final AuthRepository _authRepository;
  final SyncCoordinator _syncCoordinator;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> restoreSession() async {
    await _run(() async {
      final user = await _authRepository.restoreSession();
      _user = user;
      await _syncCoordinator.setCurrentUserId(user?.id);
    }, fallbackError: 'No se pudo restaurar la sesión.');
  }

  Future<bool> signInWithGoogle() async {
    return _run(() async {
      final user = await _authRepository.signInWithGoogle();
      _user = user;
      await _syncCoordinator.setCurrentUserId(user?.id);
      if (user != null) {
        await _syncCoordinator.prepareInitialSyncForSignedInUser();
        await _syncCoordinator.synchronizeNow();
      }
    }, fallbackError: 'No se pudo iniciar sesión con Google.');
  }

  Future<bool> signOut() async {
    return _run(() async {
      await _authRepository.signOut();
      _user = null;
      await _syncCoordinator.setCurrentUserId(null);
    }, fallbackError: 'No se pudo cerrar sesión.');
  }

  Future<bool> _run(
    Future<void> Function() action, {
    required String fallbackError,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e, stackTrace) {
      debugPrint('$fallbackError $e\n$stackTrace');
      _error =
          e is StateError
              ? e.message
              : '$fallbackError Detalle: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
