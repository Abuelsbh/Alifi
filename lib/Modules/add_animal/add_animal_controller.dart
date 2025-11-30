import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:state_extended/state_extended.dart';
import 'package:alifi/Models/pet_report_model.dart';
import 'package:alifi/core/services/pet_reports_service.dart';
import 'package:alifi/core/services/auth_service.dart';

class AddAnimalController extends StateXController {
  AddAnimalController();

  bool loading = false;
  int activeStep = 0;
  ReportType? reportType;
  
  // Additional fields for different report types
  double adoptionFee = 0.0;
  double breedingFee = 0.0;
  double reward = 0.0;
  
  bool isVaccinated = false;
  bool isNeutered = false;
  bool isUrgent = false;
  bool hasBreedingExperience = false;
  bool isRegistered = false;
  bool goodWithKids = true;
  bool goodWithPets = true;
  bool isHouseTrained = false;
  
  DateTime? lostDate;
  DateTime? foundDate;
  
  late TextEditingController reasonController;
  late TextEditingController specialNeedsController;
  late TextEditingController breedingHistoryController;
  late TextEditingController registrationNumberController;
  late TextEditingController microchipIdController;
  late TextEditingController vetContactController;
  
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
    
    // Initialize additional controllers
    reasonController = TextEditingController();
    specialNeedsController = TextEditingController();
    breedingHistoryController = TextEditingController();
    registrationNumberController = TextEditingController();
    microchipIdController = TextEditingController();
    vetContactController = TextEditingController();
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
    
    // Dispose additional controllers
    reasonController.dispose();
    specialNeedsController.dispose();
    breedingHistoryController.dispose();
    registrationNumberController.dispose();
    microchipIdController.dispose();
    vetContactController.dispose();
    
    super.dispose();
  }

  // Reset all fields
  void resetFields() {
    activeStep = 0;
    
    // Reset Step 1
    nameController.clear();
    typeController.clear();
    colorController.clear();
    age = 1;
    ageType = "Year";
    gender = "Male";
    
    // Reset Step 2
    addressController.clear();
    contactNameController.clear();
    phoneController.clear();
    emailController.clear();
    locationLinkController.clear();
    
    // Reset Step 3
    distinctiveMarksController.clear();
    commentsController.clear();
    medicalStatus = "Healthy";
    
    // Reset Step 4
    selectedImages.clear();
    currentImageIndex = 0;
    
    // Reset additional fields
    adoptionFee = 0.0;
    breedingFee = 0.0;
    reward = 0.0;
    isVaccinated = false;
    isNeutered = false;
    isUrgent = false;
    hasBreedingExperience = false;
    isRegistered = false;
    goodWithKids = true;
    goodWithPets = true;
    isHouseTrained = false;
    lostDate = null;
    foundDate = null;
    
    reasonController.clear();
    specialNeedsController.clear();
    breedingHistoryController.clear();
    registrationNumberController.clear();
    microchipIdController.clear();
    vetContactController.clear();
  }

  // Submit animal report to Firebase
  Future<String?> submitAnimalReport() async {
    try {
      print('🚀 Starting submitAnimalReport');
      loading = true;
      setState(() {});

      final user = AuthService.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }
      print('✅ User authenticated: ${user.uid}');

      // Basic validation
      if (nameController.text.trim().isEmpty) {
        throw Exception('Pet name is required');
      }
      
      if (typeController.text.trim().isEmpty) {
        throw Exception('Pet type is required');
      }
      
      if (selectedImages.isEmpty) {
        throw Exception('At least one image is required');
      }

      // Get user profile for contact info
      final userProfile = await AuthService.getUserProfile(user.uid);
      final userName = userProfile?['username'] ?? userProfile?['name'] ?? AuthService.userDisplayName ?? '';
      final userPhone = userProfile?['phoneNumber'] ?? userProfile?['phone'] ?? '';
      final userEmail = userProfile?['email'] ?? AuthService.userEmail ?? '';

      // Convert image paths to File objects
      final List<File> imageFiles = selectedImages.map((path) => File(path)).toList();

      // Prepare base report data
      final Map<String, dynamic> baseReport = {
        'userId': user.uid,
        'petName': nameController.text.trim(),
        'petType': typeController.text.trim(),
        'breed': '', // Could be extracted from type or added as separate field
        'age': age,
        'ageType': ageType,
        'gender': gender,
        'color': colorController.text.trim(),
        'description': commentsController.text.trim(),
        'distinguishingMarks': distinctiveMarksController.text.trim(),
        'medicalStatus': medicalStatus,
        'contactName': userName,
        'contactPhone': userPhone,
        'contactEmail': userEmail,
        'address': '',
        'locationLink': '',
        'coordinates': null, // Could be added later with location service
        'area': '', // Could be extracted from address
        'landmark': '', // Could be extracted from address
      };

      String? reportId;

      print('📝 Report data prepared, type: $reportType');
      
      // Submit based on report type
      switch (reportType) {
        case ReportType.lost:
          print('📤 Submitting lost pet report');
          baseReport.addAll({
            'lastSeenDate': lostDate ?? DateTime.now(),
            'isUrgent': isUrgent,
            'reward': reward,
            'preferredContact': 'phone',
          });
          reportId = await PetReportsService.createLostPetReport(
            report: baseReport,
            images: imageFiles,
          );
          break;

        case ReportType.found:
          baseReport.addAll({
            'foundDate': foundDate ?? DateTime.now(),
            'isInShelter': false,
            'shelterInfo': '',
            'temperament': medicalStatus, // Map medical status to temperament
            'healthStatus': medicalStatus,
            'hasCollar': false,
            'collarDescription': '',
            'preferredContact': 'phone',
          });
          reportId = await PetReportsService.createFoundPetReport(
            report: baseReport,
            images: imageFiles,
          );
          break;

        case ReportType.adoption:
          baseReport.addAll({
            'adoptionFee': adoptionFee,
            'reason': reasonController.text.trim(),
            'specialNeeds': specialNeedsController.text.trim(),
            'isVaccinated': isVaccinated,
            'isNeutered': isNeutered,
            'goodWithKids': goodWithKids,
            'goodWithPets': goodWithPets,
            'isHouseTrained': isHouseTrained,
            'weight': 0.0, // Could be added as a field
            'microchipId': microchipIdController.text.trim(),
            'preferredHomeType': '',
            'medicalHistory': [],
            'temperament': medicalStatus,
            'healthStatus': medicalStatus,
            'preferredContact': 'phone',
          });
          reportId = await PetReportsService.createAdoptionPetReport(
            report: baseReport,
            images: imageFiles,
          );
          break;

        case ReportType.breeding:
          baseReport.addAll({
            'breedingFee': breedingFee,
            'specialRequirements': specialNeedsController.text.trim(),
            'hasBreedingExperience': hasBreedingExperience,
            'breedingHistory': breedingHistoryController.text.trim(),
            'isRegistered': isRegistered,
            'registrationNumber': registrationNumberController.text.trim(),
            'certifications': [],
            'breedingGoals': reasonController.text.trim(),
            'availabilityPeriod': '',
            'willTravel': false,
            'maxTravelDistance': 0,
            'offspring': '',
            'previousOffspring': [],
            'veterinarianContact': vetContactController.text.trim(),
            'preferredContact': 'phone',
          });
          reportId = await PetReportsService.createBreedingPetReport(
            report: baseReport,
            images: imageFiles,
          );
          break;

        default:
          throw Exception('Invalid report type');
      }

      print('✅ Report submitted successfully: $reportId');
      loading = false;
      setState(() {});
      
      return reportId;
    } catch (e) {
      print('❌ Error submitting report: $e');
      loading = false;
      setState(() {});
      throw Exception('Failed to submit report: $e');
    }
  }
}
