import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../Widgets/custom_textfield_widget.dart';
import '../add_animal_controller.dart';
import 'package:alifi/core/Language/app_languages.dart';
import 'package:provider/provider.dart';
import 'package:alifi/Utilities/constants.dart';
import 'package:alifi/Models/pet_report_model.dart';
import 'package:alifi/Modules/add_animal/add_animal_flow.dart';

class AddAnimalFirstStep extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final AddAnimalController con;
  final AddAnimalFlow? flow;

  /// When true, [con.reportType] was set by the parent (e.g. breeding-only flow).
  final bool categorySelectionLocked;
  final VoidCallback? onReportCategoryChanged;

  const AddAnimalFirstStep({
    Key? key,
    required this.onNext,
    this.onBack,
    required this.con,
    this.flow,
    this.categorySelectionLocked = false,
    this.onReportCategoryChanged,
  }) : super(key: key);

  @override
  State<AddAnimalFirstStep> createState() => _AddAnimalFirstStepState();
}

class _AddAnimalFirstStepState extends State<AddAnimalFirstStep> {
  static const List<String> _allCategoryIds = [
    'lost',
    'found',
    'adoption_seeking',
    'adoption_offering',
    'breeding',
  ];

  List<String> get _allowedCategoryIds {
    switch (widget.flow) {
      case AddAnimalFlow.lostOrFound:
        return const ['lost', 'found'];
      case AddAnimalFlow.adoption:
        return const ['adoption_seeking', 'adoption_offering'];
      case AddAnimalFlow.breeding:
        return const [];
      case null:
        return _allCategoryIds;
    }
  }

  String? _categoryIdFromCon() {
    final id = _rawCategoryIdFromCon();
    if (id != null && !_allowedCategoryIds.contains(id)) {
      return null;
    }
    return id;
  }

  String? _rawCategoryIdFromCon() {
    switch (widget.con.reportType) {
      case ReportType.lost:
        return 'lost';
      case ReportType.found:
        return 'found';
      case ReportType.adoption:
        return widget.con.adoptionType == 'seeking'
            ? 'adoption_seeking'
            : 'adoption_offering';
      case ReportType.breeding:
        return 'breeding';
      default:
        return null;
    }
  }

  void _applyCategoryId(String? id) {
    switch (id) {
      case 'lost':
        widget.con.reportType = ReportType.lost;
        widget.con.adoptionType = null;
        break;
      case 'found':
        widget.con.reportType = ReportType.found;
        widget.con.adoptionType = null;
        break;
      case 'adoption_offering':
        widget.con.reportType = ReportType.adoption;
        widget.con.adoptionType = 'offering';
        break;
      case 'adoption_seeking':
        widget.con.reportType = ReportType.adoption;
        widget.con.adoptionType = 'seeking';
        break;
      case 'breeding':
        widget.con.reportType = ReportType.breeding;
        widget.con.adoptionType = null;
        break;
      default:
        widget.con.reportType = null;
        widget.con.adoptionType = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      constraints: BoxConstraints(minHeight: 520.h),
      decoration: BoxDecoration(
        color: ThemeClass.of(context).secondaryColor, // background color
        borderRadius: BorderRadius.circular(24.r), // rounded corners
      ),
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.title'),
            style: TextStyleHelper.of(context).s36ItimTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
          ),
          const SizedBox(height: 30),

          if (!widget.categorySelectionLocked) ...[
            _buildReportCategoryDropdown(),
            const SizedBox(height: 15),
          ],

          // Title Field
          _buildTextField(widget.con.titleController, Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.title_field')),
          const SizedBox(height: 15),

          // Pet Type Dropdown
          _buildPetTypeDropdown(),
          const SizedBox(height: 15),

          // Colour
          _buildTextField(widget.con.colorController, Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.color')),
          const SizedBox(height: 15),

          // Gender
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderButton('Male', Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.male')),
              const SizedBox(width: 10),
              _buildGenderButton('Female', Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.female')),
              const SizedBox(width: 10),
              _buildGenderButton('Unknown', Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.unknown')),
            ],
          ),
          const SizedBox(height: 15),

          // Description
          _buildDescriptionField(),

          SizedBox(height: 24.h),

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
                  widget.onNext?.call();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.navigation.next')),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Provider.of<AppLanguage>(context, listen: false).translate('add_animal.navigation.next')),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildReportCategoryDropdown() {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    final hintStyle =
        TextStyleHelper.of(context).s14RegTextStyle.copyWith(color: Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          appLanguage.translate('add_animal.pet_details.report_category.label'),
          style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(
                color: ThemeClass.of(context).backGroundColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: 240.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categoryIdFromCon(),
              isExpanded: true,
              hint: Text(
                appLanguage.translate('add_animal.pet_details.report_category.hint'),
                style: hintStyle,
              ),
              items: _allowedCategoryIds.map((id) {
                final label = appLanguage.translate(
                  'add_animal.pet_details.report_category.$id',
                );
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    label,
                    style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(
                          color: Colors.black,
                        ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _applyCategoryId(newValue);
                });
                widget.onReportCategoryChanged?.call();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return CustomTextFieldWidget(
      width: 240.w,
      height: 39.h,
      controller: controller,
      borderStyleFlag: 1,
      hint: hint,
      textInputType: TextInputType.text,
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      width: 240.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: widget.con.descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pet_details.description_hint'),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        ),
        style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(color: Colors.black),
      ),
    );
  }

  Widget _buildPetTypeDropdown() {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    final petTypes = AppConstants.petTypes;
    
    // Get translated pet types
    List<String> translatedTypes = petTypes.map((type) {
      String key = type.toLowerCase().replaceAll(' ', '_');
      return appLanguage.translate('add_animal.pet_details.animal_types.$key');
    }).toList();
    
    return Container(
      width: 240.w,
      height: 39.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.con.selectedPetType,
          isExpanded: true,
          hint: Text(
            appLanguage.translate('add_animal.pet_details.select_pet_type'),
            style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(color: Colors.grey),
          ),
          items: petTypes.asMap().entries.map((entry) {
            int index = entry.key;
            String originalType = entry.value;
            String translatedType = translatedTypes[index];
            return DropdownMenuItem<String>(
              value: originalType,
              child: Text(
                translatedType,
                style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              widget.con.selectedPetType = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildGenderButton(String genderKey, String displayText) {
    final bool isSelected = widget.con.gender == genderKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.con.gender = genderKey;
        });
      },
      child: Container(
        width: 100.w,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade200 : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          displayText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange.shade900 : Colors.grey,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
