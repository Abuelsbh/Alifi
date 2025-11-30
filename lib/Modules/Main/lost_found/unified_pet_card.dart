import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import 'unified_pet_details_screen.dart';

class UnifiedPetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final Color color;
  final String reportType;
  final VoidCallback? onMessagePressed;

  const UnifiedPetCard({
    super.key,
    required this.pet,
    required this.reportType,
    this.onMessagePressed, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final petDetails = pet['petDetails'] as Map<String, dynamic>? ?? {};
    final petName = petDetails['name'] ?? pet['petName'] ?? 'حيوان ${reportType == 'lost' ? 'مفقود' : 'موجود'}';
    final petType = petDetails['type'] ?? pet['petType'] ?? 'غير محدد';
    final imageUrls = pet['imageUrls'] as List<dynamic>? ?? [];


    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.report,
              report: pet,
            ),
          ),
        );
      },
      child:Stack(
        clipBehavior: Clip.none,
        children: [
          // الـ Card الأساسي
          Container(
            width: double.infinity,
            height: 75.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 130.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      petName,
                      style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(
                        color: ThemeClass.of(context).backGroundColor,
                      ),
                    ),
                    Text(
                      petType,
                      style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(
                        color: ThemeClass.of(context).backGroundColor,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color == ThemeClass.of(context).primaryColor
                      ? ThemeClass.of(context).secondaryColor
                      : ThemeClass.of(context).primaryColor,
                )
              ],
            ),
          ),

          Positioned(
            top: 6.h,
            left: 16.w,
            child: Container(
              height: 83.h,
              width: 121.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                color: Colors.grey[300],
              ),
              child: imageUrls.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24.r),
                  bottomRight: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrls.first.toString(),
                  fit: BoxFit.cover,
                  memCacheWidth: 121.w.toInt(),
                  memCacheHeight: 83.h.toInt(),
                  maxWidthDiskCache: 500,
                  maxHeightDiskCache: 500,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: reportType == 'lost'
                            ? AppTheme.primaryGreen
                            : AppTheme.success,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.pets,
                    size: 40.sp,
                    color: reportType == 'lost'
                        ? AppTheme.primaryGreen
                        : AppTheme.success,
                  ),
                ),
              )
                  : Icon(
                Icons.pets,
                size: 40.sp,
                color: reportType == 'lost'
                    ? AppTheme.primaryGreen
                    : AppTheme.success,
              ),
            ),
          ),
        ],
      )
    );
  }
}