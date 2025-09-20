import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/veterinary_service.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/custom_button.dart';
import '../../Widgets/custom_textfield_widget.dart';
import '../Main/veterinary/veterinarian_dashboard_screen.dart';
import 'veterinarian_setup_screen.dart';

class VeterinarianLoginScreen extends StatefulWidget {
  const VeterinarianLoginScreen({super.key});

  @override
  State<VeterinarianLoginScreen> createState() => _VeterinarianLoginScreenState();
}

class _VeterinarianLoginScreenState extends State<VeterinarianLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill with demo credentials
    _emailController.text = 'doctor@gmail.com';
    _passwordController.text = '000111';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await VeterinaryService.signInVeterinarian(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const VeterinarianDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: Text(
          TranslationService.instance.translate('veterinarian_login'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                
                // Logo/Icon
                Icon(
                  Icons.medical_services,
                  size: 80.w,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                SizedBox(height: 20.h),
                
                // Title
                Text(
                  TranslationService.instance.translate('veterinarian_login_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                SizedBox(height: 10.h),
                
                // Subtitle
                Text(
                  TranslationService.instance.translate('veterinarian_login_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                
                SizedBox(height: 40.h),
                
                // Email Field
                CustomTextFieldWidget(
                  controller: _emailController,
                  hint: TranslationService.instance.translate('email'),
                  textInputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return TranslationService.instance.translate('email_required');
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return TranslationService.instance.translate('email_invalid');
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 20.h),
                
                // Password Field
                CustomTextFieldWidget(
                  controller: _passwordController,
                  hint: TranslationService.instance.translate('password'),
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return TranslationService.instance.translate('password_required');
                    }
                    if (value.length < 6) {
                      return TranslationService.instance.translate('password_short');
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 30.h),
                
                // Login Button
                CustomButton(
                  text: _isLoading 
                    ? TranslationService.instance.translate('signing_in')
                    : TranslationService.instance.translate('sign_in'),
                  onPressed: _isLoading ? null : _signIn,
                  isLoading: _isLoading,
                ),
                
                SizedBox(height: 20.h),
                
                // Demo Credentials Info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            TranslationService.instance.translate('demo_credentials'),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Email: doctor@gmail.com\nPassword: 000111',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Setup Account Button
                CustomButton(
                  text: TranslationService.instance.translate('veterinary.setup_account'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const VeterinarianSetupScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 