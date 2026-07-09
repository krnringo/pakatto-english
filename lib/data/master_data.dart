/// パック・カードのマスタデータ(アプリ内バンドル、サーバー不要)。
///
/// 初回3パック: 無料=Colors / 有料=Animals + Vehicles(壁打ち要件定義 2026-07-09)。
/// emoji + color は実アセット(AI生成イラスト)投入までのプレースホルダ表示に使う。
library;

import 'package:flutter/material.dart';

import '../models/pack.dart';
import '../models/word_card.dart';

WordCard _card(String packId, String id, String word, String emoji, Color color) =>
    WordCard(id: '$packId-$id', word: word, packId: packId, emoji: emoji, color: color);

final Pack colorsPack = Pack(
  id: 'colors',
  nameJa: 'いろ',
  nameEn: 'Colors',
  emoji: '🌈',
  color: const Color(0xFFFF8A65),
  isFree: true,
  cards: [
    _card('colors', 'red', 'red', '🔴', const Color(0xFFE53935)),
    _card('colors', 'blue', 'blue', '🔵', const Color(0xFF1E88E5)),
    _card('colors', 'yellow', 'yellow', '🟡', const Color(0xFFFDD835)),
    _card('colors', 'green', 'green', '🟢', const Color(0xFF43A047)),
    _card('colors', 'orange', 'orange', '🟠', const Color(0xFFFB8C00)),
    _card('colors', 'purple', 'purple', '🟣', const Color(0xFF8E24AA)),
    _card('colors', 'pink', 'pink', '🩷', const Color(0xFFEC407A)),
    _card('colors', 'black', 'black', '⚫', const Color(0xFF424242)),
    _card('colors', 'white', 'white', '⚪', const Color(0xFF9E9E9E)),
    _card('colors', 'brown', 'brown', '🟤', const Color(0xFF6D4C41)),
  ],
);

final Pack animalsPack = Pack(
  id: 'animals',
  nameJa: 'どうぶつ',
  nameEn: 'Animals',
  emoji: '🦁',
  color: const Color(0xFF66BB6A),
  isFree: false,
  cards: [
    _card('animals', 'dog', 'dog', '🐶', const Color(0xFFA1887F)),
    _card('animals', 'cat', 'cat', '🐱', const Color(0xFFFFB74D)),
    _card('animals', 'elephant', 'elephant', '🐘', const Color(0xFF90A4AE)),
    _card('animals', 'lion', 'lion', '🦁', const Color(0xFFFFA726)),
    _card('animals', 'rabbit', 'rabbit', '🐰', const Color(0xFFF8BBD0)),
    _card('animals', 'bear', 'bear', '🐻', const Color(0xFF8D6E63)),
    _card('animals', 'monkey', 'monkey', '🐵', const Color(0xFFBCAAA4)),
    _card('animals', 'giraffe', 'giraffe', '🦒', const Color(0xFFFFCA28)),
    _card('animals', 'panda', 'panda', '🐼', const Color(0xFF78909C)),
    _card('animals', 'pig', 'pig', '🐷', const Color(0xFFF48FB1)),
    _card('animals', 'horse', 'horse', '🐴', const Color(0xFF795548)),
    _card('animals', 'sheep', 'sheep', '🐑', const Color(0xFFB0BEC5)),
  ],
);

final Pack vehiclesPack = Pack(
  id: 'vehicles',
  nameJa: 'のりもの',
  nameEn: 'Vehicles',
  emoji: '🚗',
  color: const Color(0xFF42A5F5),
  isFree: false,
  cards: [
    _card('vehicles', 'car', 'car', '🚗', const Color(0xFFE53935)),
    _card('vehicles', 'bus', 'bus', '🚌', const Color(0xFFFDD835)),
    _card('vehicles', 'train', 'train', '🚃', const Color(0xFF43A047)),
    _card('vehicles', 'airplane', 'airplane', '✈️', const Color(0xFF29B6F6)),
    _card('vehicles', 'bicycle', 'bicycle', '🚲', const Color(0xFF26A69A)),
    _card('vehicles', 'boat', 'boat', '⛵', const Color(0xFF5C6BC0)),
    _card('vehicles', 'truck', 'truck', '🚚', const Color(0xFF8D6E63)),
    _card('vehicles', 'ambulance', 'ambulance', '🚑', const Color(0xFFEF5350)),
    _card('vehicles', 'fire_truck', 'fire truck', '🚒', const Color(0xFFD32F2F)),
    _card('vehicles', 'police_car', 'police car', '🚓', const Color(0xFF3949AB)),
    _card('vehicles', 'helicopter', 'helicopter', '🚁', const Color(0xFF7E57C2)),
    _card('vehicles', 'motorcycle', 'motorcycle', '🏍️', const Color(0xFF546E7A)),
  ],
);

final List<Pack> allPacks = [colorsPack, animalsPack, vehiclesPack];

Pack packById(String id) => allPacks.firstWhere((p) => p.id == id);

WordCard cardById(String id) =>
    allPacks.expand((p) => p.cards).firstWhere((c) => c.id == id);
