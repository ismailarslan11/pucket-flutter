import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../models/rank_tier.dart';
import '../services/auth_service.dart';
import '../services/friends_api.dart';
import '../theme/app_theme.dart';
import '../widgets/yesa_background.dart';
import '../widgets/yesa_effects.dart';
import 'app_router.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _addCtrl = TextEditingController();
  List<Friend> _friends = [];
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().getUid();
    final list = await FriendsApi.list(uid);
    if (!mounted) return;
    setState(() {
      _friends = list;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    final uid = context.read<AuthService>().getUid();
    final err = await FriendsApi.add(uid, name);
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? l10n.friendAdded)),
    );
    _addCtrl.clear();
    setState(() => _adding = false);
    if (err == null) _load();
  }

  Future<void> _remove(Friend f) async {
    final uid = context.read<AuthService>().getUid();
    setState(() => _friends.remove(f));
    await FriendsApi.remove(uid, f.uid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: YesaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 16, 4),
                child: Row(
                  children: [
                    ScalePress(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppGradients.neonPurple,
                          border: Border.all(color: AppColors.beyaz.withValues(alpha: 0.3)),
                          boxShadow: AppShadows.depth(AppColors.morDahaKoyu),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: AppColors.beyaz, size: 20),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.friends,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.beyaz,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _addCtrl,
                        style: const TextStyle(color: AppColors.beyaz),
                        decoration: InputDecoration(
                          hintText: l10n.friendAddHint,
                          hintStyle: const TextStyle(color: AppColors.textFaint),
                          filled: true,
                          fillColor: AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.acikMor),
                          ),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScalePress(
                      onTap: _add,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          gradient: AppGradients.neonPurple,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppShadows.neon(AppColors.acikMor, blur: 8),
                        ),
                        child: Text(
                          l10n.friendAdd,
                          style: const TextStyle(color: AppColors.beyaz, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.sariAna))
                    : _friends.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                l10n.friendsEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textMuted, height: 1.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: _friends.length,
                            itemBuilder: (_, i) => StaggerIn(
                              index: i % 8,
                              delayMs: 30,
                              child: _FriendRow(
                                friend: _friends[i],
                                onChallenge: () => AppRouter.goLobby(context, createRoom: true),
                                onRemove: () => _remove(_friends[i]),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.onChallenge, required this.onRemove});

  final Friend friend;
  final VoidCallback onChallenge;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tier = RankTier.forElo(friend.elo);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: friend.online ? AppColors.neonYesil.withValues(alpha: 0.6) : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tier.color.withValues(alpha: 0.18),
                  border: Border.all(color: tier.color.withValues(alpha: 0.7), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                  style: TextStyle(fontWeight: FontWeight.w900, color: tier.color),
                ),
              ),
              if (friend.online)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonYesil,
                      border: Border.all(color: AppColors.morDahaKoyu, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.beyaz),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${friend.elo} ELO · ${friend.online ? l10n.friendOnline : l10n.friendOffline}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: friend.online ? AppColors.neonYesil : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ScalePress(
            onTap: onChallenge,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppGradients.heroPlay,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l10n.friendChallenge,
                style: const TextStyle(color: AppColors.morDahaKoyu, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.person_remove_rounded, color: AppColors.textFaint, size: 18),
            tooltip: l10n.friendRemove,
          ),
        ],
      ),
    );
  }
}
