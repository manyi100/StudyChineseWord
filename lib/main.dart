import 'package:flutter/material.dart';
import 'screens/grade_select_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '入学必备720字',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
      ),
      // 默认启动直接进入"选择学习年级"主界面（不再自动跳回上次学习的年级）
      home: const GradeSelectScreen(),
    );
  }
}
