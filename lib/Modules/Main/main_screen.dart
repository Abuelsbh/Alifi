import 'package:flutter/material.dart';

import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/translated_bottom_navigation_bar.dart';
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: TranslatedBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: const [
            TranslatedBottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              labelKey: 'navigation.home',
            ),
            TranslatedBottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              labelKey: 'navigation.veterinary',
            ),
            TranslatedBottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              labelKey: 'navigation.lost_found',
            ),
            TranslatedBottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              labelKey: 'navigation.profile',
            ),
          ],
        ),
      ),
    );
  }
} 