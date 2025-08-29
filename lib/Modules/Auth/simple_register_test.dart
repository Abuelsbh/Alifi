import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/auth_service.dart';
import '../../core/Theme/app_theme.dart';

class SimpleRegisterTest extends StatefulWidget {
  const SimpleRegisterTest({super.key});

  @override
  State<SimpleRegisterTest> createState() => _SimpleRegisterTestState();
}

class _SimpleRegisterTestState extends State<SimpleRegisterTest> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Register Test')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24.h),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _testRegister,
                    child: const Text('Test Register'),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _testRegister() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🧪 Testing registration...');
      
      final credential = await AuthService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );


      if (mounted) {

      }
    } catch (e) {
      print('💥 FAILED: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FAILED: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 