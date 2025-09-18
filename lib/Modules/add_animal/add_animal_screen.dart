import 'package:alifi/Modules/add_animal/Widgets/add_animal_second_step.dart';
import 'package:alifi/Modules/add_animal/Widgets/add_animal_third_step.dart';
import 'package:alifi/Modules/add_animal/Widgets/add_animal_fourth_step.dart';
import 'package:alifi/Modules/add_animal/add_animal_controller.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/Widgets/bottom_navbar_widget.dart';
import 'package:alifi/Widgets/sliver_stepper_app_ba_widget.dart';
import 'package:alifi/Modules/add_animal/Widgets/add_animal_first_step.dart';
import 'package:alifi/generated/assets.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:state_extended/state_extended.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  _AddAnimalScreenState createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends StateX<AddAnimalScreen> {
  _AddAnimalScreenState() : super(controller: AddAnimalController()) {
    con = AddAnimalController();
  }
  late AddAnimalController con;

  @override
  void initState() {
    con.nameController = TextEditingController();
    con.typeController = TextEditingController();
    con.colorController = TextEditingController();
    con.activeStep = 0;
    super.initState();
  }


  @override
  void dispose() {
    con.nameController.dispose();
    con.typeController.dispose();
    con.colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: Gap(16.h),),
            SliverStepperAppBarWidget(
              activeStep: con.activeStep,
              steps: [
                EasyStep(
                  customStep: con.activeStep > 0
                    ? Icon(Icons.check, color: ThemeClass.of(context).backGroundColor, size: 20)
                    : Icon(Icons.photo_camera, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: 'Pictures',
                ),
                EasyStep(
                  customStep: con.activeStep > 1
                    ? Icon(Icons.check, color: ThemeClass.of(context).backGroundColor, size: 20)
                    : Icon(Icons.pets, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: 'Pet details',
                ),
                EasyStep(
                  customStep: con.activeStep > 2
                    ? Icon(Icons.check, color: ThemeClass.of(context).backGroundColor, size: 20)
                    : Icon(Icons.info, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: 'Contact Info',
                ),
                EasyStep(
                  customStep: con.activeStep > 3
                      ? Icon(Icons.check, color: ThemeClass.of(context).backGroundColor, size: 20)
                      : Icon(Icons.info, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: 'More Info',
                ),
              ],
              onStepReached: (step) {
                setState(() {
                  con.activeStep = step;
                });
              },
            ),
            SliverToBoxAdapter(child: Gap(16.h),),
            SliverToBoxAdapter(
              child: con.activeStep == 0? AddAnimalFourthStep(
                onNext: () {
                  setState(() {
                    con.activeStep++;
                  });
                },
                onBack: null, // First step, no back button
              ) : con.activeStep == 1? AddAnimalFirstStep(
                onNext: () {
                  setState(() {
                    con.activeStep++;
                  });
                },
                onBack: () {
                  setState(() {
                    con.activeStep--;
                  });
                },
              ) : con.activeStep == 2? AddAnimalSecondStep(
                onNext: () {
                  setState(() {
                    con.activeStep++;
                  });
                },
                onBack: () {
                  setState(() {
                    con.activeStep--;
                  });
                },
              ) : AddAnimalThirdStep(
                onDone: () {
                  // Handle form submission here
                  print("Form completed!");
                },
                onBack: () {
                  setState(() {
                    con.activeStep--;
                  });
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Image.asset(Assets.imagesAlifi2),
            )
          ],
        ),
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.lostFound,
        onTap: (selected) {
          // Handle navigation to other pages
          // You can add navigation logic here
        },
      ),
    );
  }
}
