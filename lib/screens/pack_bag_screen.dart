import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pack.dart';
import '../state/game_state.dart';
import '../widgets/carousel_scroll_behavior.dart';
import '../widgets/pack_pouch.dart';
import '../widgets/recovery_sheet.dart';
import '../widgets/stamina_chip.dart';
import 'pack_opening_screen.dart';

/// パック袋選択画面。選んだパック種の未開封の袋が縦にたくさん並び、
/// 縦スワイプでぐるぐる回して選び、中央の袋をタップで開封する。
///
/// 袋はすべて中身が同じ抽選対象で見た目も同一(在庫概念はなく、実際の
/// 開封可否はスタミナで制御する「見せかけの複数化」)。
class PackBagScreen extends StatefulWidget {
  const PackBagScreen({super.key, required this.pack});

  final Pack pack;

  @override
  State<PackBagScreen> createState() => _PackBagScreenState();
}

class _PackBagScreenState extends State<PackBagScreen> {
  // 実在庫ではなく演出上の見せかけの袋の数。中央付近から始めて
  // 上下どちらにもスワイプできるようにする。
  static const int _bagCount = 999;

  late final PageController _controller;
  int _current = _bagCount ~/ 2;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _current = _bagCount ~/ 2;
    _controller = PageController(
      viewportFraction: 0.42,
      initialPage: _current,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _deltaFor(int index) {
    if (_controller.hasClients && _controller.position.haveDimensions) {
      return (_controller.page ?? _current.toDouble()) - index;
    }
    return (_current - index).toDouble();
  }

  Future<void> _tryOpen() async {
    final state = context.read<GameState>();
    if (_opening) return;
    if (!state.canOpen) {
      showStaminaRecoverySheet(context);
      return;
    }
    _opening = true;
    try {
      final result = await state.openPack(widget.pack);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackOpeningScreen(pack: widget.pack, result: result),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final canOpen = state.canOpen;

    return Scaffold(
      backgroundColor: Color.lerp(widget.pack.color, Colors.black, 0.55),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.pack.emoji} ${widget.pack.nameJa}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  StaminaChip(stamina: state.currentStamina),
                ],
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const DragEverywhereScrollBehavior(),
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemCount: _bagCount,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final delta = _deltaFor(index);
                        final isCenter = delta.abs() < 0.5;
                        final rotation = delta * 0.6;
                        final scale =
                            (1 - delta.abs() * 0.22).clamp(0.6, 1.0);
                        return Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateX(-rotation)
                              ..scaleByDouble(scale, scale, scale, 1),
                            child: GestureDetector(
                              key: isCenter
                                  ? const ValueKey('bag-center')
                                  : null,
                              onTap: () {
                                if (!canOpen) {
                                  showStaminaRecoverySheet(context);
                                  return;
                                }
                                if (isCenter) {
                                  _tryOpen();
                                } else {
                                  _controller.animateToPage(
                                    index,
                                    duration:
                                        const Duration(milliseconds: 350),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                              child: PackPouch(
                                pack: widget.pack,
                                enabled: canOpen,
                                width: 170,
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
            const SizedBox(height: 12),
            if (canOpen)
              const Text('👆', style: TextStyle(fontSize: 32))
            else
              const Text('💤', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            const Text('🔼 🔄 🔽',
                style: TextStyle(fontSize: 20, color: Colors.white70)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
