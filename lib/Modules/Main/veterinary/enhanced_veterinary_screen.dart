import 'dart:async';
import 'package:alifi/Utilities/text_style_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../Widgets/bottom_navbar_widget.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/utils/localized_content.dart';
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
import '../../../core/Language/translation_service.dart';

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
        // Debug: Print veterinarians data to check profilePhoto
        for (var vet in vets) {
          print('🔍 Vet: ${vet['name']}, profilePhoto: ${vet['profilePhoto']}');
        }
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
        final searchLower = query.toLowerCase();
        const keys = [
          'name',
          'nameEn',
          'nameAr',
          'nameHe',
          'specialization',
          'specializationEn',
          'specializationAr',
          'specializationHe',
        ];
        for (final k in keys) {
          final v = vet[k]?.toString().toLowerCase() ?? '';
          if (v.contains(searchLower)) return true;
        }
        return false;
      }).toList();
    });
  }

  bool _isPlaceholderDisplayName(String? name) {
    if (name == null || name.isEmpty) return true;
    final n = name.trim();
    const placeholders = {'مستخدم', 'المستخدم', 'User', 'user', 'משתמש'};
    if (placeholders.contains(n)) return true;
    final generic = TranslationService.instance.translate('chat.user');
    final participant = TranslationService.instance.translate('chat.participant');
    return n == generic || n == participant;
  }

  Future<void> _startChatWithVet(Map<String, dynamic> vet) async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              TranslationService.instance.translate('chat.login_first_to_talk_vet')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final userId = AuthService.userId!;
      final vetId = vet['id'] ?? '';
      final lang = Provider.of<AppLanguage>(context, listen: false).appLang.name;
      final vetDisplayName = LocalizedContent.pickFromMap(
        Map<String, dynamic>.from(vet),
        lang,
        baseKey: 'name',
      );
      final t = TranslationService.instance;

      // Create or get existing chat
      final chatId = await ChatService.createChatWithVet(
        userId: userId,
        veterinarianId: vetId,
        initialMessage: t.translate('chat.vet_consultation_initial_message'),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatScreen(
              chatId: chatId,
              otherUserId: vetId,
              otherUserName: vetDisplayName.isNotEmpty
                  ? vetDisplayName
                  : t.translate('chat.veterinarian_fallback_name'),
              isVeterinaryChat: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${TranslationService.instance.translate('chat.error_starting_chat')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TranslationService.instance;
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
            

            
            // TabBar — التبويب المختار مُعلّم بالكامل (خلفية) وليس خطًّا فقط
            TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.primaryGreen, width: 1.2),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: t.translate('chat.tab_available_veterinarians')),
                Tab(text: t.translate('chat.tab_my_chats')),
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
        // Search bar — مع حدود واضحة
        Padding(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            controller: _searchController,
            onChanged: _filterVeterinarians,
            decoration: InputDecoration(
              hintText:
                  TranslationService.instance.translate('chat.search_veterinarian_hint'),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
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
            Text(
              TranslationService.instance.translate('chat.login_to_view_chats_subtitle'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
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
                  TranslationService.instance.translate('chat.no_chats_yet'),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8.h),
                Text(
                  TranslationService.instance.translate('chat.start_chat_with_vet_from_tab'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0); // Switch to veterinarians tab
                  },
                  icon: Icon(Icons.person),
                  label: Text(TranslationService.instance.translate('chat.show_veterinarians')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh),
                  label: Text(TranslationService.instance.translate('chat.refresh_chats')),
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
            Icons.person,
            size: 64.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            TranslationService.instance.translate('veterinary.no_vets_available_now'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            TranslationService.instance.translate('veterinary.try_refresh_or_network'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            label: Text(TranslationService.instance.translate('home.refresh')),
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
              TranslationService.instance.translate('veterinary.vets_register_system_hint'),
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
    final lang = Provider.of<AppLanguage>(context).appLang.name;
    final vetMap = Map<String, dynamic>.from(vet);
    final vetName =
        LocalizedContent.pickFromMap(vetMap, lang, baseKey: 'name');
    final vetSpec = LocalizedContent.pickFromMap(
      vetMap,
      lang,
      baseKey: 'specialization',
    );

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
                    backgroundImage: (vet['profilePhoto'] != null && 
                            vet['profilePhoto'].toString().isNotEmpty)
                        ? CachedNetworkImageProvider(vet['profilePhoto'].toString())
                        : null,
                    child: (vet['profilePhoto'] == null || 
                            vet['profilePhoto'].toString().isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 30.sp,
                            color: AppTheme.primaryGreen,
                          )
                        : null,
                  ),
                  // Online indicator
                  if (vet['isOnline'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12.w,
                        height: 12.h,
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
                      vetName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      vetSpec,
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
                  TranslationService.instance.translate('chat.open_chat_action'),
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
              FutureBuilder<DocumentSnapshot>(
                future: otherUserId != null 
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get()
                    : null,
                builder: (context, snapshot) {
                  String? profilePhoto;
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null) {
                      // Get profile photo from users collection
                      profilePhoto = data['profileImageUrl'] as String? ?? data['profilePhoto'] as String?;
                    }
                  }
                  
                  return CircleAvatar(
                    radius: 28.r,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                        ? CachedNetworkImageProvider(profilePhoto)
                        : null,
                    child: profilePhoto == null || profilePhoto.isEmpty
                        ? Icon(
                            isVeterinaryChat ? Icons.person : Icons.person,
                            size: 28.sp,
                            color: AppTheme.primaryGreen,
                          )
                        : null,
                  );
                },
              ),
              // Type badge

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
                      child: FutureBuilder<DocumentSnapshot>(
                        future: otherUserId != null 
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(otherUserId)
                                .get()
                            : null,
                        builder: (context, snapshot) {
                          String displayName = participantName;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            if (data != null) {
                              final name = isVeterinaryChat
                                  ? (data['name'] as String?)
                                  : (data['username'] as String?) ?? (data['name'] as String?);
                              if (!_isPlaceholderDisplayName(name)) {
                                displayName = name!;
                              }
                            }
                          }
                          
                          return Text(
                            displayName,
                            style: TextStyleHelper.of(context).s16RegTextStyle.copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        },
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
                    '',
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
    final generic = TranslationService.instance.translate('chat.user');
    if (userId == null) return generic;

    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return chat.participantNames[participantId] ?? generic;
      }
    }

    return generic;
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
    final lang = TranslationService.instance.currentLanguage;
    final t = TranslationService.instance;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return t.translate('chat.yesterday');
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${t.translate('chat.time_days')}';
      } else {
        return DateFormat.yMd(lang).format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}${t.translate('chat.time_hours_short')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}${t.translate('chat.time_minutes_short')}';
    } else {
      return t.translate('chat.time_now');
    }
  }

} 