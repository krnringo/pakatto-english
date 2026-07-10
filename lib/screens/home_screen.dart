import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/master_data.dart';
import '../models/pack.dart';
import '../state/game_state.dart';
import 'collection_screen.dart';
import 'pack_opening_screen.dart';
import 'parent_screen.dart';

/// ホーム=パック選択画面。解放済みパックがカルーセルで並び、横スワイプで
/// ぐるぐる回転して選び、中央のパックをタップで開封する(ポケポケ準拠)。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _opening = false;

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
    final unlockedPacks = allPacks.where((p) => state.isUnlocked(p)).toList();
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
              child: _PackCarousel(
                packs: unlockedPacks,
                enabled: canOpen,
                onOpen: _tryOpen,
                onDisabled: _showRecoverySheet,
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

/// パックのカルーセル。横スワイプで各パックがY軸回転しながら回り(ぐるぐる)、
/// 中央のパックをタップで開封。左右のパックをタップすると中央に回ってくる。
class _PackCarousel extends StatefulWidget {
  const _PackCarousel({
    required this.packs,
    required this.enabled,
    required this.onOpen,
    required this.onDisabled,
  });

  final List<Pack> packs;
  final bool enabled;
  final void Function(Pack) onOpen;
  final VoidCallback onDisabled;

  @override
  State<_PackCarousel> createState() => _PackCarouselState();
}

class _PackCarouselState extends State<_PackCarousel> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.62);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// このindexのページの中心からのずれ(0=中央、±1=隣)。
  double _deltaFor(int index) {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return (_controller.page ?? _current.toDouble()) - index;
    }
    return (_current - index).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ScrollConfiguration(
            // タッチ(iOS)に加え、マウス/トラックパッドのドラッグでも回せるように
            // する(flutter run -d chrome やデスクトップでの操作・検証のため)。
            behavior: const _DragEverywhereScrollBehavior(),
            child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.packs.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delta = _deltaFor(index);
                  final isCenter = delta.abs() < 0.5;
                  // 回転(ぐるぐる)+ 中央以外は少し縮小して奥行きを出す
                  final rotation = delta * 0.5;
                  final scale = (1 - delta.abs() * 0.18).clamp(0.72, 1.0);
                  return Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(rotation)
                        ..scaleByDouble(scale, scale, scale, 1),
                      child: GestureDetector(
                        onTap: () {
                          if (!widget.enabled) {
                            widget.onDisabled();
                            return;
                          }
                          if (isCenter) {
                            widget.onOpen(widget.packs[index]);
                          } else {
                            _controller.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: _PackCard(
                          pack: widget.packs[index],
                          enabled: widget.enabled,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ),
        ),
        const SizedBox(height: 16),
        // 操作ヒント: 開封可=タップ(👆)、スタミナ0=グレーアウトの💤
        if (widget.enabled)
          const Text('👆', style: TextStyle(fontSize: 36))
        else
          const Text('💤', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        if (widget.packs.length > 1)
          Text('👈 🔄 👉',
              style: TextStyle(
                  fontSize: 20, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

/// タッチに加えてマウス・トラックパッドのドラッグでもスクロールを許可する。
class _DragEverywhereScrollBehavior extends MaterialScrollBehavior {
  const _DragEverywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// カルーセル内の1パックの見た目。スタミナ0のときはグレーアウト。
class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.enabled});

  final Pack pack;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pack.color, Color.lerp(pack.color, Colors.white, 0.4)!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Center(
        child: Text(pack.emoji, style: const TextStyle(fontSize: 88)),
      ),
    );
    if (enabled) return card;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: card,
    );
  }
}
