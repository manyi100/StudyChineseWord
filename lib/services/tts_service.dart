import 'package:flutter_tts/flutter_tts.dart';

/// 朗读服务：封装 flutter_tts，统一管理朗读单字/词语/句子的逻辑。
/// 使用系统自带TTS引擎，完全离线，无需联网、无需额外申请API Key。
class TtsService {
  TtsService._internal() {
    _init();
  }

  static final TtsService instance = TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isReady = false;

  Future<void> _init() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.45); // 适当放慢语速，更适合识字阶段
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _isReady = true;
  }

  /// 朗读一段文字（字/词/句子通用）
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!_isReady) {
      await _init();
    }
    await _flutterTts.stop(); // 防止上一句未读完就被新的朗读请求打断叠加
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
