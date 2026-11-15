import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';

/// 首次启动 / 点「?」时的四页新手引导。
///
/// - 文案统一放在 [AppStrings]，跟随界面语言实时切换（不额外维护一套映射表）；
/// - 4 页分别讲：阶段与三维检索、四区点读、笔顺描红、多语言 / EN 释义 / 跨课手势；
/// - 360dp 窄屏与 iPad / 投影仪宽屏都不溢出：正文可滚动，标签用 Wrap。
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

/// 单页引导数据：图标与主色固定，文案按当前语言从 [AppStrings] 取。
class _OnboardingStep {
  final IconData icon;
  final Color accent;
  final String Function(AppStrings s) title;
  final String Function(AppStrings s) desc;
  final List<String> Function(AppStrings s) tags;

  const _OnboardingStep({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.tags,
  });
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  static const Color _kPaperBg = Color(0xFFF4EAD8);
  static const Color _kCardBg = Color(0xFFFFFBF2);
  static const Color _kInkDark = Color(0xFF2C241D);
  static const Color _kInkMuted = Color(0xFF6E5E4F);
  static const Color _kBorder = Color(0xFFDCCBB1);

  static final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      icon: Icons.grid_view_rounded,
      accent: Color(0xFFC84B31),
      title: (s) => s.onboardingTitle1,
      desc: (s) => s.onboardingDesc1,
      tags: (s) => s.onboardingTags1,
    ),
    _OnboardingStep(
      icon: Icons.volume_up_rounded,
      accent: Color(0xFF2D6A4F),
      title: (s) => s.onboardingTitle2,
      desc: (s) => s.onboardingDesc2,
      tags: (s) => s.onboardingTags2,
    ),
    _OnboardingStep(
      icon: Icons.draw_rounded,
      accent: Color(0xFFB5651D),
      title: (s) => s.onboardingTitle3,
      desc: (s) => s.onboardingDesc3,
      tags: (s) => s.onboardingTags3,
    ),
    _OnboardingStep(
      icon: Icons.translate_rounded,
      accent: Color(0xFF3D5A80),
      title: (s) => s.onboardingTitle4,
      desc: (s) => s.onboardingDesc4,
      tags: (s) => s.onboardingTags4,
    ),
  ];

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final step = _steps[_currentIndex];
    final isLastPage = _currentIndex == _steps.length - 1;

    return Dialog(
      backgroundColor: _kPaperBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _kBorder, width: 1.5),
      ),
      child: ConstrainedBox(
        // 兼容 360dp 手机竖屏与 iPad / 投影仪宽屏
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopBar(s),
              const SizedBox(height: 6),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) => _buildPage(
                    s,
                    _steps[index],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomBar(s, step.accent, isLastPage),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部：五语快捷切换胶囊 + 关闭
  Widget _buildTopBar(AppStrings s) {
    final current = AppLocaleScope.of(context);

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppLang.values.map((lang) {
                final selected = lang == current;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => AppLocale.set(lang),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _kInkDark
                            : Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected ? _kInkDark : const Color(0xFFD5C3A6),
                        ),
                      ),
                      child: Text(
                        lang.shortLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : _kInkDark,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: s.onboardingSkip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: _kInkMuted),
        ),
      ],
    );
  }

  /// 中部：图标 + 标题 + 3 个亮点标签 + 正文（窄屏可滚动）
  Widget _buildPage(AppStrings s, _OnboardingStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D7C1)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: step.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, size: 34, color: step.accent),
            ),
            const SizedBox(height: 14),
            Text(
              step.title(s),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kInkDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: step.tags(s).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: step.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: step.accent,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              step.desc(s),
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 14,
                height: 1.55,
                color: _kInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部：页码圆点 + 上一步 / 下一步（最后一页为「开始学习」）
  Widget _buildBottomBar(AppStrings s, Color accent, bool isLastPage) {
    return Row(
      children: [
        Row(
          children: List.generate(_steps.length, (i) {
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
        if (_currentIndex > 0)
          TextButton(
            onPressed: _goPrev,
            style: TextButton.styleFrom(
              foregroundColor: _kInkMuted,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              s.onboardingPrev,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(width: 6),
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
            isLastPage ? s.onboardingStart : s.onboardingNext,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
