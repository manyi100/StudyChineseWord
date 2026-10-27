import 'package:flutter/material.dart';

/// 拼音"四线三格"组件：传统拼音教学用的四条横线、三个格子的书写格式。
/// - 第1线(顶)到第2线之间：放声调符号和有上半部分的字母(b,h,k,l,t等)
/// - 第2线到第3线之间：拼音字母主体所在的格子(大部分小写字母的高度)
/// - 第3线到第4线(底)之间：放有下半部分的字母(g,j,p,q,y等)
/// 第3线(从上数第3条)是拼音字母的基准书写线，绘制得比其他线略粗一些。
///
/// ⚠️ 实现说明：这是简化版实现——按"整体居中、基准线对齐第3线"处理，
/// 不是逐字母精确计算每个字母升部/降部的字体度量。对拼音学习场景已经
/// 足够直观，但如果后续想要做到逐字母像素级精确对齐，需要使用
/// TextPainter结合具体字体的字形度量数据，工作量会大很多。
class PinyinGridText extends StatelessWidget {
  final String pinyin;
  final double width;
  final double height;
  final Color lineColor;
  final Color textColor;
  final double? fontSize;

  const PinyinGridText({
    super.key,
    required this.pinyin,
    this.width = 160,
    this.height = 54,
    this.lineColor = const Color(0xFFB0BEC5),
    this.textColor = Colors.black87,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PinyinGridPainter(
        pinyin: pinyin,
        lineColor: lineColor,
        textColor: textColor,
        fontSize: fontSize ?? height * 0.62,
      ),
    );
  }
}

class _PinyinGridPainter extends CustomPainter {
  final String pinyin;
  final Color lineColor;
  final Color textColor;
  final double fontSize;

  _PinyinGridPainter({
    required this.pinyin,
    required this.lineColor,
    required this.textColor,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = size.height / 3;
    final linePaintThin = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final linePaintBold = Paint()
      ..color = lineColor.withOpacity(0.9)
      ..strokeWidth = 1.6;

    // 4条横线：从上到下分别是第1~4线，第3线(基准书写线)画粗一点
    for (int i = 0; i <= 3; i++) {
      final y = rowHeight * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i == 2 ? linePaintBold : linePaintThin,
      );
    }

    // 拼音文字：基准线对齐第3线（从上数第3条横线）
    final textPainter = TextPainter(
      text: TextSpan(
        text: pinyin,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final lineMetrics = textPainter.computeLineMetrics();
    final ascent = lineMetrics.isNotEmpty ? lineMetrics.first.ascent : textPainter.height * 0.8;

    final baselineY = rowHeight * 2; // 第3条线的位置
    final textTopY = baselineY - ascent;
    final textLeftX = (size.width - textPainter.width) / 2;

    textPainter.paint(canvas, Offset(textLeftX, textTopY));
  }

  @override
  bool shouldRepaint(covariant _PinyinGridPainter oldDelegate) {
    return oldDelegate.pinyin != pinyin ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.fontSize != fontSize;
  }
}
