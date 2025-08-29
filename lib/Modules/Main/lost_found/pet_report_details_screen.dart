import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';

class PetReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const PetReportDetailsScreen({
    super.key,
    required this.report,
  });

  @override
  State<PetReportDetailsScreen> createState() => _PetReportDetailsScreenState();
}

class _PetReportDetailsScreenState extends State<PetReportDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _hasHelped = false;
  int _helpCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHelpStatus();
    _helpCount = widget.report['helpCount'] ?? 0;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpStatus() async {
    // TODO: Check if current user has helped with this report
    // This would check against a Firestore collection
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.report['type'] == 'lost';
    final petDetails = widget.report['petDetails'] as Map<String, dynamic>? ?? {};
    final contactInfo = widget.report['contactInfo'] as Map<String, dynamic>? ?? {};
    final location = widget.report['location'] as Map<String, dynamic>? ?? {};
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isLost, petDetails),
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeaderCard(isLost, petDetails),
                    _buildLocationCard(location),
                    _buildContactCard(contactInfo),
                    _buildDetailsCard(petDetails, isLost),
                    if (isLost && widget.report['reward'] != null)
                      _buildRewardCard(),
                    if (!isLost && widget.report['shelterInfo'] != null)
                      _buildShelterCard(),
                    _buildActionButtons(isLost),
                    SizedBox(height: 100.h), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isLost),
    );
  }

  Widget _buildSliverAppBar(bool isLost, Map<String, dynamic> petDetails) {
    final imageUrls = widget.report['imageUrls'] as List<dynamic>? ?? [];
    
    return SliverAppBar(
      expandedHeight: 250.h,
      floating: false,
      pinned: true,
      backgroundColor: isLost ? AppTheme.error : AppTheme.success,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          petDetails['name'] ?? (isLost ? 'حيوان مفقود' : 'حيوان موجود'),
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
              PageView.builder(
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultBackground(isLost);
                    },
                  );
                },
              )
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
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Image counter
            if (imageUrls.length > 1)
              Positioned(
                top: 50.h,
                right: 16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${imageUrls.length} صور',
                    style: TextStyle(
                      color: Colors.white,
                      
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareReport,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'report':
                _reportPost();
                break;
              case 'save':
                _saveReport();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.bookmark_border),
                  SizedBox(width: 8),
                  Text('حفظ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag, color: Colors.red),
                  SizedBox(width: 8),
                  Text('إبلاغ', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
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
            isLost ? AppTheme.error.withOpacity(0.8) : AppTheme.success.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80.sp,
          color: Colors.white.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isLost, Map<String, dynamic> petDetails) {
    final createdAt = widget.report['createdAt'];
    final timeAgo = _getTimeAgo(createdAt);
    final isUrgent = widget.report['isUrgent'] == true;
    
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
                          ? AppTheme.error.withOpacity(0.1)
                          : AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      isLost ? 'مفقود' : 'موجود',
                      style: TextStyle(
                        color: isLost ? AppTheme.error : AppTheme.success,
                        fontWeight: FontWeight.w600,
                        
                      ),
                    ),
                  ),
                  
                  if (isUrgent) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
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
                            'عاجل',
                            style: TextStyle(
                              color: AppTheme.warning,
                              
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
                      
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Text(
                widget.report['description'] ?? 'لا يوجد وصف',
                style: TextStyle(
                  
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.remove_red_eye,
                    count: widget.report['viewCount'] ?? 0,
                    label: 'مشاهدة',
                  ),
                  SizedBox(width: 16.w),
                  _buildStatItem(
                    icon: Icons.share,
                    count: widget.report['shareCount'] ?? 0,
                    label: 'مشاركة',
                  ),
                  SizedBox(width: 16.w),
                  _buildStatItem(
                    icon: Icons.favorite,
                    count: _helpCount,
                    label: 'مساعدة',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: Colors.grey[600],
        ),
        SizedBox(width: 4.w),
        Text(
          '$count $label',
          style: TextStyle(
            
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final area = location['area'] ?? 'غير محدد';
    final landmark = location['landmark'];
    
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
                    'الموقع',
                    style: TextStyle(
                      
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المنطقة: $area',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        if (landmark != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'علامة مميزة: $landmark',
                            style: TextStyle(
                              
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  CustomButton(
                    text: 'عرض الخريطة',
                    onPressed: _openMap,
                    backgroundColor: AppTheme.primaryGreen,
                    textColor: Colors.white,
                    
                    height: 36.h,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contactInfo) {
    final phone = contactInfo['phone'];
    final email = contactInfo['email'];
    final preferredContact = contactInfo['preferredContact'] ?? 'الهاتف';
    
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
                    'معلومات الاتصال',
                    style: TextStyle(
                      
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
                      text: 'اتصال',
                      onPressed: () => _makePhoneCall(phone),
                      backgroundColor: AppTheme.success,
                      textColor: Colors.white,
                      
                      height: 32.h,
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
                      text: 'إيميل',
                      onPressed: () => _sendEmail(email),
                      backgroundColor: AppTheme.info,
                      textColor: Colors.white,
                      
                      height: 32.h,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'الطريقة المفضلة: $preferredContact',
                  style: TextStyle(
                    
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

  Widget _buildDetailsCard(Map<String, dynamic> petDetails, bool isLost) {
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
                    'تفاصيل الحيوان',
                    style: TextStyle(
                      
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),
              
              _buildDetailRow('النوع', petDetails['type']),
              _buildDetailRow('السلالة', petDetails['breed']),
              _buildDetailRow('العمر', petDetails['age']),
              _buildDetailRow('الجنس', petDetails['gender']),
              _buildDetailRow('اللون', petDetails['color']),
              _buildDetailRow('الحجم', petDetails['size']),
              
              if (petDetails['distinguishingMarks'] != null) ...[
                SizedBox(height: 8.h),
                Text(
                  'علامات مميزة:',
                  style: TextStyle(
                    
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
                  'الشخصية:',
                  style: TextStyle(
                    
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
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.warning.withOpacity(0.3),
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
                            'حالة طبية خاصة:',
                            style: TextStyle(
                              
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
                
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    final reward = widget.report['reward'];
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        backgroundColor: AppTheme.warning.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.2),
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
                      'مكافأة للعثور عليه',
                      style: TextStyle(
                        
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$reward جنيه',
                      style: TextStyle(
                        
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

  Widget _buildShelterCard() {
    final shelterInfoString = widget.report['shelterInfo'] as String? ?? '';
    
    // If shelterInfo is empty, don't show the card
    if (shelterInfoString.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: CustomCard(
        backgroundColor: AppTheme.success.withOpacity(0.1),
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
                    'معلومات المأوى',
                    style: TextStyle(
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

  Widget _buildActionButtons(bool isLost) {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: _hasHelped ? 'تم المساعدة' : 'ساعد في البحث',
              onPressed: _hasHelped ? null : _helpWithSearch,
              backgroundColor: _hasHelped ? Colors.grey : AppTheme.primaryGreen,
              textColor: Colors.white,
              icon: _hasHelped ? Icons.check : Icons.favorite,
              isLoading: _isLoading,
            ),
          ),
          SizedBox(width: 12.w),
          CustomButton(
            text: 'مشاركة',
            onPressed: _shareReport,
            backgroundColor: AppTheme.info,
            textColor: Colors.white,
            icon: Icons.share,
            width: 100.w,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isLost) {
    return FloatingActionButton.extended(
      onPressed: _contactOwner,
      backgroundColor: isLost ? AppTheme.error : AppTheme.success,
      label: const Text(
        'تواصل مع المالك',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.message, color: Colors.white),
    );
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return 'غير محدد';
    
    DateTime dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    } else if (createdAt is DateTime) {
      dateTime = createdAt;
    } else {
      return 'غير محدد';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  Future<void> _helpWithSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Update help count in Firestore
      // TODO: Add user to helpers list
      
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _hasHelped = true;
        _helpCount++;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white),
              SizedBox(width: 8.w),
              const Text('شكراً لمساعدتك في البحث!'),
            ],
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _shareReport() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة المشاركة ستكون متاحة قريباً')),
    );
  }

  void _contactOwner() {
    final contactInfo = widget.report['contactInfo'] as Map<String, dynamic>? ?? {};
    final phone = contactInfo['phone'];
    
    if (phone != null) {
      _makePhoneCall(phone);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معلومات الاتصال غير متوفرة')),
      );
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح تطبيق البريد الإلكتروني')),
      );
    }
  }

  void _openMap() {
    // TODO: Implement map functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة الخريطة ستكون متاحة قريباً')),
    );
  }

  void _reportPost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إبلاغ عن المنشور'),
        content: const Text('هل تريد الإبلاغ عن هذا المنشور؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم إرسال البلاغ'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('إبلاغ'),
          ),
        ],
      ),
    );
  }

  void _saveReport() {
    // TODO: Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ المنشور'),
        backgroundColor: AppTheme.success,
      ),
    );
  }
} 