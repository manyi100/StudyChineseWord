import 'package:flutter/material.dart';

/// 汉字"田字格"组件：方形外框 + 十字内部辅助线(横竖各一条虚线，
/// 形成"田"字的格子效果)，汉字居中显示，使用打包的楷体字体。
class TianZiGeBox extends StatelessWidget {
  final String char;
  final double size;
  final Color borderColor;
  final Color guideLineColor;
  final Color textColor;

  const TianZiGeBox({
    super.key,
    required this.char,
    this.size = 130,
    this.borderColor = const Color(0xFF90A4AE),
    this.guideLineColor = const Color(0xFFCFD8DC),
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TianZiGePainter(
        borderColor: borderColor,
        guideLineColor: guideLineColor,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            char,
            style: TextStyle(
              fontFamily: 'KaiTiCustom',
              fontSize: size * 0.62,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _TianZiGePainter extends CustomPainter {
  final Color borderColor;
  final Color guideLineColor;

  _TianZiGePainter({required this.borderColor, required this.guideLineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 外框
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      borderPaint,
    );

    // 内部十字虚线辅助格（横线+竖线，组成"田"字效果）
    final dashPaint = Paint()
      ..color = guideLineColor
      ..strokeWidth = 1.2;

    _drawDashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      dashPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      dashPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    double drawn = 0;
    while (drawn < totalLength) {
      final segmentEnd = (drawn + dashWidth) > totalLength ? totalLength : drawn + dashWidth;
      canvas.drawLine(
        start + direction * drawn,
        start + direction * segmentEnd,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TianZiGePainter oldDelegate) => false;
}
