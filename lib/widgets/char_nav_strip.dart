import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';

/// 顶部汉字导航条：把当前学习列表里的汉字横向排开，
/// 当前字高亮、已学字打勾、未学字置灰，点击可直接跳转。
/// 不显示 1/4、2/4 之类的数字序号。
class CharNavStrip extends StatelessWidget {
  final List<HanziModel> chars;
  final int currentIndex;
  final Set<String> viewedIds;
  final ScrollController controller;
  final ValueChanged<int> onTap;

  const CharNavStrip({
    super.key,
    required this.chars,
    required this.currentIndex,
    required this.viewedIds,
    required this.controller,
    required this.onTap,
  });

  static const double itemExtent = 58;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = chars.length * itemExtent;
          final padding = totalWidth + 20 < constraints.maxWidth
              ? (constraints.maxWidth - totalWidth) / 2
              : 10.0;
          return ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            itemExtent: itemExtent,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: chars.length,
            itemBuilder: (context, index) {
              final hanzi = chars[index];
              final isCurrent = index == currentIndex;
              final isViewed = !isCurrent && viewedIds.contains(hanzi.id);

              final Color background;
              final Color foreground;
              final Color border;
              if (isCurrent) {
                background = const Color(0xFF4CAF50);
                foreground = Colors.white;
                border = const Color(0xFF4CAF50);
              } else if (isViewed) {
                background = const Color(0xFFE8F5E9);
                foreground = const Color(0xFF2E7D32);
                border = const Color(0xFFA5D6A7);
              } else {
                background = Colors.white;
                foreground = Colors.black54;
                border = Colors.black12;
              }

              return Center(
                child: Semantics(
                  label: '第 ${index + 1} 个字 ${hanzi.char}',
                  selected: isCurrent,
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: border,
                            width: isCurrent ? 1.8 : 1,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Center(
                              child: Text(
                                hanzi.char,
                                style: TextStyle(
                                  fontFamily: 'KaiTiCustom',
                                  fontSize: 20,
                                  height: 1.0,
                                  color: foreground,
                                ),
                              ),
                            ),
                            if (isViewed)
                              const Positioned(
                                top: -2,
                                right: -2,
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
