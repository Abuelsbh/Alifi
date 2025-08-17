import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Models/user_model.dart';
import '../../../Models/pet_report_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  UserModel? _user;
  List<LostPetModel> _userLostPets = [];
  List<FoundPetModel> _userFoundPets = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from services
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock user data
      _user = UserModel(
        id: 'user1',
        email: 'john.doe@example.com',
        username: 'John Doe',
        profilePhoto: null,
        phoneNumber: '+1234567890',
        address: 'New York, NY',
        pets: [
          PetModel(
            id: '1',
            name: 'Max',
            type: 'Dog',
            breed: 'Golden Retriever',
            age: 3,
            gender: 'Male',
            photos: [],
            vaccinations: ['Rabies', 'DHPP'],
            description: 'Friendly and energetic dog',
          ),
          PetModel(
            id: '2',
            name: 'Luna',
            type: 'Cat',
            breed: 'Persian',
            age: 2,
            gender: 'Female',
            photos: [],
            vaccinations: ['FVRCP', 'Rabies'],
            description: 'Calm and affectionate cat',
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      // Mock user reports
      _userLostPets = [
        LostPetModel(
          id: '1',
          userId: 'user1',
          petName: 'Max',
          petType: 'Dog',
          breed: 'Golden Retriever',
          age: 3,
          gender: 'Male',
          color: 'Golden',
          photos: [],
          description: 'Lost my 3-year-old Golden Retriever named Max in Central Park area.',
          location: const GeoPoint(40.7589, -73.9851),
          address: 'Central Park, New York',
          lostDate: DateTime.now().subtract(const Duration(days: 2)),
          contactPhone: '+1234567890',
          contactName: 'John Doe',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

      _userFoundPets = [
        FoundPetModel(
          id: '1',
          userId: 'user1',
          petType: 'Cat',
          breed: 'Maine Coon',
          color: 'Orange',
          photos: [],
          description: 'Found an orange Maine Coon cat in my backyard.',
          location: const GeoPoint(40.7505, -73.9934),
          address: 'Downtown Manhattan',
          foundDate: DateTime.now().subtract(const Duration(days: 1)),
          contactPhone: '+1234567890',
          contactName: 'John Doe',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Open settings
            },
            icon: Icon(Icons.settings, color: AppTheme.primaryGreen),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildLoginPrompt()
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _buildUserInfo(),
                      SizedBox(height: 24.h),
                      _buildPetsSection(),
                      SizedBox(height: 24.h),
                      _buildReportsSection(),
                      SizedBox(height: 24.h),
                      _buildSettingsSection(),
                    ],
                  ),
                ),
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
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Please log in',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Sign in to access your profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          CustomButton(
            text: 'Sign In',
            onPressed: () {
              // TODO: Navigate to login
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: _user!.profilePhoto != null
                    ? ClipOval(
                        child: Image.network(
                          _user!.profilePhoto!,
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        _user!.username.split(' ').map((e) => e[0]).join(''),
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 24.sp,
                        ),
                      ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user!.username,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _user!.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    if (_user!.phoneNumber != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        _user!.phoneNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CustomButton(
                text: 'Edit',
                type: ButtonType.secondary,
                onPressed: () {
                  // TODO: Navigate to edit profile
                },
              ),
            ],
          ),
          if (_user!.address != null) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
                SizedBox(width: 4.w),
                Text(
                  _user!.address!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Pets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            CustomButton(
              text: 'Add Pet',
              type: ButtonType.text,
              onPressed: () {
                // TODO: Navigate to add pet
              },
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_user!.pets.isEmpty)
          _buildEmptyPetsState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _user!.pets.length,
            itemBuilder: (context, index) {
              final pet = _user!.pets[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildPetCard(pet),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyPetsState() {
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Icon(
              Icons.pets_outlined,
              size: 48.sp,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No pets added yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your pets to get personalized care',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Add Your First Pet',
              onPressed: () {
                // TODO: Navigate to add pet
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(PetModel pet) {
    return CustomCard(
      onTap: () {
        // TODO: Navigate to pet details
      },
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.pets,
              color: AppTheme.primaryGreen,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${pet.breed} • ${pet.age} years old • ${pet.gender}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
                if (pet.vaccinations.isNotEmpty)
                  Text(
                    'Vaccinated: ${pet.vaccinations.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Reports',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                title: 'Lost Pets',
                count: _userLostPets.length,
                icon: Icons.search,
                color: AppTheme.primaryOrange,
                onTap: () {
                  // TODO: Navigate to user's lost pets
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildReportCard(
                title: 'Found Pets',
                count: _userFoundPets.length,
                icon: Icons.favorite,
                color: AppTheme.primaryGreen,
                onTap: () {
                  // TODO: Navigate to user's found pets
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        _buildSettingItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            // TODO: Navigate to notifications settings
          },
        ),
        _buildSettingItem(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English',
          onTap: () {
            // TODO: Navigate to language settings
          },
        ),
        _buildSettingItem(
          icon: Icons.dark_mode_outlined,
          title: 'Theme',
          subtitle: 'Light',
          onTap: () {
            // TODO: Navigate to theme settings
          },
        ),
        _buildSettingItem(
          icon: Icons.security_outlined,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {
            // TODO: Navigate to privacy settings
          },
        ),
        _buildSettingItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            // TODO: Navigate to help
          },
        ),
        _buildSettingItem(
          icon: Icons.logout,
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          onTap: () {
            _showSignOutDialog();
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? AppTheme.error : AppTheme.primaryGreen,
            size: 24.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? AppTheme.error : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Sign out user
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
} 