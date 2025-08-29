import 'package:flutter_test/flutter_test.dart';
import 'package:alifi/Models/chat_model.dart';
import 'package:alifi/core/services/chat_service.dart';
import 'package:alifi/core/services/chat_performance_manager.dart';
import 'package:alifi/core/services/chat_security_manager.dart';

void main() {
  group('Chat System Tests', () {
    test('ChatModel creation and serialization', () {
      final chat = ChatModel(
        id: 'test_chat_id',
        participants: ['user1', 'user2'],
        participantNames: {'user1': 'User 1', 'user2': 'User 2'},
        lastMessage: 'Hello World',
        lastMessageAt: DateTime.now(),
        lastMessageSender: 'user1',
        unreadCount: {'user1': 0, 'user2': 1},
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(chat.id, 'test_chat_id');
      expect(chat.participants.length, 2);
      expect(chat.lastMessage, 'Hello World');
      expect(chat.isActive, true);
    });

    test('ChatMessage creation and type handling', () {
      final message = ChatMessage(
        id: 'test_message_id',
        chatId: 'test_chat_id',
        senderId: 'user1',
        senderName: 'User 1',
        message: 'Test message',
        type: MessageType.text,
        isRead: false,
        timestamp: DateTime.now(),
        messageId: 'msg_123',
      );

      expect(message.id, 'test_message_id');
      expect(message.type, MessageType.text);
      expect(message.isRead, false);
      expect(message.message, 'Test message');
    });

    test('MessageType enum values', () {
      expect(MessageType.values.length, 6);
      expect(MessageType.text, MessageType.text);
      expect(MessageType.image, MessageType.image);
      expect(MessageType.video, MessageType.video);
      expect(MessageType.audio, MessageType.audio);
      expect(MessageType.file, MessageType.file);
      expect(MessageType.location, MessageType.location);
    });

    test('ChatSecurityManager message validation', () {
      final securityManager = ChatSecurityManager();
      
      // Valid message
      expect(securityManager.validateMessage('Hello World'), true);
      
      // Empty message
      expect(securityManager.validateMessage(''), false);
      
      // Too long message
      final longMessage = 'A' * 1001;
      expect(securityManager.validateMessage(longMessage), false);
      
      // Malicious content
      expect(securityManager.validateMessage('<script>alert("xss")</script>'), false);
    });

    test('ChatSecurityManager rate limiting', () {
      final securityManager = ChatSecurityManager();
      const userId = 'test_user';
      
      // First message should be allowed
      expect(securityManager.checkMessageRateLimit(userId), true);
      
      // Multiple messages should be allowed within limit
      for (int i = 0; i < 9; i++) {
        expect(securityManager.checkMessageRateLimit(userId), true);
      }
      
      // 11th message should be blocked
      expect(securityManager.checkMessageRateLimit(userId), false);
    });

    test('ChatSecurityManager file name sanitization', () {
      final securityManager = ChatSecurityManager();
      
      // Normal file name
      expect(securityManager.sanitizeFileName('document.pdf'), 'document.pdf');
      
      // File name with path traversal
      expect(securityManager.sanitizeFileName('../malicious.pdf'), 'malicious.pdf');
      
      // File name with special characters
      expect(securityManager.sanitizeFileName('file<>:"|?*.pdf'), 'file_______.pdf');
    });

    test('ChatPerformanceManager cache operations', () {
      final performanceManager = ChatPerformanceManager();
      const chatId = 'test_chat_id';
      
      final messages = [
        ChatMessage(
          id: 'msg1',
          chatId: chatId,
          senderId: 'user1',
          senderName: 'User 1',
          message: 'Message 1',
          type: MessageType.text,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'msg2',
          chatId: chatId,
          senderId: 'user2',
          senderName: 'User 2',
          message: 'Message 2',
          type: MessageType.text,
          timestamp: DateTime.now(),
        ),
      ];
      
      // Cache messages
      performanceManager.cacheMessages(chatId, messages);
      
      // Retrieve cached messages
      final cachedMessages = performanceManager.getCachedMessages(chatId);
      expect(cachedMessages, isNotNull);
      expect(cachedMessages!.length, 2);
      expect(cachedMessages[0].message, 'Message 1');
      expect(cachedMessages[1].message, 'Message 2');
    });

    test('ChatPerformanceManager performance monitoring', () {
      final performanceManager = ChatPerformanceManager();
      
      // Record performance metrics
      performanceManager.recordMessageLoadTime(const Duration(milliseconds: 100));
      performanceManager.recordMessageLoadTime(const Duration(milliseconds: 150));
      performanceManager.recordMessageLoadTime(const Duration(milliseconds: 200));
      
      // Get average load time
      final avgLoadTime = performanceManager.getAverageMessageLoadTime();
      expect(avgLoadTime.inMilliseconds, 150);
    });

    test('ChatPerformanceManager file size formatting', () {
      final performanceManager = ChatPerformanceManager();
      
      expect(performanceManager.getFileSizeString(1024), '1.0 KB');
      expect(performanceManager.getFileSizeString(1024 * 1024), '1.0 MB');
      expect(performanceManager.getFileSizeString(1024 * 1024 * 1024), '1.0 GB');
      expect(performanceManager.getFileSizeString(500), '500 B');
    });

    test('ChatSecurityManager secure file name generation', () {
      final securityManager = ChatSecurityManager();
      const userId = 'test_user';
      const originalName = 'document.pdf';
      
      final secureName1 = securityManager.generateSecureFileName(originalName, userId);
      final secureName2 = securityManager.generateSecureFileName(originalName, userId);
      
      // Names should be different (due to timestamp)
      expect(secureName1, isNot(equals(secureName2)));
      
      // Names should end with correct extension
      expect(secureName1.endsWith('.pdf'), true);
      expect(secureName2.endsWith('.pdf'), true);
      
      // Names should be 8 characters + extension
      expect(secureName1.split('.').first.length, 8);
    });

    test('ChatSecurityManager access validation', () {
      final securityManager = ChatSecurityManager();
      const userId = 'user1';
      const participants = ['user1', 'user2'];
      
      // Valid access
      expect(securityManager.validateChatAccess(userId, participants), true);
      
      // Invalid access
      expect(securityManager.validateChatAccess('user3', participants), false);
    });

    test('ChatPerformanceManager statistics', () {
      final performanceManager = ChatPerformanceManager();
      
      // Get performance stats
      final stats = performanceManager.getPerformanceStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cachedChats'), true);
      expect(stats.containsKey('activeSubscriptions'), true);
      expect(stats.containsKey('memoryUsage'), true);
      expect(stats.containsKey('averageMessageLoadTime'), true);
    });

    test('ChatSecurityManager statistics', () {
      final securityManager = ChatSecurityManager();
      
      // Get security stats
      final stats = securityManager.getSecurityStats();
      
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalRateLimitedUsers'), true);
      expect(stats.containsKey('maxMessageLength'), true);
      expect(stats.containsKey('maxMessagesPerMinute'), true);
    });

    test('MessageType parsing', () {
      // Test MessageType parsing from string
      expect(MessageType.text.name, 'text');
      expect(MessageType.image.name, 'image');
      expect(MessageType.video.name, 'video');
      expect(MessageType.audio.name, 'audio');
      expect(MessageType.file.name, 'file');
      expect(MessageType.location.name, 'location');
    });

    test('ChatModel copyWith functionality', () {
      final originalChat = ChatModel(
        id: 'original_id',
        participants: ['user1'],
        participantNames: {'user1': 'User 1'},
        lastMessage: 'Original message',
        lastMessageAt: DateTime.now(),
        lastMessageSender: 'user1',
        unreadCount: {'user1': 0},
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final updatedChat = originalChat.copyWith(
        lastMessage: 'Updated message',
        isActive: false,
      );
      
      expect(updatedChat.id, originalChat.id);
      expect(updatedChat.lastMessage, 'Updated message');
      expect(updatedChat.isActive, false);
      expect(updatedChat.participants, originalChat.participants);
    });

    test('ChatMessage copyWith functionality', () {
      final originalMessage = ChatMessage(
        id: 'original_msg_id',
        chatId: 'chat_id',
        senderId: 'user1',
        senderName: 'User 1',
        message: 'Original message',
        type: MessageType.text,
        isRead: false,
        timestamp: DateTime.now(),
      );
      
      final updatedMessage = originalMessage.copyWith(
        message: 'Updated message',
        isRead: true,
      );
      
      expect(updatedMessage.id, originalMessage.id);
      expect(updatedMessage.message, 'Updated message');
      expect(updatedMessage.isRead, true);
      expect(updatedMessage.type, originalMessage.type);
    });
  });
} 