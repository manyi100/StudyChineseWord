import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'app_route_observer.dart';
import 'l10n/app_strings.dart';
import 'screens/grade_select_screen.dart';
import 'services/meaning_service.dart';
import 'services/tts_service.dart';

/// 全局 ScaffoldMessenger，用于在没有 BuildContext 的地方（比如 TTS 服务里）
/// 弹出提示，例如小米机型找不到中文语音引擎时引导用户去系统设置。
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.load();
  // 释义开关默认跟随界面语言：中文界面关，其它语言开（用户可随时在右上角切换）
  await MeaningService.instance.loadPreference();
  TtsService.onUnavailable = (message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
  };
  runApp(const MyApp());
}

/// 允许「鼠标 / 飞鼠 / 触控板」按住拖动来滚动与翻页。
///
/// Flutter 默认的 `dragDevices` 只有触摸和触控笔，电视盒子、投影仪用飞鼠时
/// 按住拖动不会产生滚动，表现为“在投影仪上划不动”。
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 语言状态放在 MaterialApp 之上：切换语言时整个界面（含弹窗、SnackBar）
    // 都会按新语言重建，导航栈保持不变。
    return AppLocaleScope(
      notifier: AppLocale.notifier,
      child: Builder(
        builder: (context) => MaterialApp(
          title: context.s.appTitle,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorObservers: [appRouteObserver],
          scrollBehavior: const AppScrollBehavior(),
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF4CAF50),
            scaffoldBackgroundColor: const Color(0xFFF7F7F5),
          ),
          // 默认启动直接进入学习入口（阶段/主题、部首、笔画三种分类）
          home: const GradeSelectScreen(),
        ),
      ),
    );
  }
}
