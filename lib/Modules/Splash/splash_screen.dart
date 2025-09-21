import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../generated/assets.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  void startTime() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeClass.of(context).secondaryColor,
      body: Center(
        child: Image.asset(
          Assets.imagesLogo,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
