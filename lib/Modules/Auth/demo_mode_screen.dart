import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/Theme/app_theme.dart';
import '../../Widgets/translated_text.dart';
import '../../Widgets/translated_custom_button.dart';

class DemoModeScreen extends StatelessWidget {
  static const String routeName = '/demo';
  
  const DemoModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60.r),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 60.sp,
                  color: AppTheme.warning,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Title
              Text(
                'Demo Mode',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              // Description
              Text(
                'Firebase is not configured properly',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24.h),
              
              // Instructions
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To enable full functionality:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildStep('1.', 'Create a Firebase project'),
                    _buildStep('2.', 'Add your app to the project'),
                    _buildStep('3.', 'Download configuration files'),
                    _buildStep('4.', 'Run: flutter packages pub run flutterfire_cli:main configure'),
                    _buildStep('5.', 'Restart the app'),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Continue Button
              TranslatedCustomButton(
                textKey: 'Continue in Demo Mode',
                onPressed: () {
                  context.go('/main');
                },
                backgroundColor: AppTheme.warning,
              ),
              
              SizedBox(height: 16.h),
              
              // Learn More
              TextButton(
                onPressed: () {
                  // TODO: Open Firebase documentation
                },
                child: Text(
                  'Learn more about Firebase setup',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppTheme.warning,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 