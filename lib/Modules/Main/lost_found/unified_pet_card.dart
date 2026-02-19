import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Utilities/theme_helper.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/custom_card.dart';
import 'unified_pet_details_screen.dart';

class UnifiedPetCard extends StatelessWidget {
  final Map<String, dynamic>? pet;
  final AdoptionPetModel? adoptionPet;
  final BreedingPetModel? breedingPet;
  final Color color;
  final String reportType;
  final VoidCallback? onMessagePressed;

  const UnifiedPetCard({
    super.key,
    this.pet,
    this.adoptionPet,
    this.breedingPet,
    required this.reportType,
    this.onMessagePressed,
    required this.color,
  }) : assert(
          (pet != null && adoptionPet == null && breedingPet == null) ||
          (pet == null && adoptionPet != null && breedingPet == null) ||
          (pet == null && adoptionPet == null && breedingPet != null),
        );

  @override
  Widget build(BuildContext context) {
    final String displayTitle;
    final List<dynamic> imageUrls;
    final dynamic createdAt;
    final VoidCallback onTap;

    if (pet != null) {
      final petDetails = pet!['petDetails'] as Map<String, dynamic>? ?? {};
      final reportTitle = pet!['title']?.toString() ?? '';
      final t = Provider.of<AppLanguage>(context, listen: false);
      final lostOrFound = reportType == 'lost' ? t.translate('common.lost_pet') : t.translate('common.found_pet');
      final petName = petDetails['name'] ?? pet!['petName'] ?? '${t.translate('common.pet')} $lostOrFound';
      displayTitle = reportTitle.isNotEmpty ? reportTitle : petName;
      imageUrls = pet!['imageUrls'] as List<dynamic>? ?? [];
      createdAt = pet!['createdAt'];
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.report,
              report: pet,
            ),
          ),
        );
      };
    } else if (adoptionPet != null) {
      displayTitle = adoptionPet!.title?.isNotEmpty == true ? adoptionPet!.title! : adoptionPet!.petName;
      imageUrls = adoptionPet!.photos;
      createdAt = adoptionPet!.createdAt;
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.adoption,
              adoptionPet: adoptionPet,
            ),
          ),
        );
      };
    } else {
      final title = breedingPet!.title?.trim();
      final name = breedingPet!.petName.trim();
      final fallback = Provider.of<AppLanguage>(context, listen: false).translate('breeding.breeding_pet');
      displayTitle = (title != null && title.isNotEmpty)
          ? title
          : (name.isNotEmpty ? name : fallback);
      imageUrls = breedingPet!.photos;
      createdAt = breedingPet!.createdAt;
      onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedPetDetailsScreen(
              type: PetDetailsType.breeding,
              breedingPet: breedingPet,
            ),
          ),
        );
      };
    }

    final t = Provider.of<AppLanguage>(context, listen: false);


    return CustomCard(
      onTap: onTap,
      child: Stack(
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
            child: Directionality(
              textDirection: t.isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: t.isRTL
                    ? [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: color == ThemeClass.of(context).primaryColor
                              ? ThemeClass.of(context).secondaryColor
                              : ThemeClass.of(context).primaryColor,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayTitle,
                                style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(
                                  color: ThemeClass.of(context).backGroundColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(
                                  color: ThemeClass.of(context).backGroundColor,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 130.w),
                      ]
                    : [
                        SizedBox(width: 130.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayTitle,
                                style: TextStyleHelper.of(context).s18RegTextStyle.copyWith(
                                  color: ThemeClass.of(context).backGroundColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDate(createdAt),
                                style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(
                                  color: ThemeClass.of(context).backGroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color == ThemeClass.of(context).primaryColor
                              ? ThemeClass.of(context).secondaryColor
                              : ThemeClass.of(context).primaryColor,
                        ),
                      ],
              ),
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
                child: Container(
                  color: Colors.grey[300],
                  child: CachedNetworkImage(
                    imageUrl: imageUrls.first.toString(),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 121.w.toInt(),
                    memCacheHeight: 83.h.toInt(),
                    maxWidthDiskCache: 500,
                    maxHeightDiskCache: 500,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: reportType == 'found'
                              ? AppTheme.success
                              : AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.pets,
                      size: 40.sp,
                      color: reportType == 'found'
                          ? AppTheme.success
                          : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              )
                  : Icon(
                Icons.pets,
                size: 40.sp,
                color: reportType == 'found'
                          ? AppTheme.success
                          : AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      )
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return '';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'الآن';
          }
          return 'منذ ${difference.inMinutes} دقيقة';
        }
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays == 1) {
        return 'أمس';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} أيام';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}