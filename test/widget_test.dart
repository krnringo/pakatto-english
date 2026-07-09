import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakatto_english/data/game_repository.dart';
import 'package:pakatto_english/data/master_data.dart';
import 'package:pakatto_english/models/word_card.dart';
import 'package:pakatto_english/screens/collection_screen.dart';
import 'package:pakatto_english/screens/home_screen.dart';
import 'package:pakatto_english/screens/pack_opening_screen.dart';
import 'package:pakatto_english/screens/parent_screen.dart';
import 'package:pakatto_english/services/audio_service.dart';
import 'package:pakatto_english/state/game_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_state_test.dart' show FixedRandom;

/// 発話されたカードを記録するテスト用AudioService。
class RecordingAudioService implements AudioService {
  final List<String> spoken = [];

  @override
  Future<void> speak(WordCard card) async => spoken.add(card.word);
}

Future<GameState> freshState(
    {FixedRandom? random, DateTime Function()? clock}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return GameState(
    repository: GameRepository(prefs),
    random: random,
    clock: clock,
  )..load();
}

Widget wrap(Widget child, GameState state, AudioService audio) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: state),
      Provider<AudioService>.value(value: audio),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('ホーム画面', () {
    testWidgets('スタミナ表示と解放済みパックのみ表示される', (tester) async {
      final state = await freshState();
      await tester.pumpWidget(
          wrap(const HomeScreen(), state, RecordingAudioService()));
      await tester.pump();

      expect(find.text('⚡'), findsNWidgets(2));
      expect(find.text(colorsPack.emoji), findsOneWidget);
      // 有料パック(未解放)はホームに出ない
      expect(find.text(animalsPack.emoji), findsNothing);
    });

    testWidgets('縦スワイプで開封画面に遷移し3枚の裏カードが出る', (tester) async {
      final state = await freshState();
      final audio = RecordingAudioService();
      await tester.pumpWidget(wrap(const HomeScreen(), state, audio));
      await tester.pump();

      await tester.fling(
          find.text(colorsPack.emoji), const Offset(0, -400), 800);
      await tester.pump(); // openPack完了待ち
      await tester.pump(const Duration(milliseconds: 100)); // 画面遷移
      await tester.pump(const Duration(seconds: 1)); // 開封アニメーション

      expect(state.currentStamina, 1, reason: 'スタミナが1消費される');
      expect(find.text('⭐'), findsNWidgets(3), reason: '裏向きカード3枚');
    });

    testWidgets('スタミナ0では開封されず、回復残り時間シートが出る', (tester) async {
      var now = DateTime(2026, 7, 10, 9, 0);
      final state = await freshState(clock: () => now);
      await state.openPack(colorsPack);
      await state.openPack(colorsPack);
      expect(state.currentStamina, 0);

      await tester.pumpWidget(
          wrap(const HomeScreen(), state, RecordingAudioService()));
      await tester.pump();
      expect(find.text('💤'), findsOneWidget, reason: 'グレーアウト状態の表示');

      final openCountBefore = state.totalOpenCount;
      await tester.fling(
          find.text(colorsPack.emoji), const Offset(0, -400), 800);
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.totalOpenCount, openCountBefore, reason: '開封されない');
      expect(find.text('⏳'), findsOneWidget, reason: '回復までの残り時間表示');
    });
  });

  group('開封演出画面', () {
    testWidgets('タップでめくると音声再生+新規/復習バッジが出て、全部めくると導線が出る',
        (tester) async {
      final state = await freshState();
      final audio = RecordingAudioService();
      final result = PackOpeningResult(
        cards: [
          DrawnCard(card: colorsPack.cards[0], isReview: false, countAfter: 1),
          DrawnCard(card: colorsPack.cards[1], isReview: true, countAfter: 3),
          DrawnCard(card: colorsPack.cards[2], isReview: false, countAfter: 1),
        ],
        becameComplete: false,
      );
      await tester.pumpWidget(wrap(
        PackOpeningScreen(pack: colorsPack, result: result),
        state,
        audio,
      ));
      await tester.pump(const Duration(seconds: 1)); // 開封アニメーション完了

      // 1枚目: 新規(tap後のpump()はアニメーション開始フレーム用)
      await tester.tap(find.text('⭐').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(audio.spoken, ['red'], reason: 'めくった瞬間に音声再生');
      expect(find.text('✨ はじめて!'), findsOneWidget);

      // 2枚目: 復習(×3表示)
      await tester.tap(find.text('⭐').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(audio.spoken, ['red', 'blue']);
      expect(find.text('🔁 もういちど! ×3'), findsOneWidget);

      // 3枚目
      await tester.tap(find.text('⭐').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(audio.spoken, ['red', 'blue', 'yellow']);

      // 全部めくったのでホーム/図鑑ボタンが出る
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🏠'), findsOneWidget);
      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('コンプリート到達開封でコンプリート演出が出る', (tester) async {
      final state = await freshState();
      final result = PackOpeningResult(
        cards: [
          DrawnCard(card: colorsPack.cards[0], isReview: false, countAfter: 1),
        ],
        becameComplete: true,
      );
      await tester.pumpWidget(wrap(
        PackOpeningScreen(pack: colorsPack, result: result),
        state,
        RecordingAudioService(),
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('⭐').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1000)); // 演出待ち
      await tester.pump(const Duration(milliseconds: 800)); // スケールイン

      expect(find.text('👑'), findsOneWidget);
      expect(find.text('コンプリート!'), findsOneWidget);
    });
  });

  group('図鑑画面', () {
    testWidgets('未収集はシルエット、収集済みはタップで拡大+音声+枚数/復習回数表示',
        (tester) async {
      final now = DateTime(2026, 7, 10, 9, 0);
      final state = await freshState(
        random: FixedRandom([0, 0, 1]), // red×2(復習1), blue×1
        clock: () => now,
      );
      await state.openPack(colorsPack);
      final audio = RecordingAudioService();

      await tester.pumpWidget(wrap(const CollectionScreen(), state, audio));
      await tester.pump();

      expect(find.text('2 / 10'), findsOneWidget, reason: '進捗表示');
      expect(find.text('red'), findsOneWidget, reason: '収集済みはイラスト+単語');
      expect(find.text('yellow'), findsNothing, reason: '未収集はシルエットのみ');
      expect(find.text('×2'), findsOneWidget, reason: '所持枚数バッジ');

      // 収集済みカードをタップ → 拡大+音声+枚数・復習回数
      await tester.tap(find.text('red'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(audio.spoken, ['red']);
      expect(find.text('🃏 ×2   🔁 1'), findsOneWidget);
    });

    testWidgets('未購入パックのタブは🔒付きで、開くと全シルエット', (tester) async {
      final state = await freshState();
      await tester.pumpWidget(
          wrap(const CollectionScreen(), state, RecordingAudioService()));
      await tester.pump();

      expect(find.text(' 🔒'), findsNWidgets(2), reason: 'Animals/Vehiclesがロック');

      await tester.tap(find.text(animalsPack.emoji).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('0 / 12'), findsOneWidget);
      expect(find.text('dog'), findsNothing, reason: '未解放は全てシルエット');
    });
  });

  group('親向け画面', () {
    testWidgets('パック別収集数・総開封回数・総復習回数が表示される', (tester) async {
      final now = DateTime(2026, 7, 10, 9, 0);
      final state = await freshState(
        random: FixedRandom([0, 0, 1]),
        clock: () => now,
      );
      await state.openPack(colorsPack);

      await tester.pumpWidget(
          wrap(const ParentScreen(), state, RecordingAudioService()));
      await tester.pump();

      expect(find.text('2 / 10'), findsOneWidget);
      expect(find.text('1 回'), findsNWidgets(2), reason: '開封1回・復習1回');
      expect(find.text('未購入'), findsNWidgets(2));
    });
  });
}
