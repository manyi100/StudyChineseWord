import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'screens/grade_select_screen.dart';
import 'services/tts_service.dart';

/// 全局 ScaffoldMessenger，用于在没有 BuildContext 的地方（比如 TTS 服务里）
/// 弹出提示，例如小米机型找不到中文语音引擎时引导用户去系统设置。
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocale.load();
  TtsService.onUnavailable = (message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
  };
  runApp(const MyApp());
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
