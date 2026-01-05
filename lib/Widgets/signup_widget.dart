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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {


    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        // Show success message
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
        // Extract meaningful error message
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450.h,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(Assets.imagesBackground2), // replace with your image
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

          SizedBox(height: 18.h),

          // Login Button
          TranslatedCustomButton(
            width: 140.w,
            textKey: 'auth.signup',
            onPressed: _isLoading ? null : _register,
            isLoading: _isLoading,
          ),

          SizedBox(height: 20.h),

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
