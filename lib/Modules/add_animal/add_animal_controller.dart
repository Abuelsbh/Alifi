import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:state_extended/state_extended.dart';

class AddAnimalController extends StateXController {

  /// singleton
  factory AddAnimalController() {
    _this ??= AddAnimalController._();
    return _this!;
  }

  static AddAnimalController? _this;

  AddAnimalController._();

  bool loading = false;
  int activeStep = 0;
  
  // Step 1 Controllers
  late TextEditingController nameController;
  late TextEditingController typeController;
  late TextEditingController colorController;

  // Step 2 Controllers
  late TextEditingController addressController;
  late TextEditingController contactNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController locationLinkController;

  // Step 3 Controllers
  late TextEditingController distinctiveMarksController;
  late TextEditingController commentsController;

  int age = 1;
  String ageType = "Year";
  String gender = "Male";
  String medicalStatus = "Healthy";
  
  // Step 4 - Images
  List<String> selectedImages = [];
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize Step 1 Controllers
    nameController = TextEditingController();
    typeController = TextEditingController();
    colorController = TextEditingController();
    
    // Initialize Step 2 Controllers
    addressController = TextEditingController();
    contactNameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    locationLinkController = TextEditingController();

    // Initialize Step 3 Controllers
    distinctiveMarksController = TextEditingController();
    commentsController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose Step 1 Controllers
    nameController.dispose();
    typeController.dispose();
    colorController.dispose();
    
    // Dispose Step 2 Controllers
    addressController.dispose();
    contactNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationLinkController.dispose();

    // Dispose Step 3 Controllers
    distinctiveMarksController.dispose();
    commentsController.dispose();
    
    super.dispose();
  }
}
