import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/chat_model.dart';
import '../../../Widgets/message_bubble.dart';

class RealTimeChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> veterinarian;

  const RealTimeChatScreen({
    super.key,
    required this.chatId,
    required this.veterinarian,
  });

  @override
  State<RealTimeChatScreen> createState() => _RealTimeChatScreenState();
}

class _RealTimeChatScreenState extends State<RealTimeChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMessages();
    _messageController.addListener(_onTypingChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  void _onTypingChanged() {
    final isCurrentlyTyping = _messageController.text.trim().isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _loadMessages() {
    if (!mounted) return;

    // Mark messages as read when entering chat
    final userId = AuthService.userId;
    if (userId != null) {
      ChatService.markMessagesAsRead(
        chatId: widget.chatId,
        userId: userId,
      );
    }

    // Listen to real-time messages
    _messagesSubscription = ChatService.getChatMessagesStream(widget.chatId).listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        // Mark messages as read when new messages arrive
        final userId = AuthService.userId;
        if (userId != null) {
          ChatService.markMessagesAsRead(
            chatId: widget.chatId,
            userId: userId,
          );
        }
        
        // Auto-scroll to bottom when new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final userId = AuthService.userId;
      if (userId != null) {
        await ChatService.sendTextMessage(
          chatId: widget.chatId,
          senderId: userId,
          message: messageText,
        );
        
        _messageController.clear();
        
        // Show success feedback
        _showMessageSentFeedback();
        
        // Auto-scroll to bottom after sending message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال الرسالة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _isSending = true;
        });

        final userId = AuthService.userId;
        if (userId != null) {
          await ChatService.sendImageMessage(
            chatId: widget.chatId,
            senderId: userId,
            imageFile: File(image.path),
          );
          
          _showMessageSentFeedback();
          
          // Auto-scroll to bottom after sending image
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال الصورة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageSentFeedback() {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            const Text('تم الإرسال'),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100.h,
          left: 20.w,
          right: 20.w,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _buildMessagesList(),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final vetName = widget.veterinarian['name'] ?? 'طبيب بيطري';
    final vetSpecialization = widget.veterinarian['specialization'] ?? '';
    final isOnline = widget.veterinarian['isOnline'] ?? false;

    return AppBar(
      elevation: 1,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Vet Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                backgroundImage: widget.veterinarian['profilePhoto'] != null &&
                        widget.veterinarian['profilePhoto'].toString().isNotEmpty
                    ? NetworkImage(widget.veterinarian['profilePhoto'])
                    : null,
                child: widget.veterinarian['profilePhoto'] == null ||
                        widget.veterinarian['profilePhoto'].toString().isEmpty
                    ? Icon(
                        Icons.person,
                        size: 20.sp,
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
          
          // Vet Info
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
                if (vetSpecialization.isNotEmpty)
                  Text(
                    vetSpecialization,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [

        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: AppTheme.primaryGreen),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('الملف الشخصي'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حظر', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _showComingSoonDialog(value.toString());
          },
        ),
      ],
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
            'جاري تحميل المحادثة...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: EdgeInsets.all(16.w),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isMe = message.senderId == AuthService.userId;
          final showDateHeader = _shouldShowDateHeader(index);
          
          return Column(
            children: [
              if (showDateHeader) _buildDateHeader(message.timestamp),
              MessageBubble(
                message: message,
                isMe: isMe,
                onTap: () => _handleMessageTap(message),
                onLongPress: () => _handleMessageLongPress(message),
              ),
              SizedBox(height: 8.h),
            ],
          );
        },
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
            'ابدأ المحادثة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اكتب رسالتك الأولى لبدء الاستشارة البيطرية',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == _messages.length - 1) return true;
    
    final currentMessage = _messages[index];
    final nextMessage = _messages[index + 1];
    
    final currentDate = currentMessage.timestamp;
    final nextDate = nextMessage.timestamp;
    
    return currentDate.day != nextDate.day ||
           currentDate.month != nextDate.month ||
           currentDate.year != nextDate.year;
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    
    String dateText;
    if (timestamp.day == now.day && timestamp.month == now.month && timestamp.year == now.year) {
      dateText = 'اليوم';
    } else if (timestamp.day == now.day - 1 && timestamp.month == now.month && timestamp.year == now.year) {
      dateText = 'أمس';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                dateText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  void _handleMessageTap(ChatMessage message) {
    // Handle message tap based on type
    switch (message.type) {
      case MessageType.image:
        _showImageFullScreen(message.mediaUrl);
        break;
      case MessageType.video:
        _showVideoPlayer(message.mediaUrl);
        break;
      case MessageType.file:
        _downloadFile(message.mediaUrl, message.fileName);
        break;
      default:
        break;
    }
  }

  void _handleMessageLongPress(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMessageOptions(message),
    );
  }

  Widget _buildMessageOptions(ChatMessage message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('نسخ النص'),
            onTap: () {
              Navigator.pop(context);
              _copyMessageText(message.message);
            },
          ),
          if (message.type == MessageType.image)
            ListTile(
              leading: Icon(Icons.download),
              title: Text('حفظ الصورة'),
              onTap: () {
                Navigator.pop(context);
                _saveImage(message.mediaUrl);
              },
            ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('حذف الرسالة', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String? imageUrl) {
    if (imageUrl == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48.sp,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(String? videoUrl) {
    if (videoUrl == null) return;
    
    // TODO: Implement video player
    _showComingSoonDialog('مشغل الفيديو');
  }

  void _downloadFile(String? fileUrl, String? fileName) {
    if (fileUrl == null) return;
    
    // TODO: Implement file download
    _showComingSoonDialog('تحميل الملف');
  }

  void _copyMessageText(String text) {
    // TODO: Implement copy to clipboard
    _showComingSoonDialog('نسخ النص');
  }

  void _saveImage(String? imageUrl) {
    if (imageUrl == null) return;
    
    // TODO: Implement save image to gallery
    _showComingSoonDialog('حفظ الصورة');
  }

  void _deleteMessage(ChatMessage message) {
    // TODO: Implement delete message
    _showComingSoonDialog('حذف الرسالة');
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.attach_file,
                  color: AppTheme.primaryGreen,
                ),
                onPressed: _showAttachmentOptions,
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            SizedBox(width: 8.w),
            
            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isTyping || _isSending
                    ? AppTheme.primaryGreen
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: _isTyping ? Colors.white : Colors.grey[600],
                      ),
                onPressed: _isTyping && !_isSending ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إرفاق ملف',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'كاميرا',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _sendImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'ملف',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoonDialog('إرسال ملف');
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _isSending = true;
        });

        final userId = AuthService.userId;
        if (userId != null) {
          await ChatService.sendImageMessage(
            chatId: widget.chatId,
            senderId: userId,
            imageFile: File(image.path),
          );
          
          _showMessageSentFeedback();
          
          // Auto-scroll to bottom after taking picture
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في التقاط الصورة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('قريباً'),
        content: Text('ميزة $feature ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }
} 