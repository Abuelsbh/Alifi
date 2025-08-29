import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import 'my_pets_screen.dart';
import 'my_reports_screen.dart';


class SimpleProfileScreen extends StatefulWidget {
  const SimpleProfileScreen({super.key});

  @override
  State<SimpleProfileScreen> createState() => _SimpleProfileScreenState();
}

class _SimpleProfileScreenState extends State<SimpleProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userProfile = await AuthService.getUserProfile(AuthService.userId!);
        if (userProfile != null) {
          _user = userProfile;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _showSignOutDialog,
            icon: Icon(Icons.logout, color: AppTheme.error),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildLoginPrompt()
              : _buildUserProfile(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          const Text(
            'Please login to view your profile',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final username = _user!['username'] ?? _user!['name'] ?? 'User';
    final email = _user!['email'] ?? 'No email';
    final phone = _user!['phoneNumber'] ?? _user!['phone'];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40.r,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    username,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (phone != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Quick Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.pets, color: AppTheme.primaryGreen),
                  title: const Text('My Pets'),
                  subtitle: const Text('Manage your pets'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyPetsScreen(),
                      ));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.report, color: AppTheme.primaryOrange),
                  title: const Text('My Reports'),
                  subtitle: const Text('Lost & Found reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyReportsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.chat, color: AppTheme.info),
                  title: const Text('My Chats'),
                  subtitle: const Text('Veterinary conversations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to chats
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.grey[600]),
                  title: const Text('Settings'),
                  subtitle: const Text('App preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showSignOutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.signOut();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 