import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/Theme/app_theme.dart';
import '../../../core/Language/app_languages.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../Widgets/translated_text.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const TranslatedText('profile.notifications'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<AdminMessage>>(
        stream: NotificationService.getAdminMessagesFromNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _refreshMessages,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(message);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageCard(AdminMessage message) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: message.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: message.isRead 
              ? Colors.transparent 
              : _getTypeColor(message.type).withOpacity(0.3),
          width: message.isRead ? 0 : 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showMessageDetails(message),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w, 
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(message.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTypeIcon(message.type),
                          size: 12.sp,
                          color: _getTypeColor(message.type),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getTypeText(message.type),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: _getTypeColor(message.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (!message.isRead)
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SizedBox(width: 8.w),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 12.h),
              
              // Subject
              Text(
                message.subject,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: message.isRead ? FontWeight.w600 : FontWeight.bold,
                  color: AppTheme.lightOnSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 8.h),
              
              // Content preview
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 12.h),
              
              // Actions
              Row(
                children: [
                  if (!message.isRead)
                    TextButton.icon(
                      onPressed: () => _markAsRead(message.id),
                      icon: Icon(
                        Icons.mark_email_read,
                        size: 16.sp,
                        color: AppTheme.primaryGreen,
                      ),
                      label: Text(
                        'Mark as read',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _deleteMessage(message.id),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16.sp,
                      color: AppTheme.error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You\'ll see admin messages and notifications here',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _createTestMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Create Test Message'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.sp,
              color: AppTheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load notifications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetails(AdminMessage message) {
    // Mark as read when opened
    if (!message.isRead) {
      _markAsRead(message.id);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getTypeIcon(message.type),
              color: _getTypeColor(message.type),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message.subject,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getTypeColor(message.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Sent: ${_formatDateTime(message.createdAt)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await NotificationService.markMessageAsRead(messageId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark message as read: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      setState(() => _isLoading = true);
      await NotificationService.markAllMessagesAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All messages marked as read'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await NotificationService.deleteMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshMessages() async {
    // Stream automatically refreshes, so just wait a moment
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _createTestMessage() async {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please login first'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Create test message directly in notifications subcollection
      await FirebaseConfig.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'subject': 'Welcome to Alifi!',
        'content': 'This is a test message from the admin. The notification system is working correctly! You can now receive important updates and messages.',
        'type': 'info',
        'notificationType': 'admin_message',
        'isRead': false,
        'isAdminMessage': true,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Test message created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      print('Error creating test message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test message: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'info':
        return AppTheme.info;
      case 'warning':
        return AppTheme.warning;
      case 'success':
        return AppTheme.success;
      case 'urgent':
        return AppTheme.error;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'info':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.message;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'info':
        return 'INFO';
      case 'warning':
        return 'WARNING';
      case 'success':
        return 'SUCCESS';
      case 'urgent':
        return 'URGENT';
      default:
        return 'MESSAGE';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
} 