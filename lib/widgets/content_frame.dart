import 'package:flutter/widgets.dart';

/// 内容区最大宽度。
///
/// 手机竖屏时屏幕宽度远小于该值，布局与原来完全一致；
/// iPad、折叠屏展开、横屏等宽屏场景下，内容不再被无限拉伸，
/// 而是居中显示，避免卡片、图片和文字被放得过大。
const double kContentMaxWidth = 720;

/// 把内容限制在 [maxWidth] 内并水平居中。
///
/// 直接包在可滚动列表 / 网格外面即可：滚动方向不受影响，
/// 只是宽度被收窄并在两侧留白。
class ContentFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
