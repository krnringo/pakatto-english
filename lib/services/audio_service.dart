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

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4); // 幼児向けにゆっくり
    await _tts.setPitch(1.1);
  }

  @override
  Future<void> speak(WordCard card) async {
    await _tts.stop();
    await _tts.speak(card.word);
  }
}

/// テスト・音声不要環境用。
class SilentAudioService implements AudioService {
  @override
  Future<void> speak(WordCard card) async {}
}
