import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Utilities/text_style_helper.dart';
import '../../../Widgets/custom_textfield_widget.dart';
import '../add_animal_controller.dart';

class AddAnimalSecondStep extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final AddAnimalController con;
  const AddAnimalSecondStep({Key? key, this.onNext, this.onBack, required this.con}) : super(key: key);

  @override
  State<AddAnimalSecondStep> createState() => _AddAnimalSecondStepState();
}

class _AddAnimalSecondStepState extends State<AddAnimalSecondStep> {

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
          Text(
            "Contact Info.",
            style: TextStyleHelper.of(context).s36ItimTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
          ),
          const SizedBox(height: 30),

          // Address
          _buildTextField(widget.con.addressController, "Address"),
          const SizedBox(height: 15),

          // Contact Name
          _buildTextField(widget.con.contactNameController, "Contact Name"),
          const SizedBox(height: 15),

          // Phone Number
          _buildPhoneField(),
          const SizedBox(height: 15),

          // Email
          _buildTextField(widget.con.emailController, "Email"),
          const SizedBox(height: 15),

          _buildTextField(widget.con.locationLinkController, "Location Link"),

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
                  child: Row(
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
      textInputType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Country Code
        Container(
          width: 80.w,
          height: 42.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Center(
            child: Text(
              "+966",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // Phone Number
        CustomTextFieldWidget(
          width: 190.w,
          height: 42.h,
          controller: widget.con.phoneController,
          borderStyleFlag: 1,
          hint: "Phone No.",
          textInputType: TextInputType.phone,
        ),
      ],
    );
  }
}
