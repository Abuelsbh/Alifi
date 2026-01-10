import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/translated_text.dart';
import 'veterinarian_management_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const String routeName = '/admin';
  
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedText('admin.dashboard_title'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/main'),
            tooltip: TranslationService.instance.translate('admin.back_to_app'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.7)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, 
                               color: Colors.white, size: 32.sp),
                          SizedBox(width: 12.w),
                          TranslatedText(
                            'admin.admin_control_panel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      TranslatedText(
                        'admin.admin_control_panel_subtitle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Statistics Section
              TranslatedText(
                'admin.quick_stats',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightOnSurface,
                ),
              ),
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  Expanded(child: _buildStatCard('👥', TranslationService.instance.translate('admin.total_users'), '150+', AppTheme.info)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildStatCard('🏥', TranslationService.instance.translate('admin.veterinarians'), '12', AppTheme.primaryGreen)),
                  SizedBox(width: 16.w),
                  Expanded(child: _buildStatCard('🐕', TranslationService.instance.translate('admin.active_reports'), '45', AppTheme.primaryOrange)),
                ],
              ),
              
              SizedBox(height: 32.h),
              
              // Management Options
              TranslatedText(
                'admin.management_options',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightOnSurface,
                ),
              ),
              SizedBox(height: 16.h),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 1.2,
                children: [
                  _buildManagementCard(
                    context,
                    icon: Icons.local_hospital,
                    title: TranslationService.instance.translate('admin.veterinarian_management'),
                    subtitle: TranslationService.instance.translate('admin.veterinarian_management_subtitle'),
                    color: AppTheme.primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VeterinarianManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.people,
                    title: TranslationService.instance.translate('admin.user_management'),
                    subtitle: TranslationService.instance.translate('admin.user_management_subtitle'),
                    color: AppTheme.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminUserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.report,
                    title: TranslationService.instance.translate('admin.report_management'),
                    subtitle: TranslationService.instance.translate('admin.report_management_subtitle'),
                    color: AppTheme.primaryOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminReportsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildManagementCard(
                    context,
                    icon: Icons.settings,
                    title: TranslationService.instance.translate('admin.app_settings'),
                    subtitle: TranslationService.instance.translate('admin.app_settings_subtitle'),
                    color: Colors.grey[600]!,
                    onTap: () {
                      // TODO: Navigate to app settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: TranslatedText('admin.app_settings_coming_soon')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 24.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
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
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightOnSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 16.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 