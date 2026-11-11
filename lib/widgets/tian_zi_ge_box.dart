import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/stroke_repository.dart';
import 'audio_feedback.dart';

enum _StrokeMode {
  demo, // 自动笔顺演示
  trace, // 手指跟写描红
}

/// 汉字"田字格"组件（支持自动笔顺动画演示 + 手指一笔一画跟写描红）。
///
/// - 打开卡片或切换汉字时，默认自动播放一遍按笔顺方向的描红演示；
/// - 用户随时可以直接用手指在田字格内拖动，立即进入「手写描红」模式；
/// - 下方提供「笔顺演示」和「手写描红 / 重写」快捷按钮，兼顾演示与练字。
class TianZiGeBox extends StatefulWidget {
  final String char;
  final double size;
  final Color borderColor;
  final Color guideLineColor;
  final Color textColor;
  final List<String> strokeOrderNames;
  final VoidCallback? onSpeak;
  final bool showControls;

  /// 朗读动效使用的唯一标识（一般由卡片传入 `char_<汉字ID>`）
  final String? audioTag;

  const TianZiGeBox({
    super.key,
    required this.char,
    this.size = 152,
    this.borderColor = const Color(0xFF90A4AE),
    this.guideLineColor = const Color(0xFFCFD8DC),
    this.textColor = const Color(0xFF263238),
    this.strokeOrderNames = const [],
    this.onSpeak,
    this.showControls = true,
    this.audioTag,
  });

  @override
  State<TianZiGeBox> createState() => _TianZiGeBoxState();
}

class _TianZiGeBoxState extends State<TianZiGeBox>
    with TickerProviderStateMixin {
  CharStrokeData? _strokeData;
  _StrokeMode _mode = _StrokeMode.demo;

  // 自动演示状态：当前正在演示第几画、该画进度 0..1
  late final AnimationController _demoController;
  int _demoStrokeIndex = 0;
  bool _demoFinished = false;
  int _demoSessionId = 0;

  // 手写描红状态：当前待写第几画、提示动画控制器、用户手指轨迹（1024坐标系）
  late final AnimationController _hintController;
  int _traceStrokeIndex = 0;
  final List<Offset> _userPoints = [];
  String? _feedbackText;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    _loadCharAndStartDemo();
  }

  @override
  void didUpdateWidget(covariant TianZiGeBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.char != widget.char) {
      _loadCharAndStartDemo();
    }
  }

  @override
  void dispose() {
    _demoSessionId++;
    _demoController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _loadCharAndStartDemo() {
    _strokeData = StrokeRepository.instance.getStrokeData(widget.char);
    _userPoints.clear();
    _feedbackText = null;
    _feedbackIsError = false;
    _traceStrokeIndex = 0;
    _startDemo();
  }

  Future<void> _startDemo() async {
    final data = _strokeData;
    final session = ++_demoSessionId;
    _hintController.stop();
    _demoController.stop();
    _userPoints.clear();

    if (data == null || data.strokeCount == 0) {
      setState(() {
        _mode = _StrokeMode.demo;
        _demoFinished = true;
      });
      return;
    }

    setState(() {
      _mode = _StrokeMode.demo;
      _demoStrokeIndex = 0;
      _demoFinished = false;
      _feedbackText = null;
    });

    // 稍微停顿让页面切换动画稳定后再开始第一笔
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || session != _demoSessionId) return;

    for (int i = 0; i < data.strokeCount; i++) {
      if (!mounted || session != _demoSessionId || _mode != _StrokeMode.demo) {
        return;
      }
      setState(() => _demoStrokeIndex = i);

      // 根据该笔画骨架长度动态调整时长（短笔画快、长折笔慢）
      final medianLen = _polylineLength(data.medians[i]);
      final ms = (260 + (medianLen * 0.32)).clamp(260.0, 620.0).round();
      _demoController.duration = Duration(milliseconds: ms);

      try {
        await _demoController.forward(from: 0.0);
      } catch (_) {
        return;
      }
      if (!mounted || session != _demoSessionId || _mode != _StrokeMode.demo) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 110));
    }

    if (!mounted || session != _demoSessionId || _mode != _StrokeMode.demo) {
      return;
    }
    setState(() {
      _demoFinished = true;
    });
  }

  void _startTraceMode() {
    _demoSessionId++;
    _demoController.stop();
    _hintController.stop();
    setState(() {
      _mode = _StrokeMode.trace;
      _traceStrokeIndex = 0;
      _userPoints.clear();
      _feedbackText = null;
      _feedbackIsError = false;
    });
  }

  /// 将组件本地坐标转换为 1024×1024 笔顺坐标系
  Offset _to1024(Offset localPos) {
    final scale = 1024.0 / widget.size;
    return Offset(
      (localPos.dx * scale).clamp(0.0, 1024.0),
      (localPos.dy * scale).clamp(0.0, 1024.0),
    );
  }

  void _onPanDown(DragDownDetails details) {
    if (_strokeData == null) return;
    _userPoints
      ..clear()
      ..add(_to1024(details.localPosition));
  }

  void _onPanStart(DragStartDetails details) {
    if (_strokeData == null) return;
    final pt = _to1024(details.localPosition);
    if (_userPoints.isEmpty) {
      _userPoints.add(pt);
    } else {
      _userPoints.add(pt);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final data = _strokeData;
    if (data == null) return;

    final pt = _to1024(details.localPosition);
    if (_userPoints.isEmpty) {
      _userPoints.add(pt);
    } else if ((pt - _userPoints.last).distance >= 6.0) {
      _userPoints.add(pt);
    }

    // 如果当前还在自动演示模式，但用户明显开始动笔拖动，立即切到描红模式！
    if (_mode == _StrokeMode.demo && _polylineLength(_userPoints) > 55.0) {
      _demoSessionId++;
      _demoController.stop();
      _mode = _StrokeMode.trace;
      _traceStrokeIndex = 0;
      _feedbackText = null;
      _feedbackIsError = false;
    } else if (_mode == _StrokeMode.trace &&
        _traceStrokeIndex >= data.strokeCount &&
        _polylineLength(_userPoints) > 55.0) {
      // 已经写完一遍后再次动笔，自动开启新一轮描红
      _traceStrokeIndex = 0;
      _feedbackText = null;
      _feedbackIsError = false;
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    final data = _strokeData;
    if (data == null) {
      widget.onSpeak?.call();
      return;
    }

    final dragLen = _polylineLength(_userPoints);

    // 轻点（没有实质拖动）：
    if (dragLen < 55.0) {
      _userPoints.clear();
      if (_mode == _StrokeMode.demo) {
        widget.onSpeak?.call();
        _startDemo();
      } else {
        // 描红模式下轻点田字格：演示当前待写这一笔作为提示，并朗读
        widget.onSpeak?.call();
        if (_traceStrokeIndex < data.strokeCount) {
          _hintController.forward(from: 0.0);
        }
      }
      setState(() {});
      return;
    }

    if (_mode != _StrokeMode.trace || _traceStrokeIndex >= data.strokeCount) {
      _userPoints.clear();
      setState(() {});
      return;
    }

    final targetMedian = data.medians[_traceStrokeIndex];
    final ok = _validateStroke(_userPoints, targetMedian);
    _userPoints.clear();

    if (ok) {
      _hintController.stop();
      _traceStrokeIndex++;
      _feedbackIsError = false;
      if (_traceStrokeIndex >= data.strokeCount) {
        _feedbackText = '🎉 太棒啦！全部 ${data.strokeCount} 画都写对啦';
        widget.onSpeak?.call();
      } else {
        _feedbackText = null;
      }
    } else {
      final strokeName = _strokeNameAt(_traceStrokeIndex);
      _feedbackIsError = true;
      _feedbackText = '顺着红点方向写第 ${_traceStrokeIndex + 1} 画'
          '${strokeName != null ? "（$strokeName）" : ""}';
      _hintController.forward(from: 0.0);
    }

    setState(() {});
  }

  String? _strokeNameAt(int index) {
    if (index >= 0 && index < widget.strokeOrderNames.length) {
      return widget.strokeOrderNames[index];
    }
    return null;
  }

  /// 校验用户手写轨迹是否匹配目标笔画骨架（针对儿童手指触控做了适度宽松容差）
  bool _validateStroke(List<Offset> userPts, List<Offset> medianPts) {
    if (userPts.length < 2 || medianPts.length < 2) return false;

    final userLen = _polylineLength(userPts);
    final medianLen = _polylineLength(medianPts);
    if (userLen < math.min(60.0, medianLen * 0.25)) {
      return false;
    }

    final uStart = userPts.first;
    final uEnd = userPts.last;
    final mStart = medianPts.first;
    final mEnd = medianPts.last;

    // 1. 起笔位置校验（距离起笔点或前 25% 骨架不超过 260）
    final startDist = math.min(
      (uStart - mStart).distance,
      _distanceToPolyline(uStart, medianPts.sublist(0, (medianPts.length / 2).ceil())),
    );
    if (startDist > 265.0) return false;

    // 2. 收笔位置校验（距离收笔点不超过 285）
    final endDist = (uEnd - mEnd).distance;
    if (endDist > 285.0) return false;

    // 3. 起笔必须比收笔更接近笔画起点（防止倒插笔反写）
    final startProj = _projectNormalizedPosition(uStart, medianPts);
    final endProj = _projectNormalizedPosition(uEnd, medianPts);
    if (endProj <= startProj + 0.15) return false;

    // 4. 整体轨迹贴合度校验：采样用户轨迹点到骨架的平均距离
    double sumDist = 0.0;
    for (final p in userPts) {
      sumDist += _distanceToPolyline(p, medianPts);
    }
    final avgDist = sumDist / userPts.length;
    if (avgDist > 185.0) return false;

    // 5. 长度不能比目标笔画短太多或长太多
    if (userLen < medianLen * 0.35 || userLen > medianLen * 2.4 + 220.0) {
      return false;
    }

    return true;
  }

  static double _polylineLength(List<Offset> pts) {
    double len = 0.0;
    for (int i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    return len;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0.0) return (p - a).distance;
    final ap = p - a;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / lenSq).clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  static double _distanceToPolyline(Offset p, List<Offset> poly) {
    double best = double.infinity;
    for (int i = 1; i < poly.length; i++) {
      final d = _distanceToSegment(p, poly[i - 1], poly[i]);
      if (d < best) best = d;
    }
    return best;
  }

  /// 计算点 p 在折线 poly 上的最近投影所处的归一化进度（0.0 ~ 1.0）
  static double _projectNormalizedPosition(Offset p, List<Offset> poly) {
    final total = _polylineLength(poly);
    if (total <= 0.0) return 0.0;
    double bestDist = double.infinity;
    double bestAlong = 0.0;
    double accum = 0.0;
    for (int i = 1; i < poly.length; i++) {
      final a = poly[i - 1];
      final b = poly[i];
      final seg = b - a;
      final segLen = seg.distance;
      if (segLen > 0) {
        final ap = p - a;
        final t = ((ap.dx * seg.dx + ap.dy * seg.dy) / (segLen * segLen))
            .clamp(0.0, 1.0);
        final proj = Offset(a.dx + seg.dx * t, a.dy + seg.dy * t);
        final d = (p - proj).distance;
        if (d < bestDist) {
          bestDist = d;
          bestAlong = accum + segLen * t;
        }
      }
      accum += segLen;
    }
    return (bestAlong / total).clamp(0.0, 1.0);
  }

  String _buildStatusText(CharStrokeData data) {
    if (_feedbackText != null) return _feedbackText!;

    if (_mode == _StrokeMode.demo) {
      if (_demoFinished) {
        return '共 ${data.strokeCount} 画 · 直接在格子里写即可描红';
      }
      final idx = _demoStrokeIndex.clamp(0, data.strokeCount - 1);
      final name = _strokeNameAt(idx);
      return '笔顺演示：第 ${idx + 1} / ${data.strokeCount} 画'
          '${name != null ? "（$name）" : ""}';
    } else {
      if (_traceStrokeIndex >= data.strokeCount) {
        return '🎉 全部 ${data.strokeCount} 画描写完成！';
      }
      final name = _strokeNameAt(_traceStrokeIndex);
      return '请顺着红点写：第 ${_traceStrokeIndex + 1} / ${data.strokeCount} 画'
          '${name != null ? "（$name）" : ""}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _strokeData;

    final gridBox = RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        _EagerPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
          () => _EagerPanGestureRecognizer(),
          (_EagerPanGestureRecognizer instance) {
            instance
              ..onDown = _onPanDown
              ..onStart = _onPanStart
              ..onUpdate = _onPanUpdate
              ..onEnd = _onPanEnd;
          },
        ),
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _TianZiGeStrokePainter(
            borderColor: widget.borderColor,
            guideLineColor: widget.guideLineColor,
            textColor: widget.textColor,
            strokeData: data,
            mode: _mode,
            demoStrokeIndex: _demoStrokeIndex,
            demoProgress: _demoController.value,
            demoFinished: _demoFinished,
            traceStrokeIndex: _traceStrokeIndex,
            hintProgress: _hintController.isAnimating ? _hintController.value : 0.0,
            userPoints: List<Offset>.unmodifiable(_userPoints),
          ),
          child: data == null
              ? Center(
                  child: Text(
                    widget.char,
                    style: TextStyle(
                      fontFamily: 'KaiTiCustom',
                      fontSize: widget.size * 0.62,
                      color: widget.textColor,
                      height: 1.0,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );

    if (!widget.showControls || data == null) {
      return gridBox;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        gridBox,
        const SizedBox(height: 8),
        Text(
          _buildStatusText(data),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _feedbackIsError
                ? const Color(0xFFD32F2F)
                : const Color(0xFF455A64),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.white.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onSpeak,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SpeakerIcon(
                    tag: widget.audioTag ?? 'char_${widget.char}',
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ModeButton(
              icon: Icons.play_circle_outline_rounded,
              label: '笔顺演示',
              selected: _mode == _StrokeMode.demo,
              activeColor: const Color(0xFF1976D2),
              onTap: () {
                widget.onSpeak?.call();
                _startDemo();
              },
            ),
            const SizedBox(width: 10),
            _ModeButton(
              icon: Icons.edit_rounded,
              label: _mode == _StrokeMode.trace &&
                      _traceStrokeIndex >= data.strokeCount
                  ? '再写一遍'
                  : '手写描红',
              selected: _mode == _StrokeMode.trace,
              activeColor: const Color(0xFFE53935),
              onTap: _startTraceMode,
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeColor : Colors.white.withOpacity(0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? activeColor : Colors.black12,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 立即赢取手势竞技场（GestureArena）的拖拽识别器，
/// 保证在田字格内写「横/竖」时不会误触发外层 PageView 翻页或 ScrollView 滚动。
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _TianZiGeStrokePainter extends CustomPainter {
  final Color borderColor;
  final Color guideLineColor;
  final Color textColor;
  final CharStrokeData? strokeData;
  final _StrokeMode mode;
  final int demoStrokeIndex;
  final double demoProgress;
  final bool demoFinished;
  final int traceStrokeIndex;
  final double hintProgress;
  final List<Offset> userPoints;

  _TianZiGeStrokePainter({
    required this.borderColor,
    required this.guideLineColor,
    required this.textColor,
    required this.strokeData,
    required this.mode,
    required this.demoStrokeIndex,
    required this.demoProgress,
    required this.demoFinished,
    required this.traceStrokeIndex,
    required this.hintProgress,
    required this.userPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    final data = strokeData;
    if (data == null || data.strokeCount == 0) return;

    final scale = size.width / 1024.0;
    canvas.save();
    canvas.scale(scale, scale);

    final baseWatermarkPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    final completedPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.fill;

    final targetWatermarkPaint = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..style = PaintingStyle.fill;

    // 1. 绘制所有笔画的底字轮廓
    for (int i = 0; i < data.strokeCount; i++) {
      final isCurrentTraceTarget =
          mode == _StrokeMode.trace && i == traceStrokeIndex;
      canvas.drawPath(
        data.strokePaths[i],
        isCurrentTraceTarget ? targetWatermarkPaint : baseWatermarkPaint,
      );
    }

    if (mode == _StrokeMode.demo) {
      // 2A. 自动笔顺演示模式
      if (demoFinished) {
        for (int i = 0; i < data.strokeCount; i++) {
          canvas.drawPath(data.strokePaths[i], completedPaint);
        }
      } else {
        // 已完成的笔画
        for (int i = 0; i < demoStrokeIndex && i < data.strokeCount; i++) {
          canvas.drawPath(data.strokePaths[i], completedPaint);
        }
        // 当前正在顺向扫出的笔画（朱砂红描红效果）
        if (demoStrokeIndex < data.strokeCount) {
          _drawProgressiveStroke(
            canvas,
            data.strokePaths[demoStrokeIndex],
            data.medianPaths[demoStrokeIndex],
            demoProgress,
            const Color(0xFFE53935),
          );
        }
      }
    } else {
      // 2B. 手写描红模式
      for (int i = 0; i < traceStrokeIndex && i < data.strokeCount; i++) {
        canvas.drawPath(data.strokePaths[i], completedPaint);
      }

      if (traceStrokeIndex < data.strokeCount) {
        // 如果正在播放错误/轻点提示动画，顺向扫出当前笔画
        if (hintProgress > 0.0 && hintProgress < 1.0) {
          _drawProgressiveStroke(
            canvas,
            data.strokePaths[traceStrokeIndex],
            data.medianPaths[traceStrokeIndex],
            hintProgress,
            const Color(0xFFE53935),
          );
        }

        // 绘制当前待写笔画的起笔红点与走向引导线
        _drawStrokeGuide(canvas, data.medians[traceStrokeIndex]);
      }
    }

    // 3. 绘制用户实时手指笔迹
    if (userPoints.isNotEmpty) {
      final userPaint = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 64.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (userPoints.length == 1) {
        canvas.drawCircle(
          userPoints.first,
          32.0,
          Paint()..color = const Color(0xFFE53935),
        );
      } else {
        final userPath = Path()..moveTo(userPoints.first.dx, userPoints.first.dy);
        for (int i = 1; i < userPoints.length; i++) {
          userPath.lineTo(userPoints[i].dx, userPoints[i].dy);
        }
        canvas.drawPath(userPath, userPaint);
      }
    }

    canvas.restore();
  }

  /// 顺着笔画骨架 medianPath 从起笔到收笔渐进揭示 strokePath 轮廓
  void _drawProgressiveStroke(
    Canvas canvas,
    Path strokePath,
    Path medianPath,
    double progress,
    Color color,
  ) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.0) return;
    if (p >= 0.98) {
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final metrics = medianPath.computeMetrics().toList();
    if (metrics.isEmpty) {
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final metric = metrics.first;
    final subPath = metric.extractPath(0.0, metric.length * p);

    canvas.save();
    canvas.clipPath(strokePath);
    canvas.drawPath(
      subPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 260.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  /// 在当前待写笔画上绘制起笔红点 + 虚线方向引导 + 终点小箭头
  void _drawStrokeGuide(Canvas canvas, List<Offset> median) {
    if (median.isEmpty) return;

    final guideLinePaint = Paint()
      ..color = const Color(0xFFE53935).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    for (int i = 1; i < median.length; i++) {
      _drawDashedLine(
        canvas,
        median[i - 1],
        median[i],
        guideLinePaint,
        dashWidth: 22.0,
        dashSpace: 16.0,
      );
    }

    // 终点方向小箭头
    if (median.length >= 2) {
      final p1 = median[median.length - 2];
      final p2 = median.last;
      final dir = p2 - p1;
      final dist = dir.distance;
      if (dist > 1.0) {
        final u = dir / dist;
        final n = Offset(-u.dy, u.dx);
        const arrowLen = 34.0;
        const arrowHalfWidth = 18.0;
        final base = p2 - u * arrowLen;
        final left = base + n * arrowHalfWidth;
        final right = base - n * arrowHalfWidth;
        final arrowPath = Path()
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close();
        canvas.drawPath(
          arrowPath,
          Paint()
            ..color = const Color(0xFFE53935).withOpacity(0.85)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // 起笔圆点（白边红心）
    final start = median.first;
    canvas.drawCircle(
      start,
      28.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      start,
      22.0,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill,
    );
  }

  void _paintGrid(Canvas canvas, Size size) {
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

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5.0,
    double dashSpace = 4.0,
  }) {
    final totalLength = (end - start).distance;
    if (totalLength <= 0.0) return;
    final direction = (end - start) / totalLength;
    double drawn = 0;
    while (drawn < totalLength) {
      final segmentEnd =
          (drawn + dashWidth) > totalLength ? totalLength : drawn + dashWidth;
      canvas.drawLine(
        start + direction * drawn,
        start + direction * segmentEnd,
        paint,
      );
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TianZiGeStrokePainter oldDelegate) {
    return oldDelegate.strokeData != strokeData ||
        oldDelegate.mode != mode ||
        oldDelegate.demoStrokeIndex != demoStrokeIndex ||
        oldDelegate.demoProgress != demoProgress ||
        oldDelegate.demoFinished != demoFinished ||
        oldDelegate.traceStrokeIndex != traceStrokeIndex ||
        oldDelegate.hintProgress != hintProgress ||
        oldDelegate.userPoints.length != userPoints.length;
  }
}
