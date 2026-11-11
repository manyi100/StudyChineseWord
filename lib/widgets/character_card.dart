import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';
import '../services/tts_service.dart';
import 'audio_feedback.dart';
import 'pinyin_grid_text.dart';
import 'tian_zi_ge_box.dart';

/// 单张汉字学习卡片：配图 + 拼音/大字 + 组词 + 例句 + 部首笔顺 + 收藏按钮。
/// 点击汉字/词语/句子均会调用TTS朗读对应内容。
/// 组词/例句数据尚未整理完成时会自动隐藏对应区块，不会显示空白。
class CharacterCard extends StatelessWidget {
  final HanziModel hanzi;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const CharacterCard({
    super.key,
    required this.hanzi,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  // 根据分组生成柔和的卡片主题色，纯粹为了视觉区分，不影响数据逻辑
  Color get _cardColor {
    const colors = [
      Color(0xFFE8F5E9),
      Color(0xFFE3F2FD),
      Color(0xFFFCE4EC),
      Color(0xFFFFF3E0),
      Color(0xFFF3E5F5),
    ];
    final idx = hanzi.groupId.hashCode.abs() % colors.length;
    return colors[idx];
  }

  String get _charTag => 'char_${hanzi.id}';
  String get _imageTag => 'image_${hanzi.id}';
  String get _sentenceTag => 'sentence_${hanzi.id}';
  String _wordTag(WordEntry word) => 'word_${hanzi.id}_${word.text}';

  /// 点击图片时朗读的内容：优先整句，其次组词，最后单字
  String get _imageAudioText {
    if (hanzi.sentence != null) return hanzi.sentence!.text;
    if (hanzi.words.isNotEmpty) return hanzi.words.first.text;
    return hanzi.char;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 调试用标记：该字数据存在已知问题（来源行重复/无法识别），需人工核对
            if (hanzi.needsReview)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '⚠️ 该字数据需人工核对原书',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),

            // 配图区：按每张图自己的真实宽高比显示，铺满圆角框，不裁切也不留白。
            // 实测这批插图比例在 1.81~2.0 之间浮动，写死 1.81 会让大部分图上下被
            // 裁掉一点，所以这里先按 1.81 占位，取到真实尺寸后自动校正。
            // 点击图片会朗读例句（插图本来就是按例句生成的），并浮出句子气泡。
            GestureDetector(
              onTap: () => TtsService.instance
                  .speak(_imageAudioText, tag: _imageTag),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    if (hanzi.imageAsset != null)
                      _HanziImage(asset: hanzi.imageAsset!)
                    else
                      Container(
                        color: Colors.white.withOpacity(0.6),
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: 1.81,
                          child: const Icon(Icons.image_outlined,
                              size: 52, color: Colors.black26),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: SpeakerIcon(
                        tag: _imageTag,
                        size: 18,
                        color: Colors.black54,
                        backgroundColor: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: isFavorite
                                  ? Colors.amber[700]
                                  : Colors.black38,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: SpeakingBubble(
                          tag: _imageTag,
                          text: _imageAudioText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 拼音(四线三格) + 汉字(田字格：自动笔顺演示 + 手写描红)
            Column(
              children: [
                GestureDetector(
                  onTap: () => TtsService.instance
                      .speak(hanzi.char, tag: _charTag),
                  child: PinyinGridText(
                    pinyin: hanzi.pinyin,
                    width: 140,
                    height: 50,
                  ),
                ),
                const SizedBox(height: 10),
                TianZiGeBox(
                  char: hanzi.char,
                  size: 152,
                  strokeOrderNames: hanzi.strokeOrderNames,
                  onSpeak: () => TtsService.instance
                      .speak(hanzi.char, tag: _charTag),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 组词区：没有数据时整块隐藏，不显示空白。
            // 固定为一行三等分，词语再长也不换行：拼音最多折两行，词语单行缩放。
            if (hanzi.words.isNotEmpty) ...[
              const _SectionLabel(label: '组词'),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < hanzi.words.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                          child: _WordChip(
                            word: hanzi.words[i],
                            tag: _wordTag(hanzi.words[i]),
                            onTap: () => TtsService.instance.speak(
                              hanzi.words[i].text,
                              tag: _wordTag(hanzi.words[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 例句区：没有数据时整块隐藏
            if (hanzi.sentence != null) ...[
              const _SectionLabel(label: '造句'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => TtsService.instance
                    .speak(hanzi.sentence!.text, tag: _sentenceTag),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SpeakerIcon(
                        tag: _sentenceTag,
                        size: 18,
                        color: const Color(0xFF455A64),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hanzi.sentence!.text,
                          style: const TextStyle(fontSize: 18, height: 1.4),
                        ),
                      ),
                      SpeakingLabel(tag: _sentenceTag),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 底部信息条：部首/笔顺（真实校验数据）
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '部首：${hanzi.radical ?? '—'}　共${hanzi.strokeCount ?? '?'}画',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '笔顺：${hanzi.strokeOrderDisplay}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black.withOpacity(0.5),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordEntry word;
  final String tag;
  final VoidCallback onTap;

  const _WordChip({
    required this.word,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<String?>(
        valueListenable: TtsService.instance.speakingTag,
        builder: (context, activeTag, _) {
          final active = activeTag == tag;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFF1F8E9) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? const Color(0xFF7CB342) : Colors.black12,
                width: active ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word.pinyin,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.05,
                    color:
                        active ? const Color(0xFF558B2F) : Colors.black45,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpeakerIcon(
                      tag: tag,
                      size: 11,
                      gap: 0,
                      color: active
                          ? const Color(0xFF558B2F)
                          : Colors.black45,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word.text,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 按图片真实宽高比撑满父容器的配图组件。
///
/// 这批插图的比例并不统一（1.81~2.0），如果统一写死一个比例，用 BoxFit.cover
/// 会把偏宽或偏高的图裁掉一点，用 BoxFit.contain 又会留出底色边。这里在加载时
/// 读取图片真实尺寸，再设置 AspectRatio，保证既不裁切也不留白。
class _HanziImage extends StatefulWidget {
  final String asset;

  const _HanziImage({required this.asset});

  @override
  State<_HanziImage> createState() => _HanziImageState();
}

class _HanziImageState extends State<_HanziImage> {
  // 取到真实尺寸前先按常见比例占位，避免首帧高度为 0
  double _aspectRatio = 1.81;
  bool _resolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _HanziImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      _resolved = false;
      _aspectRatio = 1.81;
      _resolveAspectRatio();
    }
  }

  void _resolveAspectRatio() {
    if (_resolved) return;

    final stream = AssetImage(widget.asset)
        .resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final ratio = info.image.width / info.image.height;
        _resolved = true;
        stream.removeListener(listener);
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (_aspectRatio - ratio).abs() > 0.001) {
            setState(() => _aspectRatio = ratio);
          }
        });
      },
      onError: (error, stack) {
        _resolved = true;
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Image.asset(
        widget.asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) => Container(
          color: Colors.white.withOpacity(0.6),
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined,
              size: 52, color: Colors.black26),
        ),
      ),
    );
  }
}
