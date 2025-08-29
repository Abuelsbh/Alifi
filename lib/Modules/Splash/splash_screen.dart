import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/firebase/firebase_config.dart';
import '../../Widgets/translated_text.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _backgroundOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    // Background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _backgroundOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() async {
    // Start background animation
    _backgroundController.forward();

    // Wait a bit then start logo animation
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    // Wait for logo animation to complete then start text animation
    await Future.delayed(const Duration(milliseconds: 1000));
    _textController.forward();

    // Initialize test data including demo veterinarian
    await _initializeTestData();

    // Wait for all animations to complete then navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      // Check if Firebase is in demo mode
      if (FirebaseConfig.isDemoMode) {
        // Firebase not configured, show demo mode screen
        context.go('/demo');
      } else if (AuthService.isAuthenticated) {
        // User is logged in, go to main screen
        context.go('/main');
      } else {
        // User is not logged in, go to test register screen for debugging
        context.go('/test-register');
      }
    }
  }

  // Initialize test data including demo veterinarian
  Future<void> _initializeTestData() async {
    try {
      print('🔵 Initializing test data for demo...');
      
      if (FirebaseConfig.isDemoMode) {
        print('⚠️ Demo mode - skipping Firebase data initialization');
        return;
      }
      
      // Add demo veterinarian if not exists
      final vetsQuery = await FirebaseConfig.firestore
          .collection('veterinarians')
          .where('email', isEqualTo: 'dr.ahmed@vetclinic.com')
          .get();

      if (vetsQuery.docs.isEmpty) {
        print('🩺 Adding demo veterinarian...');
        
        await FirebaseConfig.firestore
            .collection('veterinarians')
            .add({
          'name': 'د. أحمد محمد الطبيب',
          'email': 'dr.ahmed@vetclinic.com',
          'specialization': 'طب بيطري عام',
          'yearsOfExperience': 8,
          'rating': 4.8,
          'totalReviews': 156,
          'profilePhoto': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400',
          'bio': 'طبيب بيطري متخصص في علاج الحيوانات الأليفة مع خبرة 8 سنوات في العلاج والجراحة',
          'isActive': true,
          'isOnline': true,
          'isAvailable': true,
          'consultationFee': 150,
          'availableFrom': '09:00',
          'availableTo': '18:00',
          'phoneNumber': '+201234567890',
          'address': 'عيادة الرحمة البيطرية، التجمع الخامس، القاهرة الجديدة',
          'clinicName': 'عيادة الرحمة البيطرية',
          'languages': ['العربية', 'الإنجليزية'],
          'services': [
            'فحص شامل',
            'التطعيمات', 
            'علاج الأمراض',
            'الجراحة البسيطة',
            'استشارات التغذية'
          ],
          'workingDays': ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء'],
          'emergencyAvailable': true,
          'videoCallAvailable': true,
          'homeVisitAvailable': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        
        print('✅ Demo veterinarian added successfully');
      } else {
        print('✅ Demo veterinarian already exists');
      }
      
    } catch (e) {
      print('⚠️ Error initializing test data: $e');
      // Continue anyway - this is not critical for app startup
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundOpacityAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(_backgroundOpacityAnimation.value),
                  AppTheme.lightGreen.withOpacity(_backgroundOpacityAnimation.value * 0.8),
                  AppTheme.primaryOrange.withOpacity(_backgroundOpacityAnimation.value * 0.6),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: SplashBackgroundPainter(
                      animation: _backgroundOpacityAnimation,
                    ),
                  ),
                ),
                
                // Floating particles
                ...List.generate(20, (index) => _buildFloatingParticle(index)),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      AnimatedBuilder(
                        animation: _logoController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Opacity(
                              opacity: _logoOpacityAnimation.value,
                              child: Container(
                                width: 120.w,
                                height: 120.h,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.pets,
                                  size: 60.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 40.h),
                      
                      // App name
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _textSlideAnimation.value),
                            child: Opacity(
                              opacity: _textOpacityAnimation.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Alifi',
                                    style: TextStyle(
                                      fontSize: 48.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  TranslatedText(
                                    'app_description',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w300,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 60.h),
                      
                      // Loading indicator
                      AnimatedBuilder(
                        animation: _textController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 40.w,
                                  height: 40.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Bottom decoration
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _backgroundOpacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _backgroundOpacityAnimation.value,
                        child: Container(
                          height: 100.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 123) % 100;
    final size = (random % 20 + 10).toDouble();
    final left = (random % 100).toDouble();

    
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned(
          left: left.w,
          top: (index * 50).h,
          child: Opacity(
            opacity: _backgroundOpacityAnimation.value * 0.6,
            child: Container(
              width: size.w,
              height: size.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  SplashBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1 * animation.value)
      ..strokeWidth = 1;

    // Draw animated pattern
    for (int i = 0; i < size.width; i += 40) {
      for (int j = 0; j < size.height; j += 40) {
        final offset = Offset(i.toDouble(), j.toDouble());
        canvas.drawCircle(offset, 1, paint);
      }
    }

    // Draw animated waves
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.05 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 20.0 + (i * 10);
      final waveOffset = animation.value * 100 * (i + 1);
      
      path.moveTo(0, size.height * 0.7 + waveOffset);
      
      for (double x = 0; x < size.width; x += 10) {
        final y = size.height * 0.7 + 
                 waveOffset + 
                 (waveHeight * (i + 1)) *
                 (animation.value * 0.5 + 0.5) * 
                 (x / size.width) * 
                 (1 + 0.5 * (i + 1));
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}