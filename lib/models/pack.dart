import 'package:flutter/material.dart';

import 'word_card.dart';

/// カードパックのマスタデータ。
///
/// [isFree] が false のパックは購入で解放される(課金実装は別仕様)。
/// 本仕様では「解放済みかどうか」のフラグのみ扱う。
class Pack {
  const Pack({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.emoji,
    required this.color,
    required this.isFree,
    required this.cards,
  });

  final String id;
  final String nameJa;
  final String nameEn;
  final String emoji;
  final Color color;
  final bool isFree;
  final List<WordCard> cards;

  int get totalCards => cards.length;
}
