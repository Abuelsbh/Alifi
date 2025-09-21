import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import 'auth_service.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static const String _messagesCollection = 'admin_messages';
  static const String _usersCollection = 'users';

  // Get admin messages for current user
  static Stream<List<AdminMessage>> getAdminMessagesStream() {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        print('⚠️ No user ID found for notifications');
        return Stream.value([]);
      }

      print('🔔 Setting up admin messages stream for user: $userId');

      // Try with orderBy first, fallback to without orderBy if index not ready
      return _firestore
          .collection(_messagesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            print('⚠️ Index error, using fallback query: $error');
            // Fallback to simple query without orderBy
            return _firestore
                .collection(_messagesCollection)
                .where('userId', isEqualTo: userId)
                .snapshots();
          })
          .map((snapshot) {
        print('🔔 Received ${snapshot.docs.length} admin messages');

        var messages = snapshot.docs.map((doc) {
          try {
            return AdminMessage.fromFirestore(doc);
          } catch (e) {
            print('❌ Error parsing admin message ${doc.id}: $e');
            return null;
          }
        }).where((message) => message != null).cast<AdminMessage>().toList();

        // Sort manually if we used fallback query
        try {
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } catch (e) {
          print('⚠️ Error sorting messages: $e');
        }

        print('✅ Successfully parsed ${messages.length} admin messages');
        return messages;
      }).handleError((error) {
        print('❌ Final error in admin messages stream: $error');
        return <AdminMessage>[];
      });
    } catch (e) {
      print('❌ Error setting up admin messages stream: $e');
      return Stream.value([]);
    }
  }

  // Get unread messages count
  static Stream<int> getUnreadMessagesCountStream() {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        return Stream.value(0);
      }

      // Use simple query to avoid index issues
      return _firestore
          .collection(_messagesCollection)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            try {
              // Filter unread messages manually to avoid compound index requirement
              final unreadCount = snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['isRead'] == false || data?['isRead'] == null;
              }).length;
              
              return unreadCount;
            } catch (e) {
              print('❌ Error counting unread messages: $e');
              return 0;
            }
          })
          .handleError((error) {
            print('❌ Error in unread messages stream: $error');
            return 0;
          });
    } catch (e) {
      print('❌ Error getting unread messages count: $e');
      return Stream.value(0);
    }
  }

  // Mark message as read
  static Future<void> markMessageAsRead(String messageId) async {
    try {
      final userId = AuthService.userId;
      if (userId == null) return;

      // Update both admin_messages and notifications
      await Future.wait([
        // Update main collection
        _firestore.collection(_messagesCollection).doc(messageId).update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((e) {
          print('⚠️ Could not update admin_messages: $e');
        }),
        
        // Update notifications subcollection
        _updateNotificationAsRead(userId, messageId),
      ]);
      
      print('✅ Message marked as read: $messageId');
    } catch (e) {
      print('❌ Error marking message as read: $e');
      throw e;
    }
  }

  // Helper function to update notification in subcollection
  static Future<void> _updateNotificationAsRead(String userId, String messageId) async {
    try {
      final notificationsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('notifications');
      
      // Find notification with matching messageId
      final querySnapshot = await notificationsRef
          .where('messageId', isEqualTo: messageId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        await doc.reference.update({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('⚠️ Could not update notification as read: $e');
    }
  }

  // Mark all messages as read
  static Future<void> markAllMessagesAsRead() async {
    try {
      final userId = AuthService.userId;
      if (userId == null) return;

      final unreadMessages = await _firestore
          .collection(_messagesCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ All messages marked as read');
    } catch (e) {
      print('❌ Error marking all messages as read: $e');
      throw e;
    }
  }

  // Delete message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
      print('✅ Message deleted: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw e;
    }
  }

  // Get user notifications (subcollection) - Alternative method
  static Stream<List<UserNotification>> getUserNotificationsStream() {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('notifications')
          .snapshots()
          .map((snapshot) {
        var notifications = snapshot.docs.map((doc) {
          try {
            return UserNotification.fromFirestore(doc);
          } catch (e) {
            print('❌ Error parsing notification ${doc.id}: $e');
            return null;
          }
        }).where((notification) => notification != null).cast<UserNotification>().toList();

        // Sort manually to avoid index requirement
        try {
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } catch (e) {
          print('⚠️ Error sorting notifications: $e');
        }

        return notifications;
      }).handleError((error) {
        print('❌ Error in user notifications stream: $error');
        return <UserNotification>[];
      });
    } catch (e) {
      print('❌ Error setting up user notifications stream: $e');
      return Stream.value([]);
    }
  }

  // Alternative method using notifications subcollection
  static Stream<List<AdminMessage>> getAdminMessagesFromNotifications() {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        print('⚠️ No user ID found for notifications');
        return Stream.value([]);
      }

      print('🔔 Using notifications subcollection as fallback');

      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('notifications')
          .where('notificationType', isEqualTo: 'admin_message')
          .snapshots()
          .map((snapshot) {
        var messages = snapshot.docs.map((doc) {
          try {
            final notification = UserNotification.fromFirestore(doc);
            // Convert UserNotification to AdminMessage
            return AdminMessage(
              id: notification.messageId ?? doc.id,
              userId: notification.userId,
              subject: notification.subject,
              content: notification.content,
              type: notification.type,
              isRead: notification.isRead,
              isAdminMessage: true,
              createdAt: notification.createdAt,
            );
          } catch (e) {
            print('❌ Error converting notification to message ${doc.id}: $e');
            return null;
          }
        }).where((message) => message != null).cast<AdminMessage>().toList();

        // Sort manually
        try {
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } catch (e) {
          print('⚠️ Error sorting messages: $e');
        }

        print('✅ Successfully loaded ${messages.length} messages from notifications');
        return messages;
      }).handleError((error) {
        print('❌ Error in notifications fallback stream: $error');
        return <AdminMessage>[];
      });
    } catch (e) {
      print('❌ Error setting up notifications fallback stream: $e');
      return Stream.value([]);
    }
  }

  // Alternative unread count using notifications subcollection
  // static Stream<int> getUnreadMessagesCountFromNotifications() {
  //   try {
  //     final userId = AuthService.userId;
  //     if (userId == null) {
  //       return Stream.value(0);
  //     }
  //
  //     return _firestore
  //         .collection(_usersCollection)
  //         .doc(userId)
  //         .collection('notifications')
  //         .where('notificationType', isEqualTo: 'admin_message')
  //         .snapshots()
  //         .map((snapshot) {
  //           try {
  //             final unreadCount = snapshot.docs.where((doc) {
  //               final data = doc.data() as Map<String, dynamic>?;
  //               return data?['isRead'] == false || data?['isRead'] == null;
  //             }).length;
  //
  //             return unreadCount;
  //           } catch (e) {
  //             print('❌ Error counting unread notifications: $e');
  //             return 0;
  //           }
  //         })
  //         .handleError((error) {
  //           print('❌ Error in unread notifications count stream: $error');
  //           return 0;
  //         });
  //   } catch (e) {
  //     print('❌ Error getting unread notifications count: $e');
  //     return Stream.value(0);
  //   }
  // }

  // Alternative unread count using notifications subcollection  
  static Stream<int> getUnreadMessagesCountFromNotifications() {
    try {
      final userId = AuthService.userId;
      if (userId == null) {
        return Stream.value(0);
      }

      return _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('notifications')
          .where('notificationType', isEqualTo: 'admin_message')
          .snapshots()
          .map((snapshot) {
            try {
              final unreadCount = snapshot.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['isRead'] == false || data?['isRead'] == null;
              }).length;
              
              return unreadCount;
            } catch (e) {
              print('❌ Error counting unread notifications: $e');
              return 0;
            }
          })
          .handleError((error) {
            print('❌ Error in unread notifications count stream: $error');
            return 0;
          });
    } catch (e) {
      print('❌ Error getting unread notifications count: $e');
      return Stream.value(0);
    }
  }
}

// Admin Message Model
class AdminMessage {
  final String id;
  final String userId;
  final String subject;
  final String content;
  final String type;
  final bool isRead;
  final bool isAdminMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;

  AdminMessage({
    required this.id,
    required this.userId,
    required this.subject,
    required this.content,
    required this.type,
    required this.isRead,
    required this.isAdminMessage,
    required this.createdAt,
    this.updatedAt,
    this.readAt,
  });

  factory AdminMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AdminMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'info',
      isRead: data['isRead'] ?? false,
      isAdminMessage: data['isAdminMessage'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'content': content,
      'type': type,
      'isRead': isRead,
      'isAdminMessage': isAdminMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }
}

// User Notification Model (for subcollection)
class UserNotification {
  final String id;
  final String userId;
  final String subject;
  final String content;
  final String type;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final String? messageId;

  UserNotification({
    required this.id,
    required this.userId,
    required this.subject,
    required this.content,
    required this.type,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.messageId,
  });

  factory UserNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'info',
      notificationType: data['notificationType'] ?? 'admin_message',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageId: data['messageId'],
    );
  }
} 