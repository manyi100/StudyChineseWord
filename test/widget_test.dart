import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:entrance_720_words/l10n/app_strings.dart';
import 'package:entrance_720_words/main.dart';
import 'package:entrance_720_words/services/hanzi_repository.dart';
import 'package:entrance_720_words/widgets/character_card.dart';

void main() {
  testWidgets('home shows stage/radical/stroke navigation and course list',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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
    SharedPreferences.setMockInitialValues({});
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
    await tester.flingFrom(
        const Offset(180, 220), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('第 2 课 · 五六七八'), findsOneWidget);

    // 让首次提示条 / 朗读兜底定时器走完，避免测试结束时报 pending timer
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets('language menu switches zh / en / ja / ko / vi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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
    SharedPreferences.setMockInitialValues({});
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
}
