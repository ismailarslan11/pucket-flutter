import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../config/google_auth_config.dart';

class GoogleMacUser {
  const GoogleMacUser({
    required this.uid,
    this.email,
    this.name,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? name;
  final String? photoUrl;
}

/// macOS'ta Firebase Auth + native GoogleSignIn keychain + Apple imzası gerektirir.
/// Bu servis tarayıcı OAuth (PKCE) ile Google profilini alır; Firebase Auth kullanılmaz.
class MacosGoogleSignIn {
  static String get _clientId => GoogleAuthConfig.iosClientId;

  static String get _callbackScheme {
    final idPart = _clientId.split('.apps.googleusercontent.com').first;
    return 'com.googleusercontent.apps.$idPart';
  }

  static String get _redirectUri => '$_callbackScheme:/';

  static Future<GoogleMacUser> authenticate() async {
    final verifier = _randomString(64);
    final challenge = _codeChallenge(verifier);

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'openid email profile',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: _callbackScheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw StateError('Google yetkilendirme kodu alınamadı');
    }

    final tokenResponse = await http.post(
      Uri.https('oauth2.googleapis.com', '/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw StateError('Google token alınamadı');
    }

    final tokens = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    final idToken = tokens['id_token'] as String?;
    if (idToken == null) {
      throw StateError('Google ID token alınamadı');
    }

    final payload = _decodeJwtPayload(idToken);
    final uid = payload['sub'] as String?;
    if (uid == null || uid.isEmpty) {
      throw StateError('Google kullanıcı kimliği alınamadı');
    }

    return GoogleMacUser(
      uid: uid,
      email: payload['email'] as String?,
      name: payload['name'] as String?,
      photoUrl: payload['picture'] as String?,
    );
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw StateError('Geçersiz Google token');
    }
    var payload = parts[1];
    final mod = payload.length % 4;
    if (mod > 0) payload += '=' * (4 - mod);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  static String _randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _codeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
