import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../Modules/Auth/login_screen.dart';
import '../Modules/Main/home/home_screen.dart';
import '../Modules/Main/veterinary/enhanced_veterinary_screen.dart';
import '../Modules/add_animal/add_animal_screen.dart';
import '../Models/pet_report_model.dart';
import '../Utilities/dialog_helper.dart';
import '../Utilities/bottom_sheet_helper.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/auth_service.dart';
import '../core/Theme/app_theme.dart';
import '../core/Language/translation_service.dart';
import 'login_widget.dart';
import 'translated_text.dart';

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
                if (item.type == SelectedBottomNavBar.lostFound) {
                  _showAnimalTypeBottomSheet(context);
                } else {
                  onTap!(item.type);
                }
              } else {
                if (AuthService.isAuthenticated) {
                  if (item.type == SelectedBottomNavBar.lostFound) {
                    _showAnimalTypeBottomSheet(context);
                  } else {
                    context.pushNamed(item.routeName ?? 'home');
                  }
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

  void _showAnimalTypeBottomSheet(BuildContext context) {
    BottomSheetHelper.bottomSheet(
      context: context,
      widget: const AnimalTypeSelectionBottomSheet(),
      topBorderRadius: 20,
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

class AnimalTypeSelectionBottomSheet extends StatelessWidget {
  const AnimalTypeSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ThemeClass.of(context).primaryColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),

      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimalTypeOption(
             context: context,
             title: TranslationService.instance.translate('lost_found.lost_pet'),
             onTap: () => _navigateToAddAnimal(context, ReportType.lost),
           ),
           SizedBox(height: 15.h),
           
           _buildAnimalTypeOption(
             context: context,
             title: TranslationService.instance.translate('lost_found.found_pet'),
             onTap: () => _navigateToAddAnimal(context, ReportType.found),
           ),
           SizedBox(height: 15.h),
           
           _buildAnimalTypeOption(
             context: context,
             title: TranslationService.instance.translate('adoption.adoption_pet'),
             onTap: () => _navigateToAddAnimal(context, ReportType.adoption),
           ),
           SizedBox(height: 15.h),
           
           _buildAnimalTypeOption(
             context: context,
             title: TranslationService.instance.translate('breeding.breeding_pet'),
             onTap: () => _navigateToAddAnimal(context, ReportType.breeding),
           ),
        ],
      ),
    );
  }

  Widget _buildAnimalTypeOption({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ThemeClass.of(context).secondaryColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),

          border: Border.all(
            color: ThemeClass.of(context).secondaryColor,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                title,
                style:TextStyleHelper.of(context).s18RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor)
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAnimal(BuildContext context, ReportType reportType) {
    // إغلاق bottom sheet أولاً
    Navigator.of(context).pop();
    
    // تحديد العنوان بناءً على نوع التقرير
    String title;
    switch (reportType) {
      case ReportType.lost:
        title = TranslationService.instance.translate('post_report.lost_pet_title');
        break;
      case ReportType.found:
        title = TranslationService.instance.translate('post_report.found_pet_title');
        break;
      case ReportType.adoption:
        title = TranslationService.instance.translate('post_report.adoption_pet_title');
        break;
      case ReportType.breeding:
        title = TranslationService.instance.translate('post_report.breeding_pet_title');
        break;
    }
    
    // التنقل إلى صفحة إضافة الحيوان مع تمرير النوع والعنوان
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnimalScreen(
          reportType: reportType,
          title: title,
        ),
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
    // لا routeName لأنه سيعرض bottom sheet
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
