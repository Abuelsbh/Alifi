import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/Theme/theme_model.dart';
import '../core/Theme/theme_provider.dart';

class ThemeClass extends ThemeModel{

  static ThemeModel of(BuildContext context) => Provider.of<ThemeProvider>(context,listen: false).appTheme;


  ThemeClass.defaultTheme({
    super.isDark= false,
    super.primaryColor = const Color(0xFFFF914C),
    super.secondaryColor = const Color(0xFF386641),
    super.accentColor = Colors.blueGrey,
    super.backGroundColor = Colors.white,
    super.darkGreyColor = const Color(0xff8b8787),
    super.lightGreyColor = const Color(0xFFEAE6E6),
    super.warningColor = Colors.red,
  });
}