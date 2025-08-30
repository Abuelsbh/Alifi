import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../lost_found/lost_found_screen.dart';
import '../veterinary/enhanced_veterinary_screen.dart';
import '../profile/simple_profile_screen.dart';

class HomeScreen extends StatefulWidget {
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
  int _totalVeterinarians = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;

  // Using app theme colors
  Color get _primaryColor => AppTheme.primaryGreen;
  Color get _secondaryColor => AppTheme.primaryOrange;
  Color get _backgroundColor => Theme.of(context).colorScheme.background;
  Color get _surfaceColor => Theme.of(context).colorScheme.surface;
  Color get _onSurfaceColor => Theme.of(context).colorScheme.onSurface;
  Color get _onBackgroundColor => Theme.of(context).colorScheme.onBackground;
  Color get _shadowColor => Colors.black.withOpacity(0.08);

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
    try {
      if (AuthService.isAuthenticated) {
        // Get real statistics from Firebase
        final lostPetsStream = PetReportsService.getLostPetsStream();
        final foundPetsStream = PetReportsService.getFoundPetsStream();
        final userId = AuthService.userId;

        // Listen to streams and update counts
        lostPetsStream.listen((lostPets) {
          if (mounted) {
            setState(() {
              _totalLostPets = lostPets.length;
            });
          }
        });

        foundPetsStream.listen((foundPets) {
          if (mounted) {
            setState(() {
              _totalFoundPets = foundPets.length;
            });
          }
        });

        if (userId != null) {
          // Get unread messages count
          final unreadStream = ChatService.getUnreadMessageCountStream(userId);
          unreadStream.listen((count) {
            if (mounted) {
              setState(() {
                _unreadMessages = count;
              });
            }
          });
        }

        // Get veterinarians count
        final vetsStream = ChatService.getVeterinariansStream();
        vetsStream.listen((vets) {
          if (mounted) {
            setState(() {
              _totalVeterinarians = vets.length;
              _isLoading = false;
            });
            _shimmerController.stop();
          }
        });
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

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildBackgroundElements(),

            // Main content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header Section
                  SliverToBoxAdapter(child: _buildEnhancedHeader()),

                  // Welcome Section
                  SliverToBoxAdapter(child: _buildWelcomeSection()),

                  // Statistics Cards
                  //SliverToBoxAdapter(child: _buildStatisticsCards()),

                  // Menu Items Section
                  SliverToBoxAdapter(child: _buildEnhancedMenuItems()),

                  // Bottom spacing
                  SliverToBoxAdapter(child: SizedBox(height: 30.h)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingMedicalButton(),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating circles
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Positioned(
              top: 100.h + _floatingAnimation.value,
              right: 30.w,
              child: Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Positioned(
              top: 300.h - _floatingAnimation.value * 0.5,
              left: 20.w,
              child: Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        // Dotted pattern
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/dotted_pattern.svg',
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.grey.withOpacity(0.2),
              BlendMode.srcOver,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedHeader() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.3),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile section
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(),
                        child: Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () => _navigateToProfile(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                                      Text(
                            TranslationService.instance.translate('home.greeting'),
                            style: TextStyle(
                              color: _onBackgroundColor,
                              fontSize: 14.sp,
                            ),
                          ),
                          Text(
                            TranslationService.instance.translate('home.welcome_message'),
                            style: TextStyle(
                              color: _onSurfaceColor,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Notifications
                  Stack(
                    children: [
                      Container(
                        width: 45.w,
                        height: 45.h,
                        decoration: BoxDecoration(
                          color: _surfaceColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: _primaryColor,
                          size: 22.sp,
                        ),
                      ),
                      if (_unreadMessages > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 20.w,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadMessages > 9 ? '9+' : '$_unreadMessages',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor,
                    _primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alife - أليفي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'منصتك المتكاملة لخدمات الحيوانات الأليفة',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pets,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.7),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: 135.h,
              margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
              child: Row(
                children: [
                  _buildStatCard(
                    title: TranslationService.instance.translate('home.lost_pets'),
                    count: _totalLostPets,
                    color: AppTheme.error,
                    icon: Icons.search,
                  ),
                  SizedBox(width: 12.w),
                  _buildStatCard(
                    title: TranslationService.instance.translate('home.adoption_pets'),
                    count: _totalFoundPets,
                    color: _primaryColor,
                    icon: Icons.favorite,
                  ),
                  SizedBox(width: 12.w),
                  _buildStatCard(
                    title: TranslationService.instance.translate('home.veterinarians'),
                    count: _totalVeterinarians,
                    color: _secondaryColor,
                    icon: Icons.medical_services,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 35.w,
              height: 35.h,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 18.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _isLoading ? '--' : count.toString(),
              style: TextStyle(
                color: _onSurfaceColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: _onBackgroundColor,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMenuItems() {
    final menuItems = [
      {
        'title': TranslationService.instance.translate('home.lost_animals'),
        'subtitle': TranslationService.instance.translate('home.lost_animals_subtitle'),
        'icon': Icons.search,
        'count': _totalLostPets,
        'color': AppTheme.error,
        'onTap': () => _navigateToLostPets(),
      },
      {
        'title': TranslationService.instance.translate('home.adoption_animals'),
        'subtitle': TranslationService.instance.translate('home.adoption_animals_subtitle'),
        'icon': Icons.favorite,
        'count': _totalFoundPets,
        'color': _primaryColor,
        'onTap': () => _navigateToAdoption(),
      },
      {
        'title': TranslationService.instance.translate('home.mating_animals'),
        'subtitle': TranslationService.instance.translate('home.mating_animals_subtitle'),
        'icon': Icons.favorite_border,
        'count': 0,
        'color': _secondaryColor,
        'onTap': () => _navigateToMating(),
      },
      {
        'title': TranslationService.instance.translate('home.pet_stores'),
        'subtitle': TranslationService.instance.translate('home.pet_stores_subtitle'),
        'icon': Icons.store,
        'count': 0,
        'color': AppTheme.info,
        'onTap': () => _navigateToStores(),
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.instance.translate('home.available_services'),
            style: TextStyle(
              color: _onSurfaceColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15.h),
          ...menuItems.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;

            return AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value * (0.8 + index * 0.1)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: _buildEnhancedMenuItem(
                        title: item['title'],
                        subtitle: item['subtitle'],
                        icon: item['icon'],
                        count: item['count'],
                        color: item['color'],
                        onTap: item['onTap'],
                        isHighlighted: item['isHighlighted'] ?? false,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEnhancedMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isHighlighted
            ? Border.all(color: _secondaryColor, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: _onSurfaceColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: _onBackgroundColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios,
                  color: _onBackgroundColor,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  void _navigateToLostPets() {
    // Navigate to lost-found screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LostFoundScreen(),
      ),
    );
  }

  void _navigateToAdoption() {
    // Navigate to lost-found screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LostFoundScreen(),
      ),
    );
  }

  void _navigateToMating() {
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.instance.translate('home.mating_animals')),
        content: Text(TranslationService.instance.translate('common.feature_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.instance.translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void _navigateToStores() {
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.instance.translate('home.pet_stores')),
        content: Text(TranslationService.instance.translate('common.feature_development')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.instance.translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void _navigateToVeterinary() {
    // Navigate to veterinary screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EnhancedVeterinaryScreen(),
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleProfileScreen(),
      ),
    );
  }

  Widget _buildFloatingMedicalButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(

            child: FloatingActionButton(
              onPressed: () => _navigateToVeterinary(),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(
                Icons.medical_services,
                color: _primaryColor,
                size: 40.sp,
              ),
            ),
          ),
        );
      },
    );
  }
}