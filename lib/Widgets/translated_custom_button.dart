import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../core/Theme/app_theme.dart';
import '../core/Language/app_languages.dart';

class TranslatedCustomButton extends StatelessWidget {
  final String textKey;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final String? fallbackText;

  const TranslatedCustomButton({
    super.key,
    required this.textKey,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguage>(
      builder: (context, appLanguage, child) {
        final translatedText = appLanguage.translate(textKey);
        final displayText = translatedText != textKey ? translatedText : (fallbackText ?? textKey);
        
        return SizedBox(
          width: isFullWidth ? double.infinity : width,
          height: height ?? 48.h,
          child: _buildButton(context, displayText),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primaryGreen,
            foregroundColor: textColor ?? Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _buildButtonContent(text),
        );

      case ButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppTheme.primaryGreen,
            side: BorderSide(
              color: backgroundColor ?? AppTheme.primaryGreen,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _buildButtonContent(text),
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppTheme.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: _buildButtonContent(text),
        );

      case ButtonType.icon:
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: icon != null ? Icon(icon, size: 20.sp) : const SizedBox.shrink(),
          label: _buildButtonContent(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primaryGreen,
            foregroundColor: textColor ?? Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
    }
  }

  Widget _buildButtonContent(String text) {
    if (isLoading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null && type != ButtonType.icon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
  icon,
} 