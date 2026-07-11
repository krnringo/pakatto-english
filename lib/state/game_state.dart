import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../models/owned_card.dart';
import '../models/pack.dart';
import '../models/stamina_state.dart';
import '../models/word_card.dart';

/// 開封で引いた1枚の結果。
class DrawnCard {
  const DrawnCard({
    required this.card,
    required this.isReview,
    required this.countAfter,
  });

  final WordCard card;

  /// true = 既に所持していたカード(復習)。
  final bool isReview;

  /// この抽選を反映した後の所持枚数(演出の「×N」表示用)。
  final int countAfter;
}

/// 1回の開封(3枚)の結果。
class PackOpeningResult {
  const PackOpeningResult({required this.cards, required this.becameComplete});

  final List<DrawnCard> cards;

  /// この開封で初めてパックコンプリートに到達した。
  final bool becameComplete;
}

/// ゲーム全体の状態。抽選・復習判定・スタミナ消費を行い、都度永続化する。
///
/// [random] と [clock] はテストから差し替え可能。
class GameState extends ChangeNotifier {
  GameState({
    required GameRepository repository,
    Random? random,
    DateTime Function()? clock,
  })  : _repo = repository,
        _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  static const int cardsPerOpening = 3;

  final GameRepository _repo;
  final Random _random;
  final DateTime Function() _clock;

  Map<String, OwnedCard> _ownedCards = {};
  StaminaState _stamina = StaminaState.initial();
  int _totalOpenCount = 0;
  Set<String> _unlockedPackIds = {};

  void load() {
    _ownedCards = _repo.loadOwnedCards();
    _stamina = _repo.loadStamina();
    _totalOpenCount = _repo.loadTotalOpenCount();
    _unlockedPackIds = _repo.loadUnlockedPackIds();
    notifyListeners();
  }

  // --- スタミナ ---

  int get currentStamina => _stamina.currentAt(_clock());

  Duration? get timeToNextRecovery => _stamina.timeToNextRecovery(_clock());

  bool get canOpen => currentStamina > 0;

  // --- 所持状況 ---

  OwnedCard? ownedCard(String cardId) => _ownedCards[cardId];

  bool isCollected(String cardId) => _ownedCards.containsKey(cardId);

  int collectedCount(Pack pack) =>
      pack.cards.where((c) => _ownedCards.containsKey(c.id)).length;

  bool isComplete(Pack pack) => collectedCount(pack) >= pack.totalCards;

  int get totalOpenCount => _totalOpenCount;

  int get totalReviewCount =>
      _ownedCards.values.fold(0, (sum, o) => sum + o.reviewCount);

  bool isUnlocked(Pack pack) => pack.isFree || _unlockedPackIds.contains(pack.id);

  // --- 開封 ---

  /// パックを1回開封する(スタミナ1消費、3枚抽選、復習判定、永続化)。
  ///
  /// スタミナ0、または未解放パックのときは [StateError]。呼び出し側は
  /// [canOpen] / [isUnlocked] で事前に防ぐ。UI側のフィルタだけに頼らず、
  /// 実際に抽選・永続化を行うこの境界でもパック解放を担保する。
  Future<PackOpeningResult> openPack(Pack pack) async {
    if (!isUnlocked(pack)) {
      throw StateError('pack is locked');
    }
    final now = _clock();
    _stamina = _stamina.consume(now);

    final wasComplete = isComplete(pack);
    final drawn = <DrawnCard>[];
    for (var i = 0; i < cardsPerOpening; i++) {
      final card = pack.cards[_random.nextInt(pack.cards.length)];
      final existing = _ownedCards[card.id];
      if (existing == null) {
        _ownedCards[card.id] = OwnedCard(
          cardId: card.id,
          count: 1,
          reviewCount: 0,
          firstAcquiredAt: now,
        );
        drawn.add(DrawnCard(card: card, isReview: false, countAfter: 1));
      } else {
        existing.count += 1;
        existing.reviewCount += 1;
        drawn.add(
            DrawnCard(card: card, isReview: true, countAfter: existing.count));
      }
    }
    _totalOpenCount += 1;

    await _repo.saveOwnedCards(_ownedCards);
    await _repo.saveStamina(_stamina);
    await _repo.saveTotalOpenCount(_totalOpenCount);
    notifyListeners();

    return PackOpeningResult(
      cards: drawn,
      becameComplete: !wasComplete && isComplete(pack),
    );
  }
}
