import 'package:alifi/Modules/add_animal/add_animal_flow.dart';
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
  /// From nav sheet: limits the step‑1 dropdown (lost/found, adoption pair, or fixed breeding).
  final AddAnimalFlow? flow;
  /// When null (and no [flow]), the user can choose any report category in step 1.
  final ReportType? reportType;
  final String? adoptionType; // 'seeking' or 'offering' (only for [ReportType.adoption])

  const AddAnimalScreen({
    super.key,
    this.flow,
    this.reportType,
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
    if (widget.flow == AddAnimalFlow.breeding) {
      con.reportType = ReportType.breeding;
      con.adoptionType = null;
    } else {
      con.reportType = widget.reportType;
      if (widget.adoptionType != null) {
        con.adoptionType = widget.adoptionType;
      } else if (widget.reportType == ReportType.adoption) {
        con.adoptionType = 'offering';
      }
    }
  }

  bool get _seekingAdoption =>
      con.reportType == ReportType.adoption && con.adoptionType == 'seeking';

  bool _validateStep0() {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    final categoryLabel =
        appLanguage.translate('add_animal.pet_details.report_category.label');
    final req = appLanguage.translate('validation.required_field');

    if (widget.flow == AddAnimalFlow.lostOrFound) {
      if (con.reportType != ReportType.lost && con.reportType != ReportType.found) {
        _showErrorDialog('$req: $categoryLabel');
        return false;
      }
    } else if (widget.flow == AddAnimalFlow.adoption) {
      if (con.reportType != ReportType.adoption ||
          con.adoptionType == null ||
          con.adoptionType!.isEmpty) {
        _showErrorDialog('$req: $categoryLabel');
        return false;
      }
    } else if (widget.flow == null) {
      if (widget.reportType == null && con.reportType == null) {
        _showErrorDialog('$req: $categoryLabel');
        return false;
      }
      if (con.reportType == ReportType.adoption &&
          (con.adoptionType == null || con.adoptionType!.isEmpty)) {
        _showErrorDialog('$req: $categoryLabel');
        return false;
      }
    }

    if (con.selectedPetType == null || con.selectedPetType!.isEmpty) {
      _showErrorDialog(
        '$req: ${appLanguage.translate('add_animal.pet_details.pet_type')}',
      );
      return false;
    }
    return true;
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
                if (!_seekingAdoption)
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
                flow: widget.flow,
                categorySelectionLocked: widget.reportType != null ||
                    widget.flow == AddAnimalFlow.breeding,
                onReportCategoryChanged: () => setState(() {}),
                onNext: () {
                  if (!_validateStep0()) return;

                  setState(() {
                    if (_seekingAdoption) {
                      _handleFormSubmission();
                    } else {
                      con.activeStep++;
                    }
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
      if (con.selectedPetType == null || con.selectedPetType!.isEmpty) {
        final appLanguage = Provider.of<AppLanguage>(context, listen: false);
        _showErrorDialog(appLanguage.translate('validation.required_field') + ': ' + appLanguage.translate('add_animal.pet_details.pet_type'));
        return;
      }
      
      if (!_seekingAdoption) {
        if (con.selectedImages.isEmpty) {
          final appLanguage = Provider.of<AppLanguage>(context, listen: false);
          _showErrorDialog(appLanguage.translate('post_report.photo_required'));
          return;
        }
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
    final t = Provider.of<AppLanguage>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.translate('common.success')),
          content: Text(t.translate('post_report.success')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
                con.resetFields(); // Reset form
              },
              child: Text(t.translate('common.ok')),
            ),
          ],
        );
      },
    );
  }
}
