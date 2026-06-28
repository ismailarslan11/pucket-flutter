import 'package:flutter/material.dart';

import '../screens/app_router.dart';

class DeepLinkService {
  static String? pendingJoinCode;

  static void handleUri(BuildContext context, Uri? uri) {
    if (uri == null) return;
    String? code;
    if (uri.scheme == 'pucket' && uri.host == 'join') {
      code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : uri.path.replaceFirst('/', '');
    } else if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'join') {
      code = uri.pathSegments[1];
    }
    if (code == null || code.isEmpty) {
      if (uri.scheme == 'pucket' && uri.host == 'join' && uri.queryParameters['code'] != null) {
        code = uri.queryParameters['code'];
      }
    }
    if (code == null || code.isEmpty) return;
    code = code.toUpperCase();
    pendingJoinCode = code;
    if (context.mounted) {
      AppRouter.goLobby(context, joinCode: code);
    }
  }

  static void consumePending(BuildContext context) {
    final code = pendingJoinCode;
    if (code == null) return;
    pendingJoinCode = null;
    AppRouter.goLobby(context, joinCode: code);
  }
}
