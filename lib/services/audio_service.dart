import 'package:flutter_tts/flutter_tts.dart';

import '../models/word_card.dart';

/// カード音声の再生。実アセット(AI TTS音声ファイル)投入までは
/// OS内蔵TTSで代替する(タスク8で差し替え)。
abstract class AudioService {
  Future<void> speak(WordCard card);
}

class TtsAudioService implements AudioService {
  TtsAudioService() {
    _init();
  }

  final FlutterTts _tts = FlutterTts();
  int _cheerIndex = 0;

  // 単語の後に添える短い掛け声。毎回同じだと単調になるので順番にローテーションする。
  static const _cheers = ['Yay!', 'Woo-hoo!', 'Awesome!', 'Yippee!'];

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    // 単語→掛け声を順番どおりに再生するため、前の発話が終わってから次を再生する。
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  Future<void> speak(WordCard card) async {
    await _tts.stop();

    // 単語自体は明瞭に発音させる(学習が主目的なので速くしすぎない)。
    await _tts.setPitch(1.3);
    await _tts.setSpeechRate(0.5);
    await _tts.speak('${card.word}!');

    // 直後に短い掛け声を続けてテンションを上げる。
    // OS内蔵TTSの表現力には限界があるため、本格的に元気な声は
    // タスク8のAI音声(実収録のキッズ向けVA)差し替えで対応する。
    await _tts.setPitch(1.6);
    await _tts.setSpeechRate(0.62);
    await _tts.speak(_cheers[_cheerIndex % _cheers.length]);
    _cheerIndex++;
  }
}

/// テスト・音声不要環境用。
class SilentAudioService implements AudioService {
  @override
  Future<void> speak(WordCard card) async {}
}
