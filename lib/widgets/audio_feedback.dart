import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../services/tts_service.dart';

/// 会随朗读状态变化的喇叭图标：
/// - 空闲时显示普通喇叭；
/// - 正在朗读对应 [tag] 的内容时，变成 3 根跳动的声波柱；
/// - 朗读结束（或超时兜底）后自动恢复。
class SpeakerIcon extends StatelessWidget {
  final String tag;
  final double size;
  final Color color;
  final Color? backgroundColor;

  const SpeakerIcon({
    super.key,
    required this.tag,
    this.size = 18,
    this.color = const Color(0xFF455A64),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '朗读',
      button: true,
      child: ValueListenableBuilder<String?>(
        valueListenable: TtsService.instance.speakingTag,
        builder: (context, activeTag, _) {
          final active = activeTag == tag;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size + 12,
            height: size + 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: active
                ? SoundWave(color: color, size: size)
                : Icon(Icons.volume_up_rounded, size: size, color: color),
          );
        },
      ),
    );
  }
}

/// 三根上下跳动的声波柱
class SoundWave extends StatefulWidget {
  final Color color;
  final double size;

  const SoundWave({super.key, required this.color, this.size = 18});

  @override
  State<SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<SoundWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 2,
      height: widget.size + 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = _controller.value * 2 * math.pi + i * 1.4;
              final ratio = 0.35 + 0.45 * ((math.sin(phase) + 1) / 2);
              return Container(
                width: math.max(2.5, widget.size * 0.16),
                height: (widget.size + 2) * ratio,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 固定在图标旁的“朗读中”文字，避免动效不够明显
class SpeakingLabel extends StatelessWidget {
  final String tag;
  final double width;

  const SpeakingLabel({super.key, required this.tag, this.width = 44});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: TtsService.instance.speakingTag,
      builder: (context, activeTag, _) {
        return SizedBox(
          width: width,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: activeTag == tag ? 1 : 0,
            child: const Text(
              '朗读中',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 图片上方浮出的句子气泡：朗读时淡入，读完淡出
class SpeakingBubble extends StatelessWidget {
  final String tag;
  final String text;

  const SpeakingBubble({super.key, required this.tag, required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: TtsService.instance.speakingTag,
        builder: (context, activeTag, _) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: activeTag == tag ? 1 : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up_rounded,
                      size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 首次进入学习页的一次性提示条
class AudioHintBanner extends StatelessWidget {
  final VoidCallback onClose;

  const AudioHintBanner({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded,
              size: 18, color: Color(0xFFEF6C00)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '点汉字、词语、句子或图片，都能听发音',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8D4E00)),
            ),
          ),
          InkResponse(
            onTap: onClose,
            radius: 18,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF8D4E00)),
            ),
          ),
        ],
      ),
    );
  }
}
