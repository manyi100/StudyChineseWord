import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:entrance_720_words/main.dart';
import 'package:entrance_720_words/services/hanzi_repository.dart';

void main() {
  testWidgets('home shows stage/radical/stroke navigation and course list',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // 资源较大，先在真实异步环境里完成加载，避免 pumpAndSettle 卡在 loading
    await tester.runAsync(() async {
      await HanziRepository.instance.ensureLoaded();
    });

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 首页：三种分类入口 + 6 个阶段
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
    // 首次进入会显示“点哪里都能发音”的提示，且各朗读入口都有喇叭图标
    expect(find.text('点汉字、词语、句子或图片，都能听发音'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);

    // 返回后切换到按部首（学习页用的是自定义返回按钮）
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('按部首'));
    await tester.pumpAndSettle();
    expect(find.textContaining('个部首'), findsOneWidget);

    // 切换到按笔画
    await tester.tap(find.text('按笔画'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1~3'), findsOneWidget);
  });
}
