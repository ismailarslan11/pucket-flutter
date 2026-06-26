import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../services/player_meta_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pucket_button.dart';

class CosmeticsScreen extends StatefulWidget {
  const CosmeticsScreen({super.key});

  @override
  State<CosmeticsScreen> createState() => _CosmeticsScreenState();
}

class _CosmeticsScreenState extends State<CosmeticsScreen> {
  String _disc = 'green';
  String _board = 'classic';
  bool _saving = false;

  static const discColors = {
    'green': Color(0xFF4CAF50),
    'gold': Color(0xFFF0C040),
    'blue': Color(0xFF2196F3),
    'red': Color(0xFFE53935),
    'purple': Color(0xFF9C27B0),
  };

  static const boardThemes = ['classic', 'neon', 'wood'];

  @override
  void initState() {
    super.initState();
    final meta = context.read<PlayerMetaService>().meta;
    _disc = meta?.cosmetics['discColor'] ?? 'green';
    _board = meta?.cosmetics['boardTheme'] ?? 'classic';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.read<AuthService>();
    final meta = context.read<PlayerMetaService>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.menuCosmetics),
        backgroundColor: AppColors.bg,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.cosmeticsDisc, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: discColors.entries.map((e) {
              final selected = _disc == e.key;
              return GestureDetector(
                onTap: () => setState(() => _disc = e.key),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.value,
                    border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(l10n.cosmeticsBoard, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...boardThemes.map((t) => ListTile(
                title: Text(l10n.boardThemeName(t)),
                trailing: _board == t ? const Icon(Icons.check, color: AppColors.green) : null,
                onTap: () => setState(() => _board = t),
              )),
          const SizedBox(height: 20),
          PucketButton(
            label: _saving ? '...' : l10n.save,
            onPressed: _saving
                ? () {}
                : () async {
                    setState(() => _saving = true);
                    await meta.setCosmetics(auth.getUid(), {
                      'discColor': _disc,
                      'boardTheme': _board,
                    });
                    if (mounted) {
                      setState(() => _saving = false);
                      Navigator.pop(context);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
