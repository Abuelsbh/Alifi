import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _microchipController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  String? _selectedType;
  String? _selectedGender;
  bool _isNeutered = false;
  File? _selectedImage;
  bool _isLoading = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<String> _petTypes = [
    'كلب',
    'قطة', 
    'أرنب',
    'طائر',
    'سمك',
    'همستر',
    'أخرى',
  ];
  
  final List<String> _genders = ['ذكر', 'أنثى'];

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _microchipController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'إضافة حيوان أليف',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pet Photo Section
              _buildPhotoSection(),
              
              SizedBox(height: 24.h),
              
              // Basic Information
              _buildSectionTitle('المعلومات الأساسية'),
              SizedBox(height: 16.h),
              _buildBasicInfoSection(),
              
              SizedBox(height: 24.h),
              
              // Physical Characteristics
              _buildSectionTitle('الخصائص الجسدية'),
              SizedBox(height: 16.h),
              _buildPhysicalSection(),
              
              SizedBox(height: 24.h),
              
              // Medical Information
              _buildSectionTitle('المعلومات الطبية'),
              SizedBox(height: 16.h),
              _buildMedicalSection(),
              
              SizedBox(height: 24.h),
              
              // Emergency Contact
              _buildSectionTitle('جهة الاتصال الطارئ'),
              SizedBox(height: 16.h),
              _buildEmergencySection(),
              
              SizedBox(height: 32.h),
              
              // Save Button
              CustomButton(
                text: _isLoading ? 'جاري الحفظ...' : 'حفظ الحيوان الأليف',
                onPressed: _isLoading ? null : _savePet,
                backgroundColor: AppTheme.primaryGreen,
                textColor: Colors.white,
                isLoading: _isLoading,
              ),
              
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(60.r),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 40.sp,
                      color: AppTheme.primaryGreen,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'إضافة صورة',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم الحيوان الأليف *',
                hintText: 'أدخل اسم حيوانك الأليف',
                prefixIcon: Icon(Icons.pets, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى إدخال اسم الحيوان الأليف';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.h),
            
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'نوع الحيوان *',
                prefixIcon: Icon(Icons.category, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              items: _petTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'يرجى اختيار نوع الحيوان';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.h),
            
            TextFormField(
              controller: _breedController,
              decoration: InputDecoration(
                labelText: 'السلالة',
                hintText: 'أدخل سلالة الحيوان',
                prefixIcon: Icon(Icons.pets, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'الجنس *',
                prefixIcon: Icon(Icons.wc, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              items: _genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'يرجى اختيار الجنس';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'العمر (بالسنوات)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.cake, color: AppTheme.primaryGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'الوزن (كجم)',
                      hintText: '0.0',
                      prefixIcon: Icon(Icons.monitor_weight, color: AppTheme.primaryGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            TextFormField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: 'اللون',
                hintText: 'أدخل لون الحيوان',
                prefixIcon: Icon(Icons.palette, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalSection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextFormField(
              controller: _microchipController,
              decoration: InputDecoration(
                labelText: 'رقم الرقاقة الإلكترونية',
                hintText: 'أدخل رقم الرقاقة (اختياري)',
                prefixIcon: Icon(Icons.memory, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Icon(Icons.medical_services, color: AppTheme.primaryGreen),
                SizedBox(width: 12.w),
                Text(
                  'تم التعقيم/الإخصاء',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Switch(
                  value: _isNeutered,
                  onChanged: (value) {
                    setState(() {
                      _isNeutered = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            TextFormField(
              controller: _allergiesController,
              decoration: InputDecoration(
                labelText: 'الحساسيات',
                hintText: 'اذكر أي حساسيات معروفة (مفصولة بفواصل)',
                prefixIcon: Icon(Icons.warning, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              maxLines: 2,
            ),
            
            SizedBox(height: 16.h),
            
            TextFormField(
              controller: _medicationsController,
              decoration: InputDecoration(
                labelText: 'الأدوية الحالية',
                hintText: 'اذكر الأدوية التي يتناولها حالياً',
                prefixIcon: Icon(Icons.medication, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextFormField(
              controller: _emergencyNameController,
              decoration: InputDecoration(
                labelText: 'اسم جهة الاتصال',
                hintText: 'أدخل اسم الشخص للاتصال به في الطوارئ',
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى إدخال اسم جهة الاتصال';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.h),
            
            TextFormField(
              controller: _emergencyPhoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                hintText: '+201234567890',
                prefixIcon: Icon(Icons.phone, color: AppTheme.primaryGreen),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في اختيار الصورة: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService.userId;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // TODO: Upload image to Firebase Storage
      String? imageUrl;
      if (_selectedImage != null) {
        // imageUrl = await uploadImageToStorage(_selectedImage!);
      }

      // TODO: Save pet data to Firestore
      final petData = {
        'userId': userId,
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'breed': _breedController.text.trim(),
        'gender': _selectedGender,
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'weight': double.tryParse(_weightController.text.trim()) ?? 0.0,
        'color': _colorController.text.trim(),
        'microchip': _microchipController.text.trim().isNotEmpty 
            ? _microchipController.text.trim() 
            : null,
        'isNeutered': _isNeutered,
        'allergies': _allergiesController.text.trim().split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'medications': _medicationsController.text.trim().split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'emergencyContact': {
          'name': _emergencyNameController.text.trim(),
          'phone': _emergencyPhoneController.text.trim(),
        },
        'imageUrl': imageUrl,
        'medicalHistory': [],
        'vaccinations': [],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8.w),
              const Text('تم حفظ الحيوان الأليف بنجاح'),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ البيانات: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 