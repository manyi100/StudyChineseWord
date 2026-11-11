import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;

/// 单个汉字的笔顺矢量数据（原始坐标系为 Make Me a Hanzi 的 1024×1024，
/// 解析时已统一转换到左上角为原点、宽高均为 1024 的屏幕正向坐标系：
///   x' = x,  y' = 900 - y
/// 渲染时只需按 canvasSize / 1024 等比缩放即可）。
class CharStrokeData {
  /// 每一笔的外轮廓闭合路径（1024×1024 坐标系）
  final List<Path> strokePaths;

  /// 每一笔的中心骨架折线点序列（从起笔到收笔，1024×1024 坐标系）
  final List<List<Offset>> medians;

  /// 每一笔中心骨架对应的 Path（用于顺向描红裁切动画）
  final List<Path> medianPaths;

  const CharStrokeData({
    required this.strokePaths,
    required this.medians,
    required this.medianPaths,
  });

  int get strokeCount => strokePaths.length;
}

/// 汉字笔顺矢量仓库：加载 assets/data/stroke_data.json，
/// 并按需解析单个汉字的 SVG 轮廓与骨架折线。
class StrokeRepository {
  StrokeRepository._internal();
  static final StrokeRepository instance = StrokeRepository._internal();

  Map<String, dynamic> _rawMap = const {};
  final Map<String, CharStrokeData> _cache = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/stroke_data.json');
      _rawMap = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      _rawMap = const {};
    }
    _loaded = true;
  }

  /// 获取某个汉字的笔顺矢量数据；若不存在则返回 null。
  CharStrokeData? getStrokeData(String char) {
    final cached = _cache[char];
    if (cached != null) return cached;

    final raw = _rawMap[char];
    if (raw is! Map<String, dynamic>) return null;

    final rawStrokes = raw['strokes'] as List<dynamic>?;
    final rawMedians = raw['medians'] as List<dynamic>?;
    if (rawStrokes == null || rawMedians == null || rawStrokes.isEmpty) {
      return null;
    }

    final strokePaths = <Path>[];
    for (final s in rawStrokes) {
      strokePaths.add(_parseSvgPath(s as String));
    }

    final medians = <List<Offset>>[];
    final medianPaths = <Path>[];
    for (final m in rawMedians) {
      final pts = <Offset>[];
      for (final pt in (m as List<dynamic>)) {
        final pair = pt as List<dynamic>;
        final x = (pair[0] as num).toDouble();
        final y = 900.0 - (pair[1] as num).toDouble();
        pts.add(Offset(x, y));
      }
      medians.add(pts);

      final mp = Path();
      if (pts.isNotEmpty) {
        mp.moveTo(pts.first.dx, pts.first.dy);
        for (int i = 1; i < pts.length; i++) {
          mp.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      medianPaths.add(mp);
    }

    final data = CharStrokeData(
      strokePaths: strokePaths,
      medians: medians,
      medianPaths: medianPaths,
    );
    _cache[char] = data;
    return data;
  }

  static final RegExp _tokenRegExp = RegExp(r'[MLQCZ]|-?\d+(?:\.\d+)?');

  /// 解析 Make Me a Hanzi 的 SVG Path（仅含 M / L / Q / C / Z 绝对坐标命令），
  /// 同时完成 (x, 900 - y) 的Y轴翻转变换。
  static Path _parseSvgPath(String svg) {
    final path = Path();
    final tokens = _tokenRegExp.allMatches(svg).map((m) => m.group(0)!).toList();
    int i = 0;
    while (i < tokens.length) {
      final cmd = tokens[i++];
      switch (cmd) {
        case 'M':
          final x = double.parse(tokens[i++]);
          final y = 900.0 - double.parse(tokens[i++]);
          path.moveTo(x, y);
          break;
        case 'L':
          final x = double.parse(tokens[i++]);
          final y = 900.0 - double.parse(tokens[i++]);
          path.lineTo(x, y);
          break;
        case 'Q':
          final x1 = double.parse(tokens[i++]);
          final y1 = 900.0 - double.parse(tokens[i++]);
          final x2 = double.parse(tokens[i++]);
          final y2 = 900.0 - double.parse(tokens[i++]);
          path.quadraticBezierTo(x1, y1, x2, y2);
          break;
        case 'C':
          final x1 = double.parse(tokens[i++]);
          final y1 = 900.0 - double.parse(tokens[i++]);
          final x2 = double.parse(tokens[i++]);
          final y2 = 900.0 - double.parse(tokens[i++]);
          final x3 = double.parse(tokens[i++]);
          final y3 = 900.0 - double.parse(tokens[i++]);
          path.cubicTo(x1, y1, x2, y2, x3, y3);
          break;
        case 'Z':
          path.close();
          break;
      }
    }
    return path;
  }
}
