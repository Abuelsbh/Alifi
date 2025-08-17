import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../Models/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new chat
  Future<String> createChat({
    required String userId,
    required String veterinarianId,
    String? petId,
  }) async {
    try {
      DocumentReference docRef = await _firestore.collection('veterinary_chats').add({
        'userId': userId,
        'veterinarianId': veterinarianId,
        'petId': petId,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      throw Exception('Failed to create chat');
    }
  }

  // Get user's chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('veterinary_chats')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  // Get veterinarian's chats
  Stream<List<ChatModel>> getVeterinarianChats(String veterinarianId) {
    return _firestore
        .collection('veterinary_chats')
        .where('veterinarianId', isEqualTo: veterinarianId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  // Get chat messages
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('veterinary_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String message,
  }) async {
    try {
      // Add message to chat
      await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'message': message,
        'type': 'text',
        'mediaUrl': null,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chat's last message
      await _firestore.collection('veterinary_chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending text message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Send media message (image/video)
  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required File mediaFile,
    required MessageType mediaType,
  }) async {
    try {
      // Upload media to Firebase Storage
      String mediaUrl = await _uploadMedia(chatId, mediaFile, mediaType);

      // Add message to chat
      await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType,
        'message': mediaType == MessageType.image ? 'Image' : 'Video',
        'type': mediaType.toString().split('.').last,
        'mediaUrl': mediaUrl,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update chat's last message
      await _firestore.collection('veterinary_chats').doc(chatId).update({
        'lastMessage': mediaType == MessageType.image ? 'Image' : 'Video',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending media message: $e');
      throw Exception('Failed to send media message');
    }
  }

  // Upload media to Firebase Storage
  Future<String> _uploadMedia(String chatId, File mediaFile, MessageType mediaType) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';
      String folder = mediaType == MessageType.image ? 'images' : 'videos';
      Reference ref = _storage.ref().child('chat_media/$chatId/$folder/$fileName');
      
      UploadTask uploadTask = ref.putFile(mediaFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading media: $e');
      throw Exception('Failed to upload media');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      QuerySnapshot messages = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count for a chat
  Stream<int> getUnreadMessageCount(String chatId, String userId) {
    return _firestore
        .collection('veterinary_chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread messages for a user
  Stream<int> getTotalUnreadMessages(String userId) {
    return _firestore
        .collection('veterinary_chats')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((chatsSnapshot) async {
      int totalUnread = 0;
      for (DocumentSnapshot chatDoc in chatsSnapshot.docs) {
        QuerySnapshot messages = await _firestore
            .collection('veterinary_chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();
        totalUnread += messages.docs.length;
      }
      return totalUnread;
    });
  }

  // Close chat
  Future<void> closeChat(String chatId) async {
    try {
      await _firestore.collection('veterinary_chats').doc(chatId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error closing chat: $e');
      throw Exception('Failed to close chat');
    }
  }

  // Delete chat and all messages
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      QuerySnapshot messages = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete the chat document
      await _firestore.collection('veterinary_chats').doc(chatId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
      throw Exception('Failed to delete chat');
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('veterinary_chats')
          .doc(chatId)
          .get();
      
      if (doc.exists) {
        return ChatModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting chat by ID: $e');
      return null;
    }
  }

  // Check if chat exists between user and veterinarian
  Future<String?> getExistingChatId(String userId, String veterinarianId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('veterinary_chats')
          .where('userId', isEqualTo: userId)
          .where('veterinarianId', isEqualTo: veterinarianId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error checking existing chat: $e');
      return null;
    }
  }
} 