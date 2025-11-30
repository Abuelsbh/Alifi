import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Utilities/dialog_helper.dart';
import '../../../Widgets/login_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Models/pet_report_model.dart';
import '../../../Widgets/translated_text.dart';
import '../../../core/services/auth_service.dart';
import '../../../generated/assets.dart';
import '../../add_animal/add_animal_screen.dart';

class PostAdoptionScreen extends StatelessWidget {
  static const String routeName = '/PostAdoptionScreen';

  const PostAdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesBackground3),
                fit: BoxFit.contain,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top-left icon
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 32.w,
                            height: 32.h,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Top-right icon (gear-like)
                      ],
                    ),

                    // Offering Adoption Button (أنا بدي أحد يتبني الحيوان تبعي)
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        title: 'adoption.offering_adoption',
                        color: AppTheme.primaryOrange,
                        onTap: () => _handleOfferingAdoption(context),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Seeking Adoption Button (أنا بدي حيوان للتبني)
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        title: 'adoption.seeking_adoption',
                        color: AppTheme.primaryGreen,
                        onTap: () => _handleSeekingAdoption(context),
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: TranslatedText(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _handleOfferingAdoption(BuildContext context) {
    if (AuthService.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddAnimalScreen(
            reportType: ReportType.adoption,
            title: 'إضافة حيوان للتبني',
            adoptionType: 'offering',
          ),
        ),
      );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: const LoginWidget(),
      );
    }
  }

  void _handleSeekingAdoption(BuildContext context) {
    if (AuthService.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddAnimalScreen(
            reportType: ReportType.adoption,
            title: 'البحث عن حيوان للتبني',
            adoptionType: 'seeking',
          ),
        ),
      );
    } else {
      DialogHelper.custom(context: context).customDialog(
        dialogWidget: const LoginWidget(),
      );
    }
  }
}

