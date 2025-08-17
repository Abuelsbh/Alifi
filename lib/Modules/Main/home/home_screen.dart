import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/translated_custom_button.dart';
import '../../../Widgets/translated_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              SizedBox(height: 24.h),
              
              // Quick Actions
              _buildQuickActions(context),
              SizedBox(height: 24.h),
              
              // Latest Posts
              _buildLatestPosts(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: AppTheme.primaryGreen,
          child: Icon(
            Icons.pets,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranslatedText(
                'home.welcome',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TranslatedText(
                'home.subtitle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Open notifications
          },
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 24.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          'home.quick_actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'home.lost_pet',
                icon: Icons.search,
                type: ButtonType.secondary,
                onPressed: () {
                  // TODO: Navigate to lost pet report
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'home.found_pet',
                icon: Icons.pets,
                type: ButtonType.secondary,
                onPressed: () {
                  // TODO: Navigate to found pet report
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'home.veterinary_consultation',
                icon: Icons.medical_services,
                type: ButtonType.secondary,
                onPressed: () {
                  // TODO: Navigate to veterinary consultation
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TranslatedCustomButton(
                textKey: 'home.add_pet',
                icon: Icons.add,
                type: ButtonType.secondary,
                onPressed: () {
                  // TODO: Navigate to add pet
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
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
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestPosts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TranslatedText(
              'home.latest_posts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TranslatedCustomButton(
              textKey: 'home.view_all',
              type: ButtonType.text,
              onPressed: () {
                // TODO: Navigate to all posts
              },
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Mock data for latest posts
        _buildPostCard(
          context,
          title: 'Lost Golden Retriever',
          location: 'Downtown Area',
          time: '2 hours ago',
          isLost: true,
        ),
        SizedBox(height: 12.h),
        _buildPostCard(
          context,
          title: 'Found Black Cat',
          location: 'Park Street',
          time: '4 hours ago',
          isLost: false,
        ),
        SizedBox(height: 12.h),
        _buildPostCard(
          context,
          title: 'Lost Beagle Puppy',
          location: 'Shopping Mall',
          time: '6 hours ago',
          isLost: true,
        ),
      ],
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String title,
    required String location,
    required String time,
    required bool isLost,
  }) {
    return CustomCard(
      onTap: () {
        // TODO: Navigate to post details
      },
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isLost ? AppTheme.primaryOrange.withOpacity(0.1) : AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    isLost ? 'Lost' : 'Found',
                    style: TextStyle(
                      color: isLost ? AppTheme.primaryOrange : AppTheme.primaryGreen,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
                SizedBox(width: 4.w),
                Text(
                  location,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 