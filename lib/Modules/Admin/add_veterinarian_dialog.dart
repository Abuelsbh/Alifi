import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/veterinary_service.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/custom_button.dart';

class AddVeterinarianDialog extends StatefulWidget {
  final Map<String, dynamic>? veterinarian;
  final VoidCallback? onVeterinarianAdded;

  const AddVeterinarianDialog({
    super.key,
    this.veterinarian,
    this.onVeterinarianAdded,
  });

  @override
  State<AddVeterinarianDialog> createState() => _AddVeterinarianDialogState();
}

class _AddVeterinarianDialogState extends State<AddVeterinarianDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.veterinarian != null;
    
    if (_isEditing) {
      _nameController.text = widget.veterinarian!['name'] ?? '';
      _emailController.text = widget.veterinarian!['email'] ?? '';
      _phoneController.text = widget.veterinarian!['phone'] ?? '';
      _specializationController.text = widget.veterinarian!['specialization'] ?? '';
      _experienceController.text = widget.veterinarian!['experience'] ?? '';
      _licenseController.text = widget.veterinarian!['license'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
      //  maxWidth: 500,
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit : Icons.add,
                        color: AppTheme.primaryGreen,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Veterinarian' : 'Add New Veterinarian',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightOnSurface,
                            ),
                          ),
                          Text(
                            _isEditing 
                                ? 'Update veterinarian information'
                                : 'Create a new veterinarian account',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Form Fields
                _buildSectionTitle('Personal Information'),
                SizedBox(height: 12.h),
                
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'Dr. Ahmed Hassan',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address *',
                  hint: 'doctor@example.com',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16.h),
                
                if (!_isEditing) ...[
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password *',
                    hint: 'Minimum 6 characters',
                    icon: Icons.lock,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                ],
                
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number *',
                  hint: '+201234567890',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 24.h),
                
                _buildSectionTitle('Professional Information'),
                SizedBox(height: 12.h),
                
                _buildTextField(
                  controller: _specializationController,
                  label: 'Specialization *',
                  hint: 'General Veterinary, Surgery, etc.',
                  icon: Icons.medical_services,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Specialization is required';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: _experienceController,
                  label: 'Years of Experience *',
                  hint: '5 years',
                  icon: Icons.timeline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Experience is required';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16.h),
                
                _buildTextField(
                  controller: _licenseController,
                  label: 'License Number',
                  hint: 'VET-12345',
                  icon: Icons.verified,
                ),
                
                SizedBox(height: 32.h),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveVeterinarian,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isEditing ? 'Update' : 'Create Account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightOnSurface,
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.primaryGreen),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppTheme.error),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Future<void> _saveVeterinarian() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Update existing veterinarian
        await VeterinaryService.updateVeterinarian(
          vetId: widget.veterinarian!['id'],
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          specialization: _specializationController.text.trim(),
          experience: _experienceController.text.trim(),
          license: _licenseController.text.trim(),
        );
      } else {
        // Create new veterinarian
        await VeterinaryService.createVeterinarianFromAdmin(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          specialization: _specializationController.text.trim(),
          experience: _experienceController.text.trim(),
          phone: _phoneController.text.trim(),
          license: _licenseController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onVeterinarianAdded?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Veterinarian updated successfully!' 
                  : 'Veterinarian account created successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 