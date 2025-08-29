import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../Widgets/custom_button.dart';

import '../../../Widgets/translated_custom_button.dart' hide ButtonType;
import '../../../Widgets/translated_text.dart';
import '../../../core/services/location_service.dart';
import 'lost_found_screen.dart';

class PostReportScreen extends StatefulWidget {
  final ReportType reportType;

  const PostReportScreen({
    super.key,
    required this.reportType,
  });

  @override
  State<PostReportScreen> createState() => _PostReportScreenState();
}

class _PostReportScreenState extends State<PostReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final _locationService = LocationService();
  
  // Controllers
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _ageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Form data
  String _selectedPetType = 'Dog';
  String _selectedGender = 'Male';
  int _age = 1;
  DateTime _dateLost = DateTime.now();
  String _address = '';
  GeoPoint? _location;
  List<File> _photos = [];
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  
  // Enhanced form fields
  bool _isUrgent = false;
  double _reward = 0;
  String _contactEmail = '';
  String _preferredContact = 'phone';
  String _distinguishingMarks = '';
  String _personality = '';
  String _medicalConditions = '';
  String _shelterInfo = '';
  bool _isInShelter = false;
  bool _hasCollar = false;
  String _collarDescription = '';
  String _healthStatus = 'جيد';
  String _temperament = 'ودود';
  String _area = '';
  String _landmark = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final geoPoint = _locationService.positionToGeoPoint(position);
        final address = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        setState(() {
          _location = geoPoint;
          _address = address;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!AuthService.isAuthenticated) {
        throw Exception('Please login to submit a report');
      }

      final userId = AuthService.userId!;
      
      // Enhanced report data with all new fields
      final reportData = {
        'userId': userId,
        'petType': _selectedPetType,
        'breed': _breedController.text,
        'color': _colorController.text,
        'description': _descriptionController.text,
        'coordinates': _location ?? const GeoPoint(0, 0),
        'contactPhone': _contactPhoneController.text,
        'contactEmail': _contactEmail,
        'contactName': _contactNameController.text,
        'preferredContact': _preferredContact,
        'distinguishingMarks': _distinguishingMarks,
        'area': _area,
        'landmark': _landmark,
        'size': _ageController.text.isNotEmpty ? _ageController.text : 'متوسط',
        'isActive': true,
      };

      if (widget.reportType == ReportType.lost) {
        // Enhanced lost pet report
        reportData.addAll({
          'petName': _petNameController.text,
          'age': _age.toString(),
          'gender': _selectedGender,
          'lastSeenDate': _dateLost,
          'lastSeenLocation': _address,
          'isUrgent': _isUrgent,
          'reward': _reward,
          'personality': _personality,
          'medicalConditions': _medicalConditions,
        });
        
        print('📤 Submitting lost pet report...');
        await PetReportsService.createLostPetReport(
          report: reportData,
          images: _photos,
        );
      } else {
        // Enhanced found pet report
        reportData.addAll({
          'foundDate': _dateLost,
          'foundLocation': _address,
          'approximateAge': _ageController.text.isNotEmpty ? _ageController.text : 'غير محدد',
          'gender': _selectedGender,
          'temperament': _temperament,
          'healthStatus': _healthStatus,
          'hasCollar': _hasCollar,
          'collarDescription': _collarDescription,
          'isInShelter': _isInShelter,
          'shelterInfo': _shelterInfo,
        });
        
        print('📤 Submitting found pet report...');
        await PetReportsService.createFoundPetReport(
          report: reportData,
          images: _photos,
        );
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    widget.reportType == ReportType.lost 
                      ? 'تم نشر تقرير الحيوان المفقود بنجاح! سيتم عرضه للمجتمع للمساعدة في العثور على حيوانك الأليف.'
                      : 'تم نشر تقرير الحيوان الموجود بنجاح! سيتم عرضه لأصحاب الحيوانات المفقودة.',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('post_report.error'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: TranslatedText(
          widget.reportType == ReportType.lost 
            ? 'post_report.lost_pet_title' 
            : 'post_report.found_pet_title',
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotosSection(),
                    SizedBox(height: 24.h),
                    _buildPetDetailsSection(),
                    SizedBox(height: 24.h),
                    _buildLocationSection(),
                    SizedBox(height: 24.h),
                    _buildContactSection(),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: TranslatedCustomButton(
                        textKey: _isSubmitting ? 'post_report.submitting' : 'post_report.submit',
                        onPressed: _isSubmitting ? null : _submitReport,
                        isLoading: _isSubmitting,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Add clear photos of the pet (${_photos.length}/5)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 16.h),
        if (_photos.isEmpty)
          _buildPhotoPlaceholder()
        else
          _buildPhotosGrid(),
      ],
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48.sp,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            'Add Photos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: 'Gallery',
                type: ButtonType.secondary,
                onPressed: _photos.length < 5 ? _pickImage : null,
              ),
              SizedBox(width: 12.w),
              CustomButton(
                text: 'Camera',
                type: ButtonType.secondary,
                onPressed: _photos.length < 5 ? _takePhoto : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 1,
          ),
          itemCount: _photos.length + (_photos.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _photos.length) {
              return _buildAddPhotoButton();
            }
            return _buildPhotoItem(index);
          },
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _photos.length < 5 ? _pickImage : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          color: AppTheme.primaryGreen,
          size: 32.sp,
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            image: DecorationImage(
              image: FileImage(_photos[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4.h,
          right: 4.w,
          child: GestureDetector(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pet Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _petNameController,
          decoration: InputDecoration(
            labelText: 'post_report.pet_name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'post_report.required_field';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        DropdownButtonFormField<String>(
          value: _selectedPetType,
          decoration: InputDecoration(
            labelText: 'post_report.pet_type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          items: ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Hamster', 'Other'].map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPetType = value??'';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'post_report.required_field';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _breedController,
          decoration: InputDecoration(
            labelText: 'post_report.breed',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _colorController,
          decoration: InputDecoration(
            labelText: 'post_report.color',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: 'post_report.age',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: 'post_report.gender',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'Male',
              child: TranslatedText('post_report.male'),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: TranslatedText('post_report.female'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedGender = value??'';
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'post_report.location',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'post_report.required_field';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _contactNameController,
          decoration: InputDecoration(
            labelText: 'post_report.contact_name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'post_report.required_field';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _contactPhoneController,
          decoration: InputDecoration(
            labelText: 'post_report.contact_phone',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'post_report.required_field';
            }
            return null;
          },
        ),
      ],
    );
  }
} 