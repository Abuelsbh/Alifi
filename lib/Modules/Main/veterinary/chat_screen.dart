import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/Theme/app_theme.dart';
import '../../../Widgets/custom_button.dart';
import '../../../Widgets/translated_text.dart';
import '../../../Models/chat_model.dart';
import '../../../Models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final VeterinarianModel veterinarian;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.veterinarian,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load messages from service
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock messages
      _messages = [
        MessageModel(
          id: '1',
          chatId: widget.chatId,
          senderId: widget.veterinarian.id,
          senderName: widget.veterinarian.name,
          senderType: 'veterinarian',
          message: 'Hello! How can I help you today?',
          type: MessageType.text,
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        MessageModel(
          id: '2',
          chatId: widget.chatId,
          senderId: 'user1',
          senderName: 'John Doe',
          senderType: 'user',
          message: 'Hi Dr. ${widget.veterinarian.name.split(' ').last}, my dog has been acting strange lately.',
          type: MessageType.text,
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        MessageModel(
          id: '3',
          chatId: widget.chatId,
          senderId: widget.veterinarian.id,
          senderName: widget.veterinarian.name,
          senderType: 'veterinarian',
          message: 'I\'m sorry to hear that. Can you tell me more about the symptoms?',
          type: MessageType.text,
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // TODO: Send message through service
      await Future.delayed(const Duration(milliseconds: 500));
      
      final newMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatId,
        senderId: 'user1', // TODO: Get current user ID
        senderName: 'John Doe', // TODO: Get current user name
        senderType: 'user',
        message: message,
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(newMessage);
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      // Handle error
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        await _sendMediaMessage(File(image.path), MessageType.image);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        await _sendMediaMessage(File(video.path), MessageType.video);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _sendMediaMessage(File mediaFile, MessageType type) async {
    setState(() {
      _isSending = true;
    });

    try {
      // TODO: Upload media and send message through service
      await Future.delayed(const Duration(seconds: 2));
      
      final newMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatId,
        senderId: 'user1', // TODO: Get current user ID
        senderName: 'John Doe', // TODO: Get current user name
        senderType: 'user',
        message: type == MessageType.image ? 'Image' : 'Video',
        type: type,
        mediaUrl: 'https://example.com/media.jpg', // TODO: Get uploaded URL
        isRead: false,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(newMessage);
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      // Handle error
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.photo, color: AppTheme.primaryGreen),
                    title: TranslatedText('chat.photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                    title: TranslatedText('chat.camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.videocam, color: AppTheme.primaryGreen),
                    title: TranslatedText('chat.video'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: TranslatedText('chat.title'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Open chat options
            },
            icon: Icon(Icons.more_vert, color: AppTheme.primaryGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
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
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Send a message to begin chatting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.senderType == 'user';
        
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildMessageBubble(message, isUser),
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isUser) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              message.senderName.split(' ').map((e) => e[0]).join(''),
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isUser 
                  ? AppTheme.primaryGreen 
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r).copyWith(
                bottomLeft: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
                bottomRight: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.type == MessageType.text)
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14.sp,
                    ),
                  )
                else if (message.type == MessageType.image)
                  _buildImageMessage(message)
                else if (message.type == MessageType.video)
                  _buildVideoMessage(message),
                SizedBox(height: 4.h),
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: isUser 
                        ? Colors.white.withOpacity(0.7) 
                        : Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isUser) ...[
          SizedBox(width: 8.w),
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            child: Text(
              'JD', // TODO: Get current user initials
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageMessage(MessageModel message) {
    return Container(
      width: 200.w,
      height: 150.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: message.mediaUrl != null
            ? Image.network(
                message.mediaUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image,
                    size: 48.sp,
                    color: Colors.grey,
                  );
                },
              )
            : Icon(
                Icons.image,
                size: 48.sp,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildVideoMessage(MessageModel message) {
    return Container(
      width: 200.w,
      height: 150.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            message.mediaUrl != null
                ? Image.network(
                    message.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.video_library,
                        size: 48.sp,
                        color: Colors.grey,
                      );
                    },
                  )
                : Icon(
                    Icons.video_library,
                    size: 48.sp,
                    color: Colors.grey,
                  ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showMediaOptions,
            icon: Icon(
              Icons.attach_file,
              color: AppTheme.primaryGreen,
              size: 24.sp,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'chat.type_message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _showMediaOptions,
                      icon: Icon(Icons.attach_file, color: AppTheme.primaryGreen),
                    ),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: AppTheme.primaryGreen),
                    ),
                  ],
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 