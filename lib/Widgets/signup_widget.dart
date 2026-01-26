import 'package:alifi/Widgets/login_widget.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/translated_text.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/translated_custom_button.dart';
import '../Utilities/dialog_helper.dart';
import '../Modules/Main/profile/privacy_policy_screen.dart';

class SignupWidget extends StatefulWidget {
  const SignupWidget({super.key});

  @override
  State<SignupWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<SignupWidget> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Convert error to translation key
  String _getErrorTranslationKey(dynamic e) {
    String errorString = e.toString();
    
    // Remove "Exception: " prefix if present
    if (errorString.startsWith('Exception: ')) {
      errorString = errorString.substring(11);
    }
    
    // Check for Firebase Auth error codes
    if (errorString.contains('user-not-found') || 
        errorString.contains('No user found')) {
      return 'auth.errors.user_not_found';
    }
    if (errorString.contains('wrong-password') || 
        errorString.contains('Wrong password')) {
      return 'auth.errors.wrong_password';
    }
    if (errorString.contains('email-already-in-use') || 
        errorString.contains('already exists')) {
      return 'auth.errors.email_already_in_use';
    }
    if (errorString.contains('weak-password') || 
        errorString.contains('too weak')) {
      return 'auth.errors.weak_password';
    }
    if (errorString.contains('invalid-email') || 
        errorString.contains('not valid')) {
      return 'auth.errors.invalid_email';
    }
    if (errorString.contains('user-disabled') || 
        errorString.contains('disabled')) {
      return 'auth.errors.user_disabled';
    }
    if (errorString.contains('too-many-requests') || 
        errorString.contains('Too many requests')) {
      return 'auth.errors.too_many_requests';
    }
    if (errorString.contains('operation-not-allowed') || 
        errorString.contains('not allowed')) {
      return 'auth.errors.operation_not_allowed';
    }
    if (errorString.contains('network-request-failed') || 
        errorString.contains('Network error') ||
        errorString.contains('network')) {
      return 'auth.errors.network_request_failed';
    }
    if (errorString.contains('channel-error') || 
        errorString.contains('channel')) {
      return 'auth.errors.channel_error';
    }
    if (errorString.contains('تم حذف') || 
        errorString.contains('deleted')) {
      return 'auth.errors.account_deleted';
    }
    if (errorString.contains('تم حظر') || 
        errorString.contains('banned')) {
      return 'auth.errors.account_banned';
    }
    if (errorString.contains('تم توقيف') || 
        errorString.contains('suspended')) {
      return 'auth.errors.account_suspended';
    }
    if (errorString.contains('Authentication failed') || 
        errorString.contains('فشل')) {
      return 'auth.errors.authentication_failed';
    }
    
    // Default to unknown error
    return 'auth.errors.unknown_error';
  }

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = TranslationService.instance.translate('auth.agree_terms_required');
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.instance.translate('auth.account_created_successfully')),
            backgroundColor: AppTheme.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _getErrorTranslationKey(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TranslationService.instance;
    return Container(
      height: 560.h,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.imagesBackground2), // replace with your image
          fit: BoxFit.contain, // makes it cover the whole area
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      TranslationService.instance.translate('auth.welcome_to'),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF914C),
                      ),
                    ),
                    Image.asset(Assets.imagesAlifi2),

                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Email Field
          Container(

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: CustomTextFieldWidget(
              width: 238.w,
              height: 42.h,
              controller: _nameController,
              borderStyleFlag: 1,
              hint: TranslationService.instance.translate('auth.username'),
              textInputType: TextInputType.emailAddress,
            ),
          ),

          SizedBox(height: 16.h),

          // Password Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: CustomTextFieldWidget(
              width: 238.w,
              height: 42.h,
              controller: _emailController,
              borderStyleFlag: 1,
              hint: TranslationService.instance.translate('auth.email'),
              textInputType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return TranslationService.instance.translate('validation.required_field');
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return TranslationService.instance.translate('validation.invalid_email');
                }
                return null;
              },
            ),
          ),

          SizedBox(height: 16.h),

          // Password Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: CustomTextFieldWidget(
              width: 238.w,
              height: 42.h,
              controller: _passwordController,
              borderStyleFlag: 2,
              hint: TranslationService.instance.translate('auth.password'),
              obscure: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return TranslationService.instance.translate('validation.password_required');
                }
                if (value.length < 6) {
                  return TranslationService.instance.translate('validation.password_too_short');
                }
                return null;
              },
              // suffixIcon: IconButton(
              //   icon: Icon(
              //     _obscurePassword ? Icons.visibility : Icons.visibility_off,
              //   ),
              //   onPressed: () {
              //     setState(() {
              //       _obscurePassword = !_obscurePassword;
              //     });
              //   },
              // ),
            ),
          ),

          SizedBox(height: 16.h),

          // Password Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: CustomTextFieldWidget(
              width: 238.w,
              height: 42.h,
              controller: _confirmPasswordController,
              borderStyleFlag: 2,
              hint: TranslationService.instance.translate('auth.confirm_password'),
              obscure: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return TranslationService.instance.translate('validation.password_required');
                }
                if (value != _passwordController.text) {
                  return TranslationService.instance.translate('validation.passwords_not_match');
                }
                return null;
              },
              // suffixIcon: IconButton(
              //   icon: Icon(
              //     _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              //   ),
              //   onPressed: () {
              //     setState(() {
              //       _obscureConfirmPassword = !_obscureConfirmPassword;
              //     });
              //   },
              // ),
            ),
          ),

          SizedBox(height: 12.h),

          // Terms checkbox
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    activeColor: AppTheme.primaryGreen,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                    child: Text(
                      t.translate('auth.agree_terms'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          TranslatedCustomButton(
            width: 140.w,
            textKey: 'auth.signup',
            onPressed: _isLoading ? null : _register,
            isLoading: _isLoading,
          ),

          SizedBox(height: 16.h),

          const TranslatedText(
            'auth.already_have_account',
            style: TextStyle(color: Colors.grey),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              DialogHelper.custom(context: context).customDialog(
                dialogWidget: const LoginWidget(),
              );
            },
            child: TranslatedText(
              'auth.login',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 16.h),
          SizedBox(
            height: 40.h,
            child: _errorMessage != null
                ? Center(
                    child: TranslatedText(
                      _errorMessage!,
                      style: TextStyle(color: AppTheme.error, fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: 8.h),

          // SizedBox(height: 16.h),
          //
          // // Veterinarian Login Link
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     const TranslatedText(
          //       'veterinary.are_you_veterinarian',
          //       style: TextStyle(color: Colors.grey),
          //     ),
          //     TextButton(
          //       onPressed: () {
          //         Navigator.of(context).push(
          //           MaterialPageRoute(
          //             builder: (context) => const VeterinarianLoginScreen(),
          //           ),
          //         );
          //       },
          //       child: const TranslatedText(
          //         'veterinary.veterinarian_login',
          //         style: TextStyle(
          //           color: AppTheme.primaryGreen,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
        ),
      ),
    );
  }
}
