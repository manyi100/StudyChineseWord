import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 界面语言：中文（默认）/ 英文。
enum AppLang { zh, en }

/// 全局语言状态：负责读取、保存、切换界面语言。
///
/// 语言本身与汉字数据无关：切到英文只是把界面文案换成英文，
/// 汉字、拼音、组词、例句以及朗读内容仍然是中文。
class AppLocale {
  AppLocale._();

  static const _storageKey = 'app_language';

  /// 所有界面通过监听它来重建（见 [AppLocaleScope]）。
  static final ValueNotifier<AppLang> notifier =
      ValueNotifier<AppLang>(AppLang.zh);

  static AppLang get lang => notifier.value;

  static bool get isEn => notifier.value == AppLang.en;

  /// 启动时读取上次选择的语言，默认中文。
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      notifier.value = saved == 'en' ? AppLang.en : AppLang.zh;
    } catch (e) {
      debugPrint('[Locale] 读取界面语言失败：$e');
    }
  }

  static Future<void> set(AppLang value) async {
    if (notifier.value == value) return;
    notifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value == AppLang.en ? 'en' : 'zh');
    } catch (e) {
      debugPrint('[Locale] 保存界面语言失败：$e');
    }
  }

  static Future<void> toggle() =>
      set(notifier.value == AppLang.en ? AppLang.zh : AppLang.en);
}

/// 把语言状态注入 widget 树，语言切换时所有依赖它的页面会自动重建。
class AppLocaleScope extends InheritedNotifier<ValueNotifier<AppLang>> {
  const AppLocaleScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppLang of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    return scope?.notifier?.value ?? AppLang.zh;
  }
}

extension AppStringsContext on BuildContext {
  /// 用法：`final s = context.s;` 之后所有文案都从 [AppStrings] 取。
  AppStrings get s => AppStrings(AppLocaleScope.of(this) == AppLang.en);
}

/// 全部界面文案。中文/英文集中在同一处，避免文案散落在各个页面。
class AppStrings {
  final bool isEn;

  const AppStrings(this.isEn);

  /// 不依赖 BuildContext 的场景（TTS 回调等）使用当前语言。
  static AppStrings ofCurrent() => AppStrings(AppLocale.isEn);

  // ---------- 通用 ----------
  String get appTitle => isEn ? '720 Chinese Characters' : '入学必备720字';

  String get homeTitle => isEn ? 'Choose a Stage' : '选择学习阶段';

  /// 语言按钮显示的是“可以切换到的语言”
  String get languageButtonLabel => isEn ? '中文' : 'EN';

  String get languageTooltip => isEn ? 'Switch to Chinese' : '切换到英语';

  String get languageChanged =>
      isEn ? 'English interface enabled' : '已切换为中文界面';

  String stageName(int id) => isEn ? 'Stage $id' : '第 $id 阶段';

  /// 点击未解锁阶段时的提示
  String lockedMessage(String previous, String current) => isEn
      ? 'Finish all characters in "$previous" to unlock "$current".'
      : '请先学完"$previous"的全部字，才能解锁"$current"哦';

  String courseLabel(int n) => isEn ? 'Lesson $n' : '第 $n 课';

  String lessonTitle(int n, String chars) =>
      '${courseLabel(n)} · $chars';

  // ---------- 首页 ----------
  String homeIntro(int learned, int total) => isEn
      ? '720 characters in 6 stages · 30 lessons per stage · '
          '4 characters per lesson. Learned $learned / $total.'
      : '720 字按由易到难分为 6 个阶段，每阶段 30 课、每课 4 字；'
          '共学完 $learned / $total 字';

  String get byTheme => isEn ? 'By theme' : '按主题';

  String get byRadical => isEn ? 'By radical' : '按部首';

  String get byStrokes => isEn ? 'By strokes' : '按笔画';

  String get stageLockedHint =>
      isEn ? 'Finish the previous stage to unlock' : '完成上一阶段后解锁';

  String stageProgress(
    int learned,
    int total,
    int coursesDone,
    int coursesTotal,
  ) =>
      isEn
          ? 'Learned $learned / $total · '
              '$coursesDone / $coursesTotal lessons'
          : '已学 $learned / $total 字 · '
              '完成 $coursesDone / $coursesTotal 课';

  String get allStagesTitle =>
      isEn ? 'Keep learning unlocked stages' : '已解锁阶段连续学';

  String allStagesSubtitle(int count) => isEn
      ? 'The $count characters unlocked so far, in order'
      : '按顺序学习目前已解锁的$count字';

  String get favoritesTitle => isEn ? 'Review favorites' : '收藏复习';

  String favoritesSubtitle(int count) => count > 0
      ? (isEn
          ? '$count saved · tap to review'
          : '已收藏 $count 字，点击集中复习')
      : (isEn
          ? 'No favorites yet — tap the star on a card'
          : '还没有收藏，学习时点右上角星标');

  String radicalIntro(int count) => isEn
      ? '$count radicals · sorted by number of characters'
      : '共 $count 个部首，按字数从多到少排列';

  String get strokeIntro => isEn
      ? 'From fewer strokes to more — a good place to start'
      : '笔画由少到多，适合零基础起步';

  String gridIntro(int count) => isEn
      ? '$count characters · tap any character to start'
      : '共 $count 字 · 点击任意字开始学习';

  String charCount(int count) =>
      isEn ? '$count characters' : '$count 字';

  String radicalLabel(String raw) =>
      (isEn && raw == '其他') ? 'Other' : raw;

  String radicalTitle(String radical) => isEn
      ? 'Radical · ${radicalLabel(radical)}'
      : '部首 · $radical';

  String strokeTitle(String bandLabel) =>
      isEn ? 'Strokes · $bandLabel' : '笔画 · $bandLabel';

  /// 笔画分段名称：英文用 “1–3 strokes”，中文沿用数据里的 “1~3画”。
  String strokeBandLabel(
    String zhLabel,
    int minStrokes,
    int maxStrokes,
  ) {
    if (!isEn) return zhLabel;
    if (maxStrokes >= 99) return '$minStrokes+ strokes';
    if (minStrokes == maxStrokes) return '$minStrokes strokes';
    return '$minStrokes–$maxStrokes strokes';
  }

  // ---------- 课程列表 ----------
  String courseListTitle(int stageId) => isEn
      ? '${stageName(stageId)} · Lessons'
      : '${stageName(stageId)} · 课程';

  String courseListIntro(
    int learned,
    int total,
    int lessons,
    int done,
  ) =>
      isEn
          ? '4 characters per lesson · $lessons lessons. '
              'Learned $learned / $total characters · '
              '$done lessons completed'
          : '每课 4 字，共 $lessons 课；已学 $learned / $total 字，'
              '完成 $done / $lessons 课';

  String get continuousStage =>
      isEn ? 'Study the whole stage' : '连续学完本阶段';

  String get courseDone => isEn ? 'Done' : '已完成';

  String courseProgress(int learned, int total) => isEn
      ? '$learned / $total characters'
      : '$learned / $total 字';

  // ---------- 学习页 / 卡片 ----------
  String get allUnlockedTitle =>
      isEn ? 'All unlocked characters' : '入学必备720字 · 已解锁';

  String get emptyStage =>
      isEn ? 'No characters in this stage yet' : '该阶段暂无数据';

  String get backToStages =>
      isEn ? 'Back to stages' : '返回阶段选择';

  String lessonFinishedHint(int count) => isEn
      ? 'View all $count characters in this lesson before swiping on'
      : '先看完本课 $count 个字，再滑到下一课';

  String get audioHint => isEn
      ? 'Tap a character, word, sentence or picture to hear it read aloud'
      : '点汉字、词语、句子或图片，都能听发音';

  String get sectionWords => isEn ? 'Words' : '组词';

  String get sectionSentence => isEn ? 'Sentence' : '造句';

  String radicalMeta(String radical, String strokes) => isEn
      ? 'Radical: $radical · $strokes strokes'
      : '部首：$radical　共$strokes画';

  String strokeOrderMeta(String order) =>
      isEn ? 'Stroke order: $order' : '笔顺：$order';

  String get noStrokeData => isEn ? 'No stroke data' : '暂无笔顺数据';

  String strokeOrder(List<String> names) =>
      names.isEmpty ? noStrokeData : names.map(strokeName).join(' → ');

  String get needsReview => isEn
      ? '⚠️ This entry needs a manual check'
      : '⚠️ 该字数据需人工核对原书';

  String get semanticsRead => isEn ? 'Read aloud' : '朗读';

  String get readingLabel => isEn ? 'Reading' : '朗读中';

  // ---------- 收藏 ----------
  String get favoritesEmpty => isEn
      ? 'No favorites yet\nTap the star on a study card to save one'
      : '还没有收藏的字\n在学习页点击星星即可收藏';

  // ---------- 田字格 / 描红 ----------
  String get strokeDemo => isEn ? 'Stroke demo' : '笔顺演示';

  String get traceWrite => isEn ? 'Trace' : '手写描红';

  String get traceAgain => isEn ? 'Trace again' : '再写一遍';

  String demoDone(int total) => isEn
      ? '$total strokes · write in the grid to trace'
      : '共 $total 画 · 直接在格子里写即可描红';

  String demoProgress(int index, int total, String? name) => isEn
      ? 'Stroke demo: $index / $total${name != null ? ' ($name)' : ''}'
      : '笔顺演示：第 $index / $total 画${name != null ? '（$name）' : ''}';

  String traceDone(int total) => isEn
      ? '🎉 All $total strokes traced!'
      : '🎉 全部 $total 画描写完成！';

  String tracePrompt(int index, int total, String? name) => isEn
      ? 'Follow the red dot: stroke $index / $total'
          '${name != null ? ' ($name)' : ''}'
      : '请顺着红点写：第 $index / $total 画'
          '${name != null ? '（$name）' : ''}';

  String traceSuccess(int total) => isEn
      ? '🎉 Great job! All $total strokes are correct'
      : '🎉 太棒啦！全部 $total 画都写对啦';

  String traceRetry(int index, String? name) => isEn
      ? 'Follow the red dot for stroke $index'
          '${name != null ? ' ($name)' : ''}'
      : '顺着红点方向写第 $index 画${name != null ? '（$name）' : ''}';

  // ---------- 系统提示 ----------
  String get ttsUnavailable => isEn
      ? 'No Chinese voice is available. Open Settings → Accessibility → '
          'Text-to-speech output and choose or install a Chinese voice.'
      : '没有可用的中文语音。请到 设置 - 更多设置 - 无障碍 - 文字转语音(TTS)输出 '
          '里选择或安装一个支持中文的语音引擎。';

  // ---------- 笔顺名称 ----------
  static const Map<String, String> _strokeNamesEn = {
    '横': 'horizontal',
    '竖': 'vertical',
    '撇': 'left-falling',
    '点': 'dot',
    '点2': 'dot',
    '捺': 'right-falling',
    '提': 'rising',
    '横折': 'horizontal turn',
    '横钩': 'horizontal hook',
    '横撇': 'horizontal + left-falling',
    '横折钩': 'horizontal-turn hook',
    '竖钩': 'vertical hook',
    '竖弯': 'vertical curve',
    '竖弯钩': 'vertical-curve hook',
    '撇折': 'left-falling turn',
    '撇点': 'left-falling dot',
    '竖提': 'vertical rising',
    '斜钩': 'slant hook',
    '卧钩': 'lying hook',
    '横斜钩': 'horizontal slant hook',
    '竖折折钩': 'vertical double-turn hook',
    '横折折撇': 'horizontal double-turn',
    '弯钩': 'curved hook',
    '横折提': 'horizontal-turn rising',
    '横折折折钩': 'horizontal triple-turn hook',
    '横撇弯钩': 'horizontal left-falling hook',
    '横折折': 'horizontal double turn',
    '横折弯': 'horizontal turn + curve',
    '竖折撇': 'vertical turn + left-falling',
    '竖折折': 'vertical double turn',
  };

  /// 把数据里的中文笔顺名翻译成英文；未知名称保留原文。
  String strokeName(String raw) {
    if (!isEn) return raw;
    final parts = raw.split('|').where((e) => e.trim().isNotEmpty);
    return parts.map((e) => _strokeNamesEn[e] ?? e).join(' / ');
  }
}
