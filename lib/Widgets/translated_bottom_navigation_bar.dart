import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/Theme/app_theme.dart';
import 'translated_text.dart';

class TranslatedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final BottomNavigationBarType type;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final List<TranslatedBottomNavigationBarItem> items;

  const TranslatedBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.type = BottomNavigationBarType.fixed,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;
              
              return _buildNavItem(
                context,
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required TranslatedBottomNavigationBarItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? (selectedItemColor ?? AppTheme.primaryGreen).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected
              ? Border.all(
                  color: (selectedItemColor ?? AppTheme.primaryGreen).withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animation
            Flexible(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Transform.scale(
                  scale: isSelected ? 1.1 : 1.0,
                  child: isSelected ? item.activeIcon : item.icon,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Label
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 10.sp : 9.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (selectedItemColor ?? AppTheme.primaryGreen)
                      : (unselectedItemColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                child: TranslatedText(
                  item.labelKey,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TranslatedBottomNavigationBarItem {
  final Widget icon;
  final Widget activeIcon;
  final String labelKey;

  const TranslatedBottomNavigationBarItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });
} 