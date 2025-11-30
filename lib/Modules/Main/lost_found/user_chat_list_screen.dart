import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/chat_model.dart';
import '../../../Widgets/custom_card.dart';
import 'user_chat_screen.dart';

class UserChatListScreen extends StatefulWidget {
  const UserChatListScreen({super.key});

  @override
  State<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen>
    with TickerProviderStateMixin {
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StreamSubscription<List<ChatModel>>? _chatsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChats();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _chatsSubscription?.cancel();
    super.dispose();
  }

  void _loadChats() {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userId = AuthService.userId!;
    _chatsSubscription?.cancel();
    _chatsSubscription = ChatService.getUserToUserChatsStream(userId).listen((chats) {
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error loading chats: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  List<ChatModel> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    
    return _chats.where((chat) {
      final lastMessage = chat.lastMessage.toLowerCase();
      final userName = _getUserNameFromChat(chat).toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      
      return lastMessage.contains(searchLower) || userName.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'محادثات المستخدمين',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.primaryGreen),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
              _buildSearchBar(),

            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : !AuthService.isAuthenticated
                      ? _buildLoginPrompt()
                      : _filteredChats.isEmpty
                          ? _buildEmptyState()
                          : _buildChatsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'البحث في المحادثات...',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل المحادثات...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.login,
              size: 40.sp,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'يرجى تسجيل الدخول',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'قم بتسجيل الدخول لعرض محادثاتك',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40.sp,
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد محادثات',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ابدأ محادثة جديدة مع مستخدم آخر',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _filteredChats.length,
      itemBuilder: (context, index) {
        final chat = _filteredChats[index];
        return _buildChatTile(chat, index);
      },
    );
  }

  Widget _buildChatTile(ChatModel chat, int index) {
    final userId = AuthService.userId;
    final unreadCount = userId != null ? chat.unreadCount[userId] ?? 0 : 0;
    final isUnread = unreadCount > 0;
    final userName = _getUserNameFromChat(chat);
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        onTap: () => _openChat(chat),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Avatar
              FutureBuilder<DocumentSnapshot>(
                future: _getOtherUserIdFromChat(chat) != null 
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(_getOtherUserIdFromChat(chat))
                        .get()
                    : null,
                builder: (context, snapshot) {
                  String? profilePhoto;
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    profilePhoto = data?['profileImageUrl'] ?? data?['profilePhoto'];
                  }
                  
                  return CircleAvatar(
                    radius: 25.r,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    backgroundImage: profilePhoto != null && profilePhoto.isNotEmpty
                        ? NetworkImage(profilePhoto)
                        : null,
                    child: profilePhoto == null || profilePhoto.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 25.sp,
                            color: AppTheme.primaryGreen,
                          )
                        : null,
                  );
                },
              ),
              
              SizedBox(width: 12.w),
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(chat.lastMessageAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isUnread ? AppTheme.primaryGreen : Colors.grey[600],
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          SizedBox(width: 8.w),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUserNameFromChat(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return 'مستخدم';
    
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return chat.participantNames[participantId] ?? 'مستخدم';
      }
    }
    
    return 'مستخدم';
  }

  String? _getOtherUserIdFromChat(ChatModel chat) {
    final userId = AuthService.userId;
    if (userId == null) return null;
    
    for (final participantId in chat.participants) {
      if (participantId != userId) {
        return participantId;
      }
    }
    
    return null;
  }

  void _toggleSearch() {
    setState(() {
      if (_searchController.text.isEmpty && _searchQuery.isEmpty) {
        _searchController.text = ' ';
      } else {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _openChat(ChatModel chat) {
    final userName = _getUserNameFromChat(chat);
    final otherUserId = _getOtherUserIdFromChat(chat);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserChatScreen(
          chatId: chat.id,
          otherUserId: otherUserId ?? '',
          otherUserName: userName,
        ),
      ),
    );
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

