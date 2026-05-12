import 'package:alifi/Modules/add_animal/add_animal_flow.dart';
import 'package:alifi/Utilities/bottom_sheet_helper.dart';
import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/core/Language/translation_service.dart';
import 'package:alifi/core/services/auth_service.dart';
import 'package:alifi/Utilities/dialog_helper.dart';
import 'package:alifi/Widgets/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Bottom sheet: three add flows (lost/found, adoption, breeding).
class AddAnimalEntrySheet extends StatelessWidget {
  const AddAnimalEntrySheet({super.key});

  static void show(BuildContext context) {
    BottomSheetHelper.bottomSheet(
      context: context,
      topBorderRadius: 20,
      widget: const AddAnimalEntrySheet(),
    );
  }

  void _openAdd(BuildContext context, AddAnimalFlow flow) {
    if (!AuthService.isAuthenticated) {
      Navigator.of(context).pop();
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: const LoginWidget(),
      );
      return;
    }
    Navigator.of(context).pop();
    context.pushNamed('addAnimal', extra: flow);
  }

  @override
  Widget build(BuildContext context) {
    final t = TranslationService.instance;

    return Container(
      decoration: BoxDecoration(
        color: ThemeClass.of(context).primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _option(
                context,
                title: t.translate('navigation.add_entry.lost_or_found'),
                onTap: () => _openAdd(context, AddAnimalFlow.lostOrFound),
              ),
              SizedBox(height: 12.h),
              _option(
                context,
                title: t.translate('navigation.add_entry.adoption'),
                onTap: () => _openAdd(context, AddAnimalFlow.adoption),
              ),
              SizedBox(height: 12.h),
              _option(
                context,
                title: t.translate('navigation.add_entry.breeding'),
                onTap: () => _openAdd(context, AddAnimalFlow.breeding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: ThemeClass.of(context).secondaryColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(
                    color: ThemeClass.of(context).backGroundColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
