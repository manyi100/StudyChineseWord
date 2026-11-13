import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../l10n/app_strings.dart';

/// 朗读服务：优先播放随 App 打包的离线音频，缺失时回退系统 TTS。
///
/// 为什么内置音频：不少海外设备、电视盒子、投影仪没有中文 TTS 引擎，
/// 系统朗读会直接无声。720 单字 + 组词 + 例句的音频已随包分发，
/// 既不依赖系统语音，也能逐条校对多音字。
///
/// 兜底逻辑：`assets/audio/manifest.json` 里没有对应文本（例如以后新增的内容）
/// 时，才走系统 TTS，仍然保留原有引擎枚举与提示。
///
/// 小米/红米（MIUI、HyperOS）适配要点：
/// 1. Android 11+ 的包可见性限制会拦截"绑定其它应用的语音引擎服务"，必须在
///    AndroidManifest 的 queries 里声明 TTS_SERVICE。缺少声明时，小米国行机型上
///    TextToSpeech 初始化直接失败，表现为"没有报错、就是没声音"，而其它品牌
///    机型恰好不严格校验，所以问题只在小米上复现。声明已加在 AndroidManifest。
/// 2. 国行ROM不一定装有系统默认的那一个语音引擎，这里会枚举已安装引擎并逐个
///    尝试中文发音，避免死在某一个引擎上。
class TtsService {
  TtsService._internal();

  static final TtsService instance = TtsService._internal();

  /// 朗读不可用时（没有语音引擎、缺中文语音包、引擎被系统回收）回调，
  /// UI层据此提示用户去系统设置里启用语音引擎。每次运行最多提示一次。
  static void Function(String message)? onUnavailable;

  static const _candidateLanguages = ['zh-CN', 'zh-Hans-CN', 'zh-Hans', 'zh'];

  /// 组件测试环境没有原生音频插件，置 true 后朗读直接走系统 TTS 分支。
  static bool disableBundledAudio = false;

  static String get _unavailableMessage =>
      AppStrings.ofCurrent().ttsUnavailable;

  final FlutterTts _flutterTts = FlutterTts();
  Future<bool>? _readyFuture;
  bool _notified = false;

  /// 文本 -> 内置音频资源路径，启动后只加载一次。
  Map<String, String>? _audioIndex;
  Future<Map<String, String>?>? _audioIndexFuture;

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerSub;

  /// 当前正在朗读的目标标识（字/词/句/图片各自的 tag）。
  /// UI 用它来显示“声波跳动 / 朗读中”动效，读完自动变回喇叭图标。
  final ValueNotifier<String?> speakingTag = ValueNotifier<String?>(null);

  int _generation = 0;
  Timer? _fallbackTimer;

  /// 初始化并挑选可用的引擎/中文语音，只做一次；失败后下次调用会重新尝试。
  Future<bool> _ensureReady() async {
    final future = _readyFuture ??= _initialize();
    final ready = await future;
    if (!ready) {
      // 允许用户去系统里装好语音包后，再点一次就能恢复，不必重启App
      _readyFuture = null;
    }
    return ready;
  }

  Future<bool> _initialize() async {
    try {
      await _flutterTts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint('[TTS] 关闭 awaitSpeakCompletion 失败：$e');
    }

    // 先试系统当前引擎（null 表示不切换），再试其它已安装引擎。
    // 国行小米常常只有厂商自带引擎，没有 Google TTS，所以需要这个兜底。
    final engines = <String?>[null, ...await _installedEngines()];

    for (final engine in engines) {
      if (engine != null) {
        try {
          await _flutterTts.setEngine(engine);
        } catch (e) {
          debugPrint('[TTS] 引擎不可用，跳过 $engine：$e');
          continue;
        }
      }

      final language = await _pickChineseLanguage();
      if (language == null) continue;

      try {
        await _flutterTts.setSpeechRate(0.45); // 适当放慢语速，更适合识字阶段
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setVolume(1.0);
        debugPrint('[TTS] 就绪：engine=${engine ?? '系统默认'}, language=$language');
        _notified = false;
        return true;
      } catch (e) {
        debugPrint('[TTS] 引擎 $engine 参数设置失败：$e');
      }
    }

    debugPrint('[TTS] 没有找到支持中文的语音引擎');
    return false;
  }

  Future<List<String>> _installedEngines() async {
    try {
      final engines = await _flutterTts.getEngines;
      if (engines is List) {
        return engines.whereType<String>().toList();
      }
    } catch (e) {
      debugPrint('[TTS] 读取引擎列表失败：$e');
    }
    return const [];
  }

  /// 依次尝试几个常见的中文 locale，返回第一个真正设置成功的。
  Future<String?> _pickChineseLanguage() async {
    for (final language in _candidateLanguages) {
      try {
        final available = await _flutterTts.isLanguageAvailable(language);
        if (available != true) continue;
        final result = await _flutterTts.setLanguage(language);
        if (result == 1) return language;
      } catch (e) {
        debugPrint('[TTS] 检查语言 $language 失败：$e');
      }
    }
    return null;
  }

  /// 朗读一段文字（字/词/句子通用），返回是否成功开始朗读。
  /// [tag] 用于标注这次朗读的 UI 目标，点击后对应图标会显示朗读动效。
  Future<bool> speak(String text, {String? tag}) async {
    if (text.trim().isEmpty) return false;

    final generation = ++_generation;
    _beginSpeaking(tag ?? text, text, generation);

    // 1) 内置音频优先：完全离线，不依赖系统 TTS 引擎
    if (await _speakAsset(text, generation)) return true;

    // 2) 没有对应音频时，回退系统 TTS
    if (!await _ensureReady()) {
      _finishSpeaking(generation);
      _notifyUnavailable();
      return false;
    }

    if (await _speakOnce(text, generation)) return true;

    // 引擎可能被 MIUI 的省电策略回收了，重新初始化后再试一次
    _readyFuture = null;
    if (await _ensureReady() && await _speakOnce(text, generation)) return true;

    _finishSpeaking(generation);
    _notifyUnavailable();
    return false;
  }

  /// 读取内置音频索引（text -> 资源路径），只加载一次。
  Future<Map<String, String>?> _loadAudioIndex() {
    final cached = _audioIndex;
    if (cached != null) return Future<Map<String, String>?>.value(cached);

    return _audioIndexFuture ??= rootBundle
        .loadString('assets/audio/manifest.json')
        .then<Map<String, String>?>((raw) {
          final decoded = jsonDecode(raw) as Map<String, dynamic>;
          final map = <String, String>{};
          decoded.forEach((key, value) {
            if (value is String) map[key] = value;
          });
          _audioIndex = map;
          debugPrint('[Audio] 内置音频 ${map.length} 条');
          return map;
        })
        .catchError((Object error) {
          debugPrint('[Audio] 读取内置音频索引失败：$error');
          _audioIndexFuture = null;
          return null;
        });
  }

  /// 尝试播放内置音频；没有对应文件或播放失败时返回 false，交给系统 TTS。
  Future<bool> _speakAsset(String text, int generation) async {
    if (disableBundledAudio) return false;
    final index = await _loadAudioIndex();
    final path = index?[text];
    if (path == null) return false;

    try {
      final player = _player ??= AudioPlayer();
      _playerSub ??= player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _finishSpeaking(_generation);
        }
      });

      await player.stop();
      await player.setAsset(path);

      // 用真实时长兜底，避免动效提前消失或一直转
      final duration = player.duration;
      if (duration != null) {
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(
          duration + const Duration(milliseconds: 600),
          () => _finishSpeaking(generation),
        );
      }

      unawaited(player.play());
      return true;
    } catch (error) {
      debugPrint('[Audio] 内置音频播放失败，回退系统 TTS：$error');
      return false;
    }
  }

  void _beginSpeaking(String tag, String text, int generation) {
    _fallbackTimer?.cancel();
    speakingTag.value = tag;

    // 部分国产 ROM 的 TTS 完成回调不稳定，用“按文本长度估算”的定时器兜底，
    // 保证动效不会一直转下去。
    final ms = (text.runes.length * 380 + 1400).clamp(1600, 15000);
    _fallbackTimer = Timer(Duration(milliseconds: ms), () {
      _finishSpeaking(generation);
    });
  }

  void _finishSpeaking(int generation) {
    if (generation != _generation) return; // 已经切换到新的朗读目标
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    if (speakingTag.value != null) {
      speakingTag.value = null;
    }
  }

  Future<bool> _speakOnce(String text, int generation) async {
    try {
      await _flutterTts.stop(); // 防止上一句未读完就被新的朗读请求打断叠加

      // 每次朗读都重新注册回调，闭包捕获当前的 generation，
      // 旧朗读迟到的完成事件不会误清新朗读的状态。
      _flutterTts.setCompletionHandler(() => _finishSpeaking(generation));
      _flutterTts.setCancelHandler(() => _finishSpeaking(generation));
      _flutterTts.setErrorHandler((message) {
        debugPrint('[TTS] 朗读出错：$message');
        _finishSpeaking(generation);
      });

      final result = await _flutterTts.speak(text);
      if (result == 1) return true;
      debugPrint('[TTS] speak 返回 $result');
    } catch (e) {
      debugPrint('[TTS] 朗读失败：$e');
    }
    return false;
  }

  void _notifyUnavailable() {
    if (_notified) return;
    _notified = true;
    onUnavailable?.call(_unavailableMessage);
  }

  Future<void> stop({bool notify = true}) async {
    _generation++;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    // 组件销毁（dispose）时树处于锁定状态，不能再通知 ValueListenableBuilder；
    // 此时相关监听者也会被销毁，直接跳过通知即可。
    if (notify && speakingTag.value != null) {
      speakingTag.value = null;
    }
    try {
      await _player?.stop();
    } catch (e) {
      debugPrint('[Audio] 停止内置音频失败：$e');
    }
    await _flutterTts.stop();
  }
}
