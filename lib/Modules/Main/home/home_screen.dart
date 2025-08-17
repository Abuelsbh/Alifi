import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';

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
              Text(
                'Welcome to Alifi',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Your pet care companion',
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
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.9,
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.medical_services,
              title: 'Veterinary\nConsultation',
              color: AppTheme.primaryGreen,
              onTap: () {
                // TODO: Navigate to veterinary
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.search,
              title: 'Lost & Found\nPets',
              color: AppTheme.primaryOrange,
              onTap: () {
                // TODO: Navigate to lost & found
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.store,
              title: 'Pet Stores\nNearby',
              color: AppTheme.info,
              onTap: () {
                // TODO: Navigate to stores
              },
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.favorite,
              title: 'Adoption &\nBreeding',
              color: AppTheme.warning,
              onTap: () {
                // TODO: Navigate to adoption
              },
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
            Text(
              'Latest Community Posts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: View all posts
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildPostCard(
          context,
          title: 'Lost Golden Retriever',
          description: 'Lost my 3-year-old Golden Retriever named Max in Central Park area. Please help!',
          location: 'Central Park, New York',
          time: '2 hours ago',
          type: 'Lost',
          color: AppTheme.primaryOrange,
        ),
        SizedBox(height: 12.h),
        _buildPostCard(
          context,
          title: 'Found Black Cat',
          description: 'Found a friendly black cat with white paws near the library. Looking for owner.',
          location: 'Downtown Library',
          time: '4 hours ago',
          type: 'Found',
          color: AppTheme.primaryGreen,
        ),
        SizedBox(height: 12.h),
        _buildPostCard(
          context,
          title: 'Veterinary Consultation Available',
          description: 'Dr. Sarah Johnson is available for online consultations today. Book your slot!',
          location: 'Online',
          time: '6 hours ago',
          type: 'Veterinary',
          color: AppTheme.info,
        ),
      ],
    );
  }

  Widget _buildPostCard(
    BuildContext context, {
    required String title,
    required String description,
    required String location,
    required String time,
    required String type,
    required Color color,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: color,
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
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),
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