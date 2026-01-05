import 'dart:async';
import 'package:alifi/Modules/Auth/login_screen.dart';
import 'package:alifi/Modules/add_animal/add_animal_screen.dart';
import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/Widgets/login_widget.dart';
import 'package:alifi/core/Language/locales.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import '../../../Utilities/bottom_sheet_helper.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Utilities/strings.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../Widgets/main_navigation_screen.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/veterinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../stores/pet_stores_screen.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../lost_found/lost_found_screen.dart';
import '../lost_found/adoption_pets_screen.dart';
import '../lost_found/unified_chat_list_screen.dart';
import '../veterinary/enhanced_veterinary_screen.dart';
import '../profile/simple_profile_screen.dart';
import 'dart:async'; // Added for Timer
import '../lost_found/breeding_pets_screen.dart'; // Added for BreedingPetsScreen
import '../../../Models/pet_report_model.dart';
import '../profile/notifications_screen.dart';
import '../../../Widgets/advertisement_widget.dart';
import '../../../core/services/advertisement_service.dart';
import '../../Admin/admin_reports_screen.dart';
import '../../../core/services/location_service.dart';
import '../../../Models/location_model.dart';
import '../location/location_selection_screen.dart';
import '../../../Widgets/home_header_widget.dart';

class HomeScreen extends StatefulWidget {

  static const String routeName = '/Home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _shimmerAnimation;

  // Real data from Firebase
  int _totalLostPets = 0;
  int _totalFoundPets = 0;
  int _totalAdoptionPets = 0;
  int _totalBreedingPets = 0;
  int _totalVeterinarians = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;

  // Stream subscriptions to manage
  StreamSubscription? _lostPetsSubscription;
  StreamSubscription? _foundPetsSubscription;
  StreamSubscription? _unreadMessagesSubscription;
  StreamSubscription? _veterinariansSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _userStatusSubscription;
  StreamSubscription? _veterinarianStatusSubscription;
  Timer? _refreshTimer;
  bool _dataLoaded = false;
  bool _isLoggingOut = false; // Flag to prevent multiple logout calls
  // User data
  Map<String, dynamic>? _user;
  String _userName = 'User';
  String? _userProfileImage;
  // Location data
  LocationModel? _selectedLocation;

  Future<void> _loadUserData() async {
    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userId = AuthService.userId!;
        
        // Check user status
        await _checkAndHandleAccountStatus(userId);
        
        // Load user profile
        final userProfile = await AuthService.getUserProfile(userId);
        if (userProfile != null) {
          setState(() {
            _user = userProfile;
            _userName = userProfile['username'] ?? userProfile['name'] ?? 'User';
            _userProfileImage = userProfile['profileImageUrl'];
          });
        }
        
        // Setup listeners for account status changes
        _setupAccountStatusListeners(userId);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  Future<void> _checkAndHandleAccountStatus(String userId) async {
    if (_isLoggingOut) return; // Prevent multiple calls
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Check if user is in users collection
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Check if user is deleted
          if (userData['isDeleted'] == true) {
            await _logoutWithMessage('تم حذف هذا الحساب');
            return;
          }
          // Check if user is banned
          if (userData['status'] == 'banned') {
            await _logoutWithMessage('تم حظر هذا الحساب');
            return;
          }
        }
      }
      
      // Check if user is a veterinarian
      final vetDoc = await firestore.collection('veterinarians').doc(userId).get();
      if (vetDoc.exists) {
        final vetData = vetDoc.data();
        if (vetData != null) {
          // Check if veterinarian is deleted
          if (vetData['isDeleted'] == true) {
            await _logoutWithMessage('تم حذف هذا الحساب');
            return;
          }
          // Check if veterinarian is inactive
          if (vetData['isActive'] == false) {
            await _logoutWithMessage('تم توقيف هذا الحساب');
            return;
          }
        }
      }
    } catch (e) {
      print('Error checking account status: $e');
    }
  }
  
  void _setupAccountStatusListeners(String userId) {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Cancel existing subscriptions
      _userStatusSubscription?.cancel();
      _veterinarianStatusSubscription?.cancel();
      
      // Listen to user status changes
      _userStatusSubscription = firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists || !mounted || _isLoggingOut) return;
        
        final userData = snapshot.data();
        if (userData != null) {
          // Check if user is deleted
          if (userData['isDeleted'] == true) {
            _logoutWithMessage('تم حذف هذا الحساب');
            return;
          }
          // Check if user is banned
          if (userData['status'] == 'banned') {
            _logoutWithMessage('تم حظر هذا الحساب');
            return;
          }
        }
      }, onError: (error) {
        print('Error in user status listener: $error');
      });
      
      // Listen to veterinarian status changes
      _veterinarianStatusSubscription = firestore
          .collection('veterinarians')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists || !mounted || _isLoggingOut) return;
        
        final vetData = snapshot.data();
        if (vetData != null) {
          // Check if veterinarian is deleted
          if (vetData['isDeleted'] == true) {
            _logoutWithMessage('تم حذف هذا الحساب');
            return;
          }
          // Check if veterinarian is inactive
          if (vetData['isActive'] == false) {
            _logoutWithMessage('تم توقيف هذا الحساب');
            return;
          }
        }
      }, onError: (error) {
        print('Error in veterinarian status listener: $error');
      });
    } catch (e) {
      print('Error setting up account status listeners: $e');
    }
  }
  
  Future<void> _logoutWithMessage(String message) async {
    if (!mounted || _isLoggingOut) return; // Prevent multiple calls
    
    _isLoggingOut = true; // Set flag to prevent multiple calls
    
    try {
      // Cancel subscriptions immediately to prevent multiple triggers
      await _userStatusSubscription?.cancel();
      await _veterinarianStatusSubscription?.cancel();
      _userStatusSubscription = null;
      _veterinarianStatusSubscription = null;
      
      // Show message to user (only once)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Wait a bit for user to see the message
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if user is veterinarian and sign out accordingly
      final isVet = await VeterinaryService.isCurrentUserVeterinarian();
      if (isVet) {
        await VeterinaryService.signOutVeterinarian();
      } else {
        await AuthService.signOut();
      }
      
      // Clear user data and stay on home page
      if (mounted) {
        setState(() {
          _user = null;
          _userName = 'User';
          _userProfileImage = null;
        });
        
        // Cancel all subscriptions
        await _cancelSubscriptions();
        _dataLoaded = false;
      }
    } catch (e) {
      print('Error during logout: $e');
      // Force logout anyway
      try {
        await AuthService.signOut();
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _user = null;
          _userName = 'User';
          _userProfileImage = null;
        });
        
        // Cancel all subscriptions
        await _cancelSubscriptions();
        _dataLoaded = false;
      }
    } finally {
      // Reset flag after a delay to allow future logins
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadData();
    _loadUserData();
    _loadLocation();
    _setupAnimations();
  }

  Future<void> _loadTranslations() async {
    await TranslationService.instance.loadSavedLanguage();
  }

  void _setupAnimations() {
    // Main content animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Pulse animation for interactive elements
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Floating animation for decorative elements
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Shimmer animation for loading states
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _floatingController.repeat(reverse: true);
    if (_isLoading) _shimmerController.repeat();
  }

  Future<void> _loadData() async {
    // تجنب التحميل المتكرر
    if (_dataLoaded) return;

    try {
      if (AuthService.isAuthenticated) {
        // Cancel existing subscriptions before creating new ones
        await _cancelSubscriptions();

        // Get real statistics from Firebase
        final lostPetsStream = PetReportsService.getLostPetsStream();
        final foundPetsStream = PetReportsService.getFoundPetsStream();
        final userId = AuthService.userId;

        // Listen to streams and update counts
        _lostPetsSubscription = lostPetsStream.listen((lostPets) {
          if (mounted) {
            setState(() {
              _totalLostPets = lostPets.length;
            });
          }
        });

        _foundPetsSubscription = foundPetsStream.listen((foundPets) {
          if (mounted) {
            setState(() {
              _totalFoundPets = foundPets.length;
            });
          }
        });

        // Load adoption pets directly from Firebase
        _loadAdoptionPetsCount();
        
        // Load breeding pets directly from Firebase
        _loadBreedingPetsCount();
        
        // Refresh adoption and breeding count every 30 seconds
        _refreshTimer?.cancel(); // Cancel existing timer
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (mounted) {
            _loadAdoptionPetsCount();
            _loadBreedingPetsCount();
          } else {
            timer.cancel();
          }
        });

        if (userId != null) {
          // Get unread messages count
          final unreadStream = ChatService.getUnreadMessageCountStream(userId);
          _unreadMessagesSubscription = unreadStream.listen((count) {
            if (mounted) {
              setState(() {
                _unreadMessages = count;
              });
            }
          });
        }

        // Get veterinarians count
        final vetsStream = ChatService.getVeterinariansStream();
        _veterinariansSubscription = vetsStream.listen((vets) {
          if (mounted) {
            setState(() {
              _totalVeterinarians = vets.length;
              _isLoading = false;
            });
            _shimmerController.stop();
          }
        });

        _dataLoaded = true;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _shimmerController.stop();
      }
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _lostPetsSubscription?.cancel();
    await _foundPetsSubscription?.cancel();
    await _unreadMessagesSubscription?.cancel();
    await _veterinariansSubscription?.cancel();
    await _locationSubscription?.cancel();
    await _userStatusSubscription?.cancel();
    await _veterinarianStatusSubscription?.cancel();
    _refreshTimer?.cancel();
  }

  Future<void> _loadLocation() async {
    try {
      print('🔄 Loading user location...');
      final locationId = LocationService.getUserLocation();
      print('📍 Current user location ID: $locationId');
      
      if (locationId != null && locationId.isNotEmpty) {
        final location = await LocationService.getLocationById(locationId);
        if (mounted) {
          setState(() {
            _selectedLocation = location;
          });
          print('✅ Location loaded: ${location?.name ?? "null"}');
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedLocation = null;
          });
        }
      }

      // Listen for location changes from Firebase
      final locationsStream = LocationService.getActiveLocationsStream();
      _locationSubscription = locationsStream.listen((locations) {
        if (mounted) {
          final locationId = LocationService.getUserLocation();
          if (locationId != null && locationId.isNotEmpty) {
            try {
              final location = locations.firstWhere(
                (loc) => loc.id == locationId,
                orElse: () => LocationModel(
                  id: '',
                  name: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              setState(() {
                _selectedLocation = location.id.isNotEmpty ? location : null;
              });
            } catch (e) {
              print('⚠️ Location not found in list: $e');
              setState(() {
                _selectedLocation = null;
              });
            }
          } else {
            setState(() {
              _selectedLocation = null;
            });
          }
        }
      }, onError: (error) {
        print('❌ Error in location stream: $error');
      });
    } catch (e, stackTrace) {
      print('❌ Error loading location: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadAdoptionPetsCount() async {
    try {
      final adoptionPets = await PetReportsService.getAdoptionPetsCount();
      if (mounted) {
        setState(() {
          _totalAdoptionPets = adoptionPets;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalAdoptionPets = 0; // Fallback to 0 on error
        });
      }
    }
  }

  Future<void> _loadBreedingPetsCount() async {
    try {
      final breedingPets = await PetReportsService.getBreedingPetsCount();
      if (mounted) {
        setState(() {
          _totalBreedingPets = breedingPets;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalBreedingPets = 0; // Fallback to 0 on error
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();

    _cancelSubscriptions();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.home,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: ListView(
              children: [
                // Header Section
                HomeHeaderWidget(
                  userName: _userName,
                  userProfileImage: _userProfileImage,
                  onLocationChanged: _loadLocation,
                  onProfileTap: _navigateToProfile,
                  selectedLocation: _selectedLocation,
                ),

                SizedBox(height: 10.h),

                // Cat Image Card
                // _buildCatCard(),
                //
                // SizedBox(height: 10.h),
                // Advertisements Section
                // Use key based on location to reload ads when location changes
                AdvertisementCarousel(
                  key: ValueKey('ads_${_selectedLocation?.id ?? 'none'}'),
                ),

                Gap(12.h),
                // Available Services Section
                _buildServicesSection(),

                SizedBox(height: 10.h),

                // Chat Button
                _buildChatButton(),

                SizedBox(height: 20.h),
              ],
            ),
          ),

      ),
    );
  }


  Widget _buildCatCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Stack(
          children: [
            // Cat Image Background
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Color(0xFFFF914C), // Orange background
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                child: Image.asset(
                  Assets.imagesLostAnimal,
                  fit: BoxFit.cover, // makes sure image fills area properly
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.instance.translate('home.available_services'),
                    style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(color: ThemeClass.of(context).secondaryColor),
                  ),
                  Container(
                    width: 100.w,
                    height: 1.5.h,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF914C), // Orange underline
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Scrollable Service Cards
          SizedBox(
            height: 247.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              itemCount: 4,
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  key: ValueKey('service_card_$index'),
                  child: Container(
                    width: 234.w,
                    margin: EdgeInsets.only(right: 15.w),
                    child: _buildServiceCard(
                      _getServiceData(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getServiceData(int index) {
    switch (index) {
      case 0:
        return {
          'title': TranslationService.instance.translate('home.lost_animals'),
          'subtitle': TranslationService.instance.translate('home.lost_animals_subtitle'),
          'footerColor': ThemeClass.of(context).primaryColor, // Orange
          'icon': Assets.imagesLostAnimal,
          'badgeNumber': (_totalLostPets+_totalFoundPets).toString(),
          'badgeColor': ThemeClass.of(context).secondaryColor, // Green
          'onTap': _navigateToLostPets,
        };
      case 1:
        return {
          'title': TranslationService.instance.translate('home.pet_stores'),
          'subtitle': TranslationService.instance.translate('home.pet_stores_subtitle'),
          'footerColor': ThemeClass.of(context).secondaryColor, // Greeue
          'icon': Assets.imagesStore,
          'badgeNumber': "0",
          'badgeColor': ThemeClass.of(context).primaryColor, // Orange
          'onTap': _navigateToStores,
        };
      case 2:
        return {
          'title': TranslationService.instance.translate('home.adoption_animals'),
          'subtitle': TranslationService.instance.translate('home.adoption_animals_subtitle'),
          'footerColor': ThemeClass.of(context).primaryColor, // Green
          'icon': Assets.imagesAdoption,
          'badgeNumber': _totalAdoptionPets.toString(),
          'badgeColor': ThemeClass.of(context).secondaryColor, // Orange
          'onTap': _navigateToAdoption,
        };
      case 3:
        return {
          'title': TranslationService.instance.translate('home.mating_animals'),
          'subtitle': TranslationService.instance.translate('home.mating_animals_subtitle'),
          'footerColor': ThemeClass.of(context).secondaryColor, // Purple
          'icon': Assets.imagesMating,
          'badgeNumber': _totalBreedingPets.toString(),
          'badgeColor': ThemeClass.of(context).primaryColor, // Orange
          'onTap': _navigateToMating,
        };

      default:
        return {
          'title': TranslationService.instance.translate('common.service'),
          'subtitle': TranslationService.instance.translate('common.coming_soon'),
          'footerColor': Colors.grey,
          'icon': Icons.help,
          'badgeNumber': '0',
          'badgeColor': Colors.grey,
          'onTap': () {},
        };
    }
  }

  Widget _buildServiceCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: data['onTap'],
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24.r),
                    topRight: Radius.circular(24.r),
                  ),
                  child: Image.asset(
                    data['icon'],
                    fit: BoxFit.cover, // makes sure image fills area properly
                  ),
                ),
              ),
            ),
            // Footer Section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: data['footerColor'],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                child: Stack(
                  children: [
                    // Text Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                data['title'],
                                style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Text(
                                data['subtitle'],
                                style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),

                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: 20.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: data['badgeColor'],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                data['badgeNumber'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20)
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _navigateToChats,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w),
        height: 80.h,
        decoration: BoxDecoration(
          color: ThemeClass.of(context).secondaryColor, // Green
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          children: [
            // Text Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TranslationService.instance.translate('chat_with_dr_now'),
                      style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      TranslationService.instance.translate('we_have_the_best_doctors_in_this_app'),
                      style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).backGroundColor),

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Chat Icon with Notification
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Stack(
                children: [
                  SvgPicture.asset(Assets.iconsChat, height: 27.r, width: 27.r),
                  // Notification Dot
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF914C), // Orange
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _navigateToLostPets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LostFoundScreen(),
      ),
    );
  }

  void _navigateToAdoption() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdoptionPetsScreen(),
      ),
    );
  }

  void _navigateToMating() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BreedingPetsScreen(),
      ),
    );
  }

  void _navigateToStores() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PetStoresScreen(),
      ),
    );
  }

  void _navigateToChats() {
    if (FirebaseConfig.isDemoMode) {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
            _loadData();
            _loadUserData();
          },
        ),
      );
    } else if (AuthService.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnhancedVeterinaryScreen(),
        ),
      );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
            _loadData();
            _loadUserData();
          },
        ),
      );
    }
  }

  void _navigateToVeterinary() {
    if (FirebaseConfig.isDemoMode) {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
            _loadData();
    _loadUserData();          },
        ),
      );
    } else if (AuthService.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnhancedVeterinaryScreen(),
        ),
      );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
              _loadData();
    _loadUserData();          },
        ),
      );
    }

  }

  void _navigateToProfile() {
    if (AuthService.isAuthenticated) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleProfileScreen(),
      ),
    );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
            _loadData();
    _loadUserData();          },
        ),
      );
    }

  }
}