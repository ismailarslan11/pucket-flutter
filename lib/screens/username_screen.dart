import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _ctrl = TextEditingController();
  bool _valid = false;
  String _hint = '2-16 karakter, harf ve rakam';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final suggested = auth.user?.name ?? '';
    if (suggested.isNotEmpty) {
      _ctrl.text = suggested.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').substring(0, suggested.length.clamp(0, 16));
      _validate(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String val) {
    final v = val.trim();
    final ok = v.length >= 2 && v.length <= 16 && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v);
    setState(() {
      _valid = ok;
      _hint = ok
          ? '✓ Kullanıcı adı uygun'
          : v.length < 2
              ? 'En az 2 karakter'
              : 'Sadece harf, rakam ve _ kullanılabilir';
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = _ctrl.text.isNotEmpty ? _ctrl.text[0].toUpperCase() : '?';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF1C3A0A), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  const Text(
                    'HOŞ GELDİN!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const Text('Oyuncu adını belirle', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                  const SizedBox(height: 24),
                  Container(
                    width: 300,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Oyuncu adı gir',
                            filled: true,
                            fillColor: const Color(0xFF111111),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF333333)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.green),
                            ),
                          ),
                          onChanged: _validate,
                          onSubmitted: (_) => _submit(),
                        ),
                        Text(
                          _hint,
                          style: TextStyle(
                            color: _valid ? AppColors.green : const Color(0xFF555555),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _valid ? 1 : 0.4,
                          child: PucketButton(
                            label: 'TAMAM →',
                            width: double.infinity,
                            onPressed: _valid ? _submit : () {},
                          ),
                        ),
                      ],
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
    if (!_valid) return;
    final auth = context.read<AuthService>();
    await auth.confirmUsername(_ctrl.text.trim());
  }
}
