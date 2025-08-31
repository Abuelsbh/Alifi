import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../Models/chat_model.dart';
import '../../../Widgets/message_bubble.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String chatId;
  final String veterinarianId;
  final String veterinarianName;

  const EnhancedChatScreen({
    super.key,
    required this.chatId,
    required this.veterinarianId,
    required this.veterinarianName,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSending = false;
  bool _showAttachmentMenu = false;
  List<ChatMessage> _messages = [];
  
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;
  
  // Stream management
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMessages();
  }

  void _initializeAnimations() {
    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _attachmentAnimation = CurvedAnimation(
      parent: _attachmentAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _attachmentAnimationController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen to real-time messages
      _messagesSubscription = ChatService.getChatMessagesStream(widget.chatId).listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
          });
          
          // Auto-scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تحميل الرسائل: $e');
      setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final userId = AuthService.userId;
    
    if (userId == null) {
      _showErrorSnackBar('خطأ في المصادقة');
      return;
    }

    _messageController.clear();
    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.sendTextMessage(
        chatId: widget.chatId,
        senderId: userId,
        message: message,
      );
      
      // Auto-scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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

  Future<void> _sendImageMessage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        await _uploadAndSendMedia(File(image.path), MessageType.image);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _sendVideoMessage() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        await _uploadAndSendMedia(File(video.path), MessageType.video);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الفيديو: $e');
    }
  }

  Future<void> _sendFileMessage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _uploadAndSendMedia(file, MessageType.file, result.files.single.name);
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الملف: $e');
    }
  }

  Future<void> _uploadAndSendMedia(File file, MessageType type, [String? fileName]) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      switch (type) {
        case MessageType.image:
          await ChatService.sendImageMessage(
            chatId: widget.chatId,
            senderId: userId,
            imageFile: file,
          );
          break;
        case MessageType.video:
          await ChatService.sendVideoMessage(
            chatId: widget.chatId,
            senderId: userId,
            videoFile: file,
          );
          break;
        case MessageType.file:
          await ChatService.sendFileMessage(
            chatId: widget.chatId,
            senderId: userId,
            file: file,
            fileName: fileName,
          );
          break;
        default:
          throw Exception('نوع الملف غير مدعوم');
      }
      
      _hideAttachmentMenu();
      
      // Auto-scroll to bottom after sending media
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      _showErrorSnackBar('خطأ في رفع الملف: $e');
    } finally {
      if (mounted) {
      setState(() {
        _isSending = false;
      });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
    
    if (_showAttachmentMenu) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
  }

  void _hideAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = false;
    });
    _attachmentAnimationController.reverse();
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

  void _handleMessageTap(ChatMessage message) {
    switch (message.type) {
      case MessageType.image:
        _showImageFullScreen(message.mediaUrl ?? '');
        break;
      case MessageType.video:
        _showVideoPlayer(message.mediaUrl ?? '');
        break;
      case MessageType.file:
        _downloadFile(message.mediaUrl ?? '', message.fileName ?? 'ملف');
        break;
      default:
        break;
    }
  }

  void _handleMessageLongPress(ChatMessage message) {
    _showMessageOptions(message);
  }

  void _showImageFullScreen(String imageUrl) {
    // TODO: Implement full screen image viewer
    _showComingSoonDialog('عرض الصورة بالحجم الكامل');
  }

  void _showVideoPlayer(String videoUrl) {
    // TODO: Implement video player
    _showComingSoonDialog('مشغل الفيديو');
  }

  void _downloadFile(String fileUrl, String fileName) {
    // TODO: Implement file download
    _showComingSoonDialog('تحميل الملف');
  }

  void _showMessageOptions(ChatMessage message) {
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
            leading: const Icon(Icons.copy),
            title: const Text('نسخ النص'),
            onTap: () {
              Navigator.pop(context);
              _copyMessageText(message.message);
            },
          ),
          if (message.type == MessageType.image)
            ListTile(
              leading: const Icon(Icons.save),
              title: const Text('حفظ الصورة'),
              onTap: () {
                Navigator.pop(context);
                _saveImage(message.mediaUrl ?? '');
              },
            ),
          if (message.senderId == AuthService.userId)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف الرسالة', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
        ],
      ),
    );
  }

  void _copyMessageText(String text) {
    // TODO: Implement copy to clipboard
    _showComingSoonDialog('نسخ النص');
  }

  void _saveImage(String imageUrl) {
    // TODO: Implement save image to gallery
    _showComingSoonDialog('حفظ الصورة');
  }

  void _deleteMessage(ChatMessage message) {
    // TODO: Implement delete message
    _showComingSoonDialog('حذف الرسالة');
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قريباً'),
        content: Text('ميزة $feature ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: _hideAttachmentMenu,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _buildMessagesList(),
            ),
            _buildAttachmentMenu(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppTheme.primaryGreen,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.veterinarianName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'طبيب بيطري',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,

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
            'جاري تحميل الرسائل...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(
          message: message,
          isMe: message.senderId == AuthService.userId,
          onTap: () => _handleMessageTap(message),
          onLongPress: () => _handleMessageLongPress(message),
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
            Icons.chat_bubble_outline,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'ابدأ محادثة مع الطبيب',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اطرح أسئلتك حول صحة حيوانك الأليف',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return AnimatedBuilder(
      animation: _attachmentAnimation,
      builder: (context, child) {
        return Container(
          height: _attachmentAnimation.value * 120.h,
          child: _attachmentAnimation.value > 0
              ? Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentButton(
                        icon: Icons.camera_alt,
                        label: 'كاميرا',
                        color: AppTheme.primaryGreen,
                        onPressed: () => _sendImageMessage(ImageSource.camera),
                      ),
                      _buildAttachmentButton(
                        icon: Icons.photo_library,
                        label: 'معرض',
                        color: AppTheme.primaryOrange,
                        onPressed: () => _sendImageMessage(ImageSource.gallery),
                      ),
                      _buildAttachmentButton(
                        icon: Icons.videocam,
                        label: 'فيديو',
                        color: AppTheme.error,
                        onPressed: _sendVideoMessage,
                      ),
                      _buildAttachmentButton(
                        icon: Icons.attach_file,
                        label: 'ملف',
                        color: AppTheme.info,
                        onPressed: _sendFileMessage,
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleAttachmentMenu,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _showAttachmentMenu 
                    ? AppTheme.primaryGreen 
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showAttachmentMenu ? Icons.close : Icons.attach_file,
                color: _showAttachmentMenu 
                    ? Colors.white 
                    : AppTheme.primaryGreen,
                size: 20.sp,
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          GestureDetector(
            onTap: _isSending ? null : _sendTextMessage,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _isSending 
                    ? Colors.grey[400] 
                    : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20.sp,
                    ),
            ),
          ),
        ],
      ),
    );
  }
} 