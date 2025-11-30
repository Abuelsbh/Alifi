import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../Widgets/custom_textfield_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../generated/assets.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userProfile = await AuthService.getUserProfile(AuthService.userId!);
        if (userProfile != null) {
          _user = userProfile;
          // Load name (check multiple possible fields)
          final name = userProfile['username'] ?? 
                      userProfile['name'] ?? 
                      AuthService.userDisplayName ?? 
                      'User';
          _nameController.text = name;
          
          // Load phone (check multiple possible fields)
          final phone = userProfile['phoneNumber'] ?? 
                       userProfile['phone'] ?? 
                       '';
          _phoneController.text = phone;
          
          // Load email
          final email = userProfile['email'] ?? 
                       AuthService.userEmail ?? 
                       '';
          _emailController.text = email;
          
          // Ensure profileImageUrl is set (check multiple possible fields)
          if (_user!['profileImageUrl'] == null && _user!['profilePhoto'] != null) {
            _user!['profileImageUrl'] = _user!['profilePhoto'];
          }
          if (_user!['profileImageUrl'] == null && AuthService.userPhotoURL != null) {
            _user!['profileImageUrl'] = AuthService.userPhotoURL;
          }
        } else {
          // If no profile exists, create one from Auth data
          _user = {
            'uid': AuthService.userId,
            'email': AuthService.userEmail ?? '',
            'username': AuthService.userDisplayName ?? 'User',
            'name': AuthService.userDisplayName ?? 'User',
            'profileImageUrl': AuthService.userPhotoURL,
          };
          _nameController.text = AuthService.userDisplayName ?? 'User';
          _emailController.text = AuthService.userEmail ?? '';
          _phoneController.text = '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
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

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final userId = AuthService.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');

      await ref.putFile(File(image.path));
      final imageUrl = await ref.getDownloadURL();

      // Update user profile in Firestore (support both field names)
      await FirebaseConfig.firestore
          .collection('users')
          .doc(userId)
          .update({
        'profileImageUrl': imageUrl,
        'profilePhoto': imageUrl, // Also update profilePhoto for consistency
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also update in AuthService
      await AuthService.updateUserProfile(
        uid: userId,
        photoUrl: imageUrl,
      );

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AppLanguage>(context, listen: false).translate('profile.image_updated')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Provider.of<AppLanguage>(context, listen: false).translate('profile.image_error')}: $e'),
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

  Future<void> _submitChanges() async {
    if (!AuthService.isAuthenticated || AuthService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<AppLanguage>(context, listen: false).translate('profile.login_prompt')),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الاسم مطلوب'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.userId!;
      
      // Update name and phone only (email is read-only)
      await AuthService.updateUserProfile(
        uid: userId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      // Reload user data to get latest changes
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AppLanguage>(context, listen: false).translate('profile.image_updated') ?? 'تم تحديث الملف الشخصي بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحديث: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.profile,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 1, child: Container()),
              Expanded(
                flex: 9,
                child: Image.asset(
                  Assets.imagesBackground3,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              Expanded(
                flex: 1,
                child: Image.asset(
                  Assets.imagesAlifi2,
                  height: 100,
                  width: 200,
                ),
              ),
            ],
          ),

          // المحتوى فوق الخلفية
          Container(
            child:  _isLoading && _user == null
                ? const Center(child: CircularProgressIndicator())
                : _user == null
                ? Center(
              child: Text(
                Provider.of<AppLanguage>(context).translate('profile.login_prompt'),
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : _buildEditAccountView(),
          ),
        ],
      )
    );
  }

  Widget _buildEditAccountView() {
    final username = _user!['username'] ?? _user!['name'] ?? 'User';
    final profileImageUrl = _user!['profileImageUrl'];

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 80.h),
          // Profile Picture
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: CircleAvatar(
              radius: 60.r,
              backgroundColor: Colors.grey[300],
              backgroundImage: profileImageUrl != null 
                  ? NetworkImage(profileImageUrl) 
                  : null,
              child: profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 60.sp,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // User Name in Green
          Text(
            username,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),

          
          SizedBox(height: 32.h),
          
          // Email Field (Read-only, First)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: CustomTextFieldWidget(
              controller: _emailController,
              hint: _user!['email'] ?? AuthService.userEmail ?? 'email@example.com',
              backGroundColor: AppTheme.primaryGreen,
              borderStyleFlag: 3,
              borderRadiusValue: 24.r,
              textInputType: TextInputType.emailAddress,
              readOnly: true,
              enable: false,
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white70,
                size: 20.sp,
              ),
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Name Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: CustomTextFieldWidget(
              controller: _nameController,
              hint: username,
              backGroundColor: AppTheme.primaryGreen,
              borderStyleFlag: 3,
              borderRadiusValue: 24.r,
              textInputType: TextInputType.text,
              prefixIcon: Icon(
                Icons.edit,
                color: Colors.white,
                size: 20.sp,
              ),
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Phone Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: CustomTextFieldWidget(
              controller: _phoneController,
              hint: _user!['phoneNumber'] ?? _user!['phone'] ?? '0100000000',
              backGroundColor: AppTheme.primaryGreen,
              borderStyleFlag: 3,
              borderRadiusValue: 24.r,
              textInputType: TextInputType.phone,
              prefixIcon: Icon(
                Icons.phone,
                color: Colors.white,
                size: 20.sp,
              ),
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ),
          
          SizedBox(height: 60.h),
          
          // Submit Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
          
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

}

