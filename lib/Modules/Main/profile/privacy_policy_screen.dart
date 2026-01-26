import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppLanguage>(context);
    final policyTitle = t.translate('profile.privacy_policy') ?? 'Privacy Policy';
    final policyBody = t.translate('profile.privacy_policy_text') ??
        'We respect your privacy. This app collects only the data necessary to provide pet care services, '
        'including your profile information and animal listings. We do not sell your data to third parties. '
        'For support, follow us on social media.';
    final followUs = t.translate('profile.follow_us') ?? 'Follow us';
    final instagram = t.translate('profile.instagram') ?? 'Instagram';
    final whatsapp = t.translate('profile.whatsapp') ?? 'WhatsApp';
    final twitter = t.translate('profile.twitter') ?? 'Twitter / X';

    // Replace with your actual social URLs
    const instagramUrl = 'https://instagram.com';
    const whatsappUrl = 'https://wa.me';
    const twitterUrl = 'https://twitter.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryGreen, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          policyTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              policyBody,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
            Gap(32.h),
            Text(
              followUs,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            Gap(16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: Icons.camera_alt_outlined,
                  label: instagram,
                  onTap: () => _launchUrl(instagramUrl),
                ),
                Gap(24.w),
                _SocialButton(
                  icon: Icons.chat_bubble_outline,
                  label: whatsapp,
                  onTap: () => _launchUrl(whatsappUrl),
                ),
                Gap(24.w),
                _SocialButton(
                  icon: Icons.alternate_email,
                  label: twitter,
                  onTap: () => _launchUrl(twitterUrl),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppTheme.primaryOrange, size: 28.sp),
          ),
          Gap(8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
