import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import 'pet_report_details_screen.dart';

class UnifiedPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String reportType; // 'lost' or 'found'
  final VoidCallback? onMessagePressed;

  const UnifiedPetCard({
    super.key,
    required this.pet,
    required this.reportType,
    this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final petDetails = pet['petDetails'] as Map<String, dynamic>? ?? {};
    final petName = petDetails['name'] ?? pet['petName'] ?? 'حيوان ${reportType == 'lost' ? 'مفقود' : 'موجود'}';
    final petType = petDetails['type'] ?? pet['petType'] ?? 'غير محدد';
    final breed = petDetails['breed'] ?? pet['breed'] ?? '';
    final color = petDetails['color'] ?? pet['color'] ?? '';
    final location = reportType == 'lost' 
        ? (pet['lastSeenLocation'] ?? pet['address'] ?? 'موقع غير محدد')
        : (pet['foundLocation'] ?? pet['address'] ?? 'موقع غير محدد');
    final reward = pet['reward'] ?? 0;
    final isUrgent = pet['isUrgent'] ?? false;
    final isInShelter = pet['isInShelter'] ?? false;
    final imageUrls = pet['imageUrls'] as List<dynamic>? ?? [];
    final userId = pet['userId'] ?? '';
    final currentUserId = AuthService.userId ?? '';
    final isOwnReport = userId == currentUserId;

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetReportDetailsScreen(report: pet),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.grey[100],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pet image
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey[300],
                    ),
                    child: imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              imageUrls.first.toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.pets,
                                    size: 40.sp,
                                    color: reportType == 'lost' ? AppTheme.primaryGreen : AppTheme.success
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.pets,
                            size: 40.sp,
                            color: reportType == 'lost' ? AppTheme.primaryGreen : AppTheme.success
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // Pet info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                petName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: reportType == 'lost'
                                    ? (isUrgent ? AppTheme.error : AppTheme.primaryGreen)
                                    : AppTheme.success,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                reportType == 'lost'
                                    ? (isUrgent ? 'عاجل' : 'مفقود')
                                    : 'موجود',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$petType${breed.isNotEmpty ? ' - $breed' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: reportType == 'lost' ? AppTheme.primaryGreen : AppTheme.success,
                          ),
                        ),
                        if (color.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            'اللون: $color',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14.sp, color: Colors.grey[600]),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                location.isNotEmpty ? location : 'موقع غير محدد',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (reportType == 'lost' && reward > 0) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.monetization_on, size: 14.sp, color: AppTheme.primaryOrange),
                              SizedBox(width: 4.w),
                              Text(
                                'مكافأة: $reward جنيه',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (reportType == 'found' && isInShelter) ...[
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'في مأوى آمن',
                              style: TextStyle(
                                color: AppTheme.info,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (reportType == 'found' && pet['description'] != null) ...[
                SizedBox(height: 12.h),
                Text(
                  pet['description'] ?? 'لا يوجد وصف',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 12.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'تفاصيل',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetReportDetailsScreen(report: pet),
                          ),
                        );
                      },
                      backgroundColor: reportType == 'lost' ? AppTheme.primaryGreen : AppTheme.success,
                      textColor: Colors.white,
                      height: 42.h,
                    ),
                  ),
                  if (!isOwnReport) ...[
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomButton(
                        text: 'رسالة',
                        onPressed: onMessagePressed ?? () {
                          _showMessageDialog(context, pet);
                        },
                        backgroundColor: AppTheme.primaryOrange,
                        textColor: Colors.white,
                        height: 42.h,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageDialog(BuildContext context, Map<String, dynamic> pet) {
    final petName = pet['petDetails']?['name'] ?? pet['petName'] ?? 'الحيوان';
    final reportTypeText = reportType == 'lost' ? 'مفقود' : 'موجود';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رسالة إلى صاحب الإعلان'),
        content: Text('هل تريد إرسال رسالة إلى صاحب إعلان $petName $reportTypeText؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('سيتم إضافة ميزة المحادثة قريباً'),
                  backgroundColor: AppTheme.info,
                ),
              );
            },
            child: Text('إرسال رسالة'),
          ),
        ],
      ),
    );
  }
}