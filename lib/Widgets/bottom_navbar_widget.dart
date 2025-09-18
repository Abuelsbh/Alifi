import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum SelectedBottomNavBar { home, lostFound, veterinary, profile }

class BottomNavBarWidget extends StatelessWidget {
  final SelectedBottomNavBar selected;
  final Function(SelectedBottomNavBar)? onTap;
  
  const BottomNavBarWidget({
    super.key,
    this.selected = SelectedBottomNavBar.home,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      height: 60.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFF914C), // Orange
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Assets.iconsHome, SelectedBottomNavBar.home, 'Home'),
          _buildNavItem(Assets.iconsSettings, SelectedBottomNavBar.lostFound, 'Lost & Found'),
          _buildNavItem(Assets.iconsChat, SelectedBottomNavBar.veterinary, 'Veterinary'),
          _buildNavItem(Assets.iconsProfile, SelectedBottomNavBar.profile, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String icon, SelectedBottomNavBar navItem, String label) {
    bool isActive = selected == navItem;
    return GestureDetector(
      onTap: () => onTap?.call(navItem),
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
            SvgPicture.asset(
              icon,
              height: 24.r,
              width: 24.r,
              colorFilter: ColorFilter.mode(
                isActive ? const Color(0xFFF36F21) : Colors.white,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
