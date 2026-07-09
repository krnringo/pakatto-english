import 'package:flutter_test/flutter_test.dart';
import 'package:pakatto_english/data/master_data.dart';

void main() {
  group('マスタデータ', () {
    test('初回3パック: 無料=Colors、有料=Animals/Vehicles', () {
      expect(allPacks.length, 3);
      expect(packById('colors').isFree, isTrue);
      expect(packById('animals').isFree, isFalse);
      expect(packById('vehicles').isFree, isFalse);
    });

    test('各パック10〜15語', () {
      for (final pack in allPacks) {
        expect(pack.cards.length, inInclusiveRange(10, 15),
            reason: '${pack.id} は ${pack.cards.length}語');
      }
    });

    test('カードIDは全パック横断で一意、packIdが所属パックと一致', () {
      final ids = <String>{};
      for (final pack in allPacks) {
        for (final card in pack.cards) {
          expect(ids.add(card.id), isTrue, reason: '${card.id} が重複');
          expect(card.packId, pack.id);
          expect(card.word, isNotEmpty);
          expect(card.emoji, isNotEmpty);
        }
      }
    });

    test('cardById で全カードが引ける', () {
      for (final pack in allPacks) {
        for (final card in pack.cards) {
          expect(cardById(card.id).word, card.word);
        }
      }
    });
  });
}
