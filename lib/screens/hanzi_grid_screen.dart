import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/hanzi_model.dart';
import 'home_screen.dart';

/// 汉字网格：用于“按部首 / 按笔画”浏览时展示一组字，
/// 点击任意一个字进入该组内的左右翻页学习。
class HanziGridScreen extends StatelessWidget {
  final String title;
  final String progressKey;
  final List<HanziModel> chars;

  const HanziGridScreen({
    super.key,
    required this.title,
    required this.progressKey,
    required this.chars,
  });

  void _openAt(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          chars: chars,
          title: title,
          progressKey: progressKey,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                s.gridIntro(chars.length),
                style: const TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: chars.length,
              itemBuilder: (context, index) {
                final h = chars[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openAt(context, index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            h.char,
                            style: const TextStyle(
                              fontFamily: 'KaiTiCustom',
                              fontSize: 34,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.pinyin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
