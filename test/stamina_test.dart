import 'package:flutter_test/flutter_test.dart';
import 'package:pakatto_english/models/stamina_state.dart';

void main() {
  final base = DateTime(2026, 7, 10, 9, 0);

  group('スタミナ', () {
    test('初期状態は満タン2/2', () {
      expect(StaminaState.initial().currentAt(base), 2);
    });

    test('2/2で1回消費→1/2', () {
      final after = StaminaState.initial().consume(base);
      expect(after.currentAt(base), 1);
    });

    test('最終消費から4時間で+1、8時間で+2、12時間放置でも2(上限クランプ)', () {
      // 2/2から2回連続消費して0にする
      final zero = StaminaState.initial().consume(base).consume(base);
      expect(zero.currentAt(base), 0);
      expect(zero.currentAt(base.add(const Duration(hours: 3, minutes: 59))), 0);
      expect(zero.currentAt(base.add(const Duration(hours: 4))), 1);
      expect(zero.currentAt(base.add(const Duration(hours: 8))), 2);
      expect(zero.currentAt(base.add(const Duration(hours: 12))), 2);
      expect(zero.currentAt(base.add(const Duration(days: 30))), 2);
    });

    test('1/2の状態でも上限2でクランプされる', () {
      final one = StaminaState.initial().consume(base);
      expect(one.currentAt(base.add(const Duration(hours: 100))), 2);
    });

    test('スタミナ0で消費するとStateError', () {
      final zero = StaminaState.initial().consume(base).consume(base);
      expect(() => zero.consume(base), throwsStateError);
    });

    test('回復した分を消費できる', () {
      final zero = StaminaState.initial().consume(base).consume(base);
      final at4h = base.add(const Duration(hours: 4));
      final after = zero.consume(at4h);
      expect(after.currentAt(at4h), 0);
    });

    test('次の回復までの残り時間', () {
      final consumed = StaminaState.initial().consume(base);
      expect(consumed.timeToNextRecovery(base), const Duration(hours: 4));
      expect(
        consumed.timeToNextRecovery(base.add(const Duration(hours: 1))),
        const Duration(hours: 3),
      );
      // 満タン時はnull
      expect(StaminaState.initial().timeToNextRecovery(base), isNull);
      expect(
        consumed.timeToNextRecovery(base.add(const Duration(hours: 4))),
        isNull,
      );
    });

    test('JSON往復で状態が保たれる', () {
      final consumed = StaminaState.initial().consume(base);
      final restored = StaminaState.fromJson(consumed.toJson());
      expect(restored.currentAt(base), 1);
      expect(restored.currentAt(base.add(const Duration(hours: 4))), 2);
    });
  });
}
