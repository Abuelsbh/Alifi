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

import '../../../core/services/location_service.dart';
import '../../../core/Language/translation_service.dart';
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
  String _selectedPetType = 'كلب';
  String _selectedGender = 'ذكر';
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

  // Options for dropdowns
  final List<String> _petTypes = ['كلب', 'قط', 'طائر', 'أرنب', 'هامستر', 'أخرى'];
  final List<String> _genders = ['ذكر', 'أنثى'];
  final List<String> _healthStatuses = ['جيد', 'مقبول', 'يحتاج رعاية'];
  final List<String> _temperaments = ['ودود', 'هادئ', 'نشيط', 'خجول', 'عدواني'];
  final List<String> _contactMethods = ['هاتف', 'إيميل', 'واتساب'];

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

  // Bottom sheet for pet type selection
  void _showPetTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              TranslationService.instance.translate('post_report.select_pet_type'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ..._petTypes.map((type) => ListTile(
              title: Text(type),
              trailing: _selectedPetType == type ? Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                setState(() {
                  _selectedPetType = type;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Bottom sheet for gender selection
  void _showGenderBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              TranslationService.instance.translate('post_report.select_gender'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ..._genders.map((gender) => ListTile(
              title: Text(gender),
              trailing: _selectedGender == gender ? Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                setState(() {
                  _selectedGender = gender;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Bottom sheet for health status selection
  void _showHealthStatusBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              TranslationService.instance.translate('post_report.select_health_status'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ..._healthStatuses.map((status) => ListTile(
              title: Text(status),
              trailing: _healthStatus == status ? Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                setState(() {
                  _healthStatus = status;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Bottom sheet for temperament selection
  void _showTemperamentBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              TranslationService.instance.translate('post_report.select_temperament'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ..._temperaments.map((temperament) => ListTile(
              title: Text(temperament),
              trailing: _temperament == temperament ? Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                setState(() {
                  _temperament = temperament;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Bottom sheet for contact method selection
  void _showContactMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              TranslationService.instance.translate('post_report.select_contact_method'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ..._contactMethods.map((method) => ListTile(
              title: Text(method),
              trailing: _preferredContact == method ? Icon(Icons.check, color: AppTheme.primaryGreen) : null,
              onTap: () {
                setState(() {
                  _preferredContact = method;
                });
                Navigator.pop(context);
              },
            )),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.instance.translate('post_report.add_photo_required')),
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
                      ? TranslationService.instance.translate('post_report.lost_success')
                      : TranslationService.instance.translate('post_report.found_success'),
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
            content: Text(TranslationService.instance.translate('post_report.error')),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.reportType == ReportType.lost 
            ? TranslationService.instance.translate('post_report.lost_pet_title')
            : TranslationService.instance.translate('post_report.found_pet_title'),
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
                    if (widget.reportType == ReportType.lost) ...[
                      SizedBox(height: 24.h),
                      _buildLostPetExtraSection(),
                    ] else ...[
                      SizedBox(height: 24.h),
                      _buildFoundPetExtraSection(),
                    ],
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
          TranslationService.instance.translate('post_report.photos'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          TranslationService.instance.translate('post_report.photos_description').replaceAll('{count}', '${_photos.length}/5'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: 12.h),
          Text(
            TranslationService.instance.translate('post_report.add_photos'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: TranslationService.instance.translate('post_report.gallery'),
                type: ButtonType.secondary,
                onPressed: _photos.length < 5 ? _pickImage : null,
              ),
              SizedBox(width: 12.w),
              CustomButton(
                text: TranslationService.instance.translate('post_report.camera'),
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
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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
          TranslationService.instance.translate('post_report.pet_details'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _petNameController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.pet_name'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return TranslationService.instance.translate('post_report.required_field');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        // Pet Type Selection with Bottom Sheet
        GestureDetector(
          onTap: _showPetTypeBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedPetType,
                    style: TextStyle(
                      color: _selectedPetType.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _breedController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.breed'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _colorController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.color'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _ageController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.age'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Gender Selection with Bottom Sheet
        GestureDetector(
          onTap: _showGenderBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedGender,
                    style: TextStyle(
                      color: _selectedGender.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.instance.translate('post_report.location'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.location'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return TranslationService.instance.translate('post_report.required_field');
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
          TranslationService.instance.translate('post_report.contact_information'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _contactNameController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.contact_name'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return TranslationService.instance.translate('post_report.required_field');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _contactPhoneController,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.contact_phone'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return TranslationService.instance.translate('post_report.required_field');
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: TextEditingController(text: _contactEmail),
          onChanged: (value) => _contactEmail = value,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.contact_email'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Contact Method Selection with Bottom Sheet
        GestureDetector(
          onTap: _showContactMethodBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _preferredContact,
                    style: TextStyle(
                      color: _preferredContact.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLostPetExtraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.instance.translate('post_report.additional_info'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.description'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: TextEditingController(text: _distinguishingMarks),
          onChanged: (value) => _distinguishingMarks = value,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.distinguishing_marks'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: TextEditingController(text: _personality),
          onChanged: (value) => _personality = value,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.personality'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: TextEditingController(text: _medicalConditions),
          onChanged: (value) => _medicalConditions = value,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.medical_conditions'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Checkbox(
              value: _isUrgent,
              onChanged: (value) {
                setState(() {
                  _isUrgent = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                TranslationService.instance.translate('post_report.is_urgent'),
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        if (_isUrgent) ...[
          SizedBox(height: 16.h),
          TextFormField(
            controller: TextEditingController(text: _reward.toString()),
            onChanged: (value) => _reward = double.tryParse(value) ?? 0,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: TranslationService.instance.translate('post_report.reward'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFoundPetExtraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.instance.translate('post_report.additional_info'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: TranslationService.instance.translate('post_report.description'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Health Status Selection with Bottom Sheet
        GestureDetector(
          onTap: _showHealthStatusBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _healthStatus,
                    style: TextStyle(
                      color: _healthStatus.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        // Temperament Selection with Bottom Sheet
        GestureDetector(
          onTap: _showTemperamentBottomSheet,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _temperament,
                    style: TextStyle(
                      color: _temperament.isNotEmpty ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Checkbox(
              value: _hasCollar,
              onChanged: (value) {
                setState(() {
                  _hasCollar = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                TranslationService.instance.translate('post_report.has_collar'),
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        if (_hasCollar) ...[
          SizedBox(height: 16.h),
          TextFormField(
            controller: TextEditingController(text: _collarDescription),
            onChanged: (value) => _collarDescription = value,
            decoration: InputDecoration(
              labelText: TranslationService.instance.translate('post_report.collar_description'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
        SizedBox(height: 16.h),
        Row(
          children: [
            Checkbox(
              value: _isInShelter,
              onChanged: (value) {
                setState(() {
                  _isInShelter = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                TranslationService.instance.translate('post_report.is_in_shelter'),
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        if (_isInShelter) ...[
          SizedBox(height: 16.h),
          TextFormField(
            controller: TextEditingController(text: _shelterInfo),
            onChanged: (value) => _shelterInfo = value,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: TranslationService.instance.translate('post_report.shelter_info'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ],
    );
  }
} 