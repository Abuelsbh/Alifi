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
import 'package:alifi/Models/pet_report_model.dart';
import 'package:alifi/core/Language/app_languages.dart';
import 'package:provider/provider.dart';


class AddAnimalScreen extends StatefulWidget {
  final ReportType reportType;
  final String title;
  final String? adoptionType; // 'seeking' or 'offering'
  
  const AddAnimalScreen({
    super.key, 
    required this.reportType,
    required this.title,
    this.adoptionType,
  });

  @override
  _AddAnimalScreenState createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends StateX<AddAnimalScreen> {
  late AddAnimalController con;
  
  _AddAnimalScreenState() : super(controller: AddAnimalController()) {
    con = controller as AddAnimalController;
  }

  @override
  void initState() {
    super.initState();
    con.activeStep = 0;
    con.reportType = widget.reportType;
    if (widget.adoptionType != null) {
      con.adoptionType = widget.adoptionType;
    }
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
                    : Icon(Icons.pets, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: Provider.of<AppLanguage>(context, listen: false).translate('add_animal.step_titles.pet_details'),
                ),
                EasyStep(
                  customStep: con.activeStep > 1
                    ? Icon(Icons.check, color: ThemeClass.of(context).backGroundColor, size: 20)
                    : Icon(Icons.photo_camera, color: ThemeClass.of(context).primaryColor, size: 20),
                  title: Provider.of<AppLanguage>(context, listen: false).translate('add_animal.step_titles.pictures'),
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
              child: con.activeStep == 0? AddAnimalFirstStep(
                con: con,
                onNext: () {
                  setState(() {
                    con.activeStep++;
                  });
                },
                onBack: null, // First step, no back button
              ) : AddAnimalFourthStep(
                con: con,
                onNext: () async {
                  await _handleFormSubmission();
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
      ),
    );
  }

  Future<void> _handleFormSubmission() async {
    try {
      // Validation
      if (con.nameController.text.trim().isEmpty) {
        _showErrorDialog('يرجى إدخال اسم الحيوان');
        return;
      }
      
      if (con.typeController.text.trim().isEmpty) {
        _showErrorDialog('يرجى إدخال نوع الحيوان');
        return;
      }
      
      if (con.selectedImages.isEmpty) {
        _showErrorDialog('يرجى إضافة صورة واحدة على الأقل');
        return;
      }

      // Show loading dialog
      _showLoadingDialog();

      // Submit the report
      final reportId = await con.submitAnimalReport();
      
      // Hide loading dialog
      Navigator.of(context).pop();

      if (reportId != null) {
        // Show success dialog
        _showSuccessDialog();
      } else {
        _showErrorDialog('حدث خطأ أثناء إرسال البيانات');
      }
    } catch (e) {
      // Hide loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('حدث خطأ: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تم بنجاح'),
          content: Text('تم إضافة ${_getReportTypeText()} بنجاح!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
                con.resetFields(); // Reset form
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  String _getReportTypeText() {
    switch (widget.reportType) {
      case ReportType.lost:
        return 'الحيوان المفقود';
      case ReportType.found:
        return 'الحيوان الموجود';
      case ReportType.adoption:
        return 'الحيوان للتبني';
      case ReportType.breeding:
        return 'الحيوان للتزاوج';
      default:
        return 'الحيوان';
    }
  }
}
