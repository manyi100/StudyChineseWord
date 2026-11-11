import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// 开屏右上角的中英文切换按钮：显示“可以切换到的语言”。
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Tooltip(
          message: s.languageTooltip,
          child: Material(
            color: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(
                color: Colors.black.withValues(alpha: 0.12),
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await AppLocale.toggle();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.ofCurrent().languageChanged),
                      duration: const Duration(milliseconds: 1400),
                    ),
                  );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      s.languageButtonLabel,
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
      ),
    );
  }
}
