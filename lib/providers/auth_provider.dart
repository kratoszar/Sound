import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestore;

  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService.instance,
        _firestore = firestoreService ?? FirestoreService.instance;

  bool isInitializing = true;
  bool isBusy = false;
  String? errorMessage;

  User? firebaseUser;
  AppUser? currentUser;

  StreamSubscription<User?>? _authSub;
  StreamSubscription? _userDocSub;
  Timer? _profileRetryTimer;
  int _profileRetryCount = 0;

  bool isProfileLoading = false;
  String? profileErrorMessage;

  void init() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _profileRetryTimer?.cancel();
    _profileRetryTimer = null;
    _profileRetryCount = 0;

    isInitializing = true;
    errorMessage = null;
    isProfileLoading = false;
    profileErrorMessage = null;
    notifyListeners();

    _authSub = _authService.authStateChanges().listen(
      (user) {
        firebaseUser = user;
        _userDocSub?.cancel();
        _profileRetryTimer?.cancel();
        _profileRetryTimer = null;
        _profileRetryCount = 0;
        currentUser = null;
        isProfileLoading = false;
        profileErrorMessage = null;

        if (user == null) {
          isInitializing = false;
          notifyListeners();
          return;
        }

        _listenToUserDoc(user);
      },
      onError: (e) {
        errorMessage = e.toString();
        isInitializing = false;
        notifyListeners();
      },
    );
  }

  void _listenToUserDoc(User user) {
    _userDocSub?.cancel();
    isProfileLoading = true;
    profileErrorMessage = null;
    notifyListeners();

    _userDocSub = _firestore.userDocStream(user.uid).listen(
      (snap) async {
        if (!snap.exists) {
          // If the profile doc doesn't exist yet, create it and let the stream
          // deliver the next snapshot.
          try {
            await _firestore.ensureUserDocument(
              uid: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? (user.email ?? 'User'),
              avatar: user.photoURL,
            );
          } catch (e) {
            // We'll surface the error and allow manual retry.
            profileErrorMessage = _mapProfileError(e);
            isProfileLoading = false;
            isInitializing = false;
            notifyListeners();
          }
          return;
        }

        currentUser = AppUser.fromFirestore(snap);
        isProfileLoading = false;
        profileErrorMessage = null;
        isInitializing = false;
        notifyListeners();
      },
      onError: (e) {
        profileErrorMessage = _mapProfileError(e);
        isProfileLoading = false;
        isInitializing = false;
        notifyListeners();

        if (_isTransientFirestoreError(e)) {
          _scheduleProfileRetry();
        }
      },
    );
  }

  void _scheduleProfileRetry() {
    if (firebaseUser == null) return;
    if (_profileRetryTimer?.isActive == true) return;
    if (_profileRetryCount >= 5) return;

    final delay = Duration(seconds: 1 << _profileRetryCount); // 1,2,4,8,16
    _profileRetryCount++;
    _profileRetryTimer = Timer(delay, () {
      final user = firebaseUser;
      if (user == null) return;
      _listenToUserDoc(user);
    });
  }

  bool _isTransientFirestoreError(Object e) {
    if (e is FirebaseException) {
      return e.code == 'unavailable' || e.code == 'deadline-exceeded';
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('cloud_firestore/unavailable') ||
        msg.contains('unavailable') ||
        msg.contains('deadline-exceeded');
  }

  String _mapProfileError(Object e) {
    if (_isTransientFirestoreError(e)) {
      return 'Firestore no está disponible. Reintenta en unos segundos.';
    }
    return 'Error al cargar tu perfil: ${e.toString()}';
  }

  void retryLoadProfile() {
    final user = firebaseUser;
    if (user == null) return;
    _profileRetryTimer?.cancel();
    _profileRetryTimer = null;
    _profileRetryCount = 0;
    profileErrorMessage = null;
    _listenToUserDoc(user);
  }

  Future<void> loginWithGoogle() async {
    await _runBusy(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
      );
    });
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await _runBusy(() async {
      await _authService.signInWithEmail(
        email: email,
        password: password,
      );
    });
  }

  Future<void> logout() async {
    await _runBusy(() async {
      await _authService.signOut();
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      errorMessage = _mapAuthError(e);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String _mapAuthError(Object e) {
    if (kDebugMode) {
      debugPrint('==== AUTH ERROR ====');
      debugPrint(e.toString());
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email inválido.';
        case 'user-disabled':
          return 'El usuario está deshabilitado.';
        case 'user-not-found':
          return 'No existe una cuenta con ese email.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'Ese email ya está registrado.';
        case 'weak-password':
          return 'La contraseña es muy débil.';
        case 'google_sign_in_cancelled':
          return 'Inicio de sesión con Google cancelado.';
        default:
          return e.message ?? 'Error de autenticación: ${e.code}';
      }
    }
    return 'Error: ${e.toString()}';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _profileRetryTimer?.cancel();
    super.dispose();
  }
}

