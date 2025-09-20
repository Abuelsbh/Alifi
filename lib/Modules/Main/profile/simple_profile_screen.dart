import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/Language/app_languages.dart';
import 'my_pets_screen.dart';
import 'my_reports_screen.dart';
import 'settings_screen.dart';


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
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.profile,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(Provider.of<AppLanguage>(context).translate('profile.my_profile')),
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
          Text(
            Provider.of<AppLanguage>(context).translate('profile.login_prompt'),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(Provider.of<AppLanguage>(context).translate('auth.login')),
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
                  title: Text(Provider.of<AppLanguage>(context).translate('profile.my_pets')),
                  subtitle: Text(Provider.of<AppLanguage>(context).translate('profile.my_pets_subtitle')),
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
                  title: Text(Provider.of<AppLanguage>(context).translate('profile.my_reports')),
                  subtitle: Text(Provider.of<AppLanguage>(context).translate('profile.my_reports_subtitle')),
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
                  title: Text(Provider.of<AppLanguage>(context).translate('profile.my_chats')),
                  subtitle: Text(Provider.of<AppLanguage>(context).translate('profile.my_chats_subtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to chats
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.grey[600]),
                  title: Text(Provider.of<AppLanguage>(context).translate('profile.settings')),
                  subtitle: Text(Provider.of<AppLanguage>(context).translate('profile.app_preferences')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
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
              child: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out')),
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
        title: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out')),
        content: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<AppLanguage>(context).translate('common.cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AuthService.signOut();
                if (mounted) {
                  context.go('/home');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${Provider.of<AppLanguage>(context).translate('profile.sign_out_error')}: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(Provider.of<AppLanguage>(context).translate('profile.sign_out'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 