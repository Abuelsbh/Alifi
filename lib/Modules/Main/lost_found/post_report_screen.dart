import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Models/pet_report_model.dart';
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
  
  // Form controllers
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  final _colorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  
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
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
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
        SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Upload photos and submit report through service
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock submission
      if (widget.reportType == ReportType.lost) {
        // Create lost pet report
        final lostPet = LostPetModel(
          id: '',
          userId: 'user1', // TODO: Get current user ID
          petName: _petNameController.text,
          petType: _selectedPetType,
          breed: _breedController.text,
          age: _age,
          gender: _selectedGender,
          color: _colorController.text,
          photos: [], // TODO: Upload photos and get URLs
          description: _descriptionController.text,
          location: _location ?? const GeoPoint(0, 0),
          address: _address,
          lostDate: _dateLost,
          contactPhone: _contactPhoneController.text,
          contactName: _contactNameController.text,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Create found pet report
        final foundPet = FoundPetModel(
          id: '',
          userId: 'user1', // TODO: Get current user ID
          petType: _selectedPetType,
          breed: _breedController.text,
          color: _colorController.text,
          photos: [], // TODO: Upload photos and get URLs
          description: _descriptionController.text,
          location: _location ?? const GeoPoint(0, 0),
          address: _address,
          foundDate: _dateLost,
          contactPhone: _contactPhoneController.text,
          contactName: _contactNameController.text,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.reportType == ReportType.lost ? 'Lost' : 'Found'} pet report submitted successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
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
        title: Text(
          widget.reportType == ReportType.lost ? 'Report Lost Pet' : 'Report Found Pet',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
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
                    CustomButton(
                      text: _isSubmitting ? 'Submitting...' : 'Submit Report',
                      isFullWidth: true,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submitReport,
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
        if (widget.reportType == ReportType.lost)
          TextFormField(
            controller: _petNameController,
            decoration: InputDecoration(
              labelText: 'Pet Name',
              hintText: 'Enter pet name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter pet name';
              }
              return null;
            },
          ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPetType,
                decoration: InputDecoration(
                  labelText: 'Pet Type',
                ),
                items: ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Hamster', 'Other']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPetType = value!;
                  });
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                ),
                items: ['Male', 'Female']
                    .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (widget.reportType == ReportType.lost)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    labelText: 'Breed',
                    hintText: 'Enter breed',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter breed';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age (years)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _age > 1 ? () => setState(() => _age--) : null,
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        Expanded(
                          child: Text(
                            _age.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: _age < 20 ? () => setState(() => _age++) : null,
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (widget.reportType == ReportType.lost) SizedBox(height: 16.h),
        TextFormField(
          controller: _colorController,
          decoration: InputDecoration(
            labelText: 'Color',
            hintText: 'Enter pet color',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter color';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the pet and any additional details',
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter description';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        if (widget.reportType == ReportType.lost)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Date Lost'),
            subtitle: Text(
              '${_dateLost.day}/${_dateLost.month}/${_dateLost.year}',
            ),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dateLost,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _dateLost = date;
                });
              }
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
          initialValue: _address,
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'Enter address where pet was lost/found',
            suffixIcon: IconButton(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.my_location),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _address = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
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
            labelText: 'Contact Name',
            hintText: 'Enter your name',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        TextFormField(
          controller: _contactPhoneController,
          decoration: InputDecoration(
            labelText: 'Contact Phone',
            hintText: 'Enter your phone number',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter contact phone';
            }
            return null;
          },
        ),
      ],
    );
  }
} 