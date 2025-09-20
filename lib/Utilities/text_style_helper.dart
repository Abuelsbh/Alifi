import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../Utilities/theme_helper.dart';
import '../core/Font/font_provider.dart';

class TextStyleHelper {
  final BuildContext context;
  TextStyleHelper._(this.context);

  static TextStyleHelper of(BuildContext context) => TextStyleHelper._(context);

  double get _fSS =>
      Provider.of<FontProvider>(context, listen: false).fontSizeScale;
  FontFamilyTypes get _fF =>
      Provider.of<FontProvider>(context, listen: false).fontFamily;

  // اختيار الفونت حسب ال enum
  TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color})
  _resolveFont(FontFamilyTypes fontFamily) {
    switch (fontFamily) {
      case FontFamilyTypes.poppins:
        return GoogleFonts.poppins;
      case FontFamilyTypes.inter:
        return GoogleFonts.inter;
      case FontFamilyTypes.itim:
        return GoogleFonts.itim;
    }
  }

  /// يستعمل الفونت الافتراضي اللي مختاره المستخدم من الـ Provider
  TextStyle getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
  }) =>
      _resolveFont(_fF)(
        fontSize: (fontSize * _fSS).sp,
        fontWeight: fontWeight,
        color: ThemeClass.of(context).darkGreyColor,
      );

  /// يسمحلك تختار الفونت يدوي
  TextStyle getCustomFontStyle({
    required double fontSize,
    FontWeight? fontWeight,
    required FontFamilyTypes fontFamily,
  }) =>
      _resolveFont(fontFamily)(
        fontSize: (fontSize * _fSS).sp,
        fontWeight: fontWeight,
        color: ThemeClass.of(context).darkGreyColor,
      );

  // ----------- ready styles with default font ------------
  TextStyle get s10RegTextStyle => getTextStyle(fontSize: 10);
  TextStyle get s12RegTextStyle => getTextStyle(fontSize: 12);
  TextStyle get s14RegTextStyle => getTextStyle(fontSize: 14);
  TextStyle get s16RegTextStyle => getTextStyle(fontSize: 16);
  TextStyle get s18RegTextStyle => getTextStyle(fontSize: 18);
  TextStyle get s22RegTextStyle => getTextStyle(fontSize: 22);
  TextStyle get s24RegTextStyle => getTextStyle(fontSize: 24);
  TextStyle get s28RegTextStyle => getTextStyle(fontSize: 28);
  TextStyle get s32RegTextStyle => getTextStyle(fontSize: 32);
  TextStyle get s36RegTextStyle => getTextStyle(fontSize: 36);
  TextStyle get s45RegTextStyle => getTextStyle(fontSize: 45);

  TextStyle get s12SemiBoldTextStyle =>
      getTextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  TextStyle get s14SemiBoldTextStyle =>
      getTextStyle(fontSize: 14, fontWeight: FontWeight.w600);
  TextStyle get s16SemiBoldTextStyle =>
      getTextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  // ----------- ready styles with custom font ------------
  TextStyle s28InterTextStyle() => getCustomFontStyle(fontSize: 28, fontFamily: FontFamilyTypes.inter);

  TextStyle get s36ItimTextStyle => getCustomFontStyle(fontSize: 36, fontFamily: FontFamilyTypes.itim);

  TextStyle s14PoppinsTextStyle() =>
      getCustomFontStyle(fontSize: 14, fontFamily: FontFamilyTypes.poppins);
}
