import 'package:flutter/material.dart';
import 'package:alifi/Widgets/bottom_navbar_widget.dart';
import 'package:alifi/Modules/Main/home/home_screen.dart';
import 'package:alifi/Modules/Main/veterinary/enhanced_veterinary_screen.dart';
import 'package:alifi/Modules/Main/lost_found/lost_found_screen.dart';
import 'package:alifi/Modules/Main/profile/simple_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final SelectedBottomNavBar initialSelected;
  
  const MainNavigationScreen({
    super.key,
    this.initialSelected = SelectedBottomNavBar.home,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late SelectedBottomNavBar _selectedNavBar;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LostFoundScreen(),
    const EnhancedVeterinaryScreen(),
    const SimpleProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedNavBar = widget.initialSelected;
    _currentIndex = _getIndexFromSelected(_selectedNavBar);
  }

  int _getIndexFromSelected(SelectedBottomNavBar selected) {
    switch (selected) {
      case SelectedBottomNavBar.home:
        return 0;
      case SelectedBottomNavBar.lostFound:
        return 1;
      case SelectedBottomNavBar.veterinary:
        return 2;
      case SelectedBottomNavBar.profile:
        return 3;
    }
  }

  void _onNavBarTap(SelectedBottomNavBar selected) {
    setState(() {
      _selectedNavBar = selected;
      _currentIndex = _getIndexFromSelected(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selected: _selectedNavBar,
        onTap: _onNavBarTap,
      ),
    );
  }
}
