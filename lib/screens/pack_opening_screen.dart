import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pack.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../widgets/card_face.dart';
import 'collection_screen.dart';

/// パック開封演出: 開封アニメーション → 3枚を1枚ずつタップでめくる →
/// めくるたび音声再生+新規/復習バッジ → 全部めくったら結果(+コンプリート演出)。
///
/// 抽選・永続化は遷移前に完了済みで、この画面は演出のみを担当する。
class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({
    super.key,
    required this.pack,
    required this.result,
  });

  final Pack pack;
  final PackOpeningResult result;

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _packController;
  bool _packOpened = false;
  final Set<int> _flipped = {};
  bool _completeShown = false;

  bool get _allFlipped => _flipped.length == widget.result.cards.length;

  @override
  void initState() {
    super.initState();
    _packController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward().whenComplete(() => setState(() => _packOpened = true));
  }

  @override
  void dispose() {
    _packController.dispose();
    super.dispose();
  }

  void _onFlipped(int index) {
    final drawn = widget.result.cards[index];
    context.read<AudioService>().speak(drawn.card);
    setState(() => _flipped.add(index));
    if (_allFlipped && widget.result.becameComplete && !_completeShown) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _completeShown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF283593),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(),
                if (!_packOpened)
                  _OpeningPack(controller: _packController, pack: widget.pack)
                else
                  _buildCards(),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _allFlipped ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: _buildBottomButtons(),
                ),
                const SizedBox(height: 24),
              ],
            ),
            if (_completeShown && widget.result.becameComplete)
              _CompleteOverlay(
                pack: widget.pack,
                onClose: () => setState(() => _completeShown = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.result.cards.length; i++)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _FlippableCard(
                    drawn: widget.result.cards[i],
                    onFlipped: () => _onFlipped(i),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return IgnorePointer(
      ignoring: !_allFlipped,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BigIconButton(
            emoji: '🏠',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 32),
          _BigIconButton(
            emoji: '📖',
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => CollectionScreen(initialPackId: widget.pack.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// パックが震えて弾ける開封アニメーション。
class _OpeningPack extends StatelessWidget {
  const _OpeningPack({required this.controller, required this.pack});

  final AnimationController controller;
  final Pack pack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final shake = sin(t * pi * 10) * 8 * (1 - t);
        final scale = 1.0 + t * 0.4;
        final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(shake, 0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: _PackVisual(pack: pack, width: 160),
    );
  }
}

/// パックの見た目(ホーム画面と共用)。
class _PackVisual extends StatelessWidget {
  const _PackVisual({required this.pack, required this.width});

  final Pack pack;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
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
        child: Text(pack.emoji, style: TextStyle(fontSize: width * 0.45)),
      ),
    );
  }
}

/// タップでめくれるカード。めくり終わると新規/復習バッジを表示する。
class _FlippableCard extends StatefulWidget {
  const _FlippableCard({required this.drawn, required this.onFlipped});

  final DrawnCard drawn;
  final VoidCallback onFlipped;

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _flipStarted = false;
  bool _badgeVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipStarted) return;
    _flipStarted = true;
    _controller.forward().whenComplete(() {
      widget.onFlipped();
      setState(() => _badgeVisible = true);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AspectRatio(
        aspectRatio: 0.7,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final angle = _controller.value * pi;
                  final showFace = _controller.value >= 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showFace
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: CardFace(card: widget.drawn.card),
                          )
                        : const CardBack(),
                  );
                },
              ),
            ),
            if (_badgeVisible)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: _ResultBadge(drawn: widget.drawn),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 新規=「はじめて!」/ 復習=「もういちど!×N」のバッジ。
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.drawn});

  final DrawnCard drawn;

  @override
  Widget build(BuildContext context) {
    final isReview = drawn.isReview;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isReview ? const Color(0xFF00897B) : const Color(0xFFFFB300),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: Text(
          isReview ? '🔁 もういちど! ×${drawn.countAfter}' : '✨ はじめて!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// パックコンプリート演出のオーバーレイ。
class _CompleteOverlay extends StatelessWidget {
  const _CompleteOverlay({required this.pack, required this.onClose});

  final Pack pack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 8),
                  Text('${pack.emoji} 🎉🎉🎉',
                      style: const TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  const Text(
                    'コンプリート!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8F00),
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
}

/// 幼児向けの大きな絵ボタン。
class _BigIconButton extends StatelessWidget {
  const _BigIconButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
      ),
    );
  }
}
