import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../generated/assets.dart';
import 'my_pets_screen.dart';
import 'my_reports_screen.dart';
import 'settings_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../lost_found/adoption_pets_screen.dart';
import '../lost_found/breeding_pets_screen.dart';
import '../stores/pet_stores_screen.dart';
import 'edit_account_screen.dart';


class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});

  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  final ImagePicker _picker = ImagePicker();
  bool _servicesExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userProfile = await AuthService.getUserProfile(AuthService.userId!);
        if (userProfile != null) {
          _user = userProfile;
          // Ensure username is set from multiple sources
          if ((_user!['username'] == null || _user!['username'].toString().isEmpty) &&
              (_user!['name'] == null || _user!['name'].toString().isEmpty)) {
            _user!['username'] = AuthService.userDisplayName ?? 
                                AuthService.userEmail?.split('@')[0] ?? 
                                'User';
            _user!['name'] = _user!['username'];
          }
        } else {
          // If Firestore profile doesn't exist, create a basic profile from Firebase Auth
          final displayName = AuthService.userDisplayName ?? 
                             AuthService.userEmail?.split('@')[0] ?? 
                             'User';
          _user = {
            'uid': AuthService.userId,
            'email': AuthService.userEmail ?? '',
            'username': displayName,
            'name': displayName,
            'profileImageUrl': AuthService.userPhotoURL,
          };
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Even if there's an error, if user is authenticated, show basic profile
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final displayName = AuthService.userDisplayName ?? 
                           AuthService.userEmail?.split('@')[0] ?? 
                           'User';
        _user = {
          'uid': AuthService.userId,
          'email': AuthService.userEmail ?? '',
          'username': displayName,
          'name': displayName,
          'profileImageUrl': AuthService.userPhotoURL,
        };
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Check if current user is admin
  bool _isAdmin() {
    // For demo purposes, we'll check if email contains 'admin'
    // In production, this should check user role in database
    final email = _user?['email'] ?? '';
    return email.contains('admin') || 
           email == 'doctor@gmail.com' || 
           email == 'admin@alifi.com';
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _user == null
                ? _buildLoginPrompt()
                : _buildUserProfile(),
          ),
        ],
      )

    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            Provider.of<AppLanguage>(context).translate('profile.login_prompt'),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(Provider.of<AppLanguage>(context).translate('auth.login')),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    // Get username from multiple possible sources
    String username = 'User';
    if (_user != null) {
      username = _user!['username'] ?? 
                 _user!['name'] ?? 
                 AuthService.userDisplayName ?? 
                 AuthService.userEmail?.split('@')[0] ?? 
                 'User';
    } else {
      username = AuthService.userDisplayName ?? 
                 AuthService.userEmail?.split('@')[0] ?? 
                 'User';
    }
    
    final profileImageUrl = _user?['profileImageUrl'] ?? AuthService.userPhotoURL;
    
    return Column(
      children: [
        SizedBox(height: 40.h),
        // Profile Picture
        CircleAvatar(
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

        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServicesSection(),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: 120,
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),


            // Chats Section
            _buildSection(
              title: Provider.of<AppLanguage>(context).translate('profile.my_chats') ?? 'Chats',
              onTap: () {
                // TODO: Navigate to chats
              },
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: 120,
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            // Account Section
            _buildSection(
              title: Provider.of<AppLanguage>(context).translate('profile.account') ?? 'Account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditAccountScreen(),
                  ),
                );
              },
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: 120,
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            // Language Section
            _buildLanguageSection(),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: 120,
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            
            // Sign Out Section
            _buildSignOutSection(),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              width: 120,
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
          ],
        )

      ],
    );
  }
  
  Widget _buildSignOutSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: InkWell(
        onTap: _showSignOutDialog,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text(
            Provider.of<AppLanguage>(context).translate('profile.sign_out') ?? 'Sign Out',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.error,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildServicesSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _servicesExpanded = !_servicesExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Row(
                children: [
                  Text(
                    Provider.of<AppLanguage>(context).translate('profile.services') ?? 'Services',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  Gap(12.w),
                  Icon(
                    _servicesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryOrange,
                  ),
                ],
              ),
            ),
          ),
          if (_servicesExpanded) ...[
            _buildServiceItem(
              'Lost Animals',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LostFoundScreen(),
                  ),
                );
              },
            ),
            _buildServiceItem(
              'Animal for Adoption',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdoptionPetsScreen(),
                  ),
                );
              },
            ),
            _buildServiceItem(
              'Animals for Mating',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BreedingPetsScreen(),
                  ),
                );
              },
            ),
            _buildServiceItem(
              'Pet Supply Stores',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PetStoresScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }
  
  Widget _buildServiceItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: 20.w, bottom: 12.h),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({required String title, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),

      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLanguageSection() {
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: InkWell(
        onTap: () {
          _showLanguageBottomSheet();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child:  Text(
            Provider.of<AppLanguage>(context).translate('profile.language') ?? 'Language',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryOrange,
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Consumer<AppLanguage>(
          builder: (context, appLanguage, child) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Text(
                      Provider.of<AppLanguage>(context).translate('profile.language') ?? 'Language',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Language options
                  ...appLanguage.availableLanguages.map((language) {
                    final isSelected = appLanguage.appLang.name == language['code'];
                    final languageCode = language['code']!;

                    return ListTile(
                      title: Text(
                        language['nativeName']!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(language['name']!),
                      trailing: isSelected
                          ? Icon(Icons.check, color: AppTheme.primaryGreen)
                          : null,
                      onTap: () {
                        final selectedLanguage = Languages.values.firstWhere(
                          (lang) => lang.name == languageCode,
                        );
                        appLanguage.changeLanguage(language: selectedLanguage);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out')),
        content: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<AppLanguage>(context).translate('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.signOut();
                if (mounted) {
                  context.go('/home');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${Provider.of<AppLanguage>(context).translate('profile.sign_out_error')}: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
