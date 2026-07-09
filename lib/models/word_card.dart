import 'package:flutter/material.dart';

/// 英単語カードのマスタデータ。
///
/// [imageAsset] / [audioAsset] は実アセット差し替え(タスク8)用のパス。
/// アセット未投入の間は [emoji] + [color] でプレースホルダ表示し、
/// 音声はOS内蔵TTSで代替する。
class WordCard {
  const WordCard({
    required this.id,
    required this.word,
    required this.packId,
    required this.emoji,
    required this.color,
    String? imageAsset,
    String? audioAsset,
  })  : imageAsset = imageAsset ?? 'assets/images/$id.png',
        audioAsset = audioAsset ?? 'assets/audio/$id.mp3';

  final String id;
  final String word;
  final String packId;
  final String emoji;
  final Color color;
  final String imageAsset;
  final String audioAsset;
}
