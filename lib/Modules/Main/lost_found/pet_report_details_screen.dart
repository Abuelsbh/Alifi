import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/translation_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';

class PetReportDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const PetReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = report['type'] == 'lost';
    final petDetails = report['petDetails'] as Map<String, dynamic>? ?? {};
    final contactInfo = report['contactInfo'] as Map<String, dynamic>? ?? {};
    final location = report['location'] as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isLost, petDetails),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderCard(context, isLost, petDetails),
                _buildLocationCard(context, location),
                _buildContactCard(context, contactInfo),
                _buildDetailsCard(context, petDetails, isLost),
                if (isLost && report['reward'] != null)
                  _buildRewardCard(context),
                if (!isLost && report['shelterInfo'] != null)
                  _buildShelterCard(context),
                _buildActionButtons(context, isLost),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, isLost, contactInfo),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isLost, Map<String, dynamic> petDetails) {
    final imageUrls = report['imageUrls'] as List<dynamic>? ?? [];
    
    return SliverAppBar(
      expandedHeight: 250.h,
      floating: false,
      pinned: true,
      backgroundColor: isLost ? AppTheme.error : AppTheme.success,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          petDetails['name'] ?? (isLost ? TranslationService.instance.translate('lost_pet') : TranslationService.instance.translate('found_pet')),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrls.isNotEmpty)
              _buildImageCarousel(context, imageUrls, isLost)
            else
              _buildDefaultBackground(isLost),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _shareReport(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'report':
                _reportPost(context);
                break;
              case 'save':
                _saveReport(context);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  const Icon(Icons.bookmark_border),
                  const SizedBox(width: 8),
                  Text(TranslationService.instance.translate('save')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(TranslationService.instance.translate('report'), style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCarousel(BuildContext context, List<dynamic> imageUrls, bool isLost) {
    return _ImageCarousel(
      imageUrls: imageUrls,
      isLost: isLost,
      onImageTap: (index) => _showFullScreenImage(context, imageUrls, index),
    );
  }

  void _showFullScreenImage(BuildContext context, List<dynamic> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageView(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildDefaultBackground(bool isLost) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isLost ? AppTheme.error : AppTheme.success,
            isLost ? AppTheme.error.withValues(alpha: 0.8) : AppTheme.success.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80.sp,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isLost, Map<String, dynamic> petDetails) {
    final createdAt = report['createdAt'];
    final timeAgo = _getTimeAgo(createdAt);
    final isUrgent = report['isUrgent'] == true;
    final helpCount = report['helpCount'] ?? 0;
    
    return Container(
      margin: EdgeInsets.all(16.w),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isLost 
                          ? AppTheme.error.withValues(alpha: 0.1)
                          : AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      isLost ? TranslationService.instance.translate('lost') : TranslationService.instance.translate('found'),
                      style: TextStyle(
                        color: isLost ? AppTheme.error : AppTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  
                  if (isUrgent) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 12.sp,
                            color: AppTheme.warning,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            TranslationService.instance.translate('urgent'),
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Text(
                report['description'] ?? TranslationService.instance.translate('no_description'),
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  _buildStatItem(TranslationService.instance.translate('views'), report['viewCount'] ?? 0),
                  SizedBox(width: 16.w),
                  _buildStatItem(TranslationService.instance.translate('shares'), report['shareCount'] ?? 0),
                  SizedBox(width: 16.w),
                  _buildStatItem(TranslationService.instance.translate('help'), helpCount),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Row(
      children: [
        Icon(
          Icons.remove_red_eye,
          size: 16.sp,
          color: Colors.grey[600],
        ),
        SizedBox(width: 4.w),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, Map<String, dynamic> location) {
    final address = location['address'] ?? '';
    final coordinates = location['coordinates'];
    
    if (address.isEmpty && coordinates == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.primaryGreen,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    TranslationService.instance.translate('location'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              if (address.isNotEmpty)
                Text(
                  address,
                  style: TextStyle(fontSize: 14.sp),
                ),
              
              if (coordinates != null) ...[
                SizedBox(height: 8.h),
                CustomButton(
                  text: TranslationService.instance.translate('view_on_map'),
                  onPressed: () => _openMap(context),
                  backgroundColor: AppTheme.info,
                  textColor: Colors.white,
                  height: 42.h,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Map<String, dynamic> contactInfo) {
    final phone = contactInfo['phone'];
    final email = contactInfo['email'];
    final preferredContact = contactInfo['preferredContact'] ?? TranslationService.instance.translate('phone');
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_phone,
                    color: AppTheme.primaryGreen,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    TranslationService.instance.translate('contact_information'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              if (phone != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        phone,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    CustomButton(
                      text: TranslationService.instance.translate('call'),
                      onPressed: () => _makePhoneCall(context, phone),
                      backgroundColor: AppTheme.success,
                      textColor: Colors.white,
                      height: 42.h,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              
              if (email != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 16.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    CustomButton(
                      text: TranslationService.instance.translate('email'),
                      onPressed: () => _sendEmail(context, email),
                      backgroundColor: AppTheme.info,
                      textColor: Colors.white,
                      height: 42.h,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${TranslationService.instance.translate('preferred_method')}: $preferredContact',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, Map<String, dynamic> petDetails, bool isLost) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: AppTheme.primaryGreen,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    TranslationService.instance.translate('pet_details'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              _buildDetailRow(TranslationService.instance.translate('type'), petDetails['type']),
              _buildDetailRow(TranslationService.instance.translate('breed'), petDetails['breed']),
              _buildDetailRow(TranslationService.instance.translate('age'), petDetails['age']),
              _buildDetailRow(TranslationService.instance.translate('gender'), petDetails['gender']),
              _buildDetailRow(TranslationService.instance.translate('color'), petDetails['color']),
              _buildDetailRow(TranslationService.instance.translate('size'), petDetails['size']),
              
              if (petDetails['distinguishingMarks'] != null) ...[
                SizedBox(height: 8.h),
                Text(
                  '${TranslationService.instance.translate('distinguishing_marks')}:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  petDetails['distinguishingMarks'],
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
              
              if (petDetails['personality'] != null) ...[
                SizedBox(height: 8.h),
                Text(
                  '${TranslationService.instance.translate('personality')}:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  petDetails['personality'],
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
              
              if (petDetails['medicalConditions'] != null) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 16.sp,
                            color: AppTheme.warning,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${TranslationService.instance.translate('medical_conditions')}:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        petDetails['medicalConditions'],
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context) {
    final reward = report['reward'];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        backgroundColor: AppTheme.warning.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: AppTheme.warning,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.instance.translate('reward_for_finding'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$reward ${TranslationService.instance.translate('currency')}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShelterCard(BuildContext context) {
    final shelterInfoString = report['shelterInfo'] as String? ?? '';
    
    if (shelterInfoString.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        backgroundColor: AppTheme.success.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.home,
                    color: AppTheme.success,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    TranslationService.instance.translate('shelter_information'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Text(
                shelterInfoString,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isLost) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: TranslationService.instance.translate('help_with_search'),
              onPressed: () => _helpWithSearch(context),
              backgroundColor: AppTheme.primaryGreen,
              textColor: Colors.white,
              icon: Icons.favorite,
            ),
          ),
          SizedBox(width: 12.w),
          CustomButton(
            text: TranslationService.instance.translate('share'),
            onPressed: () => _shareReport(context),
            backgroundColor: AppTheme.info,
            textColor: Colors.white,
            icon: Icons.share,
            width: 100.w,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, bool isLost, Map<String, dynamic> contactInfo) {
    return FloatingActionButton.extended(
      onPressed: () => _contactOwner(context, contactInfo),
      backgroundColor: isLost ? AppTheme.error : AppTheme.success,
      label: Text(
        TranslationService.instance.translate('contact_owner'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.message, color: Colors.white),
    );
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return TranslationService.instance.translate('unknown');
    
    DateTime dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    } else if (createdAt is DateTime) {
      dateTime = createdAt;
    } else {
      return TranslationService.instance.translate('unknown');
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${TranslationService.instance.translate('ago')} ${difference.inDays} ${TranslationService.instance.translate('days')}';
    } else if (difference.inHours > 0) {
      return '${TranslationService.instance.translate('ago')} ${difference.inHours} ${TranslationService.instance.translate('hours')}';
    } else if (difference.inMinutes > 0) {
      return '${TranslationService.instance.translate('ago')} ${difference.inMinutes} ${TranslationService.instance.translate('minutes')}';
    } else {
      return TranslationService.instance.translate('now');
    }
  }

  void _helpWithSearch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(TranslationService.instance.translate('thanks_for_helping')),
          ],
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TranslationService.instance.translate('share_feature_coming_soon'))),
    );
  }

  void _contactOwner(BuildContext context, Map<String, dynamic> contactInfo) {
    final phone = contactInfo['phone'];
    
    if (phone != null) {
      _makePhoneCall(context, phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(TranslationService.instance.translate('contact_info_unavailable'))),
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.instance.translate('cannot_make_call'))),
        );
      }
    }
  }

  Future<void> _sendEmail(BuildContext context, String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TranslationService.instance.translate('cannot_open_email'))),
        );
      }
    }
  }

  void _openMap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(TranslationService.instance.translate('map_feature_coming_soon'))),
    );
  }

  void _reportPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.instance.translate('report_post')),
        content: Text(TranslationService.instance.translate('do_you_want_to_report_this_post')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationService.instance.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.instance.translate('report_sent')),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(TranslationService.instance.translate('report')),
          ),
        ],
      ),
    );
  }

  void _saveReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationService.instance.translate('post_saved')),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}

// ===== الحل النهائي للتنقل بين الصور =====
class _ImageCarousel extends StatefulWidget {
  final List<dynamic> imageUrls;
  final bool isLost;
  final Function(int) onImageTap;

  const _ImageCarousel({
    required this.imageUrls,
    required this.isLost,
    required this.onImageTap,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // الصور الرئيسية
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => widget.onImageTap(index),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultBackground(widget.isLost);
                    },
                  ),
                ),
              );
            },
          ),
          
          // مؤشرات الصفحات
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: _currentIndex == index ? 24.w : 8.w,
                    height: 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      color: _currentIndex == index 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          
          // عداد الصور
          Positioned(
            top: 50.h,
            right: 16.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // أزرار التنقل
          if (widget.imageUrls.length > 1) ...[
            // زر السابق
            Positioned(
              left: 16.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(25.r),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // زر التالي
            Positioned(
              right: 16.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex < widget.imageUrls.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(25.r),
                    child: Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultBackground(bool isLost) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isLost ? AppTheme.error : AppTheme.success,
            isLost ? AppTheme.error.withValues(alpha: 0.8) : AppTheme.success.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80.sp,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ===== شاشة كامل الشاشة =====
class _FullScreenImageView extends StatefulWidget {
  final List<dynamic> imageUrls;
  final int initialIndex;

  const _FullScreenImageView({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<_FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Share image functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // الصور
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.white, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              TranslationService.instance.translate('error_loading_image'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // أزرار التنقل لكامل الشاشة
          if (widget.imageUrls.length > 1) ...[
            // زر السابق
            Positioned(
              left: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // زر التالي
            Positioned(
              right: 20.w,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex < widget.imageUrls.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(30.r),
                    child: Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // مؤشرات الصفحات لكامل الشاشة
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 50.h,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 12.w,
                    height: 12.h,
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index 
                        ? Colors.white 
                        : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}