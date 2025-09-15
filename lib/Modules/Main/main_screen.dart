import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    const LostFoundScreen(),
    const EnhancedVeterinaryScreen(),
    const SimpleProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      height: 60.h,
      decoration: BoxDecoration(
        color: Color(0xFFFF914C), // Orange
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Assets.iconsHome, 0, 'Home'),
          _buildNavItem(Assets.iconsSettings, 1, 'Veterinary'),
          _buildNavItem(Assets.iconsChat, 2, 'Lost & Found'),
          _buildNavItem(Assets.iconsProfile, 3, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, int index, String label) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        width: 44.w,
        height: 44.h,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon,height: 24.r, width: 24.r, color: isActive ? Color(0xFFF36F21) : Colors.white,),
            // Icon(
            //   icon,
            //   color: isActive ? Color(0xFFF36F21) : Colors.white,
            //   size: 20.sp,
            // ),
            SizedBox(height: 2.h),
            // Text(
            //   label,
            //   style: TextStyle(
            //     color: isActive ? Color(0xFFF36F21) : Colors.white,
            //     fontSize: 8.sp,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
