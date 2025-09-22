import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Utilities/text_style_helper.dart';
import '../../../Widgets/custom_textfield_widget.dart';
import '../add_animal_controller.dart';
import 'package:alifi/core/Language/app_languages.dart';
import 'package:provider/provider.dart';

class AddAnimalThirdStep extends StatefulWidget {
  final VoidCallback? onDone;
  final VoidCallback? onBack;
  final AddAnimalController con;
  const AddAnimalThirdStep({Key? key, this.onDone, this.onBack, required this.con}) : super(key: key);

  @override
  State<AddAnimalThirdStep> createState() => _AddAnimalThirdStepState();
}

class _AddAnimalThirdStepState extends State<AddAnimalThirdStep> {


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      height: 520.h,
      decoration: BoxDecoration(
        color: ThemeClass.of(context).secondaryColor, // background color
        borderRadius: BorderRadius.circular(24.r), // rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.title'),
            style: TextStyleHelper.of(context).s36ItimTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
          ),
          const SizedBox(height: 30),

          // Distinctive Marks
          _buildTextField(widget.con.distinctiveMarksController, Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.distinctive_marks')),
          const SizedBox(height: 15),

          // Medical Status Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMedicalStatusButton(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.medical_status.healthy')),
              const SizedBox(width: 10),
              _buildMedicalStatusButton(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.medical_status.sick')),
            ],
          ),
          const SizedBox(height: 15),

          // Medical Status Buttons (Second Row)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMedicalStatusButton(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.medical_status.injured')),
              const SizedBox(width: 10),
              _buildMedicalStatusButton(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.medical_status.pregnant')),
            ],
          ),
          const SizedBox(height: 15),

          // Comments (Optional)
          CustomTextFieldWidget(
            width: 280.w,
            height: 80.h,
            controller: widget.con.commentsController,
            borderStyleFlag: 1,
            hint: Provider.of<AppLanguage>(context, listen: false).translate('add_animal.more_info.comments'),
            textInputType: TextInputType.multiline,
          ),

          const Spacer(),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF914C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                onPressed: () {
                  widget.onBack?.call();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 5),
                      Text(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.navigation.back')),
                    ],
                  ),
                ),
              ),
              
              // Next Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF914C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
                onPressed: () {
                  widget.onDone?.call();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.navigation.done')),
                      SizedBox(width: 5),
                      Icon(Icons.check, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return CustomTextFieldWidget(
      width: 280.w,
      height: 42.h,
      controller: controller,
      borderStyleFlag: 1,
      hint: hint,
      textInputType: TextInputType.text,
    );
  }

  Widget _buildMedicalStatusButton(String status) {
    final bool isSelected = widget.con.medicalStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.con.medicalStatus = status;
        });
      },
      child: Container(
        width: 120.w,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange.shade900 : Colors.grey,
          ),
        ),
      ),
    );
  }


} 