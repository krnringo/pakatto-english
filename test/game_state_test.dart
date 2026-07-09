import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pakatto_english/data/game_repository.dart';
import 'package:pakatto_english/data/master_data.dart';
import 'package:pakatto_english/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 抽選結果を固定するための疑似乱数(nextIntが指定した並びを順に返す)。
class FixedRandom implements Random {
  FixedRandom(this.values);

  final List<int> values;
  int _i = 0;

  @override
  int nextInt(int max) => values[_i++ % values.length] % max;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  final base = DateTime(2026, 7, 10, 9, 0);

  Future<GameRepository> freshRepo() async {
    SharedPreferences.setMockInitialValues({});
    return GameRepository(await SharedPreferences.getInstance());
  }

  group('抽選', () {
    test('10語パックで1000回抽選し、全カードが出現し偏りが極端でない', () async {
      final repo = await freshRepo();
      var now = base;
      final state = GameState(
        repository: repo,
        random: Random(42),
        clock: () => now,
      );

      final counts = <String, int>{};
      var drawnTotal = 0;
      while (drawnTotal < 1000) {
        now = now.add(const Duration(hours: 8)); // スタミナを回復させながら回す
        final result = await state.openPack(colorsPack);
        for (final d in result.cards) {
          counts[d.card.id] = (counts[d.card.id] ?? 0) + 1;
          drawnTotal++;
        }
      }

      expect(counts.keys.length, colorsPack.totalCards, reason: '全カードが出現する');
      final expected = drawnTotal / colorsPack.totalCards; // ≒100
      for (final entry in counts.entries) {
        expect(entry.value, greaterThan(expected * 0.5),
            reason: '${entry.key} が少なすぎる(${entry.value})');
        expect(entry.value, lessThan(expected * 1.7),
            reason: '${entry.key} が多すぎる(${entry.value})');
      }
    });
  });

  group('復習判定', () {
    test('所持0のカードを引く→枚数1/復習0。同カードを再度引く→枚数2/復習1', () async {
      final repo = await freshRepo();
      var now = base;
      // 1回目・2回目とも index 0,1,2 のカードを引く
      final state = GameState(
        repository: repo,
        random: FixedRandom([0, 1, 2, 0, 1, 2]),
        clock: () => now,
      );

      final first = await state.openPack(colorsPack);
      expect(first.cards.every((d) => !d.isReview), isTrue, reason: '全て新規');
      for (final d in first.cards) {
        final owned = state.ownedCard(d.card.id)!;
        expect(owned.count, 1);
        expect(owned.reviewCount, 0);
        expect(d.countAfter, 1);
      }

      now = now.add(const Duration(hours: 8));
      final second = await state.openPack(colorsPack);
      expect(second.cards.every((d) => d.isReview), isTrue, reason: '全て復習');
      for (final d in second.cards) {
        final owned = state.ownedCard(d.card.id)!;
        expect(owned.count, 2);
        expect(owned.reviewCount, 1);
        expect(d.countAfter, 2);
      }
    });

    test('同一開封内の重複: 2枚目からは復習になる', () async {
      final repo = await freshRepo();
      final state = GameState(
        repository: repo,
        random: FixedRandom([5, 5, 5]),
        clock: () => base,
      );

      final result = await state.openPack(colorsPack);
      expect(result.cards[0].isReview, isFalse);
      expect(result.cards[1].isReview, isTrue);
      expect(result.cards[2].isReview, isTrue);
      expect(result.cards[2].countAfter, 3);
      final owned = state.ownedCard(result.cards[0].card.id)!;
      expect(owned.count, 3);
      expect(owned.reviewCount, 2);
    });
  });

  group('スタミナ消費と開封拒否', () {
    test('2/2で1回開封→1/2。0で開封するとStateError', () async {
      final repo = await freshRepo();
      final state = GameState(
        repository: repo,
        random: Random(1),
        clock: () => base,
      );

      expect(state.currentStamina, 2);
      await state.openPack(colorsPack);
      expect(state.currentStamina, 1);
      await state.openPack(colorsPack);
      expect(state.currentStamina, 0);
      expect(state.canOpen, isFalse);
      expect(() => state.openPack(colorsPack), throwsStateError);
    });
  });

  group('進捗', () {
    test('10語中7種所持で7/10、10種でコンプリートフラグtrue', () async {
      final repo = await freshRepo();
      var now = base;
      // 0..6 の7種 → 7/10、その後 7,8,9 でコンプリート
      final state = GameState(
        repository: repo,
        random: FixedRandom([0, 1, 2, 3, 4, 5, 6, 6, 6, 7, 8, 9]),
        clock: () => now,
      );

      await state.openPack(colorsPack); // 0,1,2
      now = now.add(const Duration(hours: 8));
      await state.openPack(colorsPack); // 3,4,5
      now = now.add(const Duration(hours: 8));
      final third = await state.openPack(colorsPack); // 6,6,6
      expect(state.collectedCount(colorsPack), 7);
      expect(state.isComplete(colorsPack), isFalse);
      expect(third.becameComplete, isFalse);

      now = now.add(const Duration(hours: 8));
      final fourth = await state.openPack(colorsPack); // 7,8,9 → コンプリート
      expect(state.collectedCount(colorsPack), 10);
      expect(state.isComplete(colorsPack), isTrue);
      expect(fourth.becameComplete, isTrue, reason: 'この開封でコンプリート到達');

      // コンプリート後も開封継続可能、becameCompleteは再びfalse
      now = now.add(const Duration(hours: 8));
      final fifth = await state.openPack(colorsPack);
      expect(fifth.becameComplete, isFalse);
      expect(fifth.cards.every((d) => d.isReview), isTrue,
          reason: 'コンプリート後は全カードが復習');
    });
  });

  group('永続化', () {
    test('別インスタンスでloadすると収集状況・スタミナ・開封回数が復元される', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = base;

      final state1 = GameState(
        repository: GameRepository(prefs),
        random: FixedRandom([0, 1, 1]),
        clock: () => now,
      );
      await state1.openPack(colorsPack);

      // アプリ再起動を模擬: 同じストレージから新しいインスタンスを作る
      final state2 = GameState(repository: GameRepository(prefs), clock: () => now);
      state2.load();

      expect(state2.collectedCount(colorsPack), 2);
      expect(state2.ownedCard(colorsPack.cards[1].id)!.count, 2);
      expect(state2.ownedCard(colorsPack.cards[1].id)!.reviewCount, 1);
      expect(state2.currentStamina, 1);
      expect(state2.totalOpenCount, 1);
      expect(state2.totalReviewCount, 1);
    });
  });

  group('パック解放', () {
    test('無料パックは常に解放、有料パックは未購入なら未解放', () async {
      final repo = await freshRepo();
      final state = GameState(repository: repo)..load();
      expect(state.isUnlocked(colorsPack), isTrue);
      expect(state.isUnlocked(animalsPack), isFalse);
      expect(state.isUnlocked(vehiclesPack), isFalse);
    });
  });
}
