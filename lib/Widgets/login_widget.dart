import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:alifi/Utilities/theme_helper.dart';
import 'package:alifi/Widgets/signup_widget.dart';
import 'package:alifi/generated/assets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/translated_text.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/translated_custom_button.dart';
import '../Modules/Auth/veterinarian_login_screen.dart';
import '../Utilities/dialog_helper.dart';

class LoginWidget extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  
  const LoginWidget({super.key, this.onLoginSuccess});

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _isLoading = false;

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        context.pop();
        // Call the callback to refresh the parent screen
        widget.onLoginSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('auth.enter_email_for_reset'),
        ),
      );
      return;
    }

    try {
      await AuthService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const TranslatedText('auth.password_reset_sent'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450.h,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.imagesBackground), // replace with your image
          fit: BoxFit.contain, // makes it cover the whole area
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
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
                    Image.asset(Assets.imagesAlifi),
                  ],
                ),

                SizedBox(height: 12.h),
                Container(
                  width: 136.w,
                  height: 66.h,
                  child: Image.asset(
                    Assets.imagesLogo2,
                    width: 136.w,
                    height: 66.h,
                  ),
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

          SizedBox(height: 8.h),

          // Forgot Password
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: TextButton(
              onPressed: _forgotPassword,
              child: TranslatedText(
                'auth.forgot_password',
                style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).secondaryColor)
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Login Button
          TranslatedCustomButton(
            width: 140.w,
            textKey: 'auth.login',
            onPressed: _isLoading ? null : _login,
            isLoading: _isLoading,
          ),

          SizedBox(height: 20.h),

          TranslatedText(
            'auth.dont_have_account',
            style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).secondaryColor)
          ),
          TextButton(
            onPressed: () {
              context.pop();
              DialogHelper.custom(context: context).customDialog(
                dialogWidget: const SignupWidget(),
              );
            },
            child: TranslatedText(
              'auth.signup',
                style: TextStyleHelper.of(context).s10RegTextStyle.copyWith(color: ThemeClass.of(context).primaryColor)
            ),
          ),

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
    );
  }
}
