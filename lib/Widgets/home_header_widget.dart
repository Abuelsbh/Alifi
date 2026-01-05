import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/services/auth_service.dart';
import '../core/services/notification_service.dart';
import '../core/Theme/app_theme.dart';
import '../Utilities/text_style_helper.dart';
import '../Utilities/theme_helper.dart';
import '../core/Language/translation_service.dart';
import '../Modules/Admin/admin_reports_screen.dart';
import '../Modules/Main/profile/notifications_screen.dart';
import '../Modules/Main/location/location_selection_screen.dart';
import '../Models/location_model.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String userName;
  final String? userProfileImage;
  final VoidCallback? onLocationChanged;
  final VoidCallback? onProfileTap;
  final LocationModel? selectedLocation;

  const HomeHeaderWidget({
    super.key,
    required this.userName,
    this.userProfileImage,
    this.onLocationChanged,
    this.onProfileTap,
    this.selectedLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Profile and Welcome
          Row(
            children: [
              // Profile Image
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: ClipOval(
                    child: userProfileImage != null
                        ? CachedNetworkImage(
                            imageUrl: userProfileImage!,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                            maxWidthDiskCache: 200,
                            maxHeightDiskCache: 200,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 25.sp,
                              ),
                            ),
                          )
                        : Image.asset(
                            'assets/images/profile_placeholder.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 25.sp,
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(width: 15.w),
              // Welcome Text
              // Text(
              //   TranslationService.instance.translate('auth.welcome'),
              //   style: TextStyleHelper.of(context)
              //       .s28InterTextStyle()
              //       .copyWith(color: ThemeClass.of(context).primaryColor),
              // ),
            ],
          ),

          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationSelectionScreen(),
                  ),
                );

                // Reload location when coming back
                onLocationChanged?.call();
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: ThemeClass.of(context).primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  if (selectedLocation != null) ...[
                    SizedBox(width: 8.w),
                    Text(
                      selectedLocation!.name,
                      style: TextStyleHelper.of(context)
                          .s14RegTextStyle
                          .copyWith(color: ThemeClass.of(context).secondaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bell Icon with notification badge (or Admin Reports for admins)
          StreamBuilder<int>(
            stream: NotificationService.getUnreadMessagesCountFromNotifications(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              final isAdmin = AuthService.isAdmin;

              return GestureDetector(
                onTap: () {
                  if (isAdmin) {
                    // Navigate to Admin Reports Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReportsScreen(),
                      ),
                    );
                  } else {
                    // Navigate to Notifications Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.notifications_outlined,
                        color: isAdmin
                            ? AppTheme.primaryGreen
                            : (unreadCount > 0
                            ? AppTheme.primaryOrange
                            : Colors.grey[600]),
                        size: 20.sp,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme.error,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14.w,
                            minHeight: 14.h,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

