import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/firebase/firebase_config.dart';

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
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userProfile = await AuthService.getUserProfile(AuthService.userId!);
        if (userProfile != null) {
          _user = userProfile;
          _nameController.text = userProfile['username'] ?? userProfile['name'] ?? '';
          _phoneController.text = userProfile['phoneNumber'] ?? userProfile['phone'] ?? '';
        } else {
          _user = {
            'uid': AuthService.userId,
            'email': AuthService.userEmail ?? '',
            'username': AuthService.userDisplayName ?? 'User',
            'name': AuthService.userDisplayName ?? 'User',
            'profileImageUrl': AuthService.userPhotoURL,
          };
          _nameController.text = AuthService.userDisplayName ?? 'User';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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

      // Update user profile in Firestore
      await FirebaseConfig.firestore
          .collection('users')
          .doc(userId)
          .update({'profileImageUrl': imageUrl});

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AppLanguage>(context).translate('profile.image_updated')),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${Provider.of<AppLanguage>(context).translate('profile.image_error')}: $e'),
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
          content: Text(Provider.of<AppLanguage>(context).translate('profile.login_prompt')),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = AuthService.userId!;
      
      // Update name and phone
      await AuthService.updateUserProfile(
        uid: userId,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      // Update password if provided
      if (_passwordController.text.trim().isNotEmpty) {
        if (_passwordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters');
        }
        await AuthService.updatePassword(_passwordController.text.trim());
        _passwordController.clear();
      }

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<AppLanguage>(context).translate('profile.image_updated') ?? 'Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      body: _isLoading && _user == null
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Text(
                    Provider.of<AppLanguage>(context).translate('profile.login_prompt'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : _buildEditAccountView(),
    );
  }

  Widget _buildEditAccountView() {
    final username = _user!['username'] ?? _user!['name'] ?? 'User';
    final profileImageUrl = _user!['profileImageUrl'];

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          // Profile Picture
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: Colors.grey[300],
              backgroundImage: profileImageUrl != null 
                  ? NetworkImage(profileImageUrl) 
                  : null,
              child: profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 50.sp,
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
          
          SizedBox(height: 16.h),
          
          // Account Button (Orange)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 32.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                Provider.of<AppLanguage>(context).translate('profile.account') ?? 'Account',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Three dots (ellipsis)
          Icon(
            Icons.more_vert,
            color: Colors.grey[400],
            size: 24.sp,
          ),
          
          SizedBox(height: 32.h),
          
          // Name Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: _buildInputField(
              controller: _nameController,
              hintText: username,
              icon: Icons.edit,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Phone Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: _buildInputField(
              controller: _phoneController,
              hintText: _user!['phoneNumber'] ?? _user!['phone'] ?? '0100000000',
              icon: Icons.edit,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Password Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: _buildPasswordField(),
          ),
          
          SizedBox(height: 32.h),
          
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
                    borderRadius: BorderRadius.circular(8),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          suffixIcon: Icon(icon, color: Colors.white, size: 20.sp),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
              size: 20.sp,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
    );
  }
}

