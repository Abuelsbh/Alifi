import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/pet_stores_service.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/translated_text.dart';

class StoreDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> store;

  const StoreDetailsScreen({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final rating = (store['rating'] ?? 4.0).toDouble();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: store['imageUrl'] != null && store['imageUrl'].isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: store['imageUrl'],
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      memCacheHeight: 500,
                      maxWidthDiskCache: 1920,
                      maxHeightDiskCache: 1080,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          // Store Details
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Name & Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store['name'] ?? 'Unknown Store',
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lightOnSurface,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: AppTheme.primaryGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${PetStoresService.getCategoryIcon(store['category'] ?? '')} ${PetStoresService.formatCategoryName(store['category'] ?? '')}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Rating
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : index < rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: AppTheme.warning,
                          size: 20.sp,
                        );
                      }),
                      SizedBox(width: 8.w),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightOnBackground,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(${Provider.of<AppLanguage>(context).translate('stores.rating')})',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.lightOnBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Description
                  if (store['description'] != null && store['description'].isNotEmpty) ...[
                    _buildSectionTitle(context, 'stores.description'),
                    SizedBox(height: 8.h),
                    Text(
                      store['description'],
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppTheme.lightOnBackground,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Contact Information
                  _buildSectionTitle(context, 'stores.contact_info'),
                  SizedBox(height: 12.h),
                  _buildContactCard(),

                  SizedBox(height: 24.h),

                  // Store Features
                  _buildSectionTitle(context, 'stores.features'),
                  SizedBox(height: 12.h),
                  _buildFeaturesCard(),

                  SizedBox(height: 24.h),

                  // Action Buttons
                  _buildActionButtons(context),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          PetStoresService.getCategoryIcon(store['category'] ?? ''),
          style: TextStyle(fontSize: 80.sp),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String titleKey) {
    return Text(
      Provider.of<AppLanguage>(context).translate(titleKey),
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppTheme.lightOnSurface,
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Address
          if (store['address'] != null && store['address'].isNotEmpty)
            _buildContactItem(
              icon: Icons.location_on,
              title: '${store['address']}, ${store['city'] ?? ''}',
              onTap: () => _openMap(),
            ),

          // Phone
          if (store['phone'] != null && store['phone'].isNotEmpty)
            _buildContactItem(
              icon: Icons.phone,
              title: store['phone'],
              onTap: () => _makePhoneCall(store['phone']),
            ),

          // Email
          if (store['email'] != null && store['email'].isNotEmpty)
            _buildContactItem(
              icon: Icons.email,
              title: store['email'],
              onTap: () => _sendEmail(store['email']),
            ),

          // Website
          if (store['website'] != null && store['website'].isNotEmpty)
            _buildContactItem(
              icon: Icons.language,
              title: store['website'],
              onTap: () => _openWebsite(store['website']),
            ),

          // Working Hours
          if (store['workingHours'] != null && store['workingHours'].isNotEmpty)
            _buildContactItem(
              icon: Icons.access_time,
              title: store['workingHours'],
              onTap: null,
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.lightOnBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppTheme.lightOnBackground.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = <Map<String, dynamic>>[];

    if (store['deliveryAvailable'] == true) {
      features.add({
        'icon': Icons.local_shipping,
        'title': 'Delivery Available',
        'description': 'Home delivery service',
      });
    }

    if (store['website'] != null && store['website'].isNotEmpty) {
      features.add({
        'icon': Icons.language,
        'title': 'Online Store',
        'description': 'Visit our website',
      });
    }

    features.add({
      'icon': Icons.store,
      'title': 'Physical Store',
      'description': 'Visit our location',
    });

    features.add({
      'icon': Icons.verified,
      'title': 'Verified Store',
      'description': 'Trusted by Alifi',
    });

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    feature['icon'],
                    color: AppTheme.primaryGreen,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightOnSurface,
                        ),
                      ),
                      Text(
                        feature['description'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.lightOnBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Call Button
        if (store['phone'] != null && store['phone'].isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall(store['phone']),
              icon: const Icon(Icons.phone),
              label: const TranslatedText('common.call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

        SizedBox(height: 12.h),

        // Visit Website Button
        if (store['website'] != null && store['website'].isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openWebsite(store['website']),
              icon: const Icon(Icons.language),
              label: const TranslatedText('stores.visit_website'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

        SizedBox(height: 12.h),

        // Get Directions Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openMap,
            icon: const Icon(Icons.directions),
            label: const TranslatedText('stores.get_directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action Methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry about ${store['name']}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openWebsite(String website) async {
    final Uri websiteUri = Uri.parse(website);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    final address = '${store['address']}, ${store['city']}';
    final Uri mapUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }
} 