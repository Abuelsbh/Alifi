import 'dart:async';
import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../Widgets/custom_card.dart';
import '../../../Models/chat_model.dart';
import '../lost_found/user_chat_screen.dart';
import 'enhanced_chat_screen.dart';
import 'real_time_chat_screen.dart';
import '../../../Widgets/home_header_widget.dart';
import '../../../core/services/location_service.dart';
import '../../../Models/location_model.dart';

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
  List<ChatModel> _userChats = [];
  List<ChatModel> _userToUserChats = [];
  bool _isLoading = true;

  // User data
  String _userName = 'User';
  String? _userProfileImage;
  
  // Location data
  LocationModel? _selectedLocation;

  // Stream subscriptions
  StreamSubscription? _veterinariansSubscription;
  StreamSubscription? _chatsSubscription;
  StreamSubscription<List<ChatModel>>? _userChatsSub;
  StreamSubscription<List<ChatModel>>? _userToUserChatsSub;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadData();
    _loadLocation();
  }

  Future<void> _loadUserData() async {
    try {
      if (AuthService.isAuthenticated && AuthService.userId != null) {
        final userProfile = await AuthService.getUserProfile(AuthService.userId!);
        if (userProfile != null) {
          setState(() {
            _userName = userProfile['username'] ?? userProfile['name'] ?? 'User';
            _userProfileImage = userProfile['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadLocation() async {
    try {
      print('🔄 Loading user location in chat screen...');
      final locationId = LocationService.getUserLocation();
      print('📍 Current user location ID: $locationId');
      
      if (locationId != null && locationId.isNotEmpty) {
        final location = await LocationService.getLocationById(locationId);
        if (mounted) {
          setState(() {
            _selectedLocation = location;
          });
          print('✅ Location loaded in chat: ${location?.name ?? "null"}');
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedLocation = null;
          });
        }
      }

      // Listen for location changes from Firebase
      final locationsStream = LocationService.getActiveLocationsStream();
      _locationSubscription = locationsStream.listen((locations) {
        if (mounted) {
          final locationId = LocationService.getUserLocation();
          if (locationId != null && locationId.isNotEmpty) {
            try {
              final location = locations.firstWhere(
                (loc) => loc.id == locationId,
                orElse: () => LocationModel(
                  id: '',
                  name: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              setState(() {
                _selectedLocation = location.id.isNotEmpty ? location : null;
              });
            } catch (e) {
              print('⚠️ Location not found in list: $e');
              setState(() {
                _selectedLocation = null;
              });
            }
          } else {
            setState(() {
              _selectedLocation = null;
            });
          }
        }
      }, onError: (error) {
        print('❌ Error in location stream: $error');
      });
    } catch (e, stackTrace) {
      print('❌ Error loading location in chat: $e');
      print('Stack trace: $stackTrace');
    }
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
    _chats.clear();
    await _cancelSubscriptions();

    setState(() => _isLoading = true);

    try {
      ChatService.clearAllCaches();

      // veterinarians stream
      _veterinariansSubscription = ChatService.getVeterinariansStream().listen((vets) {
        if (!mounted) return;
        setState(() {
          _veterinarians = vets;
          _filteredVeterinarians = vets;
          _isLoading = false;
        });
      });

      if (AuthService.isAuthenticated) {
        final userId = AuthService.userId!;

        // Stream 1
        _userChatsSub = ChatService.getUserChatsStream(userId).listen((chats) {
          if (!mounted) return;
          _mergeChats(chats, _userToUserChats);
          _userChats = chats;
        });

        // Stream 2
        _userToUserChatsSub = ChatService.getUserToUserChatsStream(userId).listen((chats) {
          if (!mounted) return;
          _mergeChats(_userChats, chats);
          _userToUserChats = chats;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error: $e");
    }
  }

  void _mergeChats(List<ChatModel> c1, List<ChatModel> c2) {
    final ids = <String>{};
    final merged = <ChatModel>[];

    for (var chat in [...c1, ...c2]) {
      if (!ids.contains(chat.id)) {
        ids.add(chat.id);
        merged.add(chat);
      }
    }

    // Sort by lastMessageAt descending (newest first)
    merged.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    setState(() {
      _chats = merged;
    });
  }


  Future<void> _cancelSubscriptions() async {
    await _veterinariansSubscription?.cancel();
    await _chatsSubscription?.cancel();
    await _userChatsSub?.cancel();
    await _userToUserChatsSub?.cancel();
    await _locationSubscription?.cancel();
    _veterinariansSubscription = null;
    _chatsSubscription = null;
    _userChatsSub = null;
    _userToUserChatsSub = null;
    _locationSubscription = null;
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
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            HomeHeaderWidget(
              userName: _userName,
              userProfileImage: _userProfileImage,
              onLocationChanged: _loadLocation,
              selectedLocation: _selectedLocation,
            ),
            

            
            // TabBar
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryGreen,
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'الأطباء المتاحين'),
                Tab(text: 'محادثاتي'),
              ],
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVeterinariansTab(),
                  _buildChatsTab(),
                ],
              ),
            ),
          ],
        ),
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
            padding: EdgeInsets.all(8.w),
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

  bool _isVeterinaryChat(ChatModel chat) {
    // Check if chat is in veterinary_chats by checking if it's in _userChats
    return _userChats.any((c) => c.id == chat.id);
  }

  Widget _buildChatCard(ChatModel chat) {
    final userId = AuthService.userId;
    final unreadCount = userId != null ? chat.unreadCount[userId] ?? 0 : 0;
    final isUnread = unreadCount > 0;
    final isVeterinaryChat = _isVeterinaryChat(chat);
    final participantName = _getParticipantName(chat);
    final otherUserId = _getOtherUserId(chat);
    
    return CustomCard(
      onTap: () {
        // Use unified chat screen for all chats
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatScreen(
              chatId: chat.id,
              otherUserId: otherUserId ?? '',
              otherUserName: participantName,
              isVeterinaryChat: isVeterinaryChat,
            ),
          ),
        );
      },
      child: Row(
        children: [
          // Avatar with type indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                child: Icon(
                  isVeterinaryChat ? Icons.medical_services : Icons.person,
                  size: 28.sp,
                  color: AppTheme.primaryGreen,
                ),
              ),
              // Type badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isVeterinaryChat ? AppTheme.primaryGreen : AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    isVeterinaryChat ? Icons.medical_services : Icons.person,
                    size: 10.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        participantName,
                        style: TextStyleHelper.of(context).s16RegTextStyle.copyWith(
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    // Chat type label
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isVeterinaryChat 
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        isVeterinaryChat ? 'طبيب' : 'مستخدم',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isVeterinaryChat ? AppTheme.primaryGreen : AppTheme.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  chat.lastMessage,
                  style: TextStyleHelper.of(context).s14RegTextStyle.copyWith(
                    color: isUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
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
                _formatTime(chat.lastMessageAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnread ? AppTheme.primaryGreen : Colors.grey[600],
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              SizedBox(height: 4.h),
              if (isUnread)
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadCount',
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
    );
  }

  String _getParticipantName(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return 'مستخدم';
    
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return chat.participantNames[participantId] ?? 'مستخدم';
      }
    }
    
    return 'مستخدم';
  }

  String? _getOtherUserId(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return null;
    
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return participantId;
      }
    }
    
    return null;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'أمس';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} أيام';
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}س';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}د';
    } else {
      return 'الآن';
    }
  }

} 