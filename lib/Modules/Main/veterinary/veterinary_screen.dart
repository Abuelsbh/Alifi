import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Models/chat_model.dart';
import 'chat_screen.dart';

class VeterinaryScreen extends StatefulWidget {
  const VeterinaryScreen({super.key});

  @override
  State<VeterinaryScreen> createState() => _VeterinaryScreenState();
}

class _VeterinaryScreenState extends State<VeterinaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<VeterinarianModel> _veterinarians = [];
  List<VeterinarianModel> _filteredVeterinarians = [];
  List<ChatModel> _userChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from services
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock veterinarians data
      _veterinarians = [
        VeterinarianModel(
          id: '1',
          name: 'Dr. Sarah Johnson',
          email: 'sarah.johnson@vetclinic.com',
          profilePhoto: null,
          specialization: 'General Veterinary Medicine',
          phoneNumber: '+1234567890',
          address: 'Central Veterinary Clinic, New York',
          rating: 4.8,
          reviewCount: 127,
          isOnline: true,
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        VeterinarianModel(
          id: '2',
          name: 'Dr. Michael Chen',
          email: 'michael.chen@vetclinic.com',
          profilePhoto: null,
          specialization: 'Surgery & Emergency Care',
          phoneNumber: '+1234567891',
          address: 'Downtown Animal Hospital, New York',
          rating: 4.9,
          reviewCount: 89,
          isOnline: false,
          isAvailable: true,
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now(),
        ),
        VeterinarianModel(
          id: '3',
          name: 'Dr. Emily Rodriguez',
          email: 'emily.rodriguez@vetclinic.com',
          profilePhoto: null,
          specialization: 'Dermatology & Internal Medicine',
          phoneNumber: '+1234567892',
          address: 'Pet Care Specialists, Brooklyn',
          rating: 4.7,
          reviewCount: 156,
          isOnline: true,
          isAvailable: false,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
      ];
      _filteredVeterinarians = _veterinarians;

      // Mock chats data
      _userChats = [
        ChatModel(
          id: '1',
          userId: 'user1',
          veterinarianId: '1',
          petId: null,
          lastMessage: 'Thank you for the consultation!',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 30)),
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        ChatModel(
          id: '2',
          userId: 'user1',
          veterinarianId: '2',
          petId: null,
          lastMessage: 'When should I bring my dog for the follow-up?',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
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

  void _filterVeterinarians() {
    setState(() {
      _filteredVeterinarians = _veterinarians.where((vet) {
        return _searchController.text.isEmpty ||
            vet.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            vet.specialization.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Veterinary Consultation',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Veterinarians'),
            Tab(text: 'My Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVeterinariansTab(),
          _buildChatsTab(),
        ],
      ),
    );
  }

  Widget _buildVeterinariansTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _filterVeterinarians(),
            decoration: InputDecoration(
              hintText: 'Search veterinarians...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppTheme.primaryGreen),
                      onPressed: () {
                        _searchController.clear();
                        _filterVeterinarians();
                      },
                    )
                  : null,
            ),
          ),
        ),
        
        // Veterinarians List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVeterinarians.isEmpty
                  ? _buildEmptyState()
                  : _buildVeterinariansList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64.sp,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No veterinarians found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinariansList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredVeterinarians.length,
      itemBuilder: (context, index) {
        final vet = _filteredVeterinarians[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildVeterinarianCard(vet),
        );
      },
    );
  }

  Widget _buildVeterinarianCard(VeterinarianModel vet) {
    return CustomCard(
      onTap: () {
        _startChat(vet);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30.r,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: Text(
                  vet.name.split(' ').map((e) => e[0]).join(''),
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vet.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: vet.isOnline ? AppTheme.success : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      vet.specialization,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16.sp,
                          color: AppTheme.warning,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${vet.rating} (${vet.reviewCount} reviews)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (!vet.isAvailable)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        'Busy',
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(height: 8.h),
                  CustomButton(
                    text: 'Chat',
                    type: ButtonType.secondary,
                    onPressed: vet.isAvailable ? () => _startChat(vet) : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16.sp,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  vet.address??'',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _userChats.isEmpty
            ? _buildEmptyChatsState()
            : _buildChatsList();
  }

  Widget _buildEmptyChatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.sp,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'No chats yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start a conversation with a veterinarian',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _userChats.length,
      itemBuilder: (context, index) {
        final chat = _userChats[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildChatCard(chat),
        );
      },
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    // Find veterinarian for this chat
    final vet = _veterinarians.firstWhere(
      (v) => v.id == chat.veterinarianId,
      orElse: () => VeterinarianModel(
        id: '',
        name: 'Unknown',
        email: '',
        specialization: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return CustomCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              veterinarian: vet,
            ),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              vet.name.split(' ').map((e) => e[0]).join(''),
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vet.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  chat.lastMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimeAgo(chat.lastMessageTime),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startChat(VeterinarianModel vet) {
    // TODO: Create or get existing chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: '', // Will be created or retrieved
          veterinarian: vet,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
} 