import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../Widgets/main_navigation_screen.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Models/chat_model.dart';
import 'enhanced_chat_screen.dart';

class EnhancedVeterinaryScreen extends StatefulWidget {
  static const String routeName = '/EnhancedVeterinaryScreen';
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

  // Stream subscriptions
  StreamSubscription? _veterinariansSubscription;
  StreamSubscription? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_veterinarians.isEmpty || _chats.isEmpty)) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Cancel existing subscriptions
    await _cancelSubscriptions();

    setState(() {
      _isLoading = true;
    });

    try {
      // Clear all caches to ensure fresh data
      ChatService.clearAllCaches();

      // Load veterinarians with real-time stream
      _veterinariansSubscription = ChatService.getVeterinariansStream().listen((vets) {
        if (mounted) {
          setState(() {
            _veterinarians = vets;
            _filteredVeterinarians = vets;
            _isLoading = false;
          });

          // Log for debugging
          print('Loaded ${vets.length} veterinarians');
          if (vets.isNotEmpty) {
            print('First vet: ${vets.first['name']} - ID: ${vets.first['id']}');
          }
        }
      }, onError: (error) {
        print('Error in veterinarians stream: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      // Load user chats if authenticated
      if (AuthService.isAuthenticated) {
        final userId = AuthService.userId!;
        _chatsSubscription = ChatService.getUserChatsStream(userId).listen((chats) {
          if (mounted) {
            setState(() {
              _chats = chats;
            });
            print('Loaded ${chats.length} chats');
          }
        }, onError: (error) {
          print('Error in chats stream: $error');
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

  Future<void> _cancelSubscriptions() async {
    await _veterinariansSubscription?.cancel();
    await _chatsSubscription?.cancel();
    _veterinariansSubscription = null;
    _chatsSubscription = null;
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
      bottomNavigationBar: BottomNavBarWidget(
        selected: SelectedBottomNavBar.veterinary,
      ),
      //bottomNavigationBar: MainNavigationScreen(initialSelected: SelectedBottomNavBar.veterinary),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.primaryGreen,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('الاستشارات البيطرية'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: _isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryGreen,
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: AppTheme.primaryGreen,
                ),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
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
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            itemCount: _filteredVeterinarians.length,
            itemBuilder: (context, index) {
              final vet = _filteredVeterinarians[index];
              return Column(
                children: [
                  _buildVeterinarianCard(vet),
                  if (index < _filteredVeterinarians.length - 1) // avoid last divider
                    Divider(
                      thickness: 1,
                      color: Colors.grey.shade300,
                      height: 16.h,
                    ),
                ],
              );
            },
          )

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
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد محادثات بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8.h),
                Text(
                  'ابدأ محادثة مع طبيب بيطري من التبويب الأول',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0); // Switch to veterinarians tab
                  },
                  icon: Icon(Icons.medical_services),
                  label: Text('عرض الأطباء البيطريين'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh),
                  label: Text('تحديث المحادثات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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
          Text(
            'لا يوجد أطباء متاحين حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            'جرب تحديث الصفحة أو تأكد من الاتصال بالإنترنت',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            label: Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '💡 إذا استمرت المشكلة، تأكد من أن الأطباء البيطريين مسجلين في النظام',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianCard(Map<String, dynamic> vet) {
    return CustomCard(
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

                ],
              ),
              SizedBox(width: 12.w),

              // Vet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vet['name'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      vet['specialization'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _startChatWithVet(vet),
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
      )
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
                    _getVetNameFromChat(chat), // Will be enhanced with real vet name
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