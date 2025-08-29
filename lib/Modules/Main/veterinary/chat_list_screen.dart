import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/chat_model.dart';
import '../../../Widgets/custom_card.dart';
import 'real_time_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    ChatService.getUserChatsStream(userId).listen((chats) {
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    });
  }

  List<ChatModel> get _filteredChats {
    if (_searchQuery.isEmpty) return _chats;
    
    return _chats.where((chat) {
      return chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'المحادثات',
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
            // Search bar
            if (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
              _buildSearchBar(),
            
            // Chats list
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
      floatingActionButton: AuthService.isAuthenticated
          ? FloatingActionButton(
              onPressed: _showNewChatDialog,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add_comment, color: Colors.white),
            )
          : null,
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'البحث في المحادثات...',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
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
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              // Navigate to login
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
            ),
            child: const Text('تسجيل الدخول'),
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
            'ابدأ محادثة جديدة مع طبيب بيطري',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _showNewChatDialog,
            icon: const Icon(Icons.add),
            label: const Text('محادثة جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
    final vetName = _getVetNameFromChat(chat);
    
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
              Stack(
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
                  // Online indicator
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
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vetName,
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

  void _toggleSearch() {
    setState(() {
      if (_searchController.text.isEmpty) {
        // Show search bar
        _searchController.text = ' '; // Trigger search bar to show
      } else {
        // Hide search bar
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _openChat(ChatModel chat) {
    final vetName = _getVetNameFromChat(chat);
    final vetId = _getVetIdFromChat(chat);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RealTimeChatScreen(
          chatId: chat.id,
          veterinarian: {
            'name': vetName,
            'specialization': 'طب بيطري عام',
            'isOnline': true,
            'id': vetId,
          },
        ),
      ),
    );
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

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildVeterinariansList(scrollController),
      ),
    );
  }

  Widget _buildVeterinariansList(ScrollController scrollController) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Title
          Text(
            'اختر طبيب بيطري',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20.h),
          
          // Veterinarians list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatService.getVeterinariansStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 40.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'لا يوجد أطباء متاحين حالياً',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final veterinarians = snapshot.data!;
                return ListView.builder(
                  controller: scrollController,
                  itemCount: veterinarians.length,
                  itemBuilder: (context, index) {
                    final vet = veterinarians[index];
                    return _buildVeterinarianTile(vet);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinarianTile(Map<String, dynamic> vet) {
    final isOnline = vet['isOnline'];
    final isAvailable = vet['isActive'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        onTap: isAvailable ? () => _startNewChat(vet) : null,
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.6,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      backgroundImage: vet['profilePhoto'] != null && 
                              vet['profilePhoto']!.isNotEmpty
                          ? NetworkImage(vet['profilePhoto']!)
                          : null,
                      child: vet['profilePhoto'] == null || 
                              vet['profilePhoto']!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 25.sp,
                              color: AppTheme.primaryGreen,
                            )
                          : null,
                    ),
                    if (isOnline)
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
                        vet['name'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        vet['specialization'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${vet['rating']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              isOnline ? 'متصل' : 'غير متصل',
                              style: TextStyle(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Start chat button
                Container(
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.primaryGreen : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chat,
                      color: isAvailable ? Colors.white : Colors.grey[600],
                      size: 20.sp,
                    ),
                    onPressed: isAvailable ? () => _startNewChat(vet) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startNewChat(Map<String, dynamic> vet) async {
    Navigator.pop(context); // Close bottom sheet
    
    try {
      final userId = AuthService.userId!;
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                SizedBox(height: 16.h),
                const Text('جاري إنشاء المحادثة...'),
              ],
            ),
          ),
        ),
      );
      
      final chatId = await ChatService.createChatWithVet(
        userId: userId,
        veterinarianId: vet['id'],
        initialMessage: 'مرحباً دكتور، أحتاج استشارة بيطرية',
      );
      
      Navigator.pop(context); // Close loading dialog
      
      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RealTimeChatScreen(
            chatId: chatId,
            veterinarian: {
              'name': vet['name'],
              'specialization': vet['specialization'],
              'isOnline': vet['isOnline'],
              'id': vet['id'],
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء المحادثة: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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