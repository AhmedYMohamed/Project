import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class LanguageSwitcherButton extends StatelessWidget {
  final Color? backgroundColor;
  final Color textColor;
  final Color iconColor;
  final EdgeInsetsGeometry padding;

  const LanguageSwitcherButton({
    super.key,
    this.backgroundColor = const Color(0xFF383A46),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isArabic = localeProvider.isArabic;
    final currentLangLabel = isArabic ? 'العربية' : 'English';

    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF2C2F36),
      ),
      child: PopupMenuButton<Locale>(
        onSelected: (Locale locale) {
          localeProvider.setLocale(locale);
        },
        offset: const Offset(0, 42),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2C2F36),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
          PopupMenuItem<Locale>(
            value: const Locale('ar'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇪🇬 ', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'العربية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isArabic ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                if (isArabic) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check, color: Color(0xFF3B82F6), size: 18),
                ],
              ],
            ),
          ),
          PopupMenuDivider(height: 1),
          PopupMenuItem<Locale>(
            value: const Locale('en'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇺🇸 ', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'English',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: !isArabic ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                if (!isArabic) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check, color: Color(0xFF3B82F6), size: 18),
                ],
              ],
            ),
          ),
        ],
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentLangLabel,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                color: iconColor.withValues(alpha: 0.7),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
