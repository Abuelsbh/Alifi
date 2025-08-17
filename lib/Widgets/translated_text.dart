import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/Language/app_languages.dart';

class TranslatedText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallbackText;

  const TranslatedText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguage>(
      builder: (context, appLanguage, child) {
        final translatedText = appLanguage.translate(textKey);
        final displayText = translatedText != textKey ? translatedText : (fallbackText ?? textKey);
        
        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

// Widget للترجمة مع دعم التنسيق
class TranslatedRichText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallbackText;
  final List<TextSpan>? children;

  const TranslatedRichText(
    this.textKey, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fallbackText,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLanguage>(
      builder: (context, appLanguage, child) {
        final translatedText = appLanguage.translate(textKey);
        final displayText = translatedText != textKey ? translatedText : (fallbackText ?? textKey);
        
        return RichText(
          text: TextSpan(
            text: displayText,
            style: style,
            children: children,
          ),
          textAlign: textAlign ?? TextAlign.start,
          maxLines: maxLines,
          overflow: overflow ?? TextOverflow.clip,
        );
      },
    );
  }
} 