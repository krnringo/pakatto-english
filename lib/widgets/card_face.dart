import 'package:flutter/material.dart';

import '../models/word_card.dart';

/// カードの表面(プレースホルダ: 絵文字+英単語)。光沢ハイライトと
/// 二重枠でカードらしい質感を出す。実アセット投入時は emoji 部分を
/// Image.asset(card.imageAsset) に差し替える。
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.wordScale = 1.0});

  final WordCard card;
  final double wordScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(card.color, Colors.white, 0.85)!,
            Color.lerp(card.color, Colors.white, 0.5)!,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: card.color.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // 左上の光沢ハイライト(ガラス感)
            Positioned(
              top: -24,
              left: -24,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(card.emoji,
                          style: const TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: card.color, width: 2),
                  ),
                  child: Text(
                    card.word,
                    style: TextStyle(
                      fontSize: 18 * wordScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 未収集カードのシルエット(影絵)表示。
class SilhouetteCard extends StatelessWidget {
  const SilhouetteCard({super.key, required this.card});

  final WordCard card;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, width: 3),
      ),
      child: Center(
        child: ColorFiltered(
          colorFilter:
              ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
          child: Text(card.emoji, style: const TextStyle(fontSize: 40)),
        ),
      ),
    );
  }
}

/// カードの裏面。斜めに流れるホロの光沢アニメーション付き。
class CardBack extends StatefulWidget {
  const CardBack({super.key});

  @override
  State<CardBack> createState() => _CardBackState();
}

class _CardBackState extends State<CardBack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF3949AB), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shimmer,
                  builder: (context, _) {
                    final dx = -w + _shimmer.value * (w * 2.6);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          width: w * 0.5,
                          height: h * 2.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: w * 0.42,
                  height: w * 0.42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Text('⭐', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
