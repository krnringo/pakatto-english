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
    // 子ども向けにテンション高く聞こえるよう、標準よりやや速く・高めに設定。
    // 本格的な元気な声(実収録のキッズ向けVA)はタスク8のAI音声差し替えで対応する。
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.35);
  }

  @override
  Future<void> speak(WordCard card) async {
    await _tts.stop();
    // 単語自体は変えず、末尾の「!」でTTSの抑揚を弾ませる。
    await _tts.speak('${card.word}!');
  }
}

/// テスト・音声不要環境用。
class SilentAudioService implements AudioService {
  @override
  Future<void> speak(WordCard card) async {}
}
