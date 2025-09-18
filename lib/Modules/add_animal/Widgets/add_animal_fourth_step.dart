import 'dart:io';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../add_animal_controller.dart';

class AddAnimalFourthStep extends StatefulWidget {
  final VoidCallback? onDone;
  final VoidCallback? onBack;
  
  const AddAnimalFourthStep({Key? key, this.onDone, this.onBack}) : super(key: key);

  @override
  State<AddAnimalFourthStep> createState() => _AddAnimalFourthStepState();
}

class _AddAnimalFourthStepState extends State<AddAnimalFourthStep> {
  AddAnimalController con = AddAnimalController();
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
          const Text(
            "Pictures",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),

          // Pictures Container
          _buildPicturesContainer(),
          
          const SizedBox(height: 15),

          // Requirements Text
          _buildRequirementsText(),

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
              
              // Done Button
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Done"),
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

  Widget _buildPicturesContainer() {
    return Container(
      width: 280.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: con.selectedImages.isEmpty 
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF914C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: Color(0xFFFF914C),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Tap to upload photos",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
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
              image: FileImage(File(con.selectedImages[con.currentImageIndex])),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Navigation Arrows
        if (con.selectedImages.length > 1) ...[
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
      ],
    );
  }

  Widget _buildRequirementsText() {
    return Column(
      children: [
        Text(
          "It must be in size 500*500 Pix",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "At least 2 pic. & Maximum 10 Pic",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "the pic must contain the real pet",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
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
          if (con.selectedImages.length < 10) {
            con.selectedImages.add(image.path);
          }
        }
        if (con.selectedImages.isNotEmpty && con.currentImageIndex >= con.selectedImages.length) {
          con.currentImageIndex = 0;
        }
      });
    }
  }

  void _previousImage() {
    setState(() {
      if (con.currentImageIndex > 0) {
        con.currentImageIndex--;
      } else {
        con.currentImageIndex = con.selectedImages.length - 1;
      }
    });
  }

  void _nextImage() {
    setState(() {
      if (con.currentImageIndex < con.selectedImages.length - 1) {
        con.currentImageIndex++;
      } else {
        con.currentImageIndex = 0;
      }
    });
  }
} 