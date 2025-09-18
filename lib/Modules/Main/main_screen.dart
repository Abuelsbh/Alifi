import 'package:flutter/material.dart';
import 'package:alifi/Widgets/main_navigation_screen.dart';
import 'package:alifi/Widgets/bottom_navbar_widget.dart';

class MainScreen extends StatelessWidget {
  static const String routeName = '/main';
  
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationScreen(initialSelected: SelectedBottomNavBar.home);
  }
}
