import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Widgets/custom_textfield_widget.dart';
import '../add_animal_controller.dart';

class AddAnimalThirdStep extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  
  const AddAnimalThirdStep({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<AddAnimalThirdStep> createState() => _AddAnimalThirdStepState();
}

class _AddAnimalThirdStepState extends State<AddAnimalThirdStep> {
  AddAnimalController con = AddAnimalController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      height: 520.h,
      decoration: BoxDecoration(
        color: ThemeClass.of(context).primaryColor, // background color
        borderRadius: BorderRadius.circular(24.r), // rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "More Info.",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),

          // Distinctive Marks
          _buildTextField(con.distinctiveMarksController, "Distinctive Marks"),
          const SizedBox(height: 15),

          // Medical Status Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMedicalStatusButton("Healthy"),
              const SizedBox(width: 10),
              _buildMedicalStatusButton("Sick"),
            ],
          ),
          const SizedBox(height: 15),

          // Medical Status Buttons (Second Row)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMedicalStatusButton("Injured"),
              const SizedBox(width: 10),
              _buildMedicalStatusButton("Pregnant"),
            ],
          ),
          const SizedBox(height: 15),

          // Comments (Optional)
          CustomTextFieldWidget(
            width: 280.w,
            height: 80.h,
            controller: con.commentsController,
            borderStyleFlag: 1,
            hint: "Comments",
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 5),
                      Text("Back"),
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
                  widget.onNext?.call();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Next"),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 18),
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
    final bool isSelected = con.medicalStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          con.medicalStatus = status;
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