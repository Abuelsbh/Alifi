import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:state_extended/state_extended.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../generated/assets.dart';
import '../splash_controller.dart';

class LargeSplashScreen extends StatefulWidget {
  const LargeSplashScreen({super.key});

  @override
  State createState() => _LargeSplashScreenState();
}

class _LargeSplashScreenState extends StateX<LargeSplashScreen> {
  _LargeSplashScreenState() : super(controller: SplashController()) {
    con = SplashController();
  }
  late SplashController con;


  @override
  void initState() {
    log('LargeSplashScreen initState called');
    con.init(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeClass.of(context).secondaryColor,
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            SvgPicture.asset(Assets.imagesLogo, width: 200.r, height: 200.r, color: ThemeClass.of(context).secondaryColor),
            const Spacer(),
            CircularProgressIndicator(color: ThemeClass.of(context).secondaryColor),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}