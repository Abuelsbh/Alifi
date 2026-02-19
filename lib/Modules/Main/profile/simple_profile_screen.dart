import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../generated/assets.dart';
import '../veterinary/enhanced_veterinary_screen.dart';
import 'my_pets_screen.dart';
import 'my_reports_screen.dart';
import 'settings_screen.dart';
import '../lost_found/lost_found_screen.dart';
import '../lost_found/adoption_pets_screen.dart';
import '../lost_found/breeding_pets_screen.dart';
import '../stores/pet_stores_screen.dart';
import 'edit_account_screen.dart';
import 'privacy_policy_screen.dart';
import 'my_animals_screen.dart';


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

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');

      await ref.putFile(File(image.path));
      final imageUrl = await ref.getDownloadURL();

      await FirebaseConfig.firestore
          .collection('users')
          .doc(userId)
          .update({
        'profileImageUrl': imageUrl,
        'profilePhoto': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await AuthService.updateUserProfile(
        uid: userId,
        photoUrl: imageUrl,
      );

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

  // Check if current user is admin
  bool _isAdmin() {
    // For demo purposes, we'll check if email contains 'admin'
    // In production, this should check user role in database
    final email = _user?['email'] ?? '';
    return email.contains('admin') || 
           email == 'doctor@gmail.com' || 
           email == 'admin@alifi.com';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.profile,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
              ),
            )
          : _user == null
              ? _buildLoginPrompt()
              : _buildUserProfile(),
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
        // Modern Header with Gradient
        Container(
          height: 204.h,
          child: SafeArea(
            child: Column(
              children: [

                // Profile Picture with Modern Design
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Middle circle
                    Container(
                      width: 130.w,
                      height: 130.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // Profile image
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profileImageUrl != null
                              ? Image.network(
                                  profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 60.sp,
                                      color: AppTheme.primaryGreen,
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: 60.sp,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // زر + لإضافة صورة البروفايل
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryGreen,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // User Name with Modern Style
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                // SizedBox(height: 4.h),
                // // Email if available
                // if (_user?['email'] != null)
                //   Text(
                //     _user!['email'],
                //     style: TextStyle(
                //       fontSize: 14.sp,
                //       color: Colors.white.withOpacity(0.9),
                //       fontWeight: FontWeight.w400,
                //     ),
                //   ),
              ],
            ),
          ),
        ),

        // Content Section
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.r),
                topRight: Radius.circular(25.r),
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Services Section with Modern Card
                  _buildModernServicesSection(),
                  Gap(16.h),
                  
                  // Menu Items as Modern Cards
                  _buildModernMenuCard(
                    icon: Icons.chat_bubble_outline,
                    title: Provider.of<AppLanguage>(context).translate('profile.my_chats') ?? 'My Chats',
                    subtitle: Provider.of<AppLanguage>(context).translate('profile.chats_subtitle') ?? 'View your conversations',
                    gradient: [AppTheme.primaryOrange, AppTheme.lightOrange],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedVeterinaryScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(12.h),
                  
                  _buildModernMenuCard(
                    icon: Icons.pets,
                    title: Provider.of<AppLanguage>(context).translate('profile.my_animals') ?? 'My Animals',
                    subtitle: Provider.of<AppLanguage>(context).translate('profile.my_pets_subtitle') ?? 'Manage your pets',
                    gradient: [AppTheme.primaryGreen, AppTheme.lightGreen],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAnimalsScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(12.h),
                  
                  _buildModernMenuCard(
                    icon: Icons.account_circle_outlined,
                    title: Provider.of<AppLanguage>(context).translate('profile.account') ?? 'Account',
                    subtitle: Provider.of<AppLanguage>(context).translate('profile.account_subtitle') ?? 'Edit your profile',
                    gradient: [AppTheme.primaryGreen.withOpacity(0.8), AppTheme.primaryOrange.withOpacity(0.6)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditAccountScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(12.h),
                  
                  _buildModernMenuCard(
                    icon: Icons.privacy_tip_outlined,
                    title: Provider.of<AppLanguage>(context).translate('profile.privacy_policy') ?? 'Privacy Policy',
                    subtitle: Provider.of<AppLanguage>(context).translate('profile.privacy_subtitle') ?? 'Read our privacy policy',
                    gradient: [Colors.grey.shade600, Colors.grey.shade400],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(12.h),
                  
                  _buildModernMenuCard(
                    icon: Icons.language,
                    title: Provider.of<AppLanguage>(context).translate('profile.language') ?? 'Language',
                    subtitle: Provider.of<AppLanguage>(context).translate('profile.language_subtitle') ?? 'Change app language',
                    gradient: [Colors.blue.shade600, Colors.blue.shade400],
                    onTap: () => _showLanguageBottomSheet(),
                  ),
                  Gap(20.h),
                  
                  // Sign Out Button
                  _buildModernSignOutButton(),
                  Gap(24.h),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Divider(color: Colors.grey.shade300, thickness: 1, height: 1),
    );
  }
  
  Widget _buildModernSignOutButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showSignOutDialog,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.error,
                  AppTheme.error.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 22.sp,
                ),
                Gap(12.w),
                Text(
                  Provider.of<AppLanguage>(context).translate('profile.sign_out') ?? 'Sign Out',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernServicesSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _servicesExpanded = !_servicesExpanded;
            });
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryOrange, AppTheme.lightOrange],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.grid_view,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    Gap(16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Provider.of<AppLanguage>(context).translate('profile.services') ?? 'Services',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                          Text(
                            Provider.of<AppLanguage>(context).translate('profile.services_subtitle') ?? 'Explore all services',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _servicesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.primaryOrange,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
                if (_servicesExpanded) ...[
                  Gap(16.h),
                  _buildModernServiceItem(
                    icon: Icons.search,
                    title: Provider.of<AppLanguage>(context).translate('profile.lost_animals') ?? 'Lost Animals',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LostFoundScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(8.h),
                  _buildModernServiceItem(
                    icon: Icons.favorite_outline,
                    title: Provider.of<AppLanguage>(context).translate('profile.animal_for_adoption') ?? 'Adoption',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdoptionPetsScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(8.h),
                  _buildModernServiceItem(
                    icon: Icons.favorite,
                    title: Provider.of<AppLanguage>(context).translate('profile.animals_for_mating') ?? 'Breeding',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BreedingPetsScreen(),
                        ),
                      );
                    },
                  ),
                  Gap(8.h),
                  _buildModernServiceItem(
                    icon: Icons.store,
                    title: Provider.of<AppLanguage>(context).translate('profile.pet_supply_stores') ?? 'Pet Stores',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PetStoresScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernServiceItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: AppTheme.primaryGreen,
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppTheme.primaryGreen.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(18.r),
      //   boxShadow: [
      //     BoxShadow(
      //       color: gradient[0].withOpacity(0.2),
      //       blurRadius: 12,
      //       offset: const Offset(0, 4),
      //       spreadRadius: 0,
      //     ),
      //   ],
      // ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient[0].withOpacity(0.1),
                  gradient[1].withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: gradient[0].withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18.sp,
                  color: gradient[0].withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
              Provider.of<AppLanguage>(context).translate('profile.lost_animals'),
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
              Provider.of<AppLanguage>(context).translate('profile.animal_for_adoption'),
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
              Provider.of<AppLanguage>(context).translate('profile.animals_for_mating'),
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
              Provider.of<AppLanguage>(context).translate('profile.pet_supply_stores'),
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
    return InkWell(
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
    );
  }
  
  Widget _buildLanguageSection() {
    return InkWell(
      onTap: () => _showLanguageBottomSheet(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          Provider.of<AppLanguage>(context).translate('profile.language') ?? 'Language',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryOrange,
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
