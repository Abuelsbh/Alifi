import 'dart:io';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../../Models/chat_model.dart';
import '../../Models/user_model.dart';
import 'auth_service.dart';

class ChatService {
  static final FirebaseDatabase _database = FirebaseConfig.database;
  static final FirebaseStorage _storage = FirebaseConfig.storage;
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore; // Still needed for veterinarians and users
  static final ImagePicker _picker = ImagePicker();
  
  // Database references
  static DatabaseReference get _veterinaryChatsRef => _database.ref('veterinary_chats');
  static DatabaseReference get _veterinaryMessagesRef => _database.ref('veterinary_messages');
  static DatabaseReference get _userChatsRef => _database.ref('user_chats');
  static DatabaseReference get _userMessagesRef => _database.ref('user_messages');

  // Throttling for markMessagesAsRead
  static final Map<String, DateTime> _lastMarkAsReadCall = {};
  static const Duration _markAsReadThrottle = Duration(seconds: 3);

  // Clear cache when needed (kept for compatibility)
  static void clearCache() {
    // No-op for Realtime Database
  }

  static void clearVeterinariansCache() {
    // No-op for Realtime Database
  }

  static void clearAllCaches() {
    // No-op for Realtime Database
  }

  // Get user's chats stream for veterinary chats
  static Stream<List<ChatModel>> getUserChatsStream(String userId) {
    if (FirebaseConfig.isDemoMode) {
      return Stream.value(<ChatModel>[]);
    }
    
    return _veterinaryChatsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return <ChatModel>[];
      }
      
      final Map<dynamic, dynamic> chatsMap = event.snapshot.value as Map<dynamic, dynamic>;
      final List<ChatModel> chats = [];
      
      chatsMap.forEach((chatId, chatData) {
        try {
          final chatDataMap = Map<String, dynamic>.from(chatData as Map);
          // Filter by isActive and participants
          if (chatDataMap['isActive'] == true) {
            final participants = List<String>.from(chatDataMap['participants'] ?? []);
            if (participants.contains(userId)) {
              final chatModel = ChatModel.fromJson({
                'id': chatId.toString(),
                ...chatDataMap,
              });
              chats.add(chatModel);
            }
          }
        } catch (e) {
          print('Error parsing chat $chatId: $e');
        }
      });
      
      // Sort by lastMessageAt descending
      chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return chats;
    });
  }

  // Get chat messages stream for veterinary chats
  static Stream<List<ChatMessage>> getChatMessagesStream(String chatId) {
    if (FirebaseConfig.isDemoMode) {
      return Stream.value(<ChatMessage>[]);
    }
    
    return _veterinaryMessagesRef
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <ChatMessage>[];
          }
          
          final Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
          final List<ChatMessage> messages = [];
          
          messagesMap.forEach((messageId, messageData) {
            try {
              final message = ChatMessage.fromJson({
                'id': messageId.toString(),
                ...Map<String, dynamic>.from(messageData as Map),
              });
              messages.add(message);
            } catch (e) {
              print('Error parsing message $messageId: $e');
            }
          });
          
          // Sort by timestamp ascending (oldest first)
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // Get veterinarians stream - using users collection with userType filter
  static Stream<List<Map<String, dynamic>>> getVeterinariansStream() {
    if (FirebaseConfig.isDemoMode) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    
    try {
      // Get current user ID to exclude from the list
      final currentUserId = AuthService.userId;
      
      return _firestore
          .collection('users')
          .where('userType', isEqualTo: 'veterinarian')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data();
                  // Filter out deleted veterinarians and current user if they are a veterinarian
                  if (data['isDeleted'] != true && doc.id != currentUserId) {
                    return {
                      'id': doc.id,
                      ...data,
                      // Map username to name for compatibility
                      'name': data['name'] ?? data['username'] ?? 'طبيب بيطري',
                      // Map profileImageUrl to profilePhoto for compatibility
                      'profilePhoto': data['profileImageUrl'] ?? data['profilePhoto'],
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
      if (FirebaseConfig.isDemoMode) {
        throw Exception('Firebase is in demo mode');
      }

      // Check if chat already exists
      DataSnapshot snapshot;
      try {
        snapshot = await _veterinaryChatsRef.get();
      } catch (e) {
        // Handle web-specific Realtime Database errors
        if (e.toString().contains('MissingPluginException') || 
            e.toString().contains('No implementation found')) {
          throw Exception(
            'خطأ في إعداد قاعدة البيانات. يرجى:\n'
            '1. التأكد من تفعيل Realtime Database في Firebase Console\n'
            '2. الحصول على عنوان قاعدة البيانات من Firebase Console\n'
            '3. إعادة بناء التطبيق (flutter clean && flutter pub get)\n'
            '4. إعادة تشغيل التطبيق'
          );
        }
        rethrow;
      }

      if (snapshot.exists) {
        final chatsMap = snapshot.value as Map<dynamic, dynamic>?;
        if (chatsMap != null) {
          for (var entry in chatsMap.entries) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            if (chatData['isActive'] == true) {
              final participants = List<String>.from(chatData['participants'] ?? []);
              if (participants.contains(userId) && participants.contains(veterinarianId)) {
                return entry.key.toString();
              }
            }
          }
        }
      }

      // Get user and veterinarian names, photos, and types from users collection
      String userName = 'المستخدم';
      String vetName = 'الدكتور';
      String? userPhoto;
      String? vetPhoto;
      
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['username'] ?? userData?['name'] ?? 'المستخدم';
          userPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
        }
        
        // Get veterinarian from users collection
        final vetDoc = await _firestore.collection('users').doc(veterinarianId).get();
        if (vetDoc.exists) {
          final vetData = vetDoc.data();
          // Check if user is actually a veterinarian
          if (vetData?['userType'] == 'veterinarian') {
            vetName = vetData?['name'] ?? vetData?['username'] ?? 'الدكتور';
            vetPhoto = vetData?['profileImageUrl'] ?? vetData?['profilePhoto'];
          } else {
            throw Exception('المستخدم المحدد ليس طبيباً بيطرياً');
          }
        } else {
          throw Exception('الطبيب البيطري غير موجود');
        }
      } catch (e) {
        print('Warning: Could not fetch user/vet data: $e');
        rethrow;
      }

      // Create new chat
      final now = DateTime.now().millisecondsSinceEpoch;
      final chatId = _veterinaryChatsRef.push().key!;
      
      final chatData = {
        'participants': [userId, veterinarianId],
        'participantNames': {
          userId: userName,
          veterinarianId: vetName,
        },
        'participantPhotos': {
          userId: userPhoto,
          veterinarianId: vetPhoto,
        },
        'participantTypes': {
          userId: 'user',
          veterinarianId: 'veterinarian',
        },
        'lastMessage': initialMessage ?? 'محادثة جديدة',
        'lastMessageAt': now,
        'lastMessageSender': userId,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
        'unreadCount': {
          userId: 0,
          veterinarianId: 1,
        },
      };

      await _veterinaryChatsRef.child(chatId).set(chatData);

      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        try {
          await sendTextMessage(
            chatId: chatId,
            senderId: userId,
            message: initialMessage,
          );
          print('✅ Initial message sent successfully to veterinary chat: $chatId');
        } catch (e) {
          print('⚠️ Error sending initial message to veterinary chat: $e');
        }
      }

      return chatId;
    } catch (e) {
      throw Exception('فشل في إنشاء المحادثة: $e');
    }
  }

  // Send text message
  static Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String message,
  }) async {
    try {
      // Get chat data
      final chatSnapshot = await _veterinaryChatsRef.child(chatId).get();
      if (!chatSnapshot.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
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
      
      // Get sender name, photo, and type from users collection
      String senderName = 'المستخدم';
      String? senderPhoto;
      String senderType = 'user';
      try {
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Check if user is a veterinarian
          if (userData?['userType'] == 'veterinarian') {
            senderName = userData?['name'] ?? userData?['username'] ?? 'الدكتور';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'veterinarian';
          } else {
            senderName = userData?['username'] ?? userData?['name'] ?? 'المستخدم';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'user';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch sender data: $e');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': message,
        'timestamp': now,
        'type': MessageType.text.name,
        'isRead': false,
        'messageId': messageId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'senderType': senderType,
      };

      // Prepare updated unread counts
      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      updatedUnreadCounts[senderId] = 0;
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      // Update chat metadata and add message atomically
      final updates = <String, dynamic>{
        'veterinary_chats/$chatId/lastMessage': message,
        'veterinary_chats/$chatId/lastMessageAt': now,
        'veterinary_chats/$chatId/lastMessageSender': senderId,
        'veterinary_chats/$chatId/updatedAt': now,
        'veterinary_chats/$chatId/unreadCount': updatedUnreadCounts,
        'veterinary_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
    } catch (e) {
      throw Exception('فشل في إرسال الرسالة: $e');
    }
  }

  // Send image message
  static Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final chatSnapshot = await _veterinaryChatsRef.child(chatId).get();
      if (!chatSnapshot.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      String senderName = 'المستخدم';
      String? senderPhoto;
      String senderType = 'user';
      try {
        // Get sender data from users collection
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Check if user is a veterinarian
          if (userData?['userType'] == 'veterinarian') {
            senderName = userData?['name'] ?? userData?['username'] ?? 'الدكتور';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'veterinarian';
          } else {
            senderName = userData?['username'] ?? userData?['name'] ?? 'المستخدم';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'user';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch sender data: $e');
      }
      
      // Upload image
      final imageUrl = await _uploadImage(imageFile, 'chat_images/$chatId');

      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'صورة',
        'timestamp': now,
        'type': MessageType.image.name,
        'mediaUrl': imageUrl,
        'isRead': false,
        'messageId': messageId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'senderType': senderType,
      };

      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      updatedUnreadCounts[senderId] = 0;
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final updates = <String, dynamic>{
        'veterinary_chats/$chatId/lastMessage': caption ?? '📷 صورة',
        'veterinary_chats/$chatId/lastMessageAt': now,
        'veterinary_chats/$chatId/lastMessageSender': senderId,
        'veterinary_chats/$chatId/updatedAt': now,
        'veterinary_chats/$chatId/unreadCount': updatedUnreadCounts,
        'veterinary_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
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
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'فيديو',
        'timestamp': now,
        'type': MessageType.video.name,
        'mediaUrl': videoUrl,
        'isRead': false,
        'messageId': messageId,
        'senderName': 'المستخدم',
      };

      final chatSnapshot = await _veterinaryChatsRef.child(chatId).get();
      final chatData = chatSnapshot.exists 
          ? Map<String, dynamic>.from(chatSnapshot.value as Map)
          : <String, dynamic>{};
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});

      final updates = <String, dynamic>{
        'veterinary_chats/$chatId/lastMessage': caption ?? '🎥 فيديو',
        'veterinary_chats/$chatId/lastMessageAt': now,
        'veterinary_chats/$chatId/lastMessageSender': senderId,
        'veterinary_chats/$chatId/updatedAt': now,
        'veterinary_chats/$chatId/unreadCount/$senderId': 0,
        'veterinary_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
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
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': fileName ?? 'ملف',
        'timestamp': now,
        'type': MessageType.file.name,
        'mediaUrl': fileUrl,
        'fileName': fileName ?? file.path.split('/').last,
        'fileSize': fileSize,
        'isRead': false,
        'messageId': messageId,
        'senderName': 'المستخدم',
      };

      final chatSnapshot = await _veterinaryChatsRef.child(chatId).get();
      final chatData = chatSnapshot.exists 
          ? Map<String, dynamic>.from(chatSnapshot.value as Map)
          : <String, dynamic>{};

      final updates = <String, dynamic>{
        'veterinary_chats/$chatId/lastMessage': fileName ?? '📎 ملف',
        'veterinary_chats/$chatId/lastMessageAt': now,
        'veterinary_chats/$chatId/lastMessageSender': senderId,
        'veterinary_chats/$chatId/updatedAt': now,
        'veterinary_chats/$chatId/unreadCount/$senderId': 0,
        'veterinary_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
    } catch (e) {
      throw Exception('فشل في إرسال الملف: $e');
    }
  }

  // Upload image
  static Future<String> _uploadImage(File imageFile, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');
      
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

  // Upload video
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

  // Upload file
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

  // Mark messages as read
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
      final messagesSnapshot = await _veterinaryMessagesRef.child(chatId).get();

      if (messagesSnapshot.exists) {
        final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>?;
        if (messagesMap != null) {
          final updates = <String, dynamic>{};
          int updatedCount = 0;
          
          messagesMap.forEach((messageId, messageData) {
            final data = Map<String, dynamic>.from(messageData as Map);
            final senderId = data['senderId'] as String?;
            final isRead = data['isRead'] ?? false;
            
            // Only update unread messages from other users
            if (senderId != null && senderId != userId && isRead == false) {
              updates['veterinary_messages/$chatId/$messageId/isRead'] = true;
              updatedCount++;
            }
          });

          if (updatedCount > 0) {
            updates['veterinary_chats/$chatId/unreadCount/$userId'] = 0;
            await _database.ref().update(updates);
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to mark messages as read: $e');
    }
  }

  // Get unread message count stream
  static Stream<int> getUnreadMessageCountStream(String userId) {
    return _veterinaryChatsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0;
      }
          
      int totalUnread = 0;
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>;
          
      chatsMap.forEach((chatId, chatData) {
        try {
          final chatDataMap = Map<String, dynamic>.from(chatData as Map);
          if (chatDataMap['isActive'] == true) {
            final participants = List<String>.from(chatDataMap['participants'] ?? []);
            if (participants.contains(userId)) {
              final unreadCount = Map<String, dynamic>.from(chatDataMap['unreadCount'] ?? {});
              final count = unreadCount[userId];
              totalUnread += (count is int) ? count : (count as num?)?.toInt() ?? 0;
            }
          }
        } catch (e) {
          print('Error parsing unread count for chat $chatId: $e');
        }
      });
          
      return totalUnread;
    });
  }

  // Delete chat
  static Future<void> deleteChat(String chatId) async {
    try {
      final updates = <String, dynamic>{
        'veterinary_chats/$chatId/isActive': false,
        'veterinary_chats/$chatId/updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _database.ref().update(updates);
    } catch (e) {
      throw Exception('فشل في حذف المحادثة: $e');
    }
  }

  // Pick image from gallery
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

  // Take photo with camera
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

  // Get chat participants
  static Future<List<UserModel>> getChatParticipants(String chatId) async {
    try {
      final chatSnapshot = await _veterinaryChatsRef.child(chatId).get();
      if (!chatSnapshot.exists) {
        return [];
      }

      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final participants = List<String>.from(chatData['participants'] ?? []);
      final users = <UserModel>[];

      for (final userId in participants) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          users.add(UserModel.fromFirestore(userDoc));
        }
      }

      return users;
    } catch (e) {
      throw Exception('فشل في جلب المشاركين: $e');
    }
  }

  // Search veterinarians - still using Firestore
  static Future<List<VeterinarianModel>> searchVeterinarians({
    String? name,
    String? specialization,
    String? location,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('userType', isEqualTo: 'veterinarian')
          .where('isActive', isEqualTo: true);

      if (specialization != null && specialization.isNotEmpty) {
        query = query.where('specialization', isEqualTo: specialization);
      }

      final snapshot = await query.get();
      List<VeterinarianModel> veterinarians = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Create VeterinarianModel from users collection data
            return VeterinarianModel(
              id: doc.id,
              name: data['name'] ?? data['username'] ?? '',
              email: data['email'] ?? '',
              profilePhoto: data['profileImageUrl'] ?? data['profilePhoto'],
              specialization: data['specialization'] ?? '',
              phoneNumber: data['phone'] ?? data['phoneNumber'],
              address: data['address'],
              rating: ((data['rating'] ?? 0.0) as num).toDouble(),
              reviewCount: (data['reviewCount'] ?? data['totalRatings'] ?? 0) as int,
              isOnline: (data['isOnline'] ?? false) as bool,
              isAvailable: (data['isAvailable'] ?? true) as bool,
              isActive: (data['isActive'] ?? true) as bool,
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          })
          .toList();

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

  // Get chat statistics
  static Future<Map<String, dynamic>> getChatStatistics(String userId) async {
    try {
      final snapshot = await _veterinaryChatsRef.get();

      int totalChats = 0;
      int activeChats = 0;
      int totalMessages = 0;
      int unreadMessages = 0;

      if (snapshot.exists) {
        final chatsMap = snapshot.value as Map<dynamic, dynamic>;
        
        for (var entry in chatsMap.entries) {
          final chatData = Map<String, dynamic>.from(entry.value as Map);
          if (chatData['isActive'] == true) {
            final participants = List<String>.from(chatData['participants'] ?? []);
            
            if (participants.contains(userId)) {
              totalChats++;
              activeChats++;

              final unreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
              final count = unreadCount[userId];
              unreadMessages += (count is int) ? count : (count as num?)?.toInt() ?? 0;

              // Count messages in this chat
              final messagesSnapshot = await _veterinaryMessagesRef.child(entry.key.toString()).get();
              if (messagesSnapshot.exists) {
                final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>?;
                if (messagesMap != null) {
                  totalMessages += messagesMap.length;
                }
              }
            }
          }
        }
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
    if (FirebaseConfig.isDemoMode) {
      return Stream.value(<ChatModel>[]);
    }
    
    return _userChatsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return <ChatModel>[];
      }
          
      final Map<dynamic, dynamic> chatsMap = event.snapshot.value as Map<dynamic, dynamic>;
      final List<ChatModel> chats = [];
          
      chatsMap.forEach((chatId, chatData) {
        try {
          final chatDataMap = Map<String, dynamic>.from(chatData as Map);
          if (chatDataMap['isActive'] == true) {
            final participants = List<String>.from(chatDataMap['participants'] ?? []);
            if (participants.contains(userId)) {
              final chatModel = ChatModel.fromJson({
                'id': chatId.toString(),
                ...chatDataMap,
              });
              chats.add(chatModel);
            }
          }
        } catch (e) {
          print('Error parsing user chat $chatId: $e');
        }
      });
          
      chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return chats;
    });
  }

  // Get chat messages stream for user-to-user chats
  static Stream<List<ChatMessage>> getUserChatMessagesStream(String chatId) {
    if (FirebaseConfig.isDemoMode) {
      return Stream.value(<ChatMessage>[]);
    }
    
    return _userMessagesRef
        .child(chatId)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
          if (event.snapshot.value == null) {
            return <ChatMessage>[];
          }
          
          final Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
          final List<ChatMessage> messages = [];
          
          messagesMap.forEach((messageId, messageData) {
            try {
              final message = ChatMessage.fromJson({
                'id': messageId.toString(),
                ...Map<String, dynamic>.from(messageData as Map),
              });
              messages.add(message);
            } catch (e) {
              print('Error parsing user message $messageId: $e');
            }
          });
          
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
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
      if (FirebaseConfig.isDemoMode) {
        throw Exception('Firebase is in demo mode');
      }

      // Check if chat already exists
      DataSnapshot snapshot;
      try {
        snapshot = await _userChatsRef.get();
      } catch (e) {
        // Handle web-specific Realtime Database errors
        if (e.toString().contains('MissingPluginException') || 
            e.toString().contains('No implementation found')) {
          throw Exception(
            'خطأ في إعداد قاعدة البيانات. يرجى:\n'
            '1. التأكد من تفعيل Realtime Database في Firebase Console\n'
            '2. الحصول على عنوان قاعدة البيانات من Firebase Console\n'
            '3. إعادة بناء التطبيق (flutter clean && flutter pub get)\n'
            '4. إعادة تشغيل التطبيق'
          );
        }
        rethrow;
      }

      if (snapshot.exists) {
        final chatsMap = snapshot.value as Map<dynamic, dynamic>?;
        if (chatsMap != null) {
          for (var entry in chatsMap.entries) {
            final chatData = Map<String, dynamic>.from(entry.value as Map);
            if (chatData['isActive'] == true) {
              final participants = List<String>.from(chatData['participants'] ?? []);
              if (participants.contains(userId) && participants.contains(otherUserId)) {
                return entry.key.toString();
              }
            }
          }
        }
      }

      // Get user names, photos, and types
      String userName = 'المستخدم';
      String otherUserName = 'المستخدم';
      String? userPhoto;
      String? otherUserPhoto;
      String userType = 'user';
      String otherUserType = 'user';
      
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['name'] ?? userData?['username'] ?? 'المستخدم';
          userPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
        }
        
        // Get other user data from users collection
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (otherUserDoc.exists) {
          final otherUserData = otherUserDoc.data();
          // Check if user is a veterinarian
          if (otherUserData?['userType'] == 'veterinarian') {
            otherUserName = otherUserData?['name'] ?? otherUserData?['username'] ?? 'الدكتور';
            otherUserPhoto = otherUserData?['profileImageUrl'] ?? otherUserData?['profilePhoto'];
            otherUserType = 'veterinarian';
          } else {
            otherUserName = otherUserData?['name'] ?? otherUserData?['username'] ?? 'المستخدم';
            otherUserPhoto = otherUserData?['profileImageUrl'] ?? otherUserData?['profilePhoto'];
            otherUserType = 'user';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch user data: $e');
      }

      // Create new chat
      final now = DateTime.now().millisecondsSinceEpoch;
      final chatId = _userChatsRef.push().key!;
      
      final chatData = {
        'participants': [userId, otherUserId],
        'participantNames': {
          userId: userName,
          otherUserId: otherUserName,
        },
        'participantPhotos': {
          userId: userPhoto,
          otherUserId: otherUserPhoto,
        },
        'participantTypes': {
          userId: userType,
          otherUserId: otherUserType,
        },
        'lastMessage': initialMessage ?? 'محادثة جديدة',
        'lastMessageAt': now,
        'lastMessageSender': userId,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
        'unreadCount': {
          userId: 0,
          otherUserId: 1,
        },
        if (petReportId != null) 'petReportId': petReportId,
        if (petReportType != null) 'petReportType': petReportType,
      };

      await _userChatsRef.child(chatId).set(chatData);

      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        try {
          await Future.delayed(const Duration(milliseconds: 300));
          
          await sendUserTextMessage(
            chatId: chatId,
            senderId: userId,
            message: initialMessage,
          );
          print('✅ Initial message sent successfully to chat: $chatId');
        } catch (e) {
          print('⚠️ Error sending initial message: $e');
        }
      }

      return chatId;
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
      print('📤 Sending user-to-user message to chat: $chatId, from: $senderId');
      
      final chatSnapshot = await _userChatsRef.child(chatId).get();
      if (!chatSnapshot.exists) {
        print('❌ Chat document does not exist: $chatId');
        throw Exception('المحادثة غير موجودة');
      }
      
      print('✅ Chat document exists, proceeding with message send');
      
      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      String senderName = 'المستخدم';
      String? senderPhoto;
      String senderType = 'user';
      try {
        // Get sender data from users collection
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Check if user is a veterinarian
          if (userData?['userType'] == 'veterinarian') {
            senderName = userData?['name'] ?? userData?['username'] ?? 'الدكتور';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'veterinarian';
          } else {
            senderName = userData?['name'] ?? userData?['username'] ?? 'المستخدم';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'user';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch sender data: $e');
      }
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': message,
        'timestamp': now,
        'type': MessageType.text.name,
        'isRead': false,
        'messageId': messageId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'senderType': senderType,
      };

      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      updatedUnreadCounts[senderId] = 0;
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final updates = <String, dynamic>{
        'user_chats/$chatId/lastMessage': message,
        'user_chats/$chatId/lastMessageAt': now,
        'user_chats/$chatId/lastMessageSender': senderId,
        'user_chats/$chatId/updatedAt': now,
        'user_chats/$chatId/unreadCount': updatedUnreadCounts,
        'user_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
      print('✅ User-to-user message sent successfully to chat: $chatId, messageId: $messageId');
    } catch (e) {
      print('❌ Error sending user-to-user message: $e');
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
      final chatSnapshot = await _userChatsRef.child(chatId).get();
      if (!chatSnapshot.exists) {
        throw Exception('المحادثة غير موجودة');
      }
      
      final chatData = Map<String, dynamic>.from(chatSnapshot.value as Map);
      final participants = List<String>.from(chatData['participants'] ?? []);
      final currentUnreadCount = Map<String, dynamic>.from(chatData['unreadCount'] ?? {});
      
      String? receiverId;
      for (String participant in participants) {
        if (participant != senderId) {
          receiverId = participant;
          break;
        }
      }
      
      String senderName = 'المستخدم';
      String? senderPhoto;
      String senderType = 'user';
      try {
        // Get sender data from users collection
        final userDoc = await _firestore.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Check if user is a veterinarian
          if (userData?['userType'] == 'veterinarian') {
            senderName = userData?['name'] ?? userData?['username'] ?? 'الدكتور';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'veterinarian';
          } else {
            senderName = userData?['name'] ?? userData?['username'] ?? 'المستخدم';
            senderPhoto = userData?['profileImageUrl'] ?? userData?['profilePhoto'];
            senderType = 'user';
          }
        }
      } catch (e) {
        print('Warning: Could not fetch sender data: $e');
      }
      
      final imageUrl = await _uploadImage(imageFile, 'user_chat_images/$chatId');

      final now = DateTime.now().millisecondsSinceEpoch;
      final messageId = now.toString();
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'message': caption ?? 'صورة',
        'timestamp': now,
        'type': MessageType.image.name,
        'mediaUrl': imageUrl,
        'isRead': false,
        'messageId': messageId,
        'senderName': senderName,
        'senderPhoto': senderPhoto,
        'senderType': senderType,
      };

      Map<String, dynamic> updatedUnreadCounts = Map<String, dynamic>.from(currentUnreadCount);
      updatedUnreadCounts[senderId] = 0;
      if (receiverId != null) {
        updatedUnreadCounts[receiverId] = (updatedUnreadCounts[receiverId] ?? 0) + 1;
      }

      final updates = <String, dynamic>{
        'user_chats/$chatId/lastMessage': caption ?? '📷 صورة',
        'user_chats/$chatId/lastMessageAt': now,
        'user_chats/$chatId/lastMessageSender': senderId,
        'user_chats/$chatId/updatedAt': now,
        'user_chats/$chatId/unreadCount': updatedUnreadCounts,
        'user_messages/$chatId/$messageId': messageData,
      };

      await _database.ref().update(updates);
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
      final messagesSnapshot = await _userMessagesRef.child(chatId).get();

      if (messagesSnapshot.exists) {
        final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>?;
        if (messagesMap != null) {
          final updates = <String, dynamic>{};
          int updatedCount = 0;
          
          messagesMap.forEach((messageId, messageData) {
            final data = Map<String, dynamic>.from(messageData as Map);
            final senderId = data['senderId'] as String?;
            final isRead = data['isRead'] ?? false;
            
            // Only update unread messages from other users
            if (senderId != null && senderId != userId && isRead == false) {
              updates['user_messages/$chatId/$messageId/isRead'] = true;
              updatedCount++;
            }
          });

          if (updatedCount > 0) {
            updates['user_chats/$chatId/unreadCount/$userId'] = 0;
            await _database.ref().update(updates);
          }
        }
      }
    } catch (e) {
      print('Warning: Failed to mark user messages as read: $e');
    }
  }

  // Get unread message count stream for user-to-user chats
  static Stream<int> getUserUnreadMessageCountStream(String userId) {
    return _userChatsRef.onValue.map((event) {
      if (event.snapshot.value == null) {
        return 0;
      }
          
      int totalUnread = 0;
      final chatsMap = event.snapshot.value as Map<dynamic, dynamic>;
          
      chatsMap.forEach((chatId, chatData) {
        try {
          final chatDataMap = Map<String, dynamic>.from(chatData as Map);
          if (chatDataMap['isActive'] == true) {
            final participants = List<String>.from(chatDataMap['participants'] ?? []);
            if (participants.contains(userId)) {
              final unreadCount = Map<String, dynamic>.from(chatDataMap['unreadCount'] ?? {});
              final count = unreadCount[userId];
              totalUnread += (count is int) ? count : (count as num?)?.toInt() ?? 0;
            }
          }
        } catch (e) {
          print('Error parsing unread count for user chat $chatId: $e');
        }
      });
          
      return totalUnread;
    });
  }
}
