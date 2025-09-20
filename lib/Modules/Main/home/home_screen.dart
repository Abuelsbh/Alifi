import 'dart:async';
import 'package:alifi/Modules/Auth/login_screen.dart';
import 'package:alifi/Modules/add_animal/add_animal_screen.dart';
import 'package:alifi/Widgets/login_widget.dart';
import 'package:alifi/core/Language/locales.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../Utilities/bottom_sheet_helper.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Utilities/strings.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../Widgets/main_navigation_screen.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../lost_found/lost_found_screen.dart';
import '../lost_found/adoption_pets_screen.dart';
import '../veterinary/enhanced_veterinary_screen.dart';
import '../profile/simple_profile_screen.dart';
import 'dart:async'; // Added for Timer
import '../lost_found/breeding_pets_screen.dart'; // Added for BreedingPetsScreen
import '../../../Models/pet_report_model.dart';

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
  Timer? _refreshTimer;
  bool _dataLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _loadData();
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
    _refreshTimer?.cancel();
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

    // Cancel all subscriptions to prevent memory leaks
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
                _buildHeader(),

                SizedBox(height: 10.h),

                // Cat Image Card
                _buildCatCard(),

                SizedBox(height: 10.h),

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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Profile and Welcome
          Row(
            children: [
              // Profile Image
              Container(
                width: 50.w,
                height: 50.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/profile_placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 25.sp,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 15.w),
              // Welcome Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Color(0xFFFF914C), // Orange
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Fares Walid',
                    style: TextStyle(
                      color: Color(0xFF386641), // Green
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right side - Icons
          Row(
            children: [
              // Bell Icon
              GestureDetector(
                onTap: () {
                  // Navigate to notifications
                },
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Menu Icon
              GestureDetector(
                onTap: () {
                  _navigateToProfile();
                },
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                    'Available Services',
                    style: TextStyle(
                      color: Color(0xFF386641), // Green
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
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
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  width: 234.w,
                  margin: EdgeInsets.only(right: 15.w),
                  child: _buildServiceCard(
                    _getServiceData(index),
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
          'title': 'Lost Animals',
          'subtitle': 'Missing animals',
          'footerColor': Color(0xFFFF914C), // Orange
          'icon': Assets.imagesLostAnimal,
          'badgeNumber': (_totalLostPets+_totalFoundPets).toString(),
          'badgeColor': Color(0xFF386641), // Green
          'onTap': _navigateToLostPets,
        };
      case 1:
        return {
          'title': 'Store',
          'subtitle': 'Pet supplies',
          'footerColor': Color(0xFF386641), // Blue
          'icon': Assets.imagesStore,
          'badgeNumber': "0",
          'badgeColor': Color(0xFFFF914C), // Orange
          'onTap': _navigateToStores,
        };
      case 2:
        return {
          'title': 'Breeding',
          'subtitle': 'Pet breeding',
          'footerColor': Color(0xFFFF914C), // Purple
          'icon': Assets.imagesLostAnimal,
          'badgeNumber': _totalBreedingPets.toString(),
          'badgeColor': Color(0xFF386641), // Orange
          'onTap': _navigateToMating,
        };
      case 3:
        return {
          'title': 'Adoption',
          'subtitle': 'Adopt a pet',
          'footerColor': Color(0xFF386641), // Green
          'icon': Assets.imagesLostAnimal,
          'badgeNumber': _totalAdoptionPets.toString(),
          'badgeColor': Color(0xFFFF914C), // Orange
          'onTap': _navigateToAdoption,
        };
      default:
        return {
          'title': 'Service',
          'subtitle': 'Coming soon',
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Text(
                                data['subtitle'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12.sp,
                                ),
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
      onTap: _navigateToVeterinary,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        height: 80.h,
        decoration: BoxDecoration(
          color: Color(0xFF386641), // Green
          borderRadius: BorderRadius.circular(20.r),
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
                      'Chat with Dr Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'we have the best doctors in this app',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Chat Icon with Notification
            Padding(
              padding: EdgeInsets.only(right: 20.w),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pet Stores'),
        content: Text('قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _navigateToVeterinary() {
    if (FirebaseConfig.isDemoMode) {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: LoginWidget(
          onLoginSuccess: () {
            _dataLoaded = false;
            _loadData();
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
          },
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
          },
        ),
      );
    }

  }
}