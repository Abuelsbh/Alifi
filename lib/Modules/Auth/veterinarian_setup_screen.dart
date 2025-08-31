import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/veterinary_setup_service.dart';
import '../../core/Language/translation_service.dart';
import '../../Widgets/custom_button.dart';

class VeterinarianSetupScreen extends StatefulWidget {
  const VeterinarianSetupScreen({super.key});

  @override
  State<VeterinarianSetupScreen> createState() => _VeterinarianSetupScreenState();
}

class _VeterinarianSetupScreenState extends State<VeterinarianSetupScreen> {
  bool _isLoading = false;
  bool _isChecking = false;
  Map<String, dynamic>? _accountStatus;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    try {
      final status = await VeterinarySetupService.getAccountStatus();
      
      if (mounted) {
        setState(() {
          _accountStatus = status;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'خطأ في التحقق من الحساب: $e';
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _createVeterinarianAccount() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await VeterinarySetupService.createVeterinarianAccount();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = result['message'];
        });
        
        // Refresh account status
        await _checkAccountStatus();
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'خطأ في إنشاء الحساب: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الحساب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDemoChat() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await VeterinarySetupService.createDemoChat();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = result['message'];
        });
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'خطأ في إنشاء المحادثة التجريبية: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء المحادثة التجريبية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAllVeterinarians() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await VeterinarySetupService.checkAllVeterinarians();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = result['message'];
        });
        
        if (result['success']) {
          final totalCount = result['total_count'] ?? 0;
          final verifiedCount = result['verified_count'] ?? 0;
          final onlineCount = result['online_count'] ?? 0;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم العثور على $totalCount طبيب بيطري ($verifiedCount موثق، $onlineCount متصل)'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Show detailed info in dialog
          _showVeterinariansInfo(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'خطأ في فحص الأطباء البيطريين: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فحص الأطباء البيطريين: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVeterinariansInfo(Map<String, dynamic> result) {
    final veterinarians = List<Map<String, dynamic>>.from(result['veterinarians'] ?? []);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('معلومات الأطباء البيطريين'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إجمالي الأطباء: ${result['total_count']}'),
              Text('الأطباء الموثقون: ${result['verified_count']}'),
              Text('الأطباء المتصلون: ${result['online_count']}'),
              SizedBox(height: 16.h),
              if (veterinarians.isNotEmpty) ...[
                Text('تفاصيل الأطباء:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                ...veterinarians.map((vet) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${vet['name']} (${vet['email']})'),
                      Text('  التخصص: ${vet['specialization']}'),
                      Text('  الحالة: ${vet['isVerified'] ? 'موثق' : 'غير موثق'} | ${vet['isOnline'] ? 'متصل' : 'غير متصل'}'),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_accountStatus == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 12.w),
            Text('جاري التحقق من الحساب...'),
          ],
        ),
      );
    }

    final authExists = _accountStatus!['auth_exists'] ?? false;
    final profileExists = _accountStatus!['profile_exists'] ?? false;

    Color cardColor;
    IconData statusIcon;
    String statusText;

    if (authExists && profileExists) {
      cardColor = Colors.green[50]!;
      statusIcon = Icons.check_circle;
      statusText = '✅ الحساب جاهز للاستخدام';
    } else if (authExists && !profileExists) {
      cardColor = Colors.orange[50]!;
      statusIcon = Icons.warning;
      statusText = '⚠️ الحساب موجود لكن يحتاج إعداد';
    } else {
      cardColor = Colors.red[50]!;
      statusIcon = Icons.error;
      statusText = '❌ الحساب غير موجود';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cardColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: cardColor == Colors.green[50] ? Colors.green : Colors.orange),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _accountStatus!['message'] ?? '',
            style: TextStyle(fontSize: 14.sp),
          ),
          if (_accountStatus!['uid'] != null) ...[
            SizedBox(height: 4.h),
            Text(
              'UID: ${_accountStatus!['uid']}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'إعداد حساب الطبيب البيطري',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),
              
              // Header
              Icon(
                Icons.medical_services,
                size: 80.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              
              SizedBox(height: 20.h),
              
              Text(
                'إعداد حساب الطبيب البيطري',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              SizedBox(height: 10.h),
              
              Text(
                'هذه الشاشة تساعدك في إعداد حساب الطبيب البيطري وحل المشاكل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              
              SizedBox(height: 30.h),
              
              // Account Status
              _buildStatusCard(),
              
              SizedBox(height: 20.h),
              
              // Action Buttons
              if (_accountStatus != null) ...[
                // Check Status Button
                CustomButton(
                  text: _isChecking ? 'جاري التحقق...' : 'إعادة التحقق من الحساب',
                  onPressed: _isChecking ? null : _checkAccountStatus,
                  isLoading: _isChecking,
                ),
                
                SizedBox(height: 12.h),
                
                // Create Account Button
                if (!(_accountStatus!['auth_exists'] ?? false) || !(_accountStatus!['profile_exists'] ?? false))
                  CustomButton(
                    text: _isLoading ? 'جاري الإنشاء...' : 'إنشاء/إصلاح حساب الطبيب البيطري',
                    onPressed: _isLoading ? null : _createVeterinarianAccount,
                    isLoading: _isLoading,
                  ),
                
                // Create Demo Chat Button
                if (_accountStatus!['auth_exists'] == true && _accountStatus!['profile_exists'] == true)
                  CustomButton(
                    text: 'إنشاء محادثة تجريبية للاختبار',
                    onPressed: _isLoading ? null : _createDemoChat,
                    isLoading: _isLoading,
                  ),
                
                // Check All Veterinarians Button
                CustomButton(
                  text: 'فحص جميع الأطباء البيطريين في النظام',
                  onPressed: _isLoading ? null : _checkAllVeterinarians,
                  isLoading: _isLoading,
                ),
                
                SizedBox(height: 12.h),
                
                // Account Details
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بيانات الحساب:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text('Email: doctor@gmail.com'),
                      Text('Password: 000111'),
                      Text('Name: د. أحمد محمد'),
                      Text('Specialization: الطب البيطري العام'),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 20.h),
              
              // Status Message
              if (_statusMessage != null)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _statusMessage!.contains('نجح') || _statusMessage!.contains('جاهز')
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _statusMessage!.contains('نجح') || _statusMessage!.contains('جاهز')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _statusMessage!.contains('نجح') || _statusMessage!.contains('جاهز')
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 