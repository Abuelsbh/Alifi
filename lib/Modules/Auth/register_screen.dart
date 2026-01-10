import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/Theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/Language/app_languages.dart';
import '../../Widgets/translated_text.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../../Widgets/translated_custom_button.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';
  
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

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
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Navigate to main screen
        context.go('/main');
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                
                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.h,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        child: Icon(
                          Icons.pets,
                          size: 50.sp,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TranslatedText(
                        'auth.create_account',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      const TranslatedText(
                        'auth.join_community',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Name Field
                CustomTextFieldWidget(
                  controller: _nameController,
                  hint: Provider.of<AppLanguage>(context).translate('auth.full_name'),
                  textInputType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Provider.of<AppLanguage>(context).translate('auth.name_required');
                    }
                    if (value.length < 2) {
                      return Provider.of<AppLanguage>(context).translate('auth.name_min_length');
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.person_outlined),
                ),
                
                SizedBox(height: 16.h),
                
                // Email Field
                CustomTextFieldWidget(
                  controller: _emailController,
                  hint: Provider.of<AppLanguage>(context).translate('auth.email'),
                  textInputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Provider.of<AppLanguage>(context).translate('auth.email_required');
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return Provider.of<AppLanguage>(context).translate('auth.valid_email_required');
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                
                SizedBox(height: 16.h),
                
                // Password Field
                CustomTextFieldWidget(
                  controller: _passwordController,
                  hint: Provider.of<AppLanguage>(context).translate('auth.password'),
                  obscure: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Provider.of<AppLanguage>(context).translate('auth.password_required');
                    }
                    if (value.length < 6) {
                      return Provider.of<AppLanguage>(context).translate('auth.password_min_length');
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Confirm Password Field
                CustomTextFieldWidget(
                  controller: _confirmPasswordController,
                  hint: Provider.of<AppLanguage>(context).translate('auth.confirm_password'),
                  obscure: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return Provider.of<AppLanguage>(context).translate('auth.confirm_password_required');
                    }
                    if (value != _passwordController.text) {
                      return Provider.of<AppLanguage>(context).translate('auth.passwords_not_match');
                    }
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Register Button
                TranslatedCustomButton(
                  textKey: 'auth.create_account',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                ),
                
                SizedBox(height: 24.h),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const TranslatedText(
                      'auth.already_have_account',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const TranslatedText(
                        'auth.login',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 