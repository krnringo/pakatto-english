import 'package:flutter/material.dart';

import '../models/word_card.dart';

/// カードの表面(プレースホルダ: 絵文字+英単語)。
/// 実アセット投入時は emoji 部分を Image.asset(card.imageAsset) に差し替える。
class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.wordScale = 1.0});

  final WordCard card;
  final double wordScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(card.color, Colors.white, 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.color, width: 3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(card.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
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

/// カードの裏面。
class CardBack extends StatelessWidget {
  const CardBack({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Center(
        child: Text('⭐', style: TextStyle(fontSize: 48)),
      ),
    );
  }
}
