import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';

/// 首次启动 / 点「?」时的四页图片引导。
///
/// - 内容用 `assets/onboarding/onboarding_step_*.webp`（图中已排好标题与要点），
///   组件只负责展示、翻页与按钮，不再重复渲染文字；
/// - 左滑进入下一步，页码圆点同步；最后一页按钮变「开始学习」；
/// - 360dp 窄屏与 iPad / 投影仪宽屏都不溢出：图片按容器等比缩放。
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  /// 首次启动自动检查并弹出（已在 [GradeSelectScreen] 的首帧回调里接入）
  static Future<void> showIfNeeded(BuildContext context) async {
    if (await StorageService.instance.hasSeenOnboarding()) return;
    if (!context.mounted) return;
    await showModal(context);
    await StorageService.instance.markOnboardingSeen();
  }

  /// 手动打开使用说明（首页右上角「?」按钮）
  static Future<void> showModal(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const OnboardingDialog(),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  static const Color _kPaperBg = Color(0xFFF4EAD8);
  static const Color _kInkMuted = Color(0xFF6E5E4F);
  static const Color _kBorder = Color(0xFFDCCBB1);

  /// 四页插图，顺序与设计稿一致
  static const List<String> _images = [
    'assets/onboarding/onboarding_step_1.webp',
    'assets/onboarding/onboarding_step_2.webp',
    'assets/onboarding/onboarding_step_3.webp',
    'assets/onboarding/onboarding_step_4.webp',
  ];

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentIndex == _images.length - 1;

  void _goNext() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 每页标题只用于无障碍朗读，画面文字已经在图里
  String _semanticLabel(AppStrings s, int index) => switch (index) {
        0 => s.onboardingTitle1,
        1 => s.onboardingTitle2,
        2 => s.onboardingTitle3,
        _ => s.onboardingTitle4,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Dialog(
      backgroundColor: _kPaperBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _kBorder, width: 1.5),
      ),
      child: ConstrainedBox(
        // 兼容 360dp 手机竖屏与 iPad / 投影仪宽屏
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) => Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        _images[index],
                        key: ValueKey('onboarding_image_$index'),
                        fit: BoxFit.contain,
                        semanticLabel: _semanticLabel(s, index),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildBottomBar(s),
            ],
          ),
        ),
      ),
    );
  }

  /// 底部：页码圆点 + 跳过 / 下一步（最后一页为「开始学习」）
  Widget _buildBottomBar(AppStrings s) {
    const accent = Color(0xFFC84B31);

    return Row(
      children: [
        Row(
          children: List.generate(_images.length, (i) {
            final active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? accent : const Color(0xFFD0C0A8),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const Spacer(),
        if (!_isLastPage)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _kInkMuted,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              s.onboardingSkip,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: _goNext,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: Text(
            _isLastPage ? s.onboardingStart : s.onboardingNext,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
