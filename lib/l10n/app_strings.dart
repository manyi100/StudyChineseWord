import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 界面语言。
///
/// 汉字文化圈里“大量学习汉字”的地区主要是：
/// - 中国（含港澳台）、新加坡、马来西亚华人社区 —— 中文母语/华文教育
/// - 日本 —— 常用汉字 2136 个，小学 6 年学 1026 个
/// - 韩国 —— 汉字（한자）作为选修，中学阶段学 1800 个基础汉字
/// - 越南 —— 历史上使用字喃/汉字，现在主要在语言学研究与兴趣学习中接触
///
/// 因此界面提供中 / 英 / 日 / 韩 / 越 五种语言；无论切到哪种语言，
/// 汉字、拼音、组词、例句和朗读内容始终是中文。
enum AppLang {
  zh,
  en,
  ja,
  ko,
  vi;

  /// 存进 shared_preferences 的值，同时用于日志
  String get code => name;

  /// 语言自称，用于语言菜单
  String get nativeName => switch (this) {
        AppLang.zh => '中文',
        AppLang.en => 'English',
        AppLang.ja => '日本語',
        AppLang.ko => '한국어',
        AppLang.vi => 'Tiếng Việt',
      };

  /// 胶囊按钮上的短标签
  String get shortLabel => switch (this) {
        AppLang.zh => '中',
        AppLang.en => 'EN',
        AppLang.ja => '日',
        AppLang.ko => '한',
        AppLang.vi => 'VI',
      };

  static AppLang fromCode(String? code) => AppLang.values.firstWhere(
        (e) => e.code == code,
        orElse: () => AppLang.zh,
      );
}

/// 全局语言状态：负责读取、保存、切换界面语言。
class AppLocale {
  AppLocale._();

  static const _storageKey = 'app_language';

  /// 所有界面通过监听它来重建（见 [AppLocaleScope]）。
  static final ValueNotifier<AppLang> notifier =
      ValueNotifier<AppLang>(AppLang.zh);

  static AppLang get lang => notifier.value;

  static bool get isEn => notifier.value == AppLang.en;

  /// 本 App 支持的界面语言代码（其余系统语言一律回落中文）
  static const Set<String> _supportedCodes = {'zh', 'en', 'ja', 'ko', 'vi'};

  /// 按手机系统语言挑界面语言：从系统语言列表里取第一个我们支持的语言。
  ///
  /// 例如系统是 `ja_JP` / `ko-KR` / `vi-VN` / `en-US` 就分别进日/韩/越/英界面；
  /// 系统是 `fr-FR`、`de-DE` 这类没支持的语言时回落中文。
  static AppLang matchSystemLang(Iterable<Locale> locales) {
    for (final locale in locales) {
      final code = locale.languageCode.toLowerCase();
      if (_supportedCodes.contains(code)) return AppLang.fromCode(code);
    }
    return AppLang.zh;
  }

  /// 当前手机系统语言对应的界面语言
  static AppLang get systemLang =>
      matchSystemLang(WidgetsBinding.instance.platformDispatcher.locales);

  /// 启动时读取上次选择的语言；从没选过就跟随手机系统语言。
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      notifier.value = saved == null ? systemLang : AppLang.fromCode(saved);
    } catch (e) {
      debugPrint('[Locale] 读取界面语言失败：$e');
    }
  }

  static Future<void> set(AppLang value) async {
    if (notifier.value == value) return;
    notifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, value.code);
    } catch (e) {
      debugPrint('[Locale] 保存界面语言失败：$e');
    }
  }

  /// 在中文 / 英文之间来回切换（保留给旧入口使用）。
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
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    return scope?.notifier?.value ?? AppLang.zh;
  }
}

extension AppStringsContext on BuildContext {
  /// 用法：`final s = context.s;` 之后所有文案都从 [AppStrings] 取。
  AppStrings get s => AppStrings(AppLocaleScope.of(this));
}

/// 全部界面文案。五种语言集中在同一处，避免文案散落在各个页面。
///
/// 所有 `_t(...)` 的参数顺序固定为：中、英、日、韩、越。
class AppStrings {
  final AppLang lang;

  const AppStrings(this.lang);

  /// 不依赖 BuildContext 的场景（TTS 回调等）使用当前语言。
  static AppStrings ofCurrent() => AppStrings(AppLocale.lang);

  bool get isZh => lang == AppLang.zh;

  /// 兼容旧代码：只判断是否英文界面。
  bool get isEn => lang == AppLang.en;

  String _t(String zh, String en, String ja, String ko, String vi) =>
      switch (lang) {
        AppLang.zh => zh,
        AppLang.en => en,
        AppLang.ja => ja,
        AppLang.ko => ko,
        AppLang.vi => vi,
      };

  // ---------- 通用 ----------
  String get appTitle => _t(
        '入学必备720字',
        '720 Chinese Characters',
        '入学準備 720字',
        '취학 전 720자',
        '720 chữ Hán nhập môn',
      );

  String get homeTitle => _t(
        '选择学习阶段',
        'Choose a Stage',
        'ステージを選ぶ',
        '학습 단계 선택',
        'Chọn giai đoạn',
      );

  String get languageTooltip => _t(
        '切换界面语言',
        'Switch interface language',
        '表示言語を切り替え',
        '인터페이스 언어 변경',
        'Đổi ngôn ngữ giao diện',
      );

  /// 学习页右上角「EN」开关：控制是否显示英文释义
  String get showMeaning => _t(
        '显示英文释义',
        'Show English meaning',
        '英語の意味を表示',
        '영어 뜻 보기',
        'Hiện nghĩa tiếng Anh',
      );

  String get hideMeaning => _t(
        '隐藏英文释义',
        'Hide English meaning',
        '英語の意味を隠す',
        '영어 뜻 숨기기',
        'Ẩn nghĩa tiếng Anh',
      );

  String get languageChanged => _t(
        '已切换为中文界面',
        'English interface enabled',
        '日本語に切り替えました',
        '한국어로 전환했습니다',
        'Đã chuyển sang tiếng Việt',
      );

  String stageName(int id) => _t(
        '第 $id 阶段',
        'Stage $id',
        'ステージ $id',
        '$id단계',
        'Giai đoạn $id',
      );

  /// 点击未解锁阶段时的提示
  String lockedMessage(String previous, String current) => _t(
        '请先学完"$previous"的全部字，才能解锁"$current"哦',
        'Finish all characters in "$previous" to unlock "$current".',
        '「$previous」の漢字をすべて学ぶと「$current」が解放されます。',
        '"$previous"의 글자를 모두 익히면 "$current"이 열립니다.',
        'Học hết chữ của "$previous" để mở khóa "$current".',
      );

  String courseLabel(int n) => _t(
        '第 $n 课',
        'Lesson $n',
        '第 $n 課',
        '$n과',
        'Bài $n',
      );

  String lessonTitle(int n, String chars) => '${courseLabel(n)} · $chars';

  // ---------- 首页 ----------
  String homeIntro(int learned, int total) => _t(
        '720 字按由易到难分为 6 个阶段，每阶段 30 课、每课 4 字；'
            '共学完 $learned / $total 字',
        '720 characters in 6 stages · 30 lessons per stage · '
            '4 characters per lesson. Learned $learned / $total.',
        '720字を易しい順に6ステージ、各ステージ30課・1課4字。'
            '学習済み $learned / $total 字',
        '720자를 쉬운 순서로 6단계, 단계당 30과 · 과당 4자. '
            '학습 완료 $learned / $total자',
        '720 chữ chia 6 giai đoạn, mỗi giai đoạn 30 bài, mỗi bài 4 chữ. '
            'Đã học $learned / $total chữ',
      );

  String get byTheme => _t(
        '按主题',
        'By theme',
        'テーマ別',
        '주제별',
        'Theo chủ đề',
      );

  String get byRadical => _t(
        '按部首',
        'By radical',
        '部首別',
        '부수별',
        'Theo bộ thủ',
      );

  String get byStrokes => _t(
        '按笔画',
        'By strokes',
        '画数別',
        '획 수별',
        'Theo số nét',
      );

  String get stageLockedHint => _t(
        '完成上一阶段后解锁',
        'Finish the previous stage to unlock',
        '前のステージを完了すると解放',
        '이전 단계를 마치면 열립니다',
        'Hoàn thành giai đoạn trước để mở khóa',
      );

  String stageProgress(
    int learned,
    int total,
    int coursesDone,
    int coursesTotal,
  ) =>
      _t(
        '已学 $learned / $total 字 · 完成 $coursesDone / $coursesTotal 课',
        'Learned $learned / $total · $coursesDone / $coursesTotal lessons',
        '学習 $learned / $total 字 · $coursesDone / $coursesTotal 課',
        '$learned / $total자 학습 · $coursesDone / $coursesTotal과',
        'Đã học $learned / $total chữ · $coursesDone / $coursesTotal bài',
      );

  String get allStagesTitle => _t(
        '已解锁阶段连续学',
        'Keep learning unlocked stages',
        '解放済みステージを続けて学習',
        '열린 단계 이어서 학습',
        'Học liên tục các giai đoạn đã mở',
      );

  String allStagesSubtitle(int count) => _t(
        '按顺序学习目前已解锁的$count字',
        'The $count characters unlocked so far, in order',
        '解放済みの$count字を順番に学習',
        '현재 열린 $count자를 순서대로 학습',
        'Học theo thứ tự $count chữ đã mở',
      );

  String get favoritesTitle => _t(
        '收藏复习',
        'Review favorites',
        'お気に入り復習',
        '즐겨찾기 복습',
        'Ôn tập yêu thích',
      );

  String favoritesSubtitle(int count) => count > 0
      ? _t(
          '已收藏 $count 字，点击集中复习',
          '$count saved · tap to review',
          '$count字をお気に入り登録中 · タップで復習',
          '$count자 즐겨찾기 · 눌러서 복습',
          'Đã lưu $count chữ · chạm để ôn tập',
        )
      : _t(
          '还没有收藏，学习时点右上角星标',
          'No favorites yet — tap the star on a card',
          'まだありません。カード右上の星をタップ',
          '아직 없습니다. 카드 오른쪽 위 별을 누르세요',
          'Chưa có mục nào — chạm ngôi sao trên thẻ',
        );

  String radicalIntro(int count) => _t(
        '共 $count 个部首，按字数从多到少排列',
        '$count radicals · sorted by number of characters',
        '部首 $count 個 · 字数の多い順',
        '부수 $count개 · 글자 수 많은 순',
        '$count bộ thủ · xếp theo số chữ',
      );

  String get strokeIntro => _t(
        '笔画由少到多，适合零基础起步',
        'From fewer strokes to more — a good place to start',
        '画数の少ない順。初めての方に最適',
        '획 수가 적은 순서 · 처음 시작하기 좋아요',
        'Từ ít nét đến nhiều nét — phù hợp người mới',
      );

  String gridIntro(int count) => _t(
        '共 $count 字 · 点击任意字开始学习',
        '$count characters · tap any character to start',
        '$count字 · 任意の字をタップして学習',
        '$count자 · 아무 글자나 눌러 시작',
        '$count chữ · chạm một chữ để bắt đầu',
      );

  String charCount(int count) => _t(
        '$count 字',
        '$count characters',
        '$count字',
        '$count자',
        '$count chữ',
      );

  String radicalLabel(String raw) =>
      (raw == '其他' && !isZh) ? _t('其他', 'Other', 'その他', '기타', 'Khác') : raw;

  String radicalTitle(String radical) => _t(
        '部首 · $radical',
        'Radical · ${radicalLabel(radical)}',
        '部首 · ${radicalLabel(radical)}',
        '부수 · ${radicalLabel(radical)}',
        'Bộ thủ · ${radicalLabel(radical)}',
      );

  String strokeTitle(String bandLabel) => _t(
        '笔画 · $bandLabel',
        'Strokes · $bandLabel',
        '画数 · $bandLabel',
        '획 수 · $bandLabel',
        'Số nét · $bandLabel',
      );

  /// 笔画分段名称：中文沿用数据里的 “1~3画”，其他语言按数字重新拼。
  String strokeBandLabel(
    String zhLabel,
    int minStrokes,
    int maxStrokes,
  ) {
    if (isZh) return zhLabel;
    if (maxStrokes >= 99) {
      return _t(
        '$minStrokes 画以上',
        '$minStrokes+ strokes',
        '$minStrokes画以上',
        '$minStrokes획 이상',
        'từ $minStrokes nét',
      );
    }
    if (minStrokes == maxStrokes) {
      return _t(
        '$minStrokes 画',
        '$minStrokes strokes',
        '$minStrokes画',
        '$minStrokes획',
        '$minStrokes nét',
      );
    }
    return _t(
      '$minStrokes~$maxStrokes 画',
      '$minStrokes–$maxStrokes strokes',
      '$minStrokes〜$maxStrokes画',
      '$minStrokes~$maxStrokes획',
      '$minStrokes–$maxStrokes nét',
    );
  }

  /// 笔画分段卡片里的两行标签：在数字与单位之间断行，避免窄卡片被挤压。
  String strokeBandMultiline(String bandLabel) {
    switch (lang) {
      case AppLang.zh:
      case AppLang.ja:
        return bandLabel.replaceAll('画', '\n画');
      case AppLang.ko:
        return bandLabel.replaceAll('획', '\n획');
      case AppLang.en:
      case AppLang.vi:
        return bandLabel.replaceFirst(' ', '\n');
    }
  }

  // ---------- 课程列表 ----------
  String courseListTitle(int stageId) => _t(
        '${stageName(stageId)} · 课程',
        '${stageName(stageId)} · Lessons',
        '${stageName(stageId)} · 課',
        '${stageName(stageId)} · 과',
        '${stageName(stageId)} · Bài',
      );

  String courseListIntro(
    int learned,
    int total,
    int lessons,
    int done,
  ) =>
      _t(
        '每课 4 字，共 $lessons 课；已学 $learned / $total 字，'
            '完成 $done / $lessons 课',
        '4 characters per lesson · $lessons lessons. '
            'Learned $learned / $total characters · '
            '$done lessons completed',
        '1課4字・全$lessons課。学習 $learned / $total 字、'
            '完了 $done / $lessons 課',
        '과당 4자 · 총 $lessons과. '
            '$learned / $total자 학습 · $done / $lessons과 완료',
        'Mỗi bài 4 chữ · $lessons bài. '
            'Đã học $learned / $total chữ · hoàn thành $done / $lessons bài',
      );

  String get continuousStage => _t(
        '连续学完本阶段',
        'Study the whole stage',
        'このステージを続けて学習',
        '이 단계 이어서 학습',
        'Học hết giai đoạn này',
      );

  String get courseDone => _t(
        '已完成',
        'Done',
        '完了',
        '완료',
        'Xong',
      );

  String courseProgress(int learned, int total) => _t(
        '$learned / $total 字',
        '$learned / $total characters',
        '$learned / $total 字',
        '$learned / $total자',
        '$learned / $total chữ',
      );

  // ---------- 学习页 / 卡片 ----------
  String get allUnlockedTitle => _t(
        '入学必备720字 · 已解锁',
        'All unlocked characters',
        '入学準備 720字 · 解放済み',
        '취학 전 720자 · 열림',
        '720 chữ Hán · đã mở',
      );

  String get emptyStage => _t(
        '该阶段暂无数据',
        'No characters in this stage yet',
        'このステージにはまだデータがありません',
        '이 단계에는 아직 자료가 없습니다',
        'Giai đoạn này chưa có dữ liệu',
      );

  String get backToStages => _t(
        '返回阶段选择',
        'Back to stages',
        'ステージ選択に戻る',
        '단계 선택으로 돌아가기',
        'Quay lại chọn giai đoạn',
      );

  String lessonFinishedHint(int count) => _t(
        '先看完本课 $count 个字，再滑到下一课',
        'View all $count characters in this lesson before swiping on',
        'この課の$count字をすべて見てから次へ進んでください',
        '이 과의 $count자를 모두 본 뒤 넘어가세요',
        'Xem hết $count chữ của bài này rồi hãy chuyển bài',
      );

  String get audioHint => _t(
        '点汉字、词语、句子或图片，都能听发音',
        'Tap a character, word, sentence or picture to hear it read aloud',
        '漢字・単語・例文・イラストをタップすると発音が聞けます',
        '글자·단어·문장·그림을 누르면 발음을 들을 수 있어요',
        'Chạm chữ, từ, câu hoặc hình để nghe phát âm',
      );

  String get sectionWords => _t('组词', 'Words', '単語', '단어', 'Từ ngữ');

  String get sectionSentence => _t('造句', 'Sentence', '例文', '문장', 'Câu ví dụ');

  String radicalMeta(String radical, String strokes) => _t(
        '部首：$radical　共$strokes画',
        'Radical: $radical · $strokes strokes',
        '部首：$radical・全$strokes画',
        '부수: $radical · 총 $strokes획',
        'Bộ thủ: $radical · $strokes nét',
      );

  String strokeOrderMeta(String order) => _t(
        '笔顺：$order',
        'Stroke order: $order',
        '筆順：$order',
        '필순: $order',
        'Thứ tự nét: $order',
      );

  String get noStrokeData => _t(
      '暂无笔顺数据', 'No stroke data', '筆順データなし', '필순 자료 없음', 'Chưa có dữ liệu nét');

  String strokeOrder(List<String> names) =>
      names.isEmpty ? noStrokeData : names.map(strokeName).join(' → ');

  String get needsReview => _t(
        '⚠️ 该字数据需人工核对原书',
        '⚠️ This entry needs a manual check',
        '⚠️ この字は原本での確認が必要です',
        '⚠️ 이 글자는 원본 확인이 필요합니다',
        '⚠️ Mục này cần kiểm tra lại với bản gốc',
      );

  String get semanticsRead => _t('朗读', 'Read aloud', '読み上げ', '읽기', 'Đọc to');

  String get readingLabel => _t('朗读中', 'Reading', '読み上げ中', '읽는 중', 'Đang đọc');

  // ---------- 收藏 ----------
  String get favoritesEmpty => _t(
        '还没有收藏的字\n在学习页点击星星即可收藏',
        'No favorites yet\nTap the star on a study card to save one',
        'お気に入りはまだありません\n学習カードの星をタップして追加',
        '즐겨찾기가 없습니다\n학습 카드의 별을 눌러 추가하세요',
        'Chưa có mục yêu thích\nChạm ngôi sao trên thẻ để lưu',
      );

  // ---------- 田字格 / 描红 ----------
  String get strokeDemo =>
      _t('笔顺演示', 'Stroke demo', '筆順アニメ', '필순 보기', 'Xem thứ tự nét');

  String get traceWrite => _t('手写描红', 'Trace', 'なぞり書き', '따라 쓰기', 'Tập viết');

  String get traceAgain =>
      _t('再写一遍', 'Trace again', 'もう一度書く', '다시 쓰기', 'Viết lại');

  String demoDone(int total) => _t(
        '共 $total 画 · 直接在格子里写即可描红',
        '$total strokes · write in the grid to trace',
        '全$total画 · マスに書くとそのままなぞり書き',
        '총 $total획 · 칸에 쓰면 따라 쓰기',
        '$total nét · viết vào ô để tập',
      );

  String demoProgress(int index, int total, String? name) => _t(
        '笔顺演示：第 $index / $total 画${name != null ? '（$name）' : ''}',
        'Stroke demo: $index / $total${name != null ? ' ($name)' : ''}',
        '筆順：$index / $total画${name != null ? '（$name）' : ''}',
        '필순: $index / $total획${name != null ? ' ($name)' : ''}',
        'Thứ tự nét: $index / $total${name != null ? ' ($name)' : ''}',
      );

  String traceDone(int total) => _t(
        '🎉 全部 $total 画描写完成！',
        '🎉 All $total strokes traced!',
        '🎉 全$total画のなぞり書き完了！',
        '🎉 $total획 따라 쓰기 완료!',
        '🎉 Đã viết xong $total nét!',
      );

  String tracePrompt(int index, int total, String? name) => _t(
        '请顺着红点写：第 $index / $total 画${name != null ? '（$name）' : ''}',
        'Follow the red dot: stroke $index / $total'
            '${name != null ? ' ($name)' : ''}',
        '赤い点をたどって書く：$index / $total画'
            '${name != null ? '（$name）' : ''}',
        '빨간 점을 따라 쓰기: $index / $total획'
            '${name != null ? ' ($name)' : ''}',
        'Viết theo điểm đỏ: nét $index / $total'
            '${name != null ? ' ($name)' : ''}',
      );

  String traceSuccess(int total) => _t(
        '🎉 太棒啦！全部 $total 画都写对啦',
        '🎉 Great job! All $total strokes are correct',
        '🎉 すごい！全$total画を正しく書けました',
        '🎉 잘했어요! $total획을 모두 바르게 썼어요',
        '🎉 Tuyệt vời! Đúng cả $total nét',
      );

  String traceRetry(int index, String? name) => _t(
        '顺着红点方向写第 $index 画${name != null ? '（$name）' : ''}',
        'Follow the red dot for stroke $index'
            '${name != null ? ' ($name)' : ''}',
        '赤い点の方向へ$index画目を書く'
            '${name != null ? '（$name）' : ''}',
        '빨간 점 방향으로 $index획 쓰기'
            '${name != null ? ' ($name)' : ''}',
        'Viết nét $index theo hướng điểm đỏ'
            '${name != null ? ' ($name)' : ''}',
      );

  // ---------- 新手引导 ----------
  String get onboardingBtnHelp => _t(
        '使用说明',
        'Guide',
        '使い方',
        '사용법',
        'Hướng dẫn',
      );

  String get onboardingSkip => _t(
        '跳过',
        'Skip',
        'スキップ',
        '건너뛰기',
        'Bỏ qua',
      );

  String get onboardingPrev => _t(
        '上一步',
        'Back',
        '戻る',
        '이전',
        'Trước',
      );

  String get onboardingNext => _t(
        '下一步',
        'Next',
        '次へ',
        '다음',
        'Tiếp',
      );

  String get onboardingStart => _t(
        '开始学习',
        'Start Learning',
        '学習を始める',
        '학습 시작',
        'Bắt đầu học',
      );

  String get onboardingTitle1 => _t(
        '720 字阶段闯关 · 三维检索',
        '720 Characters · 3 Ways to Browse',
        '720字ステージ制 · 3つの検索モード',
        '720자 단계별 학습 · 3가지 탐색 모드',
        '720 Chữ Hán · 3 Chế độ tra cứu',
      );

  String get onboardingDesc1 => _t(
        '全书分为第 1~6 阶段（每阶段 30 课、每课 4 字，共 180 课）。'
            '学完上一阶段全部 120 字自动解锁下一阶段；'
            '首页顶部可自由切换「按主题」「按部首（174 个）」「按笔画（6 档）」。',
        'Stages 1–6, 30 lessons each, 4 characters per lesson (180 lessons). '
            'Finish all 120 characters in a stage to unlock the next one; '
            'switch freely between Topic, 174 Radicals and 6 Stroke tiers.',
        '第1〜第6ステージ（各30課・1課4字、計180課）。'
            '前のステージの120字を終えると次が解放されます。'
            '上部タブで「テーマ別」「部首別（174部首）」「画数別（6段階）」を切り替えられます。',
        '1~6단계(단계별 30과, 과별 4자, 총 180과)로 구성됩니다. '
            '이전 단계 120자를 모두 익히면 다음 단계가 열립니다. '
            '상단 탭에서 주제별·부수별(174개)·획수별(6구간)을 자유롭게 오갈 수 있습니다.',
        'Gồm 6 giai đoạn (mỗi giai đoạn 30 bài, mỗi bài 4 chữ, tổng 180 bài). '
            'Học hết 120 chữ của giai đoạn trước để mở giai đoạn kế tiếp; '
            'chuyển linh hoạt giữa Theo chủ đề, 174 Bộ thủ và 6 nhóm Số nét.',
      );

  List<String> get onboardingTags1 => [
        _t('6 阶段 × 30 课', '6 Stages × 30 Lessons', '6ステージ × 30課', '6단계 × 30과',
            '6 giai đoạn × 30 bài'),
        _t('174 个部首检索', '174 Radicals', '174部首リスト', '174개 부수 탐색', '174 bộ thủ'),
        _t('6 档笔画分组', '6 Stroke Tiers', '6段階の画数検索', '6구간 획수 분류',
            '6 nhóm số nét'),
      ];

  String get onboardingTitle2 => _t(
        '四区即点即读 · 全离线语音',
        'Tap Anywhere to Hear · 100% Offline Audio',
        '4箇所タップ音声 · 完全オフライン再生',
        '4곳 터치 발음 듣기 · 100% 오프라인 음성',
        'Chạm 4 vùng nghe phát âm · Âm thanh Offline',
      );

  String get onboardingDesc2 => _t(
        '随包内置 3,380 条校准音频，不依赖网络与系统 TTS。'
            '点击「田字格汉字」「组词词块」「例句喇叭」即刻朗读；'
            '点击「顶部插画」会按「例句 → 第一个组词 → 单字」顺序连读并浮出句子气泡。',
        '3,380 built-in audio clips play offline without system TTS. '
            'Tap the Character Grid, Word Chips or Sentence Speaker to listen; '
            'tap the Illustration to play Sentence → 1st Word → Character with a bubble.',
        '3,380件の内蔵音声をオフラインで再生できます。'
            '「田字格の漢字」「単語チップ」「例文スピーカー」をタップすると発音が聞け、'
            '「イラスト」をタップすると「例文 → 最初の単語 → 単字」の順に連続再生されます。',
        '3,380개의 내장 음성으로 인터넷이나 시스템 TTS 없이 재생됩니다. '
            '한자 칸·단어 칩·예문 스피커를 터치해 발음을 듣고, '
            '일러스트를 터치하면 예문 → 첫 단어 → 단자 순으로 이어서 재생됩니다.',
        'Tích hợp sẵn 3.380 tệp âm thanh, không cần mạng hay TTS hệ thống. '
            'Chạm Ô chữ Hán, Thẻ từ ghép hoặc Loa câu ví dụ để nghe; '
            'chạm Tranh minh họa để nghe lần lượt Câu ví dụ → Từ đầu tiên → Chữ đơn.',
      );

  List<String> get onboardingTags2 => [
        _t('点汉字 / 词语 / 例句', 'Tap Char / Word / Sentence', '漢字・単語・例文タップ',
            '한자·단어·예문 터치', 'Chạm chữ / từ / câu'),
        _t('点插画三连读 + 气泡', 'Tap Picture for 3-Part Audio', 'イラストで3連続読み上げ',
            '일러스트 3연속 발음+말풍선', 'Chạm tranh đọc 3 phần'),
        _t('3,380 条离线语音', '3,380 Offline Clips', '3,380件のオフライン音声',
            '3,380개 오프라인 음성', '3.380 âm thanh offline'),
      ];

  String get onboardingTitle3 => _t(
        '自动笔顺演示 · 手指跟写描红',
        'Stroke Order Animation · Guided Finger Tracing',
        '書き順アニメーション · 指なぞり練習',
        '필순 애니메이션 · 손가락 따라 쓰기',
        'Hoạt ảnh nét viết · Luyện tô chữ bằng tay',
      );

  String get onboardingDesc3 => _t(
        '打开卡片自动逐笔演示，可随时重播。直接用手指在田字格内书写即可进入描红：'
            '从红点起笔，沿虚线写向收笔箭头；写错或轻点田字格会自动演示当前笔画。'
            '田字格独立手势识别，写「横」不会误翻页。',
        'Cards animate the stroke order automatically and can replay any stroke. '
            'Draw inside the grid to trace: start at the red dot and follow the dashed '
            'line to the arrow. Tapping the grid replays the stroke. '
            'Horizontal strokes never flip pages.',
        'カードを開くと書き順が自動再生され、いつでも再生し直せます。'
            '田字格の中を指でなぞると練習モードに入り、赤い始点から破線に沿って矢印まで書けます。'
            'マス内は独立判定のため「横画」でページがめくれることはありません。',
        '카드를 열면 필순이 자동 재생되고 언제든 다시 볼 수 있습니다. '
            '한자 칸 안을 손가락으로 따라 쓰면 빨간 시작점에서 점선을 따라 화살표까지 이어집니다. '
            '한자 칸은 독립 제스처라 가로획을 그어도 페이지가 넘어가지 않습니다.',
        'Mở thẻ là tự động chiếu thứ tự nét và có thể xem lại bất cứ lúc nào. '
            'Viết trực tiếp trong ô chữ từ chấm đỏ theo đường nét đứt đến mũi tên; '
            'viết nét ngang không lo bị lật trang nhầm.',
      );

  List<String> get onboardingTags3 => [
        _t('起笔红点 → 箭头校验', 'Red Dot → Arrow Check', '始点・方向・終点を判定',
            '시작점·방향·끝점 체크', 'Chấm đỏ → mũi tên chuẩn'),
        _t('轻点格子重播当前笔', 'Tap Grid to Replay Stroke', 'マスタップでお手本再生',
            '칸 탭하여 현재 획 다시보기', 'Chạm ô xem lại nét mẫu'),
        _t('写「横」防误触翻页', 'No Accidental Page Flip', '横画でも誤スワイプ防止',
            '가로획 페이지 넘김 방지', 'Chống lật trang nhầm'),
      ];

  String get onboardingTitle4 => _t(
        '五语切换 · EN 释义 · 跨课滑动',
        '5 UI Languages · EN Meanings · Cross-Lesson Swipes',
        '5言語UI · EN英語訳スイッチ · 課の連続スワイプ',
        '5개국어 UI · EN 영어 뜻풀이 · 단원 간 스와이프',
        'Giao diện 5 ngôn ngữ · Nghĩa EN · Vuốt chuyển bài',
      );

  String get onboardingDesc4 => _t(
        '右上角可切换中/英/日/韩/越五语界面，学习页右上角「EN」按钮可一键显隐英文释义'
            '（防误触不发声）。学完一课 4 字继续左滑直达下一课；在第 1 页右滑松手返回上一课末尾；'
            '点右上角星标可收入首页底部「收藏复习」。',
        'Switch between 5 UI languages (中/EN/日/한/VI) and tap "EN" on study cards to '
            'toggle English meanings. Swipe left after finishing 4 characters to enter the '
            'next lesson, swipe right on page 1 to return to the previous lesson, or star '
            'cards for review.',
        '右上から5言語（中/EN/日/한/VI）を切り替えられ、学習画面の「EN」で英語訳を表示・非表示にできます。'
            '4字学習後に左スワイプで次の課へ、1ページ目で右スワイプして離すと前の課へ戻ります。'
            '右上の星マークでお気に入り復習に登録できます。',
        '우측 상단에서 5개 언어(中/EN/日/한/VI)를 전환하고 학습 화면의 "EN" 버튼으로 영어 뜻풀이를 '
            '켜고 끌 수 있습니다. 4자를 모두 본 뒤 왼쪽 스와이프로 다음 과로, '
            '첫 페이지에서 오른쪽 스와이프로 이전 과로 이동하며 별표로 즐겨찾기 복습이 가능합니다.',
        'Chuyển đổi 5 ngôn ngữ (中/EN/日/한/VI) ở góc trên, nhấn nút "EN" để bật/tắt nghĩa tiếng Anh. '
            'Xem đủ 4 chữ vuốt trái sang bài tiếp theo, ở trang đầu vuốt phải thả tay để về bài trước; '
            'nhấn Ngôi sao để lưu vào Ôn tập yêu thích.',
      );

  List<String> get onboardingTags4 => [
        _t('中 / EN / 日 / 한 / VI', '5 Interface Languages', '5言語UI＆日本語筆順名',
            '5개국어 UI & 한국어 필순명', '5 ngôn ngữ giao diện'),
        _t('EN 英文释义开关', 'EN Meaning Toggle', 'EN 英語訳ON/OFF', 'EN 영어 뜻풀이 스위치',
            'Nút bật/tắt nghĩa EN'),
        _t('左滑下一课 · 右滑上一课', 'Swipe Across Lessons', '左右スワイプで課を移動',
            '좌우 스와이프 단원 이동', 'Vuốt chuyển bài'),
      ];

  // ---------- 系统提示 ----------
  String get ttsUnavailable => _t(
        '没有可用的中文语音。请到 设置 - 更多设置 - 无障碍 - 文字转语音(TTS)输出 '
            '里选择或安装一个支持中文的语音引擎。',
        'No Chinese voice is available. Open Settings → Accessibility → '
            'Text-to-speech output and choose or install a Chinese voice.',
        '中国語の音声がありません。設定 → ユーザー補助 → テキスト読み上げ出力 で'
            '中国語対応の音声エンジンを選ぶかインストールしてください。',
        '중국어 음성이 없습니다. 설정 → 접근성 → 텍스트 음성 변환 출력에서 '
            '중국어 음성 엔진을 선택하거나 설치하세요.',
        'Chưa có giọng đọc tiếng Trung. Vào Cài đặt → Trợ năng → '
            'Chuyển văn bản thành giọng nói để chọn hoặc cài giọng tiếng Trung.',
      );

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

  static const Map<String, String> _strokeNamesJa = {
    '横': '横',
    '竖': '縦',
    '撇': '左払い',
    '点': '点',
    '点2': '点',
    '捺': '右払い',
    '提': '右上がり',
    '横折': '横折れ',
    '横钩': '横鉤',
    '横撇': '横＋左払い',
    '横折钩': '横折れ鉤',
    '竖钩': '縦鉤',
    '竖弯': '縦曲がり',
    '竖弯钩': '縦曲がり鉤',
    '撇折': '左払い折れ',
    '撇点': '左払い点',
    '竖提': '縦右上がり',
    '斜钩': '斜鉤',
    '卧钩': '臥し鉤',
    '横斜钩': '横斜鉤',
    '竖折折钩': '縦二重折れ鉤',
    '横折折撇': '横二重折れ',
    '弯钩': '曲がり鉤',
    '横折提': '横折れ右上がり',
    '横折折折钩': '横三重折れ鉤',
    '横撇弯钩': '横左払い曲がり鉤',
    '横折折': '横二重折れ',
    '横折弯': '横折れ曲がり',
    '竖折撇': '縦折れ左払い',
    '竖折折': '縦二重折れ',
  };

  static const Map<String, String> _strokeNamesKo = {
    '横': '가로',
    '竖': '세로',
    '撇': '왼삐침',
    '点': '점',
    '点2': '점',
    '捺': '오른삐침',
    '提': '올림',
    '横折': '꺾은 가로',
    '横钩': '가로 갈고리',
    '横撇': '가로＋왼삐침',
    '横折钩': '꺾은 가로 갈고리',
    '竖钩': '세로 갈고리',
    '竖弯': '세로 굽음',
    '竖弯钩': '세로 굽은 갈고리',
    '撇折': '왼삐침 꺾음',
    '撇点': '왼삐침 점',
    '竖提': '세로 올림',
    '斜钩': '비스듬 갈고리',
    '卧钩': '누운 갈고리',
    '横斜钩': '가로 비스듬 갈고리',
    '竖折折钩': '세로 두 번 꺾은 갈고리',
    '横折折撇': '가로 두 번 꺾음',
    '弯钩': '굽은 갈고리',
    '横折提': '꺾은 가로 올림',
    '横折折折钩': '가로 세 번 꺾은 갈고리',
    '横撇弯钩': '가로 왼삐침 굽은 갈고리',
    '横折折': '가로 두 번 꺾음',
    '横折弯': '가로 꺾어 굽음',
    '竖折撇': '세로 꺾어 왼삐침',
    '竖折折': '세로 두 번 꺾음',
  };

  /// 把数据里的中文笔顺名翻译成当前界面语言；未知名称保留原文。
  String strokeName(String raw) {
    if (isZh) return raw;
    final map = switch (lang) {
      AppLang.ja => _strokeNamesJa,
      AppLang.ko => _strokeNamesKo,
      _ => _strokeNamesEn,
    };
    final parts = raw.split('|').where((e) => e.trim().isNotEmpty);
    return parts.map((e) => map[e] ?? e).join(' / ');
  }
}
