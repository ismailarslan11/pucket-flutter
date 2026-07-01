import 'dart:convert';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../config/google_auth_config.dart';
import '../models/rank_tier.dart';
import '../models/user_profile.dart';
import 'firebase_init.dart';
import 'macos_google_sign_in.dart';
import 'username_api.dart';

enum AuthState { loading, unauthenticated, needsUsername, authenticated }

class AuthService extends ChangeNotifier {
  AuthState authState = AuthState.loading;
  UserProfile? user;
  String? lastError;
  bool loading = false;

  FirebaseAuth? _auth;
  FirebaseFirestore? _db;
  bool _firebaseReady = false;

  static const _uidKey = 'pucket_uid';
  static const _nameKey = 'pucket_name';
  static const _eloKey = 'pucket_elo';
  static const _leagueKey = 'pucket_league';

  bool get isLoggedIn => authState == AuthState.authenticated && user != null;
  bool get firebaseAvailable => _firebaseReady;

  /// Ranked için Google/Apple (anonim veya yerel misafir değil).
  bool get canPlayRanked {
    final u = user;
    if (u == null) return false;
    if (u.isAnonymous) return false;
    if (u.uid.startsWith('u_') || u.uid.startsWith('guest_')) return false;
    return true;
  }

  bool get appleSignInAvailable =>
      _firebaseReady && !_isMacOS && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String? _cachedGuestUid;

  /// Google giriş butonu aktif mi?
  bool get googleSignInAvailable {
    if (_isMacOS) return GoogleAuthConfig.hasIosClientId;
    if (kIsWeb) return _firebaseReady && _auth != null;
    return _firebaseReady;
  }

  bool get _isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _initGoogleSignIn() async {
    if (_isMacOS || kIsWeb) return;
    final googleSignIn = GoogleSignIn.instance;
    // Android: clientId google-services.json'dan gelir; iOS client ID vermeyin.
    final iosOnlyClientId = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        GoogleAuthConfig.hasIosClientId;
    await googleSignIn.initialize(
      clientId: iosOnlyClientId ? GoogleAuthConfig.iosClientId : null,
      serverClientId:
          GoogleAuthConfig.hasWebClientId ? GoogleAuthConfig.webClientId : null,
    );
  }

  Future<void> initFirebase() async {
    _applyCachedAuthState();

    if (_isMacOS) {
      _firebaseReady = GoogleAuthConfig.hasIosClientId;
      if (authState == AuthState.loading) await _finishInitWithoutFirebase();
      return;
    }

    if (!firebaseEnabled || Firebase.apps.isEmpty) {
      _firebaseReady = false;
      if (authState == AuthState.loading) await _finishInitWithoutFirebase();
      return;
    }

    try {
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;
      unawaited(() async {
        try {
          await _initGoogleSignIn();
        } catch (_) {}
      }());
      _auth!.authStateChanges().listen(_onAuthChanged);
      _firebaseReady = true;
      final fbUser = _auth!.currentUser;
      if (user != null) {
        notifyListeners();
        unawaited(_syncAuthFromFirebaseUser(fbUser));
      } else {
        await _syncAuthFromFirebaseUser(fbUser);
      }
    } catch (_) {
      _firebaseReady = false;
      if (authState == AuthState.loading) await _finishInitWithoutFirebase();
    }
  }

  void _applyCachedAuthState() {
    if (user == null || authState != AuthState.loading) return;
    authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
    loading = false;
    notifyListeners();
  }

  Future<void> _syncAuthFromFirebaseUser(User? fbUser) async {
    if (fbUser == null) {
      if (user == null) {
        authState = AuthState.unauthenticated;
      } else {
        authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
      }
      loading = false;
      notifyListeners();
      return;
    }
    await _onAuthChanged(fbUser);
  }

  Future<void> _finishInitWithoutFirebase() async {
    if (user != null) {
      authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
    } else {
      authState = AuthState.unauthenticated;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? fbUser) async {
    if (!_firebaseReady) return;

    if (fbUser == null) {
      user = null;
      authState = AuthState.unauthenticated;
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final ref = _db!.collection('users').doc(fbUser.uid);
      final snap = await ref.get();

      if (snap.exists) {
        user = UserProfile.fromFirestore(snap.data()!, fbUser.uid);
        user!.isAnonymous = fbUser.isAnonymous;
        await _persistLocal();
        authState = AuthState.authenticated;
      } else {
        user = UserProfile(
          uid: fbUser.uid,
          name: fbUser.displayName?.split(' ').first ?? '',
          photoUrl: fbUser.photoURL,
          isAnonymous: fbUser.isAnonymous,
        );
        authState = AuthState.needsUsername;
      }
    } catch (e) {
      lastError = 'Profil yüklenemedi';
      authState = AuthState.unauthenticated;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    if (!googleSignInAvailable) {
      lastError = 'Google girişi şu an kullanılamıyor — misafir olarak devam edin';
      notifyListeners();
      return;
    }
    loading = true;
    lastError = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _auth!.signInWithPopup(GoogleAuthProvider());
        loading = false;
        notifyListeners();
        return;
      }

      if (_isMacOS) {
        final googleUser = await MacosGoogleSignIn.authenticate();
        final cachedName = user?.uid == googleUser.uid ? user!.name : null;
        final displayName = googleUser.name?.split(' ').first ?? '';
        user = UserProfile(
          uid: googleUser.uid,
          name: (cachedName != null && cachedName.length >= 2) ? cachedName : displayName,
          photoUrl: googleUser.photoUrl,
          isAnonymous: false,
          elo: user?.uid == googleUser.uid ? user!.elo : 1000,
          wins: user?.uid == googleUser.uid ? user!.wins : 0,
          losses: user?.uid == googleUser.uid ? user!.losses : 0,
          matches: user?.uid == googleUser.uid ? user!.matches : 0,
          league: user?.uid == googleUser.uid ? user!.league : 'Bronz',
        );
        if (user!.name.length >= 2) {
          await _persistLocal();
          authState = AuthState.authenticated;
        } else {
          authState = AuthState.needsUsername;
        }
        loading = false;
        notifyListeners();
        return;
      }

      final googleSignIn = GoogleSignIn.instance;
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        lastError = 'Google kimlik doğrulaması alınamadı';
        loading = false;
        notifyListeners();
        return;
      }
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await _auth!.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        lastError = switch (e.code) {
          GoogleSignInExceptionCode.clientConfigurationError =>
            'Google giriş yapılandırması eksik — tool/setup_firebase.sh çalıştırın',
          GoogleSignInExceptionCode.providerConfigurationError =>
            'Google SDK yapılandırması hatalı',
          _ => e.description ?? 'Google girişi başarısız (${e.code.name})',
        };
      }
      loading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? 'Firebase girişi başarısız';
      loading = false;
      notifyListeners();
    } on PlatformException catch (e) {
      if (e.code != 'CANCELED') {
        final msg = e.message ?? '';
        lastError = switch (e.code) {
          'sign_in_failed' when msg.contains('10') || msg.contains('DEVELOPER_ERROR') =>
            'Google giriş yapılandırması hatalı — Firebase\'e SHA-1 ekleyin (tool/setup_firebase.sh)',
          'sign_in_failed' when msg.contains('12500') || msg.contains('SIGN_IN_REQUIRED') =>
            'Google Play Hizmetleri güncel değil veya eksik',
          _ => msg.isNotEmpty ? msg : 'Google girişi başarısız',
        };
      }
      loading = false;
      notifyListeners();
    } on StateError catch (e) {
      lastError = e.message;
      loading = false;
      notifyListeners();
    } catch (e) {
      lastError = 'Google girişi başarısız: $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    if (!_firebaseReady || _isMacOS) {
      lastError = 'Apple girişi bu platformda kullanılamıyor';
      notifyListeners();
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      lastError = 'Apple girişi yalnızca iOS\'ta desteklenir';
      notifyListeners();
      return;
    }

    loading = true;
    lastError = null;
    notifyListeners();

    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      await _auth!.signInWithCredential(oauth);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        lastError = 'Apple girişi başarısız';
      }
      loading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      lastError = e.message ?? 'Apple girişi başarısız';
      loading = false;
      notifyListeners();
    } catch (_) {
      lastError = 'Apple girişi başarısız';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signInAsGuest() async {
    loading = true;
    notifyListeners();

    if (!_firebaseReady) {
      await _loadGuestProfile();
      authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
      loading = false;
      notifyListeners();
      return;
    }

    if (_isMacOS) {
      await _loadGuestProfile();
      authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
      loading = false;
      notifyListeners();
      return;
    }

    try {
      await _auth!.signInAnonymously();
    } catch (_) {
      await _loadGuestProfile();
      authState = _needsUsernamePick() ? AuthState.needsUsername : AuthState.authenticated;
      loading = false;
      notifyListeners();
    }
  }

  bool _needsUsernamePick() {
    if (user == null) return true;
    final n = user!.name.trim();
    return n.isEmpty || n == 'Oyuncu' || n.length < 2;
  }

  Future<bool> confirmUsername(String username) async {
    if (user == null) return false;
    final name = username.trim();
    if (name.length < 2 || name.length > 16) return false;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name)) return false;

    loading = true;
    lastError = null;
    notifyListeners();

    final claim = await UsernameApi.claim(uid: user!.uid, username: name);
    if (!claim.ok) {
      final err = claim.error ?? 'Bu kullanıcı adı alınamadı';
      final taken = err.contains('alınmış');
      if (!taken && user!.isAnonymous) {
        user!.name = name;
        final tier = RankTier.forElo(user!.elo);
        user!.league = tier.name;
        await _persistLocal();
        loading = false;
        authState = AuthState.authenticated;
        notifyListeners();
        return true;
      }
      loading = false;
      lastError = err;
      notifyListeners();
      return false;
    }

    user!.name = name;
    final tier = RankTier.forElo(user!.elo);
    user!.league = tier.name;

    if (_firebaseReady && _db != null && !_isMacOS) {
      try {
        await _db!.collection('users').doc(user!.uid).set({
          'uid': user!.uid,
          'username': name,
          'displayName': user!.name,
          'photoURL': user!.photoUrl ?? '',
          'elo': user!.elo,
          'wins': user!.wins,
          'losses': user!.losses,
          'matches': user!.matches,
          'league': tier.name,
          'isAnonymous': user!.isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    await _persistLocal();
    loading = false;
    authState = AuthState.authenticated;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    if (_firebaseReady && !_isMacOS) {
      try {
        await _auth!.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    user = null;
    authState = AuthState.unauthenticated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_uidKey);
    await prefs.remove(_nameKey);
    await prefs.remove('pucket_user');
    notifyListeners();
  }

  String getUid() {
    if (user != null) return user!.uid;
    return _cachedGuestUid ?? _localUid();
  }

  Future<String?> getIdToken() async {
    if (!_firebaseReady || _auth?.currentUser == null) return null;
    try {
      return await _auth!.currentUser!.getIdToken();
    } catch (_) {
      return null;
    }
  }

  String getName() => user?.name ?? 'Oyuncu';

  void applyServerProfile(Map<String, dynamic> data) {
    final anon = _auth?.currentUser?.isAnonymous ?? user?.isAnonymous ?? true;
    user = UserProfile.fromServer(data, isAnonymous: anon);
    _persistLocal();
    notifyListeners();
  }

  void applyEloResult({
    required int newElo,
    required String newLeague,
    required bool won,
  }) {
    if (user == null) return;
    user!.elo = newElo;
    user!.league = newLeague;
    if (won) {
      user!.wins++;
    } else {
      user!.losses++;
    }
    user!.matches++;
    _persistLocal();
    notifyListeners();
  }

  Future<void> syncEloToFirestore(bool won, int newElo, String newLeague) async {
    if (!_firebaseReady || _db == null || user == null) return;
    if (_auth?.currentUser?.isAnonymous ?? true) return;
    try {
      await _db!.collection('users').doc(user!.uid).update({
        'elo': newElo,
        'league': newLeague,
        'wins': user!.wins,
        'losses': user!.losses,
        'matches': user!.matches,
      });
    } catch (_) {}
  }

  Future<void> _loadGuestProfile() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString(_uidKey);
    if (uid == null || uid.isEmpty) {
      uid = _localUid();
      await prefs.setString(_uidKey, uid);
    }
    _cachedGuestUid = uid;
    user = UserProfile(
      uid: uid,
      name: prefs.getString(_nameKey) ?? '',
      elo: prefs.getInt(_eloKey) ?? 1000,
      league: prefs.getString(_leagueKey) ?? 'Bronz',
      isAnonymous: true,
    );
  }

  String _localUid() {
    final uid = 'u_${const Uuid().v4().substring(0, 8)}';
    _cachedGuestUid = uid;
    return uid;
  }

  Future<void> _persistLocal() async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uidKey, user!.uid);
    await prefs.setString(_nameKey, user!.name);
    await prefs.setInt(_eloKey, user!.elo);
    await prefs.setString(_leagueKey, user!.league);
    await prefs.setString('pucket_user', jsonEncode(user!.toJson()));
  }

  Future<void> loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pucket_user');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      user = UserProfile(
        uid: j['uid'] as String,
        name: j['name'] as String,
        elo: (j['elo'] as num?)?.toInt() ?? 1000,
        wins: (j['wins'] as num?)?.toInt() ?? 0,
        losses: (j['losses'] as num?)?.toInt() ?? 0,
        matches: (j['matches'] as num?)?.toInt() ?? 0,
        league: j['league'] as String? ?? 'Bronz',
        isAnonymous: j['isAnonymous'] as bool? ?? true,
      );
      _cachedGuestUid = user!.uid;
    } catch (_) {}
  }
}
