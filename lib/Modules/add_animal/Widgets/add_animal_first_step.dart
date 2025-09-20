import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/core/Font/font_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Widgets/custom_textfield_widget.dart';
import '../add_animal_controller.dart';

class AddAnimalFirstStep extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final AddAnimalController con;
  const AddAnimalFirstStep({Key? key, required this.onNext, this.onBack, required this.con}) : super(key: key);

  @override
  State<AddAnimalFirstStep> createState() => _AddAnimalFirstStepState();
}

class _AddAnimalFirstStepState extends State<AddAnimalFirstStep> {

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
            "Pet Details",
            style: TextStyleHelper.of(context).s36ItimTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
          ),
          const SizedBox(height: 30),

          // Pet Name
          _buildTextField(widget.con.nameController, "Pet Name"),
          const SizedBox(height: 15),

          // Pet Type
          _buildTextField(widget.con.typeController, "Pet Type"),
          const SizedBox(height: 15),

          // Age Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAgeSelector(),
              const SizedBox(width: 10),
              Column(
                children: [
                  _buildToggleButton("Year"),
                  const SizedBox(height: 5),
                  _buildToggleButton("Month"),
                ],
              )
            ],
          ),
          const SizedBox(height: 15),

          // Colour
          _buildTextField(widget.con.colorController, "Colour"),
          const SizedBox(height: 15),

          // Gender
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderButton("Male"),
              const SizedBox(width: 10),
              _buildGenderButton("Female"),
            ],
          ),

          const Spacer(),

          // Navigation Buttons
          widget.onBack != null ? Row(
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
          ) : Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF914C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.white),
                ),
              ),
              onPressed:() {
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
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return CustomTextFieldWidget(
      width: 240.w,
      height: 39.h,
      controller: controller,
      borderStyleFlag: 1,
      hint: hint,
      textInputType: TextInputType.emailAddress,
    );
  }

  Widget _buildAgeSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.orange),
                onPressed: () {
                  setState(() {
                    if (widget.con.age > 0) widget.con.age--;
                  });
                },
              ),
              Text(
                "${widget.con.age}",
                style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(color: Colors.black),

              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.orange),
                onPressed: () {
                  setState(() {
                    widget.con.age++;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String type) {
    final bool isSelected = widget.con.ageType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.con.ageType = type;
        });
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.center,
        child: Text(
          type,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange.shade900 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String value) {
    final bool isSelected = widget.con.gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.con.gender = value;
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
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange.shade900 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
