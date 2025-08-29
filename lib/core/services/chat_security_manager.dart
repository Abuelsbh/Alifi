import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../Models/chat_model.dart';

class ChatSecurityManager {
  static final ChatSecurityManager _instance = ChatSecurityManager._internal();
  factory ChatSecurityManager() => _instance;
  ChatSecurityManager._internal();

  // Security settings
  static const int maxMessageLength = 1000;
  static const int maxFileNameLength = 100;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedVideoExtensions = ['mp4', 'avi', 'mov', 'mkv'];
  static const List<String> allowedFileExtensions = ['pdf', 'doc', 'docx', 'txt', 'zip', 'rar'];
  
  // Rate limiting
  final Map<String, List<DateTime>> _messageRateLimit = {};
  final Map<String, List<DateTime>> _fileUploadRateLimit = {};
  static const int maxMessagesPerMinute = 10;
  static const int maxFileUploadsPerMinute = 3;

  /// Validate message content
  bool validateMessage(String message) {
    if (message.isEmpty) return false;
    if (message.length > maxMessageLength) return false;
    
    // Check for malicious content
    if (_containsMaliciousContent(message)) return false;
    
    return true;
  }

  /// Validate file before upload
  Future<bool> validateFile(File file, String fileType) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (!_isValidFileSize(fileSize, fileType)) return false;
      
      // Check file extension
      final fileName = file.path.split('/').last.toLowerCase();
      if (!_isValidFileExtension(fileName, fileType)) return false;
      
      // Check file name length
      if (fileName.length > maxFileNameLength) return false;
      
      // Check for malicious file names
      if (_containsMaliciousContent(fileName)) return false;
      
      return true;
    } catch (e) {
      debugPrint('Error validating file: $e');
      return false;
    }
  }

  /// Validate chat access
  bool validateChatAccess(String userId, List<String> participants) {
    return participants.contains(userId);
  }

  /// Check rate limiting for messages
  bool checkMessageRateLimit(String userId) {
    final now = DateTime.now();
    final userMessages = _messageRateLimit[userId] ?? [];
    
    // Remove old messages (older than 1 minute)
    userMessages.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    if (userMessages.length >= maxMessagesPerMinute) {
      return false;
    }
    
    userMessages.add(now);
    _messageRateLimit[userId] = userMessages;
    return true;
  }

  /// Check rate limiting for file uploads
  bool checkFileUploadRateLimit(String userId) {
    final now = DateTime.now();
    final userUploads = _fileUploadRateLimit[userId] ?? [];
    
    // Remove old uploads (older than 1 minute)
    userUploads.removeWhere((time) => now.difference(time).inMinutes >= 1);
    
    if (userUploads.length >= maxFileUploadsPerMinute) {
      return false;
    }
    
    userUploads.add(now);
    _fileUploadRateLimit[userId] = userUploads;
    return true;
  }

  /// Sanitize message content
  String sanitizeMessage(String message) {
    // Remove HTML tags
    message = _removeHtmlTags(message);
    
    // Remove script tags
    message = _removeScriptTags(message);
    
    // Limit length
    if (message.length > maxMessageLength) {
      message = message.substring(0, maxMessageLength);
    }
    
    return message.trim();
  }

  /// Sanitize file name
  String sanitizeFileName(String fileName) {
    // Remove path traversal attempts but keep the last dot for extension
    final parts = fileName.split('/');
    fileName = parts.last;
    
    // Remove special characters but keep the last dot
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1) {
      final namePart = fileName.substring(0, lastDotIndex);
      final extensionPart = fileName.substring(lastDotIndex);
      
      final sanitizedName = namePart.replaceAll(RegExp(r'[<>:"|?*]'), '_');
      fileName = sanitizedName + extensionPart;
    } else {
      fileName = fileName.replaceAll(RegExp(r'[<>:"|?*]'), '_');
    }
    
    // Limit length
    if (fileName.length > maxFileNameLength) {
      final lastDotIndex = fileName.lastIndexOf('.');
      if (lastDotIndex != -1) {
        final extension = fileName.substring(lastDotIndex);
        final nameWithoutExtension = fileName.substring(0, lastDotIndex);
        final maxNameLength = maxFileNameLength - extension.length;
        fileName = '${nameWithoutExtension.substring(0, maxNameLength)}.$extension';
      } else {
        fileName = fileName.substring(0, maxFileNameLength);
      }
    }
    
    return fileName.trim();
  }

  /// Generate secure file name
  String generateSecureFileName(String originalName, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = md5.convert(utf8.encode('$userId$timestamp$originalName')).toString();
    final extension = originalName.split('.').last.toLowerCase();
    
    return '${hash.substring(0, 8)}.$extension';
  }

  /// Validate image file
  Future<bool> validateImageFile(File file) async {
    try {
      // Check if it's actually an image
      final bytes = await file.readAsBytes();
      if (bytes.length < 4) return false;
      
      // Check for common image signatures
      if (_isValidImageSignature(bytes)) {
        return await validateFile(file, 'image');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error validating image file: $e');
      return false;
    }
  }

  /// Validate video file
  Future<bool> validateVideoFile(File file) async {
    try {
      // Check if it's actually a video
      final bytes = await file.readAsBytes();
      if (bytes.length < 8) return false;
      
      // Check for common video signatures
      if (_isValidVideoSignature(bytes)) {
        return await validateFile(file, 'video');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error validating video file: $e');
      return false;
    }
  }

  /// Check if user can send message
  bool canSendMessage(String userId, String chatId, List<String> participants) {
    // Check if user is participant
    if (!validateChatAccess(userId, participants)) return false;
    
    // Check rate limiting
    if (!checkMessageRateLimit(userId)) return false;
    
    return true;
  }

  /// Check if user can upload file
  bool canUploadFile(String userId, String chatId, List<String> participants) {
    // Check if user is participant
    if (!validateChatAccess(userId, participants)) return false;
    
    // Check rate limiting
    if (!checkFileUploadRateLimit(userId)) return false;
    
    return true;
  }

  /// Get security statistics
  Map<String, dynamic> getSecurityStats() {
    return {
      'totalRateLimitedUsers': _messageRateLimit.length,
      'totalFileUploadRateLimitedUsers': _fileUploadRateLimit.length,
      'maxMessageLength': maxMessageLength,
      'maxFileNameLength': maxFileNameLength,
      'maxMessagesPerMinute': maxMessagesPerMinute,
      'maxFileUploadsPerMinute': maxFileUploadsPerMinute,
    };
  }

  /// Clear rate limiting data
  void clearRateLimitData() {
    _messageRateLimit.clear();
    _fileUploadRateLimit.clear();
  }

  // Private helper methods

  bool _containsMaliciousContent(String content) {
    final lowerContent = content.toLowerCase();
    
    // Check for script injection attempts
    if (lowerContent.contains('<script') || 
        lowerContent.contains('javascript:') ||
        lowerContent.contains('data:text/html')) {
      return true;
    }
    
    // Check for SQL injection attempts
    if (lowerContent.contains('union select') ||
        lowerContent.contains('drop table') ||
        lowerContent.contains('delete from')) {
      return true;
    }
    
    // Check for path traversal attempts
    if (lowerContent.contains('../') ||
        lowerContent.contains('..\\') ||
        lowerContent.contains('/etc/') ||
        lowerContent.contains('c:\\windows')) {
      return true;
    }
    
    return false;
  }

  bool _isValidFileSize(int fileSize, String fileType) {
    switch (fileType.toLowerCase()) {
      case 'image':
        return fileSize <= 5 * 1024 * 1024; // 5MB
      case 'video':
        return fileSize <= 50 * 1024 * 1024; // 50MB
      case 'file':
        return fileSize <= 10 * 1024 * 1024; // 10MB
      default:
        return false;
    }
  }

  bool _isValidFileExtension(String fileName, String fileType) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (fileType.toLowerCase()) {
      case 'image':
        return allowedImageExtensions.contains(extension);
      case 'video':
        return allowedVideoExtensions.contains(extension);
      case 'file':
        return allowedFileExtensions.contains(extension);
      default:
        return false;
    }
  }

  String _removeHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String _removeScriptTags(String text) {
    return text.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
  }

  bool _isValidImageSignature(List<int> bytes) {
    // JPEG
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) return true;
    
    // PNG
    if (bytes.length >= 8 && 
        bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
        bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) return true;
    
    // GIF
    if (bytes.length >= 6 && 
        bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 &&
        bytes[3] == 0x38 && (bytes[4] == 0x37 || bytes[4] == 0x39) && bytes[5] == 0x61) return true;
    
    // WebP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;
    
    return false;
  }

  bool _isValidVideoSignature(List<int> bytes) {
    // MP4
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) return true;
    
    // AVI
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x41 && bytes[9] == 0x56 && bytes[10] == 0x49 && bytes[11] == 0x20) return true;
    
    // MOV
    if (bytes.length >= 8 &&
        bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) return true;
    
    return false;
  }
} 