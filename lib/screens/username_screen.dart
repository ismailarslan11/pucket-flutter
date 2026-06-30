import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/username_api.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_logo.dart';
import '../widgets/pucket_button.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  int _checkGen = 0;
  bool _valid = false;
  bool _checking = false;
  bool _available = false;
  bool _serverError = false;
  bool _submitting = false;
  String _hint = '2-16 karakter, harf ve rakam';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final suggested = auth.user?.name ?? '';
    if (suggested.isNotEmpty && suggested != 'Oyuncu') {
      _ctrl.text = suggested.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      if (_ctrl.text.length > 16) {
        _ctrl.text = _ctrl.text.substring(0, 16);
      }
      _validate(_ctrl.text);
      if (_valid) _scheduleCheck(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String val) {
    final v = val.trim();
    final ok = v.length >= 2 && v.length <= 16 && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v);
    setState(() {
      _valid = ok;
      if (!ok) {
        _available = false;
        _checking = false;
        _hint = v.isEmpty
            ? '2-16 karakter, harf ve rakam'
            : v.length < 2
                ? 'En az 2 karakter'
                : 'Sadece harf, rakam ve _ kullanılabilir';
      }
    });
  }

  void _scheduleCheck(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _checkAvailability(val.trim()));
  }

  Future<void> _checkAvailability(String name) async {
    if (!_valid || name.isEmpty) return;
    final gen = ++_checkGen;
    setState(() {
      _checking = true;
      _available = false;
      _serverError = false;
      _hint = 'Kontrol ediliyor...';
    });
    final uid = context.read<AuthService>().getUid();
    final result = await UsernameApi.check(name, uid: uid);
    if (!mounted) return;
    if (gen != _checkGen) return;
    if (_ctrl.text.trim() != name) {
      setState(() => _checking = false);
      return;
    }
    setState(() {
      _checking = false;
      _available = result.isAvailable;
      _serverError = result.isServerError;
      if (result.isAvailable) {
        _hint = 'Bu ad müsait';
      } else if (result.isTaken) {
        _hint = 'Bu kullanıcı adı alınmış';
      } else if (result.isInvalid) {
        _hint = result.error ?? 'Geçersiz kullanıcı adı';
      } else {
        _hint = result.error ?? 'Kontrol edilemedi — yine de devam edebilirsin';
      }
    });
  }

  void _onChanged(String val) {
    _validate(val);
    if (_valid) {
      _scheduleCheck(val.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final initial = _ctrl.text.isNotEmpty ? _ctrl.text[0].toUpperCase() : '?';
    final canSubmit = _valid && !_checking && !_submitting && (_available || _serverError);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.screenBg),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const PucketLogo(height: 72),
                  const SizedBox(height: 12),
                  const Text(
                    'KULLANICI ADI',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  Text(
                    auth.user?.isAnonymous ?? true
                        ? 'Misafir olarak devam — adın benzersiz olmalı'
                        : 'Oyuncu adını belirle',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.green.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.green, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ctrl,
                          maxLength: 16,
                          textAlign: TextAlign.center,
                          enabled: !_submitting,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'ör. PucketKing',
                            filled: true,
                            fillColor: AppColors.bgDeep,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.green),
                            ),
                          ),
                          onChanged: _onChanged,
                          onSubmitted: (_) {
                            if (canSubmit) _submit();
                          },
                        ),
                        Text(
                          _hint,
                          style: TextStyle(
                            color: _available
                                ? AppColors.green
                                : (_serverError
                                    ? AppColors.gold
                                    : (_valid && !_checking ? AppColors.red : AppColors.textDim)),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (auth.lastError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            auth.lastError!,
                            style: const TextStyle(color: AppColors.red, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: canSubmit ? 1 : 0.4,
                          child: PucketButton(
                            label: _submitting ? 'KAYDEDİLİYOR...' : 'TAMAM',
                            width: double.infinity,
                            onPressed: canSubmit ? _submit : () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    if (!_available && !_serverError) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthService>();
    final ok = await auth.confirmUsername(_ctrl.text.trim());
    if (!mounted) return;
    if (!ok) {
      final err = auth.lastError ?? 'Kaydedilemedi';
      final taken = err.contains('alınmış');
      setState(() {
        _submitting = false;
        _available = false;
        _serverError = !taken;
        _hint = taken ? 'Bu kullanıcı adı alınmış' : err;
      });
      if (taken) _scheduleCheck(_ctrl.text.trim());
    }
  }
}
