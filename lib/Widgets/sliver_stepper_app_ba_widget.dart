import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Utilities/theme_helper.dart';

class SliverStepperAppBarWidget extends StatelessWidget {
  final int activeStep;
  final List<EasyStep>  steps;
  final Function(int) onStepReached;
  const SliverStepperAppBarWidget({super.key, required this.activeStep, required this.steps, required this.onStepReached});

  @override
  Widget build(BuildContext context) {
    return   SliverAppBar(
      backgroundColor: ThemeClass.of(context).backGroundColor,
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight:  70.h,
      centerTitle: true,
      leadingWidth: 0,
      leading: null,
      title: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
        child: Padding(
          padding: steps.length>3? EdgeInsets.zero:EdgeInsets.only(top: 40.h),
          child: EasyStepper(
            internalPadding: 0,
            fitWidth: true,
            activeStep: activeStep,
            disableScroll: true,
            steppingEnabled: false,
            lineStyle: LineStyle(
              activeLineColor: ThemeClass.of(context).primaryColor,
              unreachedLineColor: ThemeClass.of(context).secondaryColor,
              lineLength: 110.w,
              lineThickness: 1,
              lineSpace: 0,
            ),
            stepRadius: steps.length>3? 30.r: 16.r,
            unreachedStepBackgroundColor: ThemeClass.of(context).secondaryColor,
            activeStepBackgroundColor: ThemeClass.of(context).primaryColor,
            finishedStepBackgroundColor: ThemeClass.of(context).primaryColor,
            showStepBorder: false,
            steps: steps,
            onStepReached: onStepReached,
          ),
        ),
      ),
    );
  }
}
