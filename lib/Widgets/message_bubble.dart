import 'package:alifi/Utilities/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/Theme/app_theme.dart';
import '../Models/chat_model.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildMessageContainer(),
          ),
        );
      },
    );
  }

  Widget _buildMessageContainer() {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: widget.isMe ? 60.w : 0,
            right: widget.isMe ? 0 : 60.w,
            bottom: 8.h,
          ),
          child: Column(
            crossAxisAlignment: widget.isMe 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
            children: [
              // Message bubble
              Container(
                decoration: widget.message.type == MessageType.text ? BoxDecoration(
                  color: _getBubbleColor(),
                  borderRadius: _getBorderRadius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ) : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: _buildMessageContent(),
                ),
              ),
              
              SizedBox(height: 4.h),
              
              // Message info
              _buildMessageInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBubbleColor() {
    if (widget.isMe) {
      return ThemeClass.of(context).primaryColor;
    } else {
      return ThemeClass.of(context).secondaryColor;
    }
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: Radius.circular(20.r),
      topRight: Radius.circular(20.r),
      bottomLeft: widget.isMe ? Radius.circular(20.r) : Radius.circular(4.r),
      bottomRight: widget.isMe ? Radius.circular(4.r) : Radius.circular(20.r),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextMessage();
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.file:
        return _buildFileMessage();
      case MessageType.audio:
        return _buildAudioMessage();
      case MessageType.location:
        return _buildLocationMessage();
    }
  }

  Widget _buildTextMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          widget.message.message,
          style: TextStyle(
            color: ThemeClass.of(context).backGroundColor,
            fontSize: 15.sp,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 200.w,
              maxHeight: 200.h,
            ),
            child: CachedNetworkImage(
              imageUrl: widget.message.mediaUrl ?? '',
              fit: BoxFit.cover,
              memCacheWidth: 200,
              memCacheHeight: 200,
              maxWidthDiskCache: 800,
              maxHeightDiskCache: 800,
              placeholder: (context, url) => Container(
                height: 150.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                return Container(
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: Colors.grey[600],
                        size: 40.sp,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'خطأ في تحميل الصورة',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // if (widget.message.message.isNotEmpty) ...[
        //   SizedBox(height: 8.h),
        //   Text(
        //     widget.message.message,
        //     style: TextStyle(
        //       color: widget.isMe ? Colors.white : Colors.black87,
        //       fontSize: 14.sp,
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 200.w,
              maxHeight: 200.h,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.message.mediaUrl ?? '',
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                  maxWidthDiskCache: 800,
                  maxHeightDiskCache: 800,
                  placeholder: (context, url) => Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    return Container(
                      height: 150.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.video_library,
                        color: Colors.grey[600],
                        size: 40.sp,
                      ),
                    );
                  },
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
        ),
        if (widget.message.message.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            widget.message.message,
            style: TextStyle(
              color: widget.isMe ? Colors.white : Colors.black87,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileMessage() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: widget.isMe 
            ? Colors.white.withOpacity(0.2)
            : AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: widget.isMe 
                  ? Colors.white.withOpacity(0.3)
                  : AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _getFileIcon(),
              color: widget.isMe ? Colors.white : AppTheme.primaryGreen,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.fileName ?? 'ملف',
                  style: TextStyle(
                    color: widget.isMe ? Colors.white : Colors.black87,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.message.fileSize != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _formatFileSize(widget.message.fileSize!),
                    style: TextStyle(
                      color: widget.isMe 
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                      fontSize: 12.sp,
                    ),
                  ),
                ],
                SizedBox(height: 2.h),
                Text(
                  'انقر للتحميل',
                  style: TextStyle(
                    color: widget.isMe 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: widget.isMe ? Colors.white : AppTheme.primaryGreen,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: widget.isMe 
                  ? Colors.white.withOpacity(0.3)
                  : AppTheme.primaryGreen.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: widget.isMe ? Colors.white : AppTheme.primaryGreen,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 8.w),
          // Voice wave animation placeholder
          Expanded(
            child: Container(
              height: 30.h,
              child: Row(
                children: List.generate(20, (index) {
                  return Container(
                    width: 2.w,
                    height: (index % 3 + 1) * 8.h,
                    margin: EdgeInsets.symmetric(horizontal: 1.w),
                    decoration: BoxDecoration(
                      color: widget.isMe 
                          ? Colors.white.withOpacity(0.6)
                          : AppTheme.primaryGreen.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  );
                }),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '0:45', // Duration placeholder
            style: TextStyle(
              color: widget.isMe 
                  ? Colors.white.withOpacity(0.8)
                  : Colors.grey[600],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage() {
    return Container(
      width: 200.w,
      height: 120.h,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          // Map placeholder
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 40.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Location marker
          Center(
            child: Icon(
              Icons.location_on,
              color: AppTheme.error,
              size: 30.sp,
            ),
          ),
          // Open in maps button
          Positioned(
            bottom: 8.h,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'عرض في الخريطة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatMessageTime(),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11.sp,
            ),
          ),
          if (widget.isMe) ...[
            SizedBox(width: 4.w),
            _buildMessageStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageStatus() {
    IconData iconData;
    Color iconColor;

    if (widget.message.isRead) {
      iconData = Icons.done_all;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.done;
      iconColor = Colors.grey[500]!;
    }

    return Icon(
      iconData,
      size: 14.sp,
      color: iconColor,
    );
  }

  String _formatMessageTime() {
    final dateTime = widget.message.timestamp;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    // Convert to 12-hour format
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'م' : 'ص';
    
    return '$displayHour:$minute $period';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  IconData _getFileIcon() {
    final fileName = widget.message.fileName?.toLowerCase() ?? '';
    
    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    } else if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Icons.archive;
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || 
               fileName.endsWith('.png') || fileName.endsWith('.gif')) {
      return Icons.image;
    } else if (fileName.endsWith('.mp4') || fileName.endsWith('.avi') || 
               fileName.endsWith('.mov')) {
      return Icons.video_file;
    } else if (fileName.endsWith('.mp3') || fileName.endsWith('.wav')) {
      return Icons.audio_file;
    } else {
      return Icons.insert_drive_file;
    }
  }
} 