import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/Language/app_languages.dart';

class TranslatedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<TranslatedBottomNavigationBarItem> items;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? backgroundColor;
  final BottomNavigationBarType? type;

  const TranslatedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.backgroundColor,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguage>(
      builder: (context, appLanguage, child) {
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: type ?? BottomNavigationBarType.fixed,
          backgroundColor: backgroundColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          selectedLabelStyle: selectedLabelStyle,
          unselectedLabelStyle: unselectedLabelStyle,
          items: items.map((item) {
            return BottomNavigationBarItem(
              icon: item.icon,
              activeIcon: item.activeIcon,
              label: appLanguage.translate(item.labelKey),
            );
          }).toList(),
        );
      },
    );
  }
}

class TranslatedBottomNavigationBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final String labelKey;

  const TranslatedBottomNavigationBarItem({
    required this.icon,
    this.activeIcon,
    required this.labelKey,
  });
} 