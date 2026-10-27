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

            // 配图区：有配图就显示，没有(imageAsset为空)就显示占位图标
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Colors.white.withOpacity(0.6),
                alignment: Alignment.center,
                child: hanzi.imageAsset != null
                    ? Image.asset(
                        hanzi.imageAsset!,
                        fit: BoxFit.cover,
                        cacheWidth: 280,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.image_outlined,
                          size: 52,
                          color: Colors.black26,
                        ),
                      )
                    : const Icon(Icons.image_outlined,
                        size: 52, color: Colors.black26),
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
