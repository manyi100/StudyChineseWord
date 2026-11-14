import 'package:flutter/material.dart';

import '../services/meaning_service.dart';

/// 学习卡片上的英文释义。
///
/// 三条原则：
/// 1. 只是辅助信息，字号小、颜色淡，不抢中文主体的视觉优先级；
/// 2. 不参与朗读——点击释义不会发声，也不会进入 TTS 队列；
/// 3. 可整体关闭，关闭时完全不占高度（返回 0 尺寸，由卡片布局自然收起）。
///
/// 释义内容固定英文：界面语言只切换界面文案，学习内容始终是中文 + 英文注释。
/// 释义是异步读取的，所以这里用 [MeaningService.changes] 监听，
/// 加载完成或开关变化时只重建这几行文字，不会重建整张卡片。
class MeaningText extends StatelessWidget {
  /// 延迟取释义：加载完成前返回 null，加载完成后由 [ListenableBuilder] 重新取一次。
  final String? Function() resolve;
  final double fontSize;
  final TextAlign textAlign;
  final Color color;
  final EdgeInsets padding;

  /// 组词释义固定一行（与 chips 一样不换行），超长时省略；
  /// 单字与例句允许两行。
  final int maxLines;

  const MeaningText(
    this.resolve, {
    super.key,
    this.fontSize = 13,
    this.textAlign = TextAlign.center,
    this.color = const Color(0x8A000000),
    this.padding = const EdgeInsets.only(top: 8),
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MeaningService.instance.changes,
      builder: (context, _) {
        if (!MeaningService.instance.visible.value)
          return const SizedBox.shrink();

        final value = resolve();
        if (value == null || value.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: padding,
          child: IgnorePointer(
            child: Text(
              value,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.25,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 单字释义：紧贴田字格下方，例如「长 → long; length」。
class CharMeaning extends StatelessWidget {
  final String char;

  const CharMeaning({super.key, required this.char});

  @override
  Widget build(BuildContext context) {
    return MeaningText(() => MeaningService.instance.charOf(char));
  }
}

/// 组词释义：一行按 chips 的先后顺序排列，用「/」分隔。
/// 三个词对应的英文顺序与上方词块一致，家长不需要猜。
class WordMeanings extends StatelessWidget {
  final List<String> words;

  const WordMeanings({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return MeaningText(
      () {
        final parts = <String>[];
        for (final word in words) {
          final meaning = MeaningService.instance.wordOf(word);
          if (meaning != null && meaning.isNotEmpty) parts.add(meaning);
        }
        return parts.isEmpty ? null : parts.join('  /  ');
      },
      fontSize: 11,
      color: const Color(0x73000000),
      padding: const EdgeInsets.only(top: 6),
      maxLines: 1,
    );
  }
}

/// 例句释义：放在句框内第二行，和中文句子同一个卡片，读起来是「一句中文 + 一句英文」。
class SentenceMeaning extends StatelessWidget {
  final String sentence;

  const SentenceMeaning({super.key, required this.sentence});

  @override
  Widget build(BuildContext context) {
    return MeaningText(
      () => MeaningService.instance.sentenceOf(sentence),
      fontSize: 13,
      textAlign: TextAlign.left,
      padding: const EdgeInsets.only(top: 4),
    );
  }
}
