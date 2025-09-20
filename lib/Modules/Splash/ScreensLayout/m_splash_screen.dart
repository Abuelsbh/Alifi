import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:state_extended/state_extended.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../generated/assets.dart';
import '../splash_controller.dart';

class MediumSplashScreen extends StatefulWidget {
  const MediumSplashScreen({super.key});

  @override
  State createState() => _MediumSplashScreenState();
}

class _MediumSplashScreenState extends StateX<MediumSplashScreen> {
  _MediumSplashScreenState() : super(controller: SplashController()) {
    con = SplashController();
  }
  late SplashController con;


  @override
  void initState() {
    log('SplashScreen initState called333');
    con.init(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: ThemeClass.of(context).secondaryColor,
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            SvgPicture.asset(Assets.imagesLogo, width: 150.r, height: 150.r,color:ThemeClass.of(context).secondaryColor),
            const Spacer(),
            CircularProgressIndicator(color: ThemeClass.of(context).secondaryColor),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

