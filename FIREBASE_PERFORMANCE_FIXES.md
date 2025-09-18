# Firebase Performance Fixes

## Issues Fixed

### 1. Firestore Index Error
**Problem**: 
```
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

**Root Cause**: 
The `markMessagesAsRead` function was using a compound query with multiple filters:
```dart
.where('senderId', isNotEqualTo: userId)
.where('isRead', isEqualTo: false)
```

**Solution**:
- Simplified the query to avoid composite index requirement
- Filter messages in memory instead of using compound Firestore queries
- Only query by `isRead == false` and filter `senderId` in Dart code

### 2. Frame Skipping Performance Issues
**Problem**: 
```
Skipped 34 frames! The application may be doing too much work on its main thread.
```

**Root Cause**:
- `markMessagesAsRead` was being called on every real-time message update
- Multiple chat screens were creating excessive Firestore operations
- No throttling mechanism for read status updates

**Solutions**:
1. **Throttling**: Added 3-second throttle to `markMessagesAsRead` calls
2. **Lifecycle Management**: Only mark messages as read when app is in foreground
3. **Reduced Calls**: Removed `markMessagesAsRead` from real-time listeners
4. **Error Handling**: Changed exceptions to warnings to prevent chat flow interruption

## Code Changes

### 1. ChatService Optimizations
```dart
// Added throttling
static final Map<String, DateTime> _lastMarkAsReadCall = {};
static const Duration _markAsReadThrottle = Duration(seconds: 3);

// Optimized markMessagesAsRead
static Future<void> markMessagesAsRead({
  required String chatId,
  required String userId,
}) async {
  // Throttling check
  final now = DateTime.now();
  final lastCall = _lastMarkAsReadCall[chatId] ?? DateTime.now().subtract(_markAsReadThrottle);
  
  if (now.difference(lastCall) < _markAsReadThrottle) {
    return; // Skip if called too recently
  }
  
  // Simplified query (no composite index needed)
  final messagesQuery = await _firestore
      .collection('veterinary_chats')
      .doc(chatId)
      .collection('messages')
      .where('isRead', isEqualTo: false)
      .limit(100)
      .get();
      
  // Filter in memory instead of Firestore query
  for (var doc in messagesQuery.docs) {
    final senderId = doc.data()['senderId'] as String?;
    if (senderId != null && senderId != userId) {
      batch.update(doc.reference, {'isRead': true});
    }
  }
}
```

### 2. Chat Screen Optimizations
```dart
class _RealTimeChatScreenState extends State<RealTimeChatScreen>
with TickerProviderStateMixin, WidgetsBindingObserver {
  
  bool _isInForeground = true;
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isInForeground = state == AppLifecycleState.resumed;
    
    // Only mark as read when app comes to foreground
    if (_isInForeground) {
      ChatService.markMessagesAsRead(chatId: widget.chatId, userId: userId);
    }
  }
  
  void _loadMessages() {
    // Mark as read ONCE when entering chat
    ChatService.markMessagesAsRead(chatId: widget.chatId, userId: userId);
    
    // Listen to messages WITHOUT marking as read on every update
    _messagesSubscription = ChatService.getChatMessagesStream(widget.chatId).listen((messages) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      // No markMessagesAsRead here - prevents excessive calls
    });
  }
}
```

## Firebase Console Actions Required

### Create Composite Index (Optional)
If you still want to use the original compound query, create this index:
1. Open: https://console.firebase.google.com/project/bookingplayground-3f74b/firestore/indexes
2. Create composite index for collection group: `messages`
3. Fields:
   - `isRead` (Ascending)
   - `senderId` (Ascending)  
   - `__name__` (Ascending)

**Note**: The current optimized solution doesn't require this index.

## Performance Improvements

1. **Reduced Firestore Reads**: Throttling prevents excessive queries
2. **Better Memory Usage**: In-memory filtering vs complex Firestore queries
3. **Smoother UI**: No more frame skipping from excessive operations
4. **Battery Efficiency**: Fewer network calls and database operations

## Monitoring

To monitor performance:
```dart
// Added logging for throttling
if (now.difference(lastCall) < _markAsReadThrottle) {
  print('Throttling markMessagesAsRead for chatId: $chatId');
  return;
}
```

## Future Optimizations

1. Consider using Firestore offline persistence
2. Implement message pagination for very long conversations
3. Add read receipts with timestamps for better UX
4. Consider WebSocket connections for real-time features 