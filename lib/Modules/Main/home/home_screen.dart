import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pet_reports_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../Widgets/translated_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // Real data from Firebase
  int _totalLostPets = 0;
  int _totalFoundPets = 0;
  int _totalVeterinarians = 0;
  int _unreadMessages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
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
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.lightGreen,
                      AppTheme.primaryOrange,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BackgroundPatternPainter(),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.only(top: 60.h, left: 20.w, right: 20.w),
                      child: AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25.r,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: Icon(
                                          Icons.pets,
                                          color: Colors.white,
                                          size: 30.sp,
                                        ),
                                      ),
                                      SizedBox(width: 15.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TranslatedText(
                                              'home.welcome',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(height: 5.h),
                                            TranslatedText(
                                              'home.subtitle',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                Icons.notifications_outlined,
                                                color: Colors.white,
                                                size: 24.sp,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(),
                  SizedBox(height: 30.h),
                  
                  // Statistics Cards
                  _buildStatisticsCards(),
                  SizedBox(height: 30.h),
                  
                  // Recent Activities
                  _buildRecentActivities(),
                  SizedBox(height: 30.h),
                  
                  // Featured Services
                  _buildFeaturedServices(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'home.quick_actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15.w,
          mainAxisSpacing: 15.h,
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionCard(
              icon: Icons.search,
              title: 'home.find_pet',
              subtitle: 'home.find_pet_desc',
              color: AppTheme.primaryGreen,
              onTap: () {
                // Navigate to find pet
              },
            ),
            _buildQuickActionCard(
              icon: Icons.medical_services,
              title: 'home.veterinary',
              subtitle: 'home.veterinary_desc',
              color: AppTheme.primaryOrange,
              onTap: () {
                // Navigate to veterinary
              },
            ),
            _buildQuickActionCard(
              icon: Icons.add_location,
              title: 'home.report_lost',
              subtitle: 'home.report_lost_desc',
              color: AppTheme.error,
              onTap: () {
                // Navigate to report lost
              },
            ),
            _buildQuickActionCard(
              icon: Icons.find_in_page,
              title: 'home.report_found',
              subtitle: 'home.report_found_desc',
              color: AppTheme.info,
              onTap: () {
                // Navigate to report found
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: TranslatedText(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 2.h),
              Flexible(
                child: TranslatedText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'home.statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.search_off,
                title: 'Lost Pets',
                value: _isLoading ? '...' : '$_totalLostPets',
                color: AppTheme.error,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.pets,
                title: 'Found Pets',
                value: _isLoading ? '...' : '$_totalFoundPets',
                color: AppTheme.success,
              ),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.medical_services,
                title: 'Veterinarians',
                value: _isLoading ? '...' : '$_totalVeterinarians',
                color: AppTheme.primaryOrange,
              ),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.message,
                title: 'Unread Messages',
                value: _isLoading ? '...' : '$_unreadMessages',
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          TranslatedText(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TranslatedText(
              'home.recent_activities',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: TranslatedText('home.view_all'),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return _buildActivityItem(
              icon: _getActivityIcon(index),
              title: _getActivityTitle(index),
              subtitle: _getActivitySubtitle(index),
              time: _getActivityTime(index),
              color: _getActivityColor(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'home.featured_services',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 280.w,
                margin: EdgeInsets.only(right: 15.w),
                child: _buildServiceCard(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(int index) {
    final services = [
      {
        'title': 'home.emergency_care',
        'description': 'home.emergency_care_desc',
        'icon': Icons.emergency,
        'color': AppTheme.error,
      },
      {
        'title': 'home.grooming',
        'description': 'home.grooming_desc',
        'icon': Icons.content_cut,
        'color': AppTheme.info,
      },
      {
        'title': 'home.vaccination',
        'description': 'home.vaccination_desc',
        'icon': Icons.vaccines,
        'color': AppTheme.success,
      },
    ];

    final service = services[index];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            service['color'] as Color,
            (service['color'] as Color).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (service['color'] as Color).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              service['icon'] as IconData,
              color: Colors.white,
              size: 32.sp,
            ),
            SizedBox(height: 16.h),
            TranslatedText(
              service['title'] as String,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            TranslatedText(
              service['description'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14.sp,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TranslatedText(
                  'home.book_now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for activity data
  IconData _getActivityIcon(int index) {
    final icons = [Icons.pets, Icons.medical_services, Icons.location_on];
    return icons[index];
  }

  String _getActivityTitle(int index) {
    final titles = ['New pet registered', 'Veterinary consultation', 'Pet found nearby'];
    return titles[index];
  }

  String _getActivitySubtitle(int index) {
    final subtitles = ['Golden Retriever added to your pets', 'Dr. Smith scheduled for tomorrow', 'Lost cat found in your area'];
    return subtitles[index];
  }

  String _getActivityTime(int index) {
    final times = ['2h ago', '1d ago', '3d ago'];
    return times[index];
  }

  Color _getActivityColor(int index) {
    final colors = [AppTheme.primaryGreen, AppTheme.primaryOrange, AppTheme.info];
    return colors[index];
  }
}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 30) {
      for (int j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
