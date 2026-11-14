import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

/// 英文释义服务。
///
/// 释义和朗读音频一样随 App 打包：`assets/data/meanings_en.json` 按「文本」查表，
/// 单字、组词、例句各一张表。查不到就返回 null，界面自动不显示，
/// 所以以后新增内容时缺释义不会出现空白区域。
///
/// 界面语言只影响界面文案；这里的释义固定英文，是否显示由用户开关控制
/// （中文界面默认关闭，其它语言界面默认打开）。
class MeaningService {
  MeaningService._internal();

  static final MeaningService instance = MeaningService._internal();

  static const _assetPath = 'assets/data/meanings_en.json';
  static const _storageKey = 'show_meanings';

  /// 学习页右上角的开关状态。释义组件监听它，切换时只重建释义行。
  final ValueNotifier<bool> visible = ValueNotifier<bool>(false);

  /// 释义加载完成 / 开关变化都会触发重建。
  /// 释义是异步读取的（不阻塞首帧），组件靠这个 Listenable 在加载完成后刷新。
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  Listenable get changes => Listenable.merge([visible, _revision]);

  final Map<String, String> _chars = {};
  final Map<String, String> _words = {};
  final Map<String, String> _sentences = {};

  bool _loaded = false;
  bool _preferenceLoaded = false;
  Future<void>? _loading;

  int get charCount => _chars.length;
  int get wordCount => _words.length;
  int get sentenceCount => _sentences.length;

  Future<void> ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _fill(_chars, data['chars']);
      _fill(_words, data['words']);
      _fill(_sentences, data['sentences']);
      _loaded = true;
      debugPrint(
        '[Meaning] 释义 ${charCount} 字 / ${wordCount} 词 / ${sentenceCount} 句',
      );
      _revision.value++;
    } catch (error) {
      debugPrint('[Meaning] 读取释义失败：$error');
      _loading = null;
    }
  }

  void _fill(Map<String, String> target, Object? source) {
    if (source is! Map) return;
    source.forEach((key, value) {
      if (key is String && value is String && value.isNotEmpty) {
        target[key] = value;
      }
    });
  }

  /// 启动时读取开关；没有记录时按界面语言给默认值。
  Future<void> loadPreference() async {
    if (_preferenceLoaded) return;
    _preferenceLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      visible.value =
          prefs.getBool(_storageKey) ?? (AppLocale.lang != AppLang.zh);
    } catch (error) {
      debugPrint('[Meaning] 读取释义开关失败：$error');
    }
  }

  Future<void> setVisible(bool value) async {
    if (visible.value == value) return;
    visible.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_storageKey, value);
    } catch (error) {
      debugPrint('[Meaning] 保存释义开关失败：$error');
    }
  }

  Future<void> toggle() => setVisible(!visible.value);

  String? charOf(String char) => _chars[char];

  String? wordOf(String word) => _words[word];

  String? sentenceOf(String sentence) => _sentences[sentence];
}
