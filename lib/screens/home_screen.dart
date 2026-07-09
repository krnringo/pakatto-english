import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/master_data.dart';
import '../models/pack.dart';
import '../state/game_state.dart';
import 'collection_screen.dart';
import 'pack_opening_screen.dart';
import 'parent_screen.dart';

/// ホーム=パック選択画面。解放済みパックが浮遊し、縦スワイプで開封する。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _tryOpen(Pack pack) async {
    final state = context.read<GameState>();
    if (_opening) return;
    if (!state.canOpen) {
      _showRecoverySheet();
      return;
    }
    _opening = true;
    try {
      final result = await state.openPack(pack);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackOpeningScreen(pack: pack, result: result),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  /// スタミナ0のとき: 次の回復までの残り時間を絵的に表示。
  void _showRecoverySheet() {
    final state = context.read<GameState>();
    final remaining = state.timeToNextRecovery;
    if (remaining == null) return;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              '⚡ あと ${h > 0 ? '$h:' : ''}${m.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('😴💤', style: TextStyle(fontSize: 32)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final unlockedPacks =
        allPacks.where((p) => state.isUnlocked(p)).toList();
    final canOpen = state.canOpen;

    return Scaffold(
      backgroundColor: const Color(0xFF81D4FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _StaminaChip(stamina: state.currentStamina),
                  const Spacer(),
                  // 親向け画面の入口(子ども向け動線から分離した控えめボタン)
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParentScreen()),
                    ),
                    icon: Icon(Icons.settings,
                        color: Colors.white.withValues(alpha: 0.6), size: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                children: [
                  for (final pack in unlockedPacks)
                    _FloatingPack(
                      pack: pack,
                      enabled: canOpen,
                      floatAnimation: _floatController,
                      onSwiped: () => _tryOpen(pack),
                      onDisabledTap: _showRecoverySheet,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CollectionScreen()),
                ),
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  child: const Center(
                      child: Text('📖', style: TextStyle(fontSize: 44))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// スタミナ表示(例: ⚡⚡ = 2/2)。
class _StaminaChip extends StatelessWidget {
  const _StaminaChip({required this.stamina});

  final int stamina;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Opacity(
              opacity: i < stamina ? 1 : 0.2,
              child: const Text('⚡', style: TextStyle(fontSize: 24)),
            ),
        ],
      ),
    );
  }
}

/// 浮遊するパック。縦スワイプで開封、スタミナ0ならグレーアウト。
class _FloatingPack extends StatelessWidget {
  const _FloatingPack({
    required this.pack,
    required this.enabled,
    required this.floatAnimation,
    required this.onSwiped,
    required this.onDisabledTap,
  });

  final Pack pack;
  final bool enabled;
  final Animation<double> floatAnimation;
  final VoidCallback onSwiped;
  final VoidCallback onDisabledTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? null : onDisabledTap,
      onVerticalDragEnd: (details) {
        if (!enabled) {
          onDisabledTap();
          return;
        }
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 250) onSwiped();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: floatAnimation,
            builder: (context, child) {
              final dy = sin(floatAnimation.value * pi) * 12;
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: ColorFiltered(
              colorFilter: enabled
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0.2126, 0.7152, 0.0722, 0, 0, //
                      0, 0, 0, 1, 0,
                    ]),
              child: Container(
                width: 180,
                height: 252,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      pack.color,
                      Color.lerp(pack.color, Colors.white, 0.4)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: Text(pack.emoji, style: const TextStyle(fontSize: 80)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (enabled)
            const Text('⬆️', style: TextStyle(fontSize: 36))
          else
            const Text('💤', style: TextStyle(fontSize: 36)),
        ],
      ),
    );
  }
}
