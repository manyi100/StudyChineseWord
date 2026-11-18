import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:entrance_720_words/l10n/app_strings.dart';
import 'package:entrance_720_words/main.dart';
import 'package:entrance_720_words/services/hanzi_repository.dart';
import 'package:entrance_720_words/services/meaning_service.dart';
import 'package:entrance_720_words/services/tts_service.dart';
import 'package:entrance_720_words/widgets/character_card.dart';

void main() {
  // 资源（字库 / 释义）在真实异步环境里预加载一次。
  // 若等到某个用例的 fake async 区里才触发，真实文件 I/O 的完成回调
  // 会排进那个已经结束的 zone，后续用例 await 同一个 Future 会永久挂起。
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await HanziRepository.instance.ensureLoaded();
    await MeaningService.instance.ensureLoaded();
  });

  // 测试环境没有原生音频插件，朗读直接走系统 TTS 分支
  TtsService.disableBundledAudio = true;

  testWidgets('home shows stage/radical/stroke navigation and course list',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;

    // 按手机常见宽度验证布局，避免词语 chip 等组件在窄屏溢出
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 资源较大，先在真实异步环境里完成加载，避免 pumpAndSettle 卡在 loading
    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 首页：三种分类入口 + 6 个阶段 + 收藏复习入口
    expect(find.text('选择学习阶段'), findsOneWidget);
    expect(find.text('按主题'), findsOneWidget);
    expect(find.text('按部首'), findsOneWidget);
    expect(find.text('按笔画'), findsOneWidget);
    expect(find.text('第 1 阶段'), findsOneWidget);

    // 进入第 1 阶段课程列表
    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 阶段 · 课程'), findsOneWidget);
    expect(find.text('第 1 课'), findsOneWidget);

    // 进入第 1 课学习页
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);
    // 旧的 1/4 序号已移除，改为顶部四字导航条
    expect(find.text('1 / 4'), findsNothing);
    // 首次进入会显示“点哪里都能发音”的提示，且各朗读入口都有喇叭图标
    expect(find.text('点汉字、词语、句子或图片，都能听发音'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);

    // 返回后切换到按部首（学习页用的是自定义返回按钮）
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 收藏复习入口已从学习页移到首页底部
    await tester.scrollUntilVisible(find.text('收藏复习'), 300);
    expect(find.text('收藏复习'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('按部首'), -300);

    await tester.tap(find.text('按部首'));
    await tester.pumpAndSettle();
    expect(find.textContaining('个部首'), findsOneWidget);

    // 切换到按笔画
    await tester.tap(find.text('按笔画'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1~3'), findsOneWidget);
  });

  testWidgets('swiping past the last character opens the next course',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);

    // 依次看完 4 个字（从配图区域滑动，避开田字格的手势）
    for (var i = 0; i < 3; i++) {
      await tester.dragFrom(const Offset(180, 220), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);

    // 在最后一页继续左滑，应进入下一课
    await tester.flingFrom(const Offset(180, 220), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);

    // 在第一页继续右滑，应直接回到上一课（停在最后一个字）
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);
    String currentChar() => tester
        .widget<CharacterCard>(find.byType(CharacterCard).first)
        .hanzi
        .char;
    expect(currentChar(), '五');

    await tester.flingFrom(const Offset(180, 220), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);
    expect(currentChar(), '四');

    // 第 1 课已经是最前一课：退到它的第一页再右滑，不应有任何跳转
    for (var i = 0; i < 3; i++) {
      await tester.dragFrom(const Offset(180, 220), const Offset(300, 0));
      await tester.pumpAndSettle();
    }
    expect(currentChar(), '一');
    await tester.flingFrom(const Offset(180, 220), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);
    expect(currentChar(), '一');

    // 让首次提示条 / 朗读兜底定时器走完，避免测试结束时报 pending timer
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets('next lesson always opens on its first character',
      (WidgetTester tester) async {
    // 第 1 课上次停在最后一个字「四」，且四个字都已学完
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding_v131': true,
      'last_index_grade_course_g1_line1': 3,
      'viewed_char_ids': '["0001","0002","0003","0004"]',
    });
    AppLocale.notifier.value = AppLang.zh;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();

    // 从课程列表进入：沿用该课上次的位置「四」
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);
    String currentChar() => tester
        .widget<CharacterCard>(find.byType(CharacterCard).first)
        .hanzi
        .char;
    expect(currentChar(), '四');

    // 在最后一页继续左滑：下一课必须从「五」开始，而不是它上次停下的「八」
    await tester.flingFrom(const Offset(180, 220), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);
    expect(currentChar(), '五');

    // 再左滑一次应只是翻到「六」，不会又跳到第 3 课
    await tester.flingFrom(const Offset(180, 220), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);
    expect(currentChar(), '六');

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('language menu switches zh / en / ja / ko / vi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;

    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    Future<void> choose(String nativeName) async {
      await tester.tap(find.byType(PopupMenuButton<AppLang>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(nativeName));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('选择学习阶段'), findsOneWidget);

    // 英文
    await choose('English');
    expect(find.text('Choose a Stage'), findsOneWidget);
    expect(find.text('By theme'), findsOneWidget);
    expect(find.text('Stage 1'), findsOneWidget);

    // 进入阶段/课程，确认深层页面也是英文
    await tester.tap(find.text('Stage 1'));
    await tester.pumpAndSettle();
    expect(find.text('Stage 1 · Lessons'), findsOneWidget);
    expect(find.text('Lesson 1'), findsOneWidget);

    // 学习卡片：英文文案 + 360dp 下不溢出
    await tester.tap(find.text('Lesson 1'));
    await tester.pumpAndSettle();
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Sentence'), findsOneWidget);
    expect(find.text('Stroke demo'), findsOneWidget);
    expect(find.text('Trace'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 日文
    await choose('日本語');
    expect(find.text('ステージを選ぶ'), findsOneWidget);
    expect(find.text('テーマ別'), findsOneWidget);
    expect(find.text('ステージ 1'), findsOneWidget);

    // 韩文
    await choose('한국어');
    expect(find.text('학습 단계 선택'), findsOneWidget);
    expect(find.text('주제별'), findsOneWidget);
    expect(find.text('1단계'), findsOneWidget);

    // 越南文
    await choose('Tiếng Việt');
    expect(find.text('Chọn giai đoạn'), findsOneWidget);
    expect(find.text('Theo chủ đề'), findsOneWidget);
    expect(find.text('Giai đoạn 1'), findsOneWidget);

    // 切回中文
    await choose('中文');
    expect(find.text('选择学习阶段'), findsOneWidget);
    expect(find.text('按主题'), findsOneWidget);

    // 消化提示条与朗读兜底定时器
    await tester.pump(const Duration(seconds: 16));

    // 避免影响其它用例
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('iPad sized screen keeps content within max width',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;

    // iPad Pro 12.9" 竖屏逻辑尺寸
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 列表内容被收窄并居中，不会横向铺满 1024
    expect(find.text('选择学习阶段'), findsOneWidget);
    final listWidth = tester.getSize(find.byType(ListView).first).width;
    expect(listWidth, lessThanOrEqualTo(720));
    expect(listWidth, greaterThan(600));

    // 学习卡片同样被限制在 720 以内
    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();
    final cardWidth = tester.getSize(find.byType(CharacterCard).first).width;
    expect(cardWidth, lessThanOrEqualTo(720));

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('english meaning shows on demand and never blocks tapping',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;

    // 360dp 是最窄的常见手机宽度：释义行最多（单字 + 三词 + 句译）时也不能溢出
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
      await MeaningService.instance.ensureLoaded();
    });

    await MeaningService.instance.setVisible(false);
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();

    // 默认关闭：不显示释义
    expect(find.text('one'), findsNothing);

    // 打开：单字 / 组词 / 例句释义同时出现
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(MeaningService.instance.visible.value, isTrue);
    expect(find.text('one'), findsWidgets);

    // 关闭：释义整体收起
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(MeaningService.instance.visible.value, isFalse);
    expect(find.text('one'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('course list refreshes after leaving a lesson reached by swiping',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();

    // 看完本课 4 个字后左滑进第 2 课（内部是 pushReplacement）
    for (var i = 0; i < 3; i++) {
      await tester.dragFrom(const Offset(180, 220), const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    await tester.flingFrom(const Offset(180, 220), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);

    // 返回列表：第 2 课应立刻显示 1 / 4 字，而不是等下次再进才更新
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('第 1 阶段 · 课程'), findsOneWidget);
    expect(find.text('1 / 4 字'), findsOneWidget);

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('TV remote arrow keys walk through characters and lessons',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();

    String currentChar() => tester
        .widget<CharacterCard>(find.byType(CharacterCard).first)
        .hanzi
        .char;
    expect(currentChar(), '一');

    // 方向键右键 = 下一个字；到最后一页再按一次 = 进下一课
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(currentChar(), '四');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);
    expect(currentChar(), '五');

    // 方向键左键 = 上一个字；在第一页再按一次 = 回上一课最后一个字
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('第 1 课 · 一二三四'), findsOneWidget);
    expect(currentChar(), '四');

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('mouse drag flips pages for projectors with air mouse',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('第 1 阶段'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 1 课'));
    await tester.pumpAndSettle();

    String currentChar() => tester
        .widget<CharacterCard>(find.byType(CharacterCard).first)
        .hanzi
        .char;
    expect(currentChar(), '一');

    // 投影仪飞鼠走的是 mouse 指针，滚动行为里必须允许它拖拽
    expect(
      ScrollConfiguration.of(tester.element(find.byType(PageView)))
          .dragDevices
          .contains(PointerDeviceKind.mouse),
      isTrue,
    );

    // 默认的 ScrollBehavior 不接收鼠标拖拽，这里必须能翻页
    // （从配图区起手，避开田字格自己的手势）
    await tester.dragFrom(
      const Offset(300, 220),
      const Offset(-260, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(currentChar(), '二');

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('first launch shows the image guide and swipes through it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    AppLocale.notifier.value = AppLang.zh;

    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // 首次启动自动弹出第 1 张图，此时按钮还是「下一步」
    expect(find.byKey(const ValueKey('onboarding_image_0')), findsOneWidget);
    expect(find.text('开始学习'), findsNothing);

    // 左滑进入下一步（直接拖 PageView，和手指在图上滑一样）
    await tester.drag(find.byType(PageView), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_image_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_image_0')), findsNothing);

    // 点「下一步」也能翻页，最后一页按钮变「开始学习」
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('onboarding_image_3')), findsOneWidget);
    expect(find.text('开始学习'), findsOneWidget);

    await tester.tap(find.text('开始学习'));
    await tester.pumpAndSettle();
    expect(find.text('选择学习阶段'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_image_0')), findsNothing);

    // 看过一次后不再自动弹出，但「?」仍可重看，且可随时跳过
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_image_0')), findsOneWidget);

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(find.text('选择学习阶段'), findsOneWidget);

    await tester.pump(const Duration(seconds: 16));
    AppLocale.notifier.value = AppLang.zh;
  });

  testWidgets('first launch follows the phone system language',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v131': true});
    AppLocale.notifier.value = AppLang.zh;

    // 系统语言是日语 → 首次启动直接进日文界面
    tester.binding.platformDispatcher.localesTestValue = const [
      Locale('ja', 'JP'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    await AppLocale.load();
    expect(AppLocale.lang, AppLang.ja);

    // 没支持的系统语言回落中文；支持的语言排在后面也能命中
    expect(AppLocale.matchSystemLang(const [Locale('fr', 'FR')]), AppLang.zh);
    expect(
      AppLocale.matchSystemLang(const [Locale('fr'), Locale('ko')]),
      AppLang.ko,
    );
    expect(AppLocale.matchSystemLang(const [Locale('zh', 'TW')]), AppLang.zh);

    // 用户自己选过语言后，就以保存的为准，不再跟系统
    SharedPreferences.setMockInitialValues({
      'app_language': 'vi',
      'has_seen_onboarding_v131': true,
    });
    await AppLocale.load();
    expect(AppLocale.lang, AppLang.vi);

    AppLocale.notifier.value = AppLang.zh;
  });
}
