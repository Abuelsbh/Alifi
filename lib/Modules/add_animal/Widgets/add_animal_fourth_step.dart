import 'dart:io';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../../Utilities/text_style_helper.dart';
import '../add_animal_controller.dart';
import 'package:alifi/core/Language/app_languages.dart';
import 'package:provider/provider.dart';

class AddAnimalFourthStep extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final AddAnimalController con;
  const AddAnimalFourthStep({Key? key, this.onNext, this.onBack, required this.con}) : super(key: key);

  @override
  State<AddAnimalFourthStep> createState() => _AddAnimalFourthStepState();
}

class _AddAnimalFourthStepState extends State<AddAnimalFourthStep> {
  final ImagePicker _picker = ImagePicker();

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
            Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.title'),
            style: TextStyleHelper.of(context).s36ItimTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
          ),
          const SizedBox(height: 30),

          // Pictures Container
          _buildPicturesContainer(),
          
          const SizedBox(height: 15),

          // Requirements Text
          _buildRequirementsText(),

          const Spacer(),

          // Navigation Button
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
          ),
        ],
      ),
    );
  }

  Widget _buildPicturesContainer() {
    return Container(
      width: 280.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: widget.con.selectedImages.isEmpty
        ? _buildEmptyImageContainer()
        : _buildImageGallery(),
    );
  }

  Widget _buildEmptyImageContainer() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Upload Cloud Icon
            SvgPicture.asset(
              Assets.iconsUpload,
              height: 48.h,
              width: 48.w,
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      children: [
        // Current Image Display
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            image: DecorationImage(
              image: FileImage(File(widget.con.selectedImages[widget.con.currentImageIndex])),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Navigation Arrows
        if (widget.con.selectedImages.length > 1) ...[
          // Left Arrow
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _previousImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFFFF914C),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          
          // Right Arrow
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _nextImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFF914C),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
        
        // Add More Button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _pickImages,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF914C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        
        // Delete Button
        Positioned(
          top: 10,
          left: 10,
          child: GestureDetector(
            onTap: _deleteCurrentImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsText() {
    return Column(
      children: [
        Text(
          Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.requirements'),
          style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        ),
        const SizedBox(height: 5),
        Text(
          Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.requirement_1'),
          style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        ),
        const SizedBox(height: 5),
        Text(
          Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.requirement_2'),
          style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        ),
        const SizedBox(height: 5),
        Text(
          Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.requirement_3'),
          style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        ),
        const SizedBox(height: 5),
        Text(
          Provider.of<AppLanguage>(context, listen: false).translate('add_animal.pictures.requirement_4'),
          style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
        ),
      ],
    );
  }

  void _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        // Add new images to existing ones, but limit to 10 total
        for (var image in images) {
          if (widget.con.selectedImages.length < 10) {
            widget.con.selectedImages.add(image.path);
          }
        }
        if (widget.con.selectedImages.isNotEmpty && widget.con.currentImageIndex >= widget.con.selectedImages.length) {
          widget.con.currentImageIndex = 0;
        }
      });
    }
  }

  void _previousImage() {
    setState(() {
      if (widget.con.currentImageIndex > 0) {
        widget.con.currentImageIndex--;
      } else {
        widget.con.currentImageIndex = widget.con.selectedImages.length - 1;
      }
    });
  }

  void _nextImage() {
    setState(() {
      if (widget.con.currentImageIndex < widget.con.selectedImages.length - 1) {
        widget.con.currentImageIndex++;
      } else {
        widget.con.currentImageIndex = 0;
      }
    });
  }

  void _deleteCurrentImage() {
    if (widget.con.selectedImages.isNotEmpty) {
      setState(() {
        widget.con.selectedImages.removeAt(widget.con.currentImageIndex);
        
        // Adjust current index after deletion
        if (widget.con.selectedImages.isEmpty) {
          widget.con.currentImageIndex = 0;
        } else if (widget.con.currentImageIndex >= widget.con.selectedImages.length) {
          widget.con.currentImageIndex = widget.con.selectedImages.length - 1;
        }
      });
    }
  }
} 