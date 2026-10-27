import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';
import '../services/tts_service.dart';
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
            // 注意不要在外层加 alignment：一旦给了对齐方式，子组件会按图片自身
            // 尺寸居中，左右两侧就会露出底色，看起来像一条白边。
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: hanzi.imageAsset != null
                  ? _HanziImage(asset: hanzi.imageAsset!)
                  : Container(
                      color: Colors.white.withOpacity(0.6),
                      alignment: Alignment.center,
                      child: AspectRatio(
                        aspectRatio: 1.81,
                        child: const Icon(Icons.image_outlined,
                            size: 52, color: Colors.black26),
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // 拼音(四线三格) + 汉字(田字格+楷体)，点击朗读单字
            GestureDetector(
              onTap: () => TtsService.instance.speak(hanzi.char),
              child: Column(
                children: [
                  PinyinGridText(pinyin: hanzi.pinyin, width: 140, height: 50),
                  const SizedBox(height: 10),
                  TianZiGeBox(char: hanzi.char, size: 120),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 组词区：没有数据时整块隐藏，不显示空白
            if (hanzi.words.isNotEmpty) ...[
              const _SectionLabel(label: '组词'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: hanzi.words.map((w) {
                  return _WordChip(
                    word: w,
                    onTap: () => TtsService.instance.speak(w.text),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 例句区：没有数据时整块隐藏
            if (hanzi.sentence != null) ...[
              const _SectionLabel(label: '造句'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => TtsService.instance.speak(hanzi.sentence!.text),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    hanzi.sentence!.text,
                    style: const TextStyle(fontSize: 18, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 底部信息条：部首/笔顺（真实校验数据） + 收藏按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '部首：${hanzi.radical ?? '—'}　共${hanzi.strokeCount ?? '?'}画',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '笔顺：${hanzi.strokeOrderDisplay}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFavorite ? Colors.amber[700] : Colors.black38,
                    size: 30,
                  ),
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
  final VoidCallback onTap;

  const _WordChip({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(word.pinyin,
                style: const TextStyle(fontSize: 11, color: Colors.black45)),
            Text(word.text, style: const TextStyle(fontSize: 17)),
          ],
        ),
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
