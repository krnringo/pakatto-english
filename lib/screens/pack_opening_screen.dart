import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pack.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../widgets/card_face.dart';
import '../widgets/pack_pouch.dart';
import 'collection_screen.dart';

const double _cardWidth = 200;
const double _cardHeight = 286;

/// パック開封演出: 開封アニメーション → 3枚が重なって出る → 上の1枚をタップで
/// めくる(音声再生+新規/復習バッジ)→ もう一度タップでどかして次の1枚 →
/// 全部めくったら結果の導線(+コンプリート演出)。
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

  /// 現在いちばん上にあるカードのindex。総数に達したら全部めくり終わり。
  int _currentIndex = 0;
  bool _completeShown = false;

  int get _total => widget.result.cards.length;
  bool get _allDone => _currentIndex >= _total;

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

  void _onRevealed(int index) {
    context.read<AudioService>().speak(widget.result.cards[index].card);
  }

  void _onDismissed() {
    setState(() => _currentIndex++);
    if (_allDone && widget.result.becameComplete && !_completeShown) {
      Future.delayed(const Duration(milliseconds: 500), () {
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
                  _buildDeck(),
                const Spacer(),
                AnimatedOpacity(
                  opacity: _allDone ? 1 : 0,
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

  /// 重なったカードの山。奥のカードは少し下にずらして「重なり」を見せ、
  /// いちばん上の1枚だけがタップに反応する。
  Widget _buildDeck() {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight + 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 奥のカード(まだめくっていない分)を下にずらして重ねる
          for (var i = _total - 1; i > _currentIndex; i--)
            Positioned(
              top: 30 + (i - _currentIndex) * 12.0,
              child: const _DeckBack(),
            ),
          if (!_allDone)
            Positioned(
              top: 20,
              child: _TopCard(
                key: ValueKey('top-$_currentIndex'),
                drawn: widget.result.cards[_currentIndex],
                onRevealed: () => _onRevealed(_currentIndex),
                onDismissed: _onDismissed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return IgnorePointer(
      ignoring: !_allDone,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BigIconButton(
            emoji: '🏠',
            // この画面は PackBagScreen の上に積まれているため、pop()単体
            // では袋選択画面止まりになる。ホームまで一気に戻す。
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(width: 32),
          _BigIconButton(
            emoji: '📖',
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) =>
                      CollectionScreen(initialPackId: widget.pack.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 山の奥に見える裏向きカード(演出のみ、タップ不可)。
class _DeckBack extends StatelessWidget {
  const _DeckBack();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: CardBack(),
    );
  }
}

/// パックが震えて弾ける開封アニメーション。弾ける瞬間に光の爆発を添える。
class _OpeningPack extends StatelessWidget {
  const _OpeningPack({required this.controller, required this.pack});

  final AnimationController controller;
  final Pack pack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final t = controller.value;
            // 光の爆発フラッシュ: 弾ける後半でぱっと広がって消える
            final burstT = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
            return IgnorePointer(
              child: Opacity(
                opacity: burstT == 0 ? 0 : (1 - burstT),
                child: Container(
                  width: 60 + burstT * 260,
                  height: 60 + burstT * 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
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
          child: PackPouch(pack: pack, enabled: true, width: 160),
        ),
      ],
    );
  }
}

/// 山のいちばん上のカード。1回目のタップでめくり(flip)、2回目のタップで
/// どかす(slide)。どかし終えると [onDismissed] で次のカードへ進む。
class _TopCard extends StatefulWidget {
  const _TopCard({
    super.key,
    required this.drawn,
    required this.onRevealed,
    required this.onDismissed,
  });

  final DrawnCard drawn;
  final VoidCallback onRevealed;
  final VoidCallback onDismissed;

  @override
  State<_TopCard> createState() => _TopCardState();
}

class _TopCardState extends State<_TopCard> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _slide;
  bool _revealed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slide = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _flip.dispose();
    _slide.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_busy) return;
    if (!_revealed) {
      _busy = true;
      _flip.forward().whenComplete(() {
        setState(() {
          _revealed = true;
          _busy = false;
        });
        widget.onRevealed();
      });
      setState(() {});
    } else {
      _busy = true;
      _slide.forward().whenComplete(widget.onDismissed);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('top-card'),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flip, _slide]),
        builder: (context, _) {
          // どかす: 上へ飛ばしつつフェードアウト
          final s = _slide.value;
          final content = Opacity(
            opacity: 1 - s,
            child: Transform.translate(
              offset: Offset(s * 60, -s * 420),
              child: Transform.rotate(angle: s * 0.4, child: _buildCard()),
            ),
          );
          return content;
        },
      ),
    );
  }

  Widget _buildCard() {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final angle = _flip.value * pi;
                final showFace = _flip.value >= 0.5;
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
          if (_revealed)
            Positioned(
              top: -14,
              left: 0,
              right: 0,
              child: Center(child: _ResultBadge(drawn: widget.drawn)),
            ),
        ],
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
