import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../Utilities/dialog_helper.dart';
import '../core/services/auth_service.dart';
import '../core/Language/translation_service.dart';
import 'add_animal_entry_sheet.dart';
import 'login_widget.dart';
import 'selected_bottom_nav_bar.dart';

export 'selected_bottom_nav_bar.dart' show SelectedBottomNavBar;

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
              if (item.type == SelectedBottomNavBar.lostFound) {
                if (onTap != null) {
                  onTap!(SelectedBottomNavBar.lostFound);
                } else {
                  AddAnimalEntrySheet.show(context);
                }
                return;
              }
              if (onTap != null) {
                onTap!(item.type);
              } else if (AuthService.isAuthenticated) {
                context.pushNamed(item.routeName ?? 'home');
              } else {
                DialogHelper.custom(context: context).customDialog(
                  dialogWidget: LoginWidget(onLoginSuccess: () {}),
                );
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
                child: _buildIcon(
                  item.iconPath,
                    isActive ? const Color(0xFFF36F21) : Colors.white,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIcon(String iconPath, Color color) {
    if (iconPath.endsWith('.svg')) {
      return SvgPicture.asset(
        iconPath,
        height: 24.r,
        width: 24.r,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    } else {
      // للصور PNG
      return Image.asset(
        iconPath,
        height: 24.r,
        width: 24.r,
        color: color,
      );
    }
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

  static _BottomNavBarItemModel get home => _BottomNavBarItemModel(
    title: TranslationService.instance.translate('navigation.home'),
    iconPath: Assets.iconsHome,
    type: SelectedBottomNavBar.home,
    routeName: 'home', // استخدام route name
  );

  static _BottomNavBarItemModel get lostFound => _BottomNavBarItemModel(
    title: TranslationService.instance.translate('navigation.lost_found'),
    iconPath: Assets.iconsSettings, // استخدام أيقونة أكثر مناسبة
    type: SelectedBottomNavBar.lostFound,
  );

  static _BottomNavBarItemModel get veterinary => _BottomNavBarItemModel(
    title: TranslationService.instance.translate('navigation.veterinary'),
    iconPath: Assets.iconsChat,
    type: SelectedBottomNavBar.veterinary,
    routeName: 'veterinary', // استخدام route name
  );

  static _BottomNavBarItemModel get profile => _BottomNavBarItemModel(
    title: TranslationService.instance.translate('navigation.profile'),
    iconPath: Assets.iconsProfile,
    type: SelectedBottomNavBar.profile,
    routeName: 'profile', // استخدام route name
  );
}
