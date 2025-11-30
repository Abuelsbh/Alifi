import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/firebase_config.dart';
import '../../Models/chat_model.dart';
import '../../Models/user_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseStorage _storage = FirebaseConfig.storage;
  static final ImagePicker _picker = ImagePicker();
  
  // Cache for chat and message streams
  static final Map<String, Stream<List<ChatModel>>> _chatStreamsCache = {};
  static final Map<String, Stream<List<ChatMessage>>> _messageStreamsCache = {};
  static final Map<String, Stream<List<Map<String, dynamic>>>> _veterinariansStreamCache = {};

  // Throttling for markMessagesAsRead
  static final Map<String, DateTime> _lastMarkAsReadCall = {};
  static const Duration _markAsReadThrottle = Duration(seconds: 3);

  // Clear cache when needed
  static void clearCache() {
    _chatStreamsCache.clear();
    _messageStreamsCache.clear();
    _veterinariansStreamCache.clear();
  }

  // Clear veterinarians cache specifically
  static void clearVeterinariansCache() {
    _veterinariansStreamCache.clear();
  }

  // Clear all caches
  static void clearAllCaches() {
    _chatStreamsCache.clear();
    _messageStreamsCache.clear();
    _veterinariansStreamCache.clear();
  }

  // Get user's chats stream with caching
  static Stream<List<ChatModel>> getUserChatsStream(String userId) {
    if (_chatStreamsCache.containsKey(userId)) {
      return _chatStreamsCache[userId]!;
    }
    
    // If in demo mode, return mock chats
    if (FirebaseConfig.isDemoMode) {
      final mockChats = [
        ChatModel(
          id: 'demo_chat_1',
          participants: [userId, 'demo_vet_1'],
          participantNames: {
            userId: 'المستخدم',
            'demo_vet_1': 'د. أحمد محمد',
          },
          lastMessage: 'مرحباً، كيف يمكنني مساعدتك؟',
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
          lastMessageSender: 'demo_vet_1',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: {userId: 0, 'demo_vet_1': 0},
        ),
        ChatModel(
          id: 'demo_chat_2',
          participants: [userId, 'demo_vet_2'],
          participantNames: {
            userId: 'المستخدم',
            'demo_vet_2': 'د. فاطمة علي',
          },
          lastMessage: 'سأقوم بفحص حالة حيوانك الأليف',
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
          lastMessageSender: 'demo_vet_2',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          unreadCount: {userId: 1, 'demo_vet_2': 0},
        ),
      ];
      
      final stream = Stream.value(mockChats);
      _chatStreamsCache[userId] = stream;
      return stream;
    }
    
    final stream = _firestore
        .collection('veterinary_chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          return chats;
        });
    
    _chatStreamsCache[userId] = stream;
    return stream;
  }

  // Get chat messages stream with caching
  static Stream<List<ChatMessage>> getChatMessagesStream(String chatId) {
    if (_messageStreamsCache.containsKey(chatId)) {
      return _messageStreamsCache[chatId]!;
    }
    
    final stream = _firestore
        .collection('veterinary_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // ترتيب من الأقدم إلى الأحدث
        .limit(50) // Optimized limit for better performance
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
    
    _messageStreamsCache[chatId] = stream;
    return stream;
  }

  // Get veterinarians stream with caching
  static Stream<List<Map<String, dynamic>>> getVeterinariansStream() {
    const cacheKey = 'veterinarians';
    if (_veterinariansStreamCache.containsKey(cacheKey)) {
      return _veterinariansStreamCache[cacheKey]!;
    }
    
    try {
      final stream = _firestore
          .collection('veterinarians')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  // Filter veterinarians who are verified or don't have isVerified field (backward compatibility)
                  if (data['isVerified'] == true || data['isVerified'] == null) {
                    return {
                      'id': doc.id,
                      ...data,
                    };
                  }
                  return null;
                })
                .where((vet) => vet != null)
                .cast<Map<String, dynamic>>()
                .toList();
          })
          .handleError((error) {
            print('Error in getVeterinariansStream: $error');
            return <Map<String, dynamic>>[];
          });
      
      _veterinariansStreamCache[cacheKey] = stream;
      return stream;
    } catch (e) {
      print('Error creating veterinarians stream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Create or get existing chat with veterinarian
  static Future<String> createChatWithVet({
    required String userId,
    required String veterinarianId,
    String? initialMessage,
  }) async {
    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection('veterinary_chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in existingChats.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(veterinarianId)) {
          return doc.id;
        }
      }

      // Get user and veterinarian names
      String userName = 'المستخدم';
      String vetName = 'الدكتور';
      
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? 'المستخدم';
        }
        
        final vetDoc = await _firestore.collection('veterinarians').doc(veterinarianId).get();
        if (vetDoc.exists) {
          vetName = vetDoc.data()?['name'] ?? 'الدكتور';
        }
      } catch (e) {
        print('Warning: Could not fetch user/vet names: $e');
      }

      // Create new chat
      final chatData = {
        'participants': [userId, veterinarianId],
        'participantNames': {
          userId: userName,
          veterinarianId: vetName,
        },
        'lastMessage': initialMessage ?? 'محادثة جديدة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': userId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          userId: 0,
          veterinarianId: 1,
        },
      };

      final chatRef = await _firestore
          .collection('veterinary_chats')
          .add(chatData);

      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendTextMessage(
          chatId: chatRef.id,
          senderId: userId,
          message: initialMessage,
        );
      }

      return chatRef.id;
    } catch (e) {
      throw Exception('فشل في إنشاء المحادثة: $e');
    }
  }

  // Send text message with optimized batch operations
  static Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      // First, get the chat document to know the participants
      final chatDoc = await _firestore.collection('veterinary_chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      // Find the other participant (receiver)
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.text.name,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': 'المستخدم',
      };

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Add message
      final messageRef = _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, messageData);

      // Prepare updated unread counts
      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      
      // Reset sender's unread count to 0
      updatedUnreadCounts[senderId] = 0;
      
      // Increment receiver's unread count
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      // Update chat metadata
      final chatRef = _firestore.collection('veterinary_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': updatedUnreadCounts,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الرسالة: $e');
    }
  }

  // Send image message with optimized upload
  static Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // First, get the chat document to know the participants
      final chatDoc = await _firestore.collection('veterinary_chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      // Find the other participant (receiver)
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      // Upload image with compression
      final imageUrl = await _uploadImage(imageFile, 'chat_images/$chatId');

      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'صورة',
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.image.name,
        'mediaUrl': imageUrl,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': 'المستخدم',
      };

      // Use batch write
      final batch = _firestore.batch();
      
      final messageRef = _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      batch.set(messageRef, messageData);

      // Prepare updated unread counts
      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      
      // Reset sender's unread count to 0
      updatedUnreadCounts[senderId] = 0;
      
      // Increment receiver's unread count
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final chatRef = _firestore.collection('veterinary_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': caption ?? '📷 صورة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': updatedUnreadCounts,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الصورة: $e');
    }
  }

  // Send video message
  static Future<void> sendVideoMessage({
    required String chatId,
    required String senderId,
    required File videoFile,
    String? caption,
  }) async {
    try {
      final videoUrl = await _uploadVideo(videoFile, 'chat_videos/$chatId');
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'فيديو',
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.video.name,
        'mediaUrl': videoUrl,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': 'المستخدم',
      };

      final batch = _firestore.batch();
      
      final messageRef = _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      batch.set(messageRef, messageData);

      final chatRef = _firestore.collection('veterinary_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': caption ?? '🎥 فيديو',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount.$senderId': 0,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الفيديو: $e');
    }
  }

  // Send file message
  static Future<void> sendFileMessage({
    required String chatId,
    required String senderId,
    required File file,
    String? fileName,
  }) async {
    try {
      final fileUrl = await _uploadFile(file, 'chat_files/$chatId', fileName);
      final fileSize = await file.length();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': fileName ?? 'ملف',
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.file.name,
        'mediaUrl': fileUrl,
        'fileName': fileName ?? file.path.split('/').last,
        'fileSize': fileSize,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': 'المستخدم',
      };

      final batch = _firestore.batch();
      
      final messageRef = _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      batch.set(messageRef, messageData);

      final chatRef = _firestore.collection('veterinary_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': fileName ?? '📎 ملف',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount.$senderId': 0,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الملف: $e');
    }
  }

  // Optimized image upload with compression
  static Future<String> _uploadImage(File imageFile, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');
      
      // Set metadata for better compression
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'compressed': 'true',
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // Optimized video upload
  static Future<String> _uploadVideo(File videoFile, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putFile(videoFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الفيديو: $e');
    }
  }

  // Optimized file upload
  static Future<String> _uploadFile(File file, String folder, String? fileName) async {
    try {
      final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$name');
      
      final metadata = SettableMetadata(
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  // Mark messages as read with batch operation - Optimized
  static Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final lastCall = _lastMarkAsReadCall[chatId] ?? DateTime.now().subtract(_markAsReadThrottle);

    if (now.difference(lastCall) < _markAsReadThrottle) {
      print('Throttling markMessagesAsRead for chatId: $chatId');
      return;
    }

    _lastMarkAsReadCall[chatId] = now;

    try {
      // Use a simpler approach to avoid composite index requirement
      // First get all messages, then filter in memory for better performance
      final messagesQuery = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .limit(100) // Limit to avoid excessive reads
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int updatedCount = 0;
        
        // Filter messages from other senders in memory to avoid composite index
        for (var doc in messagesQuery.docs) {
          final data = doc.data();
          final senderId = data['senderId'] as String?;
          
          // Only mark messages from other users as read
          if (senderId != null && senderId != userId) {
            batch.update(doc.reference, {'isRead': true});
            updatedCount++;
          }
        }

        // Only commit if there are messages to update
        if (updatedCount > 0) {
          // Reset unread count
          batch.update(
            _firestore.collection('veterinary_chats').doc(chatId),
            {'unreadCount.$userId': 0},
          );

          await batch.commit();
        }
      }
    } catch (e) {
      // Don't throw exception to avoid breaking the chat flow
      print('Warning: Failed to mark messages as read: $e');
    }
  }

  // Get unread message count stream
  static Stream<int> getUnreadMessageCountStream(String userId) {
    return _firestore
        .collection('veterinary_chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final unreadCount = Map<String, dynamic>.from(doc.data()['unreadCount'] ?? {});
        final count = unreadCount[userId];
        totalUnread += (count is int) ? count : (count as num?)?.toInt() ?? 0;
      }
      return totalUnread;
    });
  }

  // Delete chat with cleanup
  static Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messagesQuery = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Mark chat as inactive instead of deleting
      batch.update(
        _firestore.collection('veterinary_chats').doc(chatId),
        {'isActive': false, 'updatedAt': FieldValue.serverTimestamp()},
      );

      await batch.commit();

      // Clear cache
      _messageStreamsCache.remove(chatId);
    } catch (e) {
      throw Exception('فشل في حذف المحادثة: $e');
    }
  }

  // Pick image from gallery with optimization
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('فشل في اختيار الصورة: $e');
    }
  }

  // Take photo with camera with optimization
  static Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('فشل في التقاط الصورة: $e');
    }
  }

  // Get chat participants with caching
  static Future<List<UserModel>> getChatParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        return [];
      }

      final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);
      final users = <UserModel>[];

      for (final userId in participants) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      throw Exception('فشل في جلب المشاركين: $e');
    }
  }

  // Search veterinarians with optimization
  static Future<List<VeterinarianModel>> searchVeterinarians({
    String? name,
    String? specialization,
    String? location,
  }) async {
    try {
      Query query = _firestore
          .collection('veterinarians')
          .where('isActive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true);

      if (specialization != null && specialization.isNotEmpty) {
        query = query.where('specialization', isEqualTo: specialization);
      }

      final snapshot = await query.get();
      List<VeterinarianModel> veterinarians = snapshot.docs
          .map((doc) => VeterinarianModel.fromFirestore(doc))
          .toList();

      // Filter by name and location
      if (name != null && name.isNotEmpty) {
        veterinarians = veterinarians.where((vet) =>
            vet.name.toLowerCase().contains(name.toLowerCase()) ||
            vet.email.toLowerCase().contains(name.toLowerCase())).toList();
      }

      if (location != null && location.isNotEmpty) {
        veterinarians = veterinarians.where((vet) =>
            vet.address?.toLowerCase().contains(location.toLowerCase()) ?? false).toList();
      }

      return veterinarians;
    } catch (e) {
      throw Exception('فشل في البحث عن الأطباء: $e');
    }
  }

  // Get chat statistics with optimization
  static Future<Map<String, dynamic>> getChatStatistics(String userId) async {
    try {
      final userChats = await _firestore
          .collection('veterinary_chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalChats = userChats.docs.length;
      int activeChats = 0;
      int totalMessages = 0;
      int unreadMessages = 0;

      for (var chatDoc in userChats.docs) {
        final chatData = chatDoc.data();
        if (chatData['isActive'] == true) {
          activeChats++;
        }

        final unreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
        final count = unreadCount[userId];
        unreadMessages += (count is int) ? count : (count as num?)?.toInt() ?? 0;

        // Count messages in this chat
        final messagesQuery = await chatDoc.reference.collection('messages').get();
        totalMessages += messagesQuery.docs.length;
      }

      return {
        'totalChats': totalChats,
        'activeChats': activeChats,
        'totalMessages': totalMessages,
        'unreadMessages': unreadMessages,
      };
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المحادثة: $e');
    }
  }

  // ========== USER TO USER CHAT METHODS ==========

  // Get user's chats with other users stream
  static Stream<List<ChatModel>> getUserToUserChatsStream(String userId) {
    if (_chatStreamsCache.containsKey('user_$userId')) {
      return _chatStreamsCache['user_$userId']!;
    }
    
    final stream = _firestore
        .collection('user_chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .toList();
          return chats;
        });
    
    _chatStreamsCache['user_$userId'] = stream;
    return stream;
  }

  // Get chat messages stream for user-to-user chats
  static Stream<List<ChatMessage>> getUserChatMessagesStream(String chatId) {
    if (_messageStreamsCache.containsKey('user_$chatId')) {
      return _messageStreamsCache['user_$chatId']!;
    }
    
    final stream = _firestore
        .collection('user_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
    
    _messageStreamsCache['user_$chatId'] = stream;
    return stream;
  }

  // Create or get existing chat with another user
  static Future<String> createChatWithUser({
    required String userId,
    required String otherUserId,
    String? initialMessage,
    String? petReportId,
    String? petReportType,
  }) async {
    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection('user_chats')
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in existingChats.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Get user names
      String userName = 'المستخدم';
      String otherUserName = 'المستخدم';
      
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? 'المستخدم';
        }
        
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (otherUserDoc.exists) {
          otherUserName = otherUserDoc.data()?['name'] ?? otherUserDoc.data()?['username'] ?? 'المستخدم';
        }
      } catch (e) {
        print('Warning: Could not fetch user names: $e');
      }

      // Create new chat
      final chatData = {
        'participants': [userId, otherUserId],
        'participantNames': {
          userId: userName,
          otherUserId: otherUserName,
        },
        'lastMessage': initialMessage ?? 'محادثة جديدة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': userId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          userId: 0,
          otherUserId: 1,
        },
        if (petReportId != null) 'petReportId': petReportId,
        if (petReportType != null) 'petReportType': petReportType,
      };

      final chatRef = await _firestore
          .collection('user_chats')
          .add(chatData);

      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendUserTextMessage(
          chatId: chatRef.id,
          senderId: userId,
          message: initialMessage,
        );
      }

      return chatRef.id;
    } catch (e) {
      throw Exception('فشل في إنشاء المحادثة: $e');
    }
  }

  // Send text message in user-to-user chat
  static Future<void> sendUserTextMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      final chatDoc = await _firestore.collection('user_chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      // Find the other participant (receiver)
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      // Get sender name
      String senderName = 'المستخدم';
      try {
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          senderName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? 'المستخدم';
        }
      } catch (e) {
        print('Warning: Could not fetch sender name: $e');
      }
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.text.name,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': senderName,
      };

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('user_chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, messageData);

      // Prepare updated unread counts
      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      
      updatedUnreadCounts[senderId] = 0;
      
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final chatRef = _firestore.collection('user_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': updatedUnreadCounts,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الرسالة: $e');
    }
  }

  // Send image message in user-to-user chat
  static Future<void> sendUserImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final chatDoc = await _firestore.collection('user_chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      // Get sender name
      String senderName = 'المستخدم';
      try {
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          senderName = userDoc.data()?['name'] ?? userDoc.data()?['username'] ?? 'المستخدم';
        }
      } catch (e) {
        print('Warning: Could not fetch sender name: $e');
      }
      
      final imageUrl = await _uploadImage(imageFile, 'user_chat_images/$chatId');

      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'صورة',
        'timestamp': FieldValue.serverTimestamp(),
        'type': MessageType.image.name,
        'mediaUrl': imageUrl,
        'isRead': false,
        'messageId': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderName': senderName,
      };

      final batch = _firestore.batch();
      
      final messageRef = _firestore
          .collection('user_chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      
      batch.set(messageRef, messageData);

      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      
      updatedUnreadCounts[senderId] = 0;
      
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final chatRef = _firestore.collection('user_chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': caption ?? '📷 صورة',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': updatedUnreadCounts,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('فشل في إرسال الصورة: $e');
    }
  }

  // Mark messages as read for user-to-user chats
  static Future<void> markUserMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final lastCall = _lastMarkAsReadCall['user_$chatId'] ?? DateTime.now().subtract(_markAsReadThrottle);

    if (now.difference(lastCall) < _markAsReadThrottle) {
      print('Throttling markUserMessagesAsRead for chatId: $chatId');
      return;
    }

    _lastMarkAsReadCall['user_$chatId'] = now;

    try {
      final messagesQuery = await _firestore
          .collection('user_chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .limit(100)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        int updatedCount = 0;
        
        for (var doc in messagesQuery.docs) {
          final data = doc.data();
          final senderId = data['senderId'] as String?;
          
          if (senderId != null && senderId != userId) {
            batch.update(doc.reference, {'isRead': true});
            updatedCount++;
          }
        }

        if (updatedCount > 0) {
          batch.update(
            _firestore.collection('user_chats').doc(chatId),
            {'unreadCount.$userId': 0},
          );

          await batch.commit();
        }
      }
    } catch (e) {
      print('Warning: Failed to mark user messages as read: $e');
    }
  }

  // Get unread message count stream for user-to-user chats
  static Stream<int> getUserUnreadMessageCountStream(String userId) {
    return _firestore
        .collection('user_chats')
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final unreadCount = Map<String, dynamic>.from(doc.data()['unreadCount'] ?? {});
        final count = unreadCount[userId];
        totalUnread += (count is int) ? count : (count as num?)?.toInt() ?? 0;
      }
      return totalUnread;
    });
  }
} 