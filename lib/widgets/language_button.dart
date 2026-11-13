import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// 开屏右上角的界面语言入口。
///
/// 支持中文 / English / 日本語 / 한국어 / Tiếng Việt 五种界面语言，
/// 点开后在菜单里选择；选择的语言会保存在本地。
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: PopupMenuButton<AppLang>(
          tooltip: s.languageTooltip,
          initialValue: AppLocale.lang,
          position: PopupMenuPosition.under,
          onSelected: (value) async {
            final messenger = ScaffoldMessenger.of(context);
            await AppLocale.set(value);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(AppStrings.ofCurrent().languageChanged),
                  duration: const Duration(milliseconds: 1400),
                ),
              );
          },
          itemBuilder: (context) => AppLang.values
              .map(
                (lang) => PopupMenuItem<AppLang>(
                  value: lang,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          lang.shortLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(lang.nativeName),
                      if (lang == AppLocale.lang) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Color(0xFF4CAF50),
                        ),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
          child: Material(
            color: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppLocale.lang.shortLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
