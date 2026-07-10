import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/master_data.dart';
import '../models/pack.dart';
import '../state/game_state.dart';
import '../widgets/carousel_scroll_behavior.dart';
import '../widgets/pack_pouch.dart';
import '../widgets/recovery_sheet.dart';
import '../widgets/stamina_chip.dart';
import 'collection_screen.dart';
import 'pack_bag_screen.dart';
import 'parent_screen.dart';

/// ホーム=パック(ライン)選択画面。解放済みのパック種が横カルーセルで並び、
/// 横スワイプでぐるぐる回転して選ぶ。中央のパック種をタップすると、
/// 同じパック種の未開封の袋が縦に並ぶパック袋選択画面(PackBagScreen)に
/// 遷移する(ポケポケの「エキスパンションを選ぶ→袋を選ぶ」の二段階に準拠)。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _onSelectLine(BuildContext context, Pack pack) {
    final state = context.read<GameState>();
    if (!state.canOpen) {
      showStaminaRecoverySheet(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PackBagScreen(pack: pack)),
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
                  StaminaChip(stamina: state.currentStamina),
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
              child: _PackLineCarousel(
                packs: unlockedPacks,
                enabled: canOpen,
                onSelect: (pack) => _onSelectLine(context, pack),
                onDisabled: () => showStaminaRecoverySheet(context),
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

/// パック種(ライン)の横カルーセル。横スワイプでY軸回転しながら回り、
/// 中央のパック種をタップすると袋選択画面へ進む。左右のパック種をタップすると
/// 中央に回ってくる。
class _PackLineCarousel extends StatefulWidget {
  const _PackLineCarousel({
    required this.packs,
    required this.enabled,
    required this.onSelect,
    required this.onDisabled,
  });

  final List<Pack> packs;
  final bool enabled;
  final void Function(Pack) onSelect;
  final VoidCallback onDisabled;

  @override
  State<_PackLineCarousel> createState() => _PackLineCarouselState();
}

class _PackLineCarouselState extends State<_PackLineCarousel> {
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
            behavior: const DragEverywhereScrollBehavior(),
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
                          key: isCenter ? const ValueKey('line-center') : null,
                          onTap: () {
                            if (!widget.enabled) {
                              widget.onDisabled();
                              return;
                            }
                            if (isCenter) {
                              widget.onSelect(widget.packs[index]);
                            } else {
                              _controller.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                          child: PackPouch(
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
