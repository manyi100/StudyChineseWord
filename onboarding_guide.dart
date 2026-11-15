// ============================================================================
// HanziRoots (入学必备 720 字) — 五语新手引导完整实现 (v1.3.1+)
// 包含三部分：
//   1. lib/l10n/app_strings.dart 新增文案条目（严格按「中 / 英 / 日 / 韩 / 越」顺序）
//   2. lib/services/storage_service.dart 新增首次引导标记读写方法
//   3. lib/widgets/onboarding_dialog.dart 独立新手引导弹窗组件（兼容 360dp 窄屏与 720dp 宽屏）
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------------
// 【第一部分】复制到 lib/l10n/app_strings.dart 中的 AppStrings 类内
// 说明：沿用项目既有的 _t(zh, en, ja, ko, vi) 单行五语对照写法
// ----------------------------------------------------------------------------
/*
  // === 新手引导 (Onboarding Guide) ===
  static String get onboardingBtnHelp => _t('使用说明', 'Guide', '使い方', '사용법', 'Hướng dẫn');
  static String get onboardingSkip => _t('跳过', 'Skip', 'スキップ', '건너뛰기', 'Bỏ qua');
  static String get onboardingPrev => _t('上一步', 'Back', '戻る', '이전', 'Trước');
  static String get onboardingNext => _t('下一步', 'Next', '次へ', '다음', 'Tiếp');
  static String get onboardingStart => _t('开始学习', 'Start Learning', '学習を始める', '학습 시작', 'Bắt đầu học');

  // 第 1 页：阶段闯关与三维检索
  static String get onboardingTitle1 => _t(
    '720 字阶段闯关 · 三维检索',
    '720 Characters · 3 Ways to Browse',
    '720字ステージ制 · 3つの検索モード',
    '720자 단계별 학습 · 3가지 탐색 모드',
    '720 Chữ Hán · 3 Chế độ tra cứu',
  );
  static String get onboardingDesc1 => _t(
    '6 大阶段共 180 门主题课（每课 4 字），学完本阶段 120 字自动解锁下一阶段；首页顶部可自由切换「按主题」「按部首（174 个）」「按笔画（6 档）」。',
    '6 stages with 180 thematic lessons (4 characters per lesson). Finish all 120 characters in a stage to unlock the next, or browse freely by Topic, 174 Radicals, or 6 Stroke tiers.',
    '全6ステージ・180課（1課4字）。120字を終えると次のステージが解放されます。上部タブで「テーマ別」「部首別（174部首）」「画数別（6段階）」を切り替えられます。',
    '총 6단계·180과(과별 4자)로 구성되며 120자를 완료하면 다음 단계가 열립니다. 상단 탭에서 주제별, 부수별(174개), 획수별(6구간)로 자유롭게 탐색하세요.',
    'Gồm 6 giai đoạn với 180 bài học (mỗi bài 4 chữ). Học hết 120 chữ sẽ mở khóa giai đoạn tiếp theo; chuyển đổi linh hoạt giữa Theo chủ đề, 174 Bộ thủ và 6 nhóm Số nét.',
  );

  // 第 2 页：四区离线点读
  static String get onboardingTitle2 => _t(
    '四区即点即读 · 全离线语音',
    'Tap Anywhere to Hear · 100% Offline Audio',
    '4箇所タップ音声 · 完全オフライン再生',
    '4곳 터치 발음 듣기 · 100% 오프라인 음성',
    'Chạm 4 vùng nghe phát âm · Âm thanh Offline',
  );
  static String get onboardingDesc2 => _t(
    '内置 3,380 条校准音频，无需联网或系统 TTS。点击「田字格汉字」「组词词块」「例句喇叭」均可发声；点击「插画」将按「例句 → 首词 → 单字」顺序连读并浮出句子气泡。',
    '3,380 built-in audio clips work offline without system TTS. Tap the Character Grid, Word Chips, or Sentence Speaker to listen; tap the Illustration to hear Sentence → 1st Word → Character with a sentence bubble.',
    '3,380件の音声を内蔵し、通信不要で再生できます。漢字マス・単語・例文アイコンをタップして発音を確認でき、イラストをタップすると「例文 → 単語 → 単字」の順に連続再生されます。',
    '3,380개의 내장 음성으로 인터넷 없이도 발음을 들을 수 있습니다. 한자 칸·단어 칩·예문 스피커를 터치해 발음을 듣고, 일러스트를 터치하면 예문 → 첫 단어 → 단자 순으로 연속 재생됩니다.',
    'Tích hợp sẵn 3.380 tệp âm thanh chuẩn không cần mạng. Chạm vào Ô chữ Hán, Thẻ từ ghép hoặc Loa câu ví dụ để nghe; chạm vào Tranh minh họa để nghe đọc nối tiếp Câu ví dụ → Từ đầu tiên → Chữ đơn.',
  );

  // 第 3 页：笔顺动画与手写描红
  static String get onboardingTitle3 => _t(
    '自动笔顺演示 · 手指跟写描红',
    'Stroke Order Animation · Guided Finger Tracing',
    '書き順アニメーション · 指なぞり練習',
    '필순 애니메이션 · 손가락 따라 쓰기',
    'Hoạt ảnh nét viết · Luyện tô chữ bằng tay',
  );
  static String get onboardingDesc3 => _t(
    '打开卡片自动播放笔顺动画。直接在田字格内用手指书写即可进入描红：从红点起笔，沿虚线写向箭头；写错或轻点格子会重播当前笔画。田字格独立识别手势，写「横」不会误翻页。',
    'Cards automatically play stroke animations. Draw inside the grid with your finger to trace from the red dot along the dashed line to the arrow; tap the grid to replay a stroke. Horizontal strokes never trigger page flips.',
    'カードを開くと書き順を自動再生します。マス内を指でなぞると練習モードに入り、赤い点から破線に沿って矢印まで書けます。マス内は独立判定のため、横画を書いてもページはめくれません。',
    '카드를 열면 필순 애니메이션이 자동 재생됩니다. 한자 칸 안에 손가락으로 빨간 시작점부터 점선을 따라 화살표까지 써 보세요. 한자 칸은 독립 제스처로 인식되어 가로획을 그어도 페이지가 넘어가지 않습니다.',
    'Thẻ tự động chiếu thứ tự nét viết. Dùng ngón tay viết trực tiếp vào ô chữ từ chấm đỏ theo đường nét đứt đến mũi tên; chạm nhẹ vào ô để xem lại nét mẫu. Viết nét ngang không lo bị lật trang nhầm.',
  );

  // 第 4 页：五语切换、EN 释义与跨课手势
  static String get onboardingTitle4 => _t(
    '五语界面 · EN 释义 · 跨课滑动',
    '5 UI Languages · EN Meanings · Cross-Lesson Swipes',
    '5言語UI · EN英語訳スイッチ · 課の連続スワイプ',
    '5개국어 UI · EN 영어 뜻풀이 · 단원 간 스와이프',
    'Giao diện 5 ngôn ngữ · Nghĩa EN · Vuốt chuyển bài',
  );
  static String get onboardingDesc4 => _t(
    '右上角可切换中/英/日/韩/越界面，学习页点击「EN」可开关英文释义（防误触不发声）。看完一课 4 字继续左滑直达下一课，在第一页右滑松手即可返回上一课末尾；点右上角星标可加入首页「收藏复习」。',
    'Switch UI languages (中/EN/日/한/VI) at top-right, and tap "EN" on study cards to toggle English meanings. Swipe left after viewing 4 characters for the next lesson, swipe right & release on page 1 for the previous lesson, or star cards for review.',
    '右上から5言語（中/EN/日/한/VI）を切り替えられ、学習画面の「EN」で英語訳を表示・非表示にできます。4字学習後に左スワイプで次の課へ進み、1ページ目で右スワイプして離すと前の課へ戻ります。星マークでお気に入り復習も可能です。',
    '우측 상단에서 5개 언어(中/EN/日/한/VI)를 전환하고 학습 화면의 "EN" 버튼으로 영어 뜻풀이를 켜고 끌 수 있습니다. 4자를 모두 본 뒤 왼쪽 스와이프로 다음 과로, 첫 페이지에서 오른쪽 스와이프로 이전 과로 이동하며 별표로 즐겨찾기 복습이 가능합니다.',
    'Chuyển đổi 5 ngôn ngữ (中/EN/日/한/VI) ở góc phải trên, nhấn nút "EN" để bật/tắt nghĩa tiếng Anh. Học xong 4 chữ vuốt trái sang bài kế tiếp, ở trang đầu vuốt phải thả tay để về bài trước; nhấn Ngôi sao để lưu vào mục Ôn tập yêu thích.',
  );
*/

// ----------------------------------------------------------------------------
// 【第二部分】复制到 lib/services/storage_service.dart 中的 StorageService 类内
// ----------------------------------------------------------------------------
class OnboardingStorageHelper {
  static const String _kOnboardingSeenKey = 'has_seen_onboarding_v131';

  /// 检查是否已经展示过新手引导
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingSeenKey) ?? false;
  }

  /// 标记新手引导已读
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
  }
}

// ----------------------------------------------------------------------------
// 【第三部分】独立文件：lib/widgets/onboarding_dialog.dart
// 说明：
//   - 若你的工程中已有 AppLang / AppStrings，可直接接入 AppStrings.languageNotifier
//   - 下方内置了与 lib/l10n/app_strings.dart 完全同构的五语映射表，开箱即用
//   - 已做 360dp 窄屏防溢出（SingleChildScrollView + Wrap）与 iPad/TV 宽屏居中约束
// ----------------------------------------------------------------------------

/// 与项目 lib/l10n/app_strings.dart 保持一致的五语枚举
enum OnboardingLang {
  zh('zh', '中'),
  en('en', 'EN'),
  ja('ja', '日'),
  ko('ko', '한'),
  vi('vi', 'VI');

  final String code;
  final String badge;
  const OnboardingLang(this.code, this.badge);

  static OnboardingLang fromCode(String? code) {
    for (final lang in OnboardingLang.values) {
      if (lang.code == code) return lang;
    }
    return OnboardingLang.zh;
  }
}

/// 单页引导数据模型
class _OnboardingStepData {
  final IconData icon;
  final Color accentColor;
  final List<String> titles; // [zh, en, ja, ko, vi]
  final List<String> descriptions; // [zh, en, ja, ko, vi]
  final List<List<String>> highlights; // 每个语言 3 个短标签

  const _OnboardingStepData({
    required this.icon,
    required this.accentColor,
    required this.titles,
    required this.descriptions,
    required this.highlights,
  });

  String titleFor(OnboardingLang lang) => titles[lang.index];
  String descFor(OnboardingLang lang) => descriptions[lang.index];
  List<String> highlightsFor(OnboardingLang lang) => highlights[lang.index];
}

class OnboardingDialog extends StatefulWidget {
  /// 初始语言代码（可传入 AppStrings 当前的 app_language：'zh'/'en'/'ja'/'ko'/'vi'）
  final String initialLangCode;

  /// 当用户在引导弹窗内切换语言时同步回调给外部 AppStrings
  final ValueChanged<String>? onLanguageChanged;

  const OnboardingDialog({
    super.key,
    this.initialLangCode = 'zh',
    this.onLanguageChanged,
  });

  /// 首次启动自动检查并弹出引导（在 GradeSelectScreen.initState 的 addPostFrameCallback 中调用）
  static Future<void> showIfNeeded(
    BuildContext context, {
    String currentLangCode = 'zh',
    ValueChanged<String>? onLanguageChanged,
  }) async {
    final seen = await OnboardingStorageHelper.hasSeenOnboarding();
    if (seen || !context.mounted) return;
    await showModal(
      context,
      currentLangCode: currentLangCode,
      onLanguageChanged: onLanguageChanged,
    );
    await OnboardingStorageHelper.markOnboardingSeen();
  }

  /// 手动打开使用说明弹窗（可绑定在首页右上角「?」帮助按钮上）
  static Future<void> showModal(
    BuildContext context, {
    String currentLangCode = 'zh',
    ValueChanged<String>? onLanguageChanged,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => OnboardingDialog(
        initialLangCode: currentLangCode,
        onLanguageChanged: onLanguageChanged,
      ),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  static const Color _kPaperBg = Color(0xFFF4EAD8); // 与启动图/自适应图标一致的米色底
  static const Color _kCardBg = Color(0xFFFFFBF2);
  static const Color _kInkDark = Color(0xFF2C241D);
  static const Color _kInkMuted = Color(0xFF6E5E4F);

  late OnboardingLang _lang;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const List<_OnboardingStepData> _steps = [
    // Step 1: 阶段闯关与三维分类
    _OnboardingStepData(
      icon: Icons.grid_view_rounded,
      accentColor: Color(0xFFC84B31),
      titles: [
        '720 字阶段闯关 · 三维检索',
        '720 Characters · 3 Ways to Browse',
        '720字ステージ制 · 3つの検索モード',
        '720자 단계별 학습 · 3가지 탐색 모드',
        '720 Chữ Hán · 3 Chế độ tra cứu',
      ],
      descriptions: [
        '全书分为第 1~6 阶段（每阶段 30 课、每课 4 字，共 180 课）。学完上一阶段全部 120 字自动解锁下一阶段；首页顶部可自由切换「按主题」「按部首（174 个）」「按笔画（6 档）」。',
        'Organized into Stages 1–6 (30 lessons per stage, 4 characters per lesson). Finish all 120 characters in a stage to unlock the next, or switch tabs to browse by Topic, 174 Radicals, or 6 Stroke tiers.',
        '第1〜第6ステージ（各30課・1課4字、計180課）で構成。前のステージの120字を終えると次のステージが解放されます。上部タブで「テーマ別」「部首別（174部首）」「画数別（6段階）」を切り替えられます。',
        '1~6단계(단계별 30과, 과별 4자, 총 180과)로 구성됩니다. 이전 단계 120자를 모두 학습하면 다음 단계가 잠금 해제되며, 상단 탭에서 주제별·부수별(174개)·획수별(6구간)로 탐색할 수 있습니다.',
        'Gồm 6 Giai đoạn (mỗi giai đoạn 30 bài, mỗi bài 4 chữ, tổng 180 bài). Học hết 120 chữ sẽ mở khóa giai đoạn kế tiếp; chuyển tab trên cùng để duyệt Theo chủ đề, 174 Bộ thủ hoặc 6 nhóm Số nét.',
      ],
      highlights: [
        ['6 阶段 × 30 课', '174 个部首检索', '6 档笔画分组'],
        ['6 Stages × 30 Lessons', '174 Radicals', '6 Stroke Tiers'],
        ['6ステージ × 30課', '174部首リスト', '6段階の画数検索'],
        ['6단계 × 30과', '174개 부수 탐색', '6구간 획수 분류'],
        ['6 Giai đoạn × 30 Bài', '174 Bộ thủ', '6 Nhóm số nét'],
      ],
    ),

    // Step 2: 四区离线点读
    _OnboardingStepData(
      icon: Icons.volume_up_rounded,
      accentColor: Color(0xFF2D6A4F),
      titles: [
        '四区即点即读 · 全离线语音',
        'Tap Anywhere to Hear · 100% Offline Audio',
        '4箇所タップ音声 · 完全オフライン再生',
        '4곳 터치 발음 듣기 · 100% 오프라인 음성',
        'Chạm 4 vùng nghe phát âm · Âm thanh Offline',
      ],
      descriptions: [
        '随包内置 3,380 条校准音频，不依赖网络与系统 TTS。点击「田字格汉字」「组词词块」「例句喇叭」即刻朗读；点击「顶部插画」会按「例句 → 第一个组词 → 单字」顺序连读并浮出句子气泡。',
        '3,380 built-in audio clips play offline without needing system TTS. Tap the Character Grid, Word Chips, or Sentence Speaker to listen; tap the Illustration to play Sentence → 1st Word → Character with a floating bubble.',
        '3,380件の内蔵音声によりオフラインで再生可能。「田字格の漢字」「単語チップ」「例文スピーカー」をタップして発音を聞けるほか、「イラスト」をタップすると「例文 → 最初の単語 → 単字」の順に連続再生されます。',
        '3,380개의 내장 음성으로 인터넷이나 시스템 TTS 없이도 재생됩니다. 한자 칸·단어 칩·예문 스피커를 터치해 발음을 듣고, 일러스트를 터치하면 예문 → 첫 단어 → 단자 순으로 말풍선과 함께 연속 재생됩니다.',
        'Tích hợp sẵn 3.380 tệp âm thanh chuẩn hoạt động không cần mạng. Chạm vào Ô chữ Hán, Thẻ từ ghép hoặc Loa câu ví dụ để nghe; chạm vào Tranh minh họa để nghe đọc lần lượt Câu ví dụ → Từ đầu tiên → Chữ đơn.',
      ],
      highlights: [
        ['点汉字 / 词语 / 例句', '点插画三连读 + 气泡', '3,380 条离线语音'],
        ['Tap Char / Word / Sentence', 'Tap Picture for 3-Part Audio', '3,380 Offline Clips'],
        ['漢字・単語・例文タップ', 'イラストで3連続読み上げ', '3,380件のオフライン音声'],
        ['한자·단어·예문 터치', '일러스트 3연속 발음+말풍선', '3,380개 오프라인 음성'],
        ['Chạm Chữ / Từ / Câu', 'Chạm Tranh đọc 3 phần', '3.380 Âm thanh Offline'],
      ],
    ),

    // Step 3: 笔顺动画与手指描红
    _OnboardingStepData(
      icon: Icons.draw_rounded,
      accentColor: Color(0xFFB5651D),
      titles: [
        '自动笔顺演示 · 手指跟写描红',
        'Stroke Order Animation · Guided Finger Tracing',
        '書き順アニメーション · 指なぞり練習',
        '필순 애니메이션 · 손가락 따라 쓰기',
        'Hoạt ảnh nét viết · Luyện tô chữ bằng tay',
      ],
      descriptions: [
        '打开卡片自动逐笔演示，可随时重播。直接用手指在田字格内书写即可进入描红：从红点起笔，沿虚线写向收笔箭头；写错或轻点田字格会自动演示当前笔画。田字格独立手势识别，写「横」不会误翻页。',
        'Cards automatically animate stroke order on open. Draw directly inside the grid with your finger: start at the red dot, follow the dashed line to the arrow. Tap the grid to replay a stroke. Horizontal strokes never flip pages.',
        'カードを開くと書き順アニメーションが自動再生されます。田字格の中を指で直接なぞると練習モードに入り、赤い始点から破線に沿って矢印まで書けます。マス内は独立判定のため「横画」でページがめくれることはありません。',
        '카드를 열면 필순 애니메이션이 자동 재생됩니다. 한자 칸 안에 손가락으로 빨간 시작점에서 점선을 따라 화살표까지 직접 써 보세요. 한자 칸은 독립 제스처로 인식되어 가로획을 그어도 페이지가 넘어가지 않습니다.',
        'Mở thẻ tự động chiếu thứ tự nét viết. Dùng ngón tay viết trực tiếp vào ô chữ từ chấm đỏ, kéo theo đường nét đứt đến mũi tên; chạm nhẹ vào ô để chiếu lại nét mẫu. Viết nét ngang không bị lật trang nhầm.',
      ],
      highlights: [
        ['起笔红点 → 箭头校验', '轻点格子重播当前笔', '写「横」防误触翻页'],
        ['Red Dot → Arrow Check', 'Tap Grid to Replay Stroke', 'No Accidental Page Flip'],
        ['始点・方向・終点を判定', 'マスタップでお手本再生', '横画でも誤スワイプ防止'],
        ['시작점·방향·끝점 실시간 체크', '칸 탭하여 현재 획 다시보기', '가로획 페이지 넘김 방지'],
        ['Chấm đỏ → Mũi tên chuẩn', 'Chạm ô xem lại nét mẫu', 'Chống lật trang nhầm'],
      ],
    ),

    // Step 4: 多语言、EN 释义与跨课手势
    _OnboardingStepData(
      icon: Icons.translate_rounded,
      accentColor: Color(0xFF3D5A80),
      titles: [
        '五语切换 · EN 释义 · 跨课滑动',
        '5 UI Languages · EN Meanings · Cross-Lesson Swipes',
        '5言語UI · EN英語訳スイッチ · 課の連続スワイプ',
        '5개국어 UI · EN 영어 뜻풀이 · 단원 간 스와이프',
        'Giao diện 5 ngôn ngữ · Nghĩa EN · Vuốt chuyển bài',
      ],
      descriptions: [
        '右上角可切换中/英/日/韩/越五语界面，学习页右上角「EN」按钮可一键显隐英文释义（防误触不发声）。学完一课 4 字继续左滑直达下一课；在第 1 页右滑松手返回上一课末尾；点右上角星标可收入首页底部「收藏复习」。',
        'Switch between 5 UI languages (中/EN/日/한/VI) and tap "EN" on study cards to toggle English meanings. Swipe left after finishing 4 characters to enter the next lesson, swipe right & release on page 1 for the previous lesson, or star cards for review.',
        '右上から5言語（中/EN/日/한/VI）を切り替え可能。学習画面の「EN」で英語訳を表示・非表示にできます。4字学習後に左スワイプで次の課へ、1ページ目で右スワイプして離すと前の課へ移動します。右上の星マークでお気に入り復習に登録できます。',
        '우측 상단에서 5개 언어(中/EN/日/한/VI)를 전환하고 학습 화면의 "EN" 버튼으로 영어 뜻풀이를 켜고 끌 수 있습니다. 4자를 모두 본 뒤 왼쪽 스와이프로 다음 과로, 첫 페이지에서 오른쪽 스와이프로 이전 과로 이동하며 별표로 즐겨찾기 복습이 가능합니다.',
        'Chuyển đổi 5 ngôn ngữ (中/EN/日/한/VI) ở góc trên, nhấn nút "EN" để bật/tắt nghĩa tiếng Anh. Xem đủ 4 chữ vuốt trái sang bài tiếp theo, ở trang đầu vuốt phải thả tay để về bài trước; nhấn Ngôi sao để lưu vào Ôn tập yêu thích.',
      ],
      highlights: [
        ['中 / EN / 日 / 한 / VI', 'EN 英文释义开关', '左滑下一课 · 右滑上一课'],
        ['5 Interface Languages', 'EN Meaning Toggle', 'Swipe Across Lessons'],
        ['5言語UI＆日本語筆順名', 'EN 英語訳ON/OFF', '左右スワイプで課を移動'],
        ['5개국어 UI & 한국어 필순명', 'EN 영어 뜻풀이 스위치', '좌우 스와이프 단원 이동'],
        ['5 Ngôn ngữ giao diện', 'Nút bật/tắt nghĩa EN', 'Vuốt chuyển bài mượt mà'],
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _lang = OnboardingLang.fromCode(widget.initialLangCode);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _tr(String zh, String en, String ja, String ko, String vi) {
    switch (_lang) {
      case OnboardingLang.zh:
        return zh;
      case OnboardingLang.en:
        return en;
      case OnboardingLang.ja:
        return ja;
      case OnboardingLang.ko:
        return ko;
      case OnboardingLang.vi:
        return vi;
    }
  }

  void _selectLanguage(OnboardingLang newLang) {
    if (_lang == newLang) return;
    setState(() => _lang = newLang);
    widget.onLanguageChanged?.call(newLang.code);
  }

  void _goNext() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentIndex == _steps.length - 1;

    return Dialog(
      backgroundColor: _kPaperBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFDCCBB1), width: 1.5),
      ),
      child: ConstrainedBox(
        // 兼容 360dp 手机竖屏与 720dp iPad / 投影仪横屏
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部栏：五语快捷切换胶囊 + 关闭按钮
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: OnboardingLang.values.map((lang) {
                          final bool selected = lang == _lang;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => _selectLanguage(lang),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _kInkDark
                                      : Colors.white.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: selected
                                        ? _kInkDark
                                        : const Color(0xFFD5C3A6),
                                  ),
                                ),
                                child: Text(
                                  lang.badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : _kInkDark,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: _tr('跳过', 'Skip', 'スキップ', '건너뛰기', 'Bỏ qua'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _kInkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 中部：4 步滑动卡片
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5D7C1)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 图标徽章
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: step.accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 34,
                                color: step.accentColor,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 步骤标题
                            Text(
                              step.titleFor(_lang),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _kInkDark,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 3 个核心亮点胶囊标签（Wrap 自适应窄屏防溢出）
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              children: step.highlightsFor(_lang).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: step.accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: step.accentColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // 详细说明正文
                            Text(
                              step.descFor(_lang),
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: _kInkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // 底部栏：页码指示器 + 上一步/下一步按钮
              Row(
                children: [
                  // 页码圆点
                  Row(
                    children: List.generate(_steps.length, (i) {
                      final bool active = i == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? _steps[_currentIndex].accentColor
                              : const Color(0xFFD0C0A8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),

                  // 上一步按钮
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _goPrev,
                      style: TextButton.styleFrom(
                        foregroundColor: _kInkMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        _tr('上一步', 'Back', '戻る', '이전', 'Trước'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 6),

                  // 下一步 / 开始学习按钮
                  FilledButton(
                    onPressed: _goNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: _steps[_currentIndex].accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      isLastPage
                          ? _tr(
                              '开始学习',
                              'Start Learning',
                              '学習を始める',
                              '학습 시작',
                              'Bắt đầu học',
                            )
                          : _tr('下一步', 'Next', '次へ', '다음', 'Tiếp'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// 【第四部分】在 lib/screens/grade_select_screen.dart 中的接入示例
// ----------------------------------------------------------------------------
/*
  // 1. 在 GradeSelectScreen 的 initState() 中自动触发首次引导：
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingDialog.showIfNeeded(
        context,
        currentLangCode: AppStrings.currentLang.code, // 或你的语言状态字段
        onLanguageChanged: (code) {
          AppStrings.setLanguageByCode(code);
          setState(() {});
        },
      );
    });
  }

  // 2. 在首页右上角 LanguageButton 旁边加一个「?」帮助图标按钮，随时重看说明：
  IconButton(
    icon: const Icon(Icons.help_outline_rounded),
    tooltip: AppStrings.onboardingBtnHelp,
    onPressed: () {
      OnboardingDialog.showModal(
        context,
        currentLangCode: AppStrings.currentLang.code,
        onLanguageChanged: (code) {
          AppStrings.setLanguageByCode(code);
          setState(() {});
        },
      );
    },
  ),
*/