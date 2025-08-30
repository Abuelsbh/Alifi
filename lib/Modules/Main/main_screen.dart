import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'veterinary/enhanced_veterinary_screen.dart';
import 'lost_found/lost_found_screen.dart';
import 'profile/simple_profile_screen.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/main';
  
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EnhancedVeterinaryScreen(),
    const LostFoundScreen(),
    const SimpleProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Removed bottomNavigationBar to hide the navigation bar
    );
  }
} 