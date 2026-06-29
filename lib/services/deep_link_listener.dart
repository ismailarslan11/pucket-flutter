import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'deep_link_service.dart';

/// Uygulama açılışında ve çalışırken gelen pucket://join/CODE linklerini dinler.
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initLinks();
  }

  Future<void> _initLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        DeepLinkService.handleUri(context, initial);
      }
      _sub = _appLinks.uriLinkStream.listen((uri) {
        if (mounted) DeepLinkService.handleUri(context, uri);
      });
    } catch (e) {
      debugPrint('Deep link init skipped: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
