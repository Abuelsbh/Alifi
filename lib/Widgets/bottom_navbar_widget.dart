import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../Modules/Auth/login_screen.dart';
import '../Modules/Main/home/home_screen.dart';
import '../Modules/Main/veterinary/enhanced_veterinary_screen.dart';
import '../Utilities/dialog_helper.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/auth_service.dart';
import 'login_widget.dart';

enum SelectedBottomNavBar { home, lostFound, veterinary, profile }

class BottomNavBarWidget extends StatelessWidget {
  final SelectedBottomNavBar selected;
  final Function(SelectedBottomNavBar)? onTap;

  const BottomNavBarWidget({
    super.key,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BottomNavBarItemModel.home,
      _BottomNavBarItemModel.lostFound,
      _BottomNavBarItemModel.veterinary,
      _BottomNavBarItemModel.profile,
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      height: 60.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFF914C), // Orange background
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          bool isActive = selected == item.type;
          return GestureDetector(
            onTap: () {
              if (onTap != null) {
                onTap!(item.type);
              } else {
                if (AuthService.isAuthenticated) {
                  context.pushNamed(item.routeName ?? 'home');
                } else {
                  DialogHelper.custom(context: context).customDialog(
                    dialogWidget: LoginWidget(
                      onLoginSuccess: () {
                        //context.go(item.routeName ?? 'home');
                      },
                    ),
                  );
                }
              }
            },
            child: Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  item.iconPath,
                  height: 24.r,
                  width: 24.r,
                  colorFilter: ColorFilter.mode(
                    isActive ? const Color(0xFFF36F21) : Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BottomNavBarItemModel {
  final String iconPath;
  final String title;
  final SelectedBottomNavBar type;
  final String? routeName; // الآن يحتوي على route names وليس paths

  _BottomNavBarItemModel({
    required this.iconPath,
    required this.title,
    required this.type,
    this.routeName,
  });

  static _BottomNavBarItemModel home = _BottomNavBarItemModel(
    title: "Home",
    iconPath: Assets.iconsHome,
    type: SelectedBottomNavBar.home,
    routeName: 'home', // استخدام route name
  );

  static _BottomNavBarItemModel lostFound = _BottomNavBarItemModel(
    title: "Lost & Found",
    iconPath: Assets.iconsSettings,
    type: SelectedBottomNavBar.lostFound,
    routeName: 'lostFound', // استخدام route name
  );

  static _BottomNavBarItemModel veterinary = _BottomNavBarItemModel(
    title: "Veterinary",
    iconPath: Assets.iconsChat,
    type: SelectedBottomNavBar.veterinary,
    routeName: 'veterinary', // استخدام route name
  );

  static _BottomNavBarItemModel profile = _BottomNavBarItemModel(
    title: "Profile",
    iconPath: Assets.iconsProfile,
    type: SelectedBottomNavBar.profile,
    routeName: 'profile', // استخدام route name
  );
}
