import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Models/chat_model.dart';
import 'enhanced_chat_screen.dart';

class EnhancedVeterinaryScreen extends StatefulWidget {
  const EnhancedVeterinaryScreen({super.key});

  @override
  State<EnhancedVeterinaryScreen> createState() => _EnhancedVeterinaryScreenState();
}

class _EnhancedVeterinaryScreenState extends State<EnhancedVeterinaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _veterinarians = [];
  List<Map<String, dynamic>> _filteredVeterinarians = [];
  List<ChatModel> _chats = [];
  bool _isLoading = true;

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
      // Load veterinarians with real-time stream
      ChatService.getVeterinariansStream().listen((vets) {
        if (mounted) {
          setState(() {
            _veterinarians = vets;
            _filteredVeterinarians = vets;
            _isLoading = false;
          });
        }
      });

      // Load user chats if authenticated
      if (AuthService.isAuthenticated) {
        final userId = AuthService.userId!;
        ChatService.getUserChatsStream(userId).listen((chats) {
          if (mounted) {
            setState(() {
              _chats = chats;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading veterinary data: $e');
    }
  }

  void _filterVeterinarians(String query) {
    setState(() {
      _filteredVeterinarians = _veterinarians.where((vet) {
        final name = vet['name']?.toString().toLowerCase() ?? '';
        final specialization = vet['specialization']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        
        return name.contains(searchLower) || 
               specialization.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _startChatWithVet(Map<String, dynamic> vet) async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً للتحدث مع الطبيب'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userId = AuthService.userId!;
      final vetId = vet['id'] ?? '';
      
      // Create or get existing chat
      final chatId = await ChatService.createChatWithVet(
        userId: userId,
        veterinarianId: vetId,
        initialMessage: 'مرحباً دكتور، أحتاج استشارة بيطرية',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(
              chatId: chatId,
              veterinarianId: vetId,
              veterinarianName: vet['name'] ?? 'طبيب بيطري',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في بدء المحادثة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('الاستشارات البيطرية'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'الأطباء المتاحين'),
            Tab(text: 'محادثاتي'),
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
        // Search bar
        Padding(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            controller: _searchController,
            onChanged: _filterVeterinarians,
            decoration: InputDecoration(
              hintText: 'البحث عن طبيب أو تخصص...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.background,
            ),
          ),
        ),
        
        // Veterinarians List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredVeterinarians.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _filteredVeterinarians.length,
                      itemBuilder: (context, index) {
                        final vet = _filteredVeterinarians[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildVeterinarianCard(vet),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatsTab() {
    if (!AuthService.isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            const Text(
              'يرجى تسجيل الدخول لعرض محادثاتك',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _chats.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                const Text(
                  'لا توجد محادثات بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8.h),
                const Text(
                  'ابدأ محادثة مع طبيب بيطري',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: _chats.length,
            itemBuilder: (context, index) {
              final chat = _chats[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildChatCard(chat),
              );
            },
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
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          const Text(
            'لا يوجد أطباء متاحين حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8.h),
          const Text(
            'جرب البحث أو تحديث الصفحة',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianCard(Map<String, dynamic> vet) {
    final isOnline = vet['isOnline'] ?? false;
    final isAvailable = vet['isAvailable'] ?? true;
    
    return CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile photo
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      backgroundImage: vet['profilePhoto'] != null && vet['profilePhoto'].isNotEmpty
                          ? NetworkImage(vet['profilePhoto'])
                          : null,
                      child: vet['profilePhoto'] == null || vet['profilePhoto'].isEmpty
                          ? Icon(
                              Icons.person,
                              size: 30.sp,
                              color: AppTheme.primaryGreen,
                            )
                          : null,
                    ),
                    // Online indicator
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16.w,
                          height: 16.h,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                
                // Vet info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vet['name'] ?? 'طبيب بيطري',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        vet['specialization'] ?? 'طب بيطري عام',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${vet['rating'] ?? 4.5}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            ' (${vet['totalReviews'] ?? 0} تقييم)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status and action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        isOnline ? 'متصل' : 'غير متصل',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: isAvailable ? () => _startChatWithVet(vet) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: Size(80.w, 32.h),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                      ),
                      child: Text(
                        'محادثة',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            if (vet['bio'] != null && vet['bio'].isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                vet['bio'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            if (vet['consultationFee'] != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.monetization_on, size: 16.sp, color: AppTheme.primaryGreen),
                  SizedBox(width: 4.w),
                  Text(
                    'رسوم الاستشارة: ${vet['consultationFee']} جنيه',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    return CustomCard(
      onTap: () {
        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(
              chatId: chat.id,
              veterinarianId: _getVetIdFromChat(chat),
              veterinarianName: _getVetNameFromChat(chat),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25.r,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 25.sp,
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دكتور بيطري', // Will be enhanced with real vet name
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    chat.lastMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
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
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            // Unread count placeholder
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getVetNameFromChat(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return 'طبيب بيطري';
    
    // Get the other participant's name (not the current user)
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return chat.participantNames[participantId] ?? 'طبيب بيطري';
      }
    }
    
    return 'طبيب بيطري';
  }

  String _getVetIdFromChat(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return '';
    
    // Get the other participant's ID (not the current user)
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return participantId;
      }
    }
    
    return '';
  }
} 