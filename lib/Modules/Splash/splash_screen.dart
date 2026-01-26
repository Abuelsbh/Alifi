import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/Utilities/shared_preferences.dart';
import 'package:alifi/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../generated/assets.dart';
import '../Main/location/location_selection_screen.dart';
import '../Main/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  void startTime() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    // Check if it's the first launch and user hasn't selected a location
    final isFirstLaunch = SharedPref.isFirstLaunch();
    final userLocation = LocationService.getUserLocation();
    
    if (isFirstLaunch || userLocation == null || userLocation.isEmpty) {
      // Navigate to location selection screen for first time
      context.go('${LocationSelectionScreen.routeName}?firstTime=true');
    } else {
      // Navigate to home screen
      context.go(HomeScreen.routeName);
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
