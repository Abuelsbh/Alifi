import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../Models/chat_model.dart';

class ChatPerformanceManager {
  static final ChatPerformanceManager _instance = ChatPerformanceManager._internal();
  factory ChatPerformanceManager() => _instance;
  ChatPerformanceManager._internal();

  // Cache management
  final Map<String, List<ChatMessage>> _messageCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  
  // Performance settings
  static const int maxCachedMessages = 100;
  static const Duration cacheExpiryTime = Duration(minutes: 30);
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Memory management
  static const int maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  int _currentMemoryUsage = 0;

  // Performance monitoring
  final List<Duration> _messageLoadTimes = [];
  final List<Duration> _imageLoadTimes = [];

  /// Initialize performance manager
  void initialize() {
    _startCacheCleanupTimer();
    _startMemoryMonitoring();
  }

  /// Clean up resources
  void dispose() {
    _clearAllCaches();
    _cancelAllSubscriptions();
  }

  /// Cache messages for a chat
  void cacheMessages(String chatId, List<ChatMessage> messages) {
    if (messages.length > maxCachedMessages) {
      messages = messages.take(maxCachedMessages).toList();
    }
    
    _messageCache[chatId] = messages;
    _cacheTimestamps[chatId] = DateTime.now();
    
    _updateMemoryUsage();
  }

  /// Get cached messages for a chat
  List<ChatMessage>? getCachedMessages(String chatId) {
    final timestamp = _cacheTimestamps[chatId];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > cacheExpiryTime) {
      _messageCache.remove(chatId);
      _cacheTimestamps.remove(chatId);
      return null;
    }
    
    return _messageCache[chatId];
  }

  /// Add subscription for cleanup
  void addSubscription(String chatId, StreamSubscription subscription) {
    _activeSubscriptions[chatId] = subscription;
  }

  /// Remove subscription
  void removeSubscription(String chatId) {
    final subscription = _activeSubscriptions.remove(chatId);
    subscription?.cancel();
  }

  /// Optimize image before upload
  Future<File?> optimizeImage(File imageFile) async {
    try {
      final fileSize = await imageFile.length();
      
      // If image is already small enough, return as is
      if (fileSize <= maxImageSize) {
        return imageFile;
      }

      // Compress image
      final compressedImage = await _compressImage(imageFile);
      return compressedImage;
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Validate file before upload
  Future<bool> validateFile(File file, String fileType) async {
    try {
      final fileSize = await file.length();
      
      switch (fileType.toLowerCase()) {
        case 'image':
          return fileSize <= maxImageSize;
        case 'video':
          return fileSize <= maxVideoSize;
        case 'file':
          return fileSize <= maxFileSize;
        default:
          return false;
      }
    } catch (e) {
      debugPrint('Error validating file: $e');
      return false;
    }
  }

  /// Get file size in human readable format
  String getFileSizeString(int bytes) {
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

  /// Monitor message load performance
  void recordMessageLoadTime(Duration duration) {
    _messageLoadTimes.add(duration);
    
    // Keep only last 100 measurements
    if (_messageLoadTimes.length > 100) {
      _messageLoadTimes.removeAt(0);
    }
  }

  /// Monitor image load performance
  void recordImageLoadTime(Duration duration) {
    _imageLoadTimes.add(duration);
    
    // Keep only last 100 measurements
    if (_imageLoadTimes.length > 100) {
      _imageLoadTimes.removeAt(0);
    }
  }

  /// Get average message load time
  Duration getAverageMessageLoadTime() {
    if (_messageLoadTimes.isEmpty) return Duration.zero;
    
    final totalMicroseconds = _messageLoadTimes
        .map((duration) => duration.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return Duration(microseconds: totalMicroseconds ~/ _messageLoadTimes.length);
  }

  /// Get average image load time
  Duration getAverageImageLoadTime() {
    if (_imageLoadTimes.isEmpty) return Duration.zero;
    
    final totalMicroseconds = _imageLoadTimes
        .map((duration) => duration.inMicroseconds)
        .reduce((a, b) => a + b);
    
    return Duration(microseconds: totalMicroseconds ~/ _imageLoadTimes.length);
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'cachedChats': _messageCache.length,
      'activeSubscriptions': _activeSubscriptions.length,
      'memoryUsage': getFileSizeString(_currentMemoryUsage),
      'averageMessageLoadTime': getAverageMessageLoadTime().inMilliseconds,
      'averageImageLoadTime': getAverageImageLoadTime().inMilliseconds,
      'totalMessageLoads': _messageLoadTimes.length,
      'totalImageLoads': _imageLoadTimes.length,
    };
  }

  /// Clear all caches
  void _clearAllCaches() {
    _messageCache.clear();
    _cacheTimestamps.clear();
    _currentMemoryUsage = 0;
  }

  /// Cancel all active subscriptions
  void _cancelAllSubscriptions() {
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();
  }

  /// Start cache cleanup timer
  void _startCacheCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupExpiredCache();
    });
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > cacheExpiryTime) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _messageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    _updateMemoryUsage();
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkMemoryUsage();
    });
  }

  /// Check memory usage and cleanup if necessary
  void _checkMemoryUsage() {
    if (_currentMemoryUsage > maxMemoryUsage) {
      _cleanupOldestCache();
    }
  }

  /// Clean up oldest cache entries
  void _cleanupOldestCache() {
    if (_cacheTimestamps.isEmpty) return;
    
    // Sort by timestamp (oldest first)
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest 25% of cache
    final removeCount = (sortedEntries.length * 0.25).ceil();
    
    for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
      final key = sortedEntries[i].key;
      _messageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    _updateMemoryUsage();
  }

  /// Update memory usage calculation
  void _updateMemoryUsage() {
    int totalSize = 0;
    
    for (final messages in _messageCache.values) {
      for (final message in messages) {
        totalSize += message.message.length * 2; // UTF-16 characters
        if (message.mediaUrl != null) {
          totalSize += message.mediaUrl!.length * 2;
        }
        if (message.fileName != null) {
          totalSize += message.fileName!.length * 2;
        }
      }
    }
    
    _currentMemoryUsage = totalSize;
  }

  /// Compress image
  Future<File?> _compressImage(File imageFile) async {
    try {
      // Use image_picker to compress
      final compressedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (compressedImage != null) {
        return File(compressedImage.path);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls.take(10)) { // Limit to 10 images
      try {
        // Preload image using network image
        final image = NetworkImage(url);
        await image.resolve(const ImageConfiguration());
      } catch (e) {
        debugPrint('Error preloading image $url: $e');
      }
    }
  }

  /// Debounce function calls
  Timer? _debounceTimer;
  void debounce(VoidCallback callback, Duration duration) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  DateTime? _lastThrottleTime;
  bool throttle(VoidCallback callback, Duration duration) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
      return true;
    }
    return false;
  }
} 