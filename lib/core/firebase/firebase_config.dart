import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import '../services/chat_service.dart';

class FirebaseConfig {
  static bool _isInitialized = false;
  static bool _isDemoMode = false;

  // Firebase instances
  static FirebaseAuth get auth {
    if (_isDemoMode) {
      throw Exception('Firebase is running in demo mode. Please configure valid API keys.');
    }
    return FirebaseAuth.instance;
  }
  
  static FirebaseFirestore get firestore {
    if (_isDemoMode) {
      throw Exception('Firebase is running in demo mode. Please configure valid API keys.');
    }
    return FirebaseFirestore.instance;
  }
  
  static FirebaseDatabase? _databaseInstance;
  
  static FirebaseDatabase get database {
    if (_isDemoMode) {
      throw Exception('Firebase is running in demo mode. Please configure valid API keys.');
    }
    
    // Cache the instance to avoid recreating it
    if (_databaseInstance != null) {
      return _databaseInstance!;
    }
    
    // For web, we need to specify the database URL
    if (kIsWeb) {
      try {
        // Try the new format first (default region)
        const databaseURL = 'https://bookingplayground-3f74b-default-rtdb.firebaseio.com';
        _databaseInstance = FirebaseDatabase.instanceFor(
          app: Firebase.app(), 
          databaseURL: databaseURL
        );
        return _databaseInstance!;
      } catch (e) {
        print('⚠️ Warning: Could not initialize Realtime Database with URL. Error: $e');
        print('💡 Please check your Firebase Console for the correct database URL.');
        print('💡 The URL should be in format: https://PROJECT_ID-default-rtdb.firebaseio.com');
        print('💡 Or: https://PROJECT_ID-default-rtdb.REGION.firebasedatabase.app');
        // Try without explicit URL (might work if configured in Firebase Console)
        try {
          _databaseInstance = FirebaseDatabase.instance;
          return _databaseInstance!;
        } catch (e2) {
          print('❌ Failed to initialize Realtime Database: $e2');
          rethrow;
        }
      }
    }
    
    _databaseInstance = FirebaseDatabase.instance;
    return _databaseInstance!;
  }
  
  static FirebaseStorage get storage {
    if (_isDemoMode) {
      throw Exception('Firebase is running in demo mode. Please configure valid API keys.');
    }
    return FirebaseStorage.instance;
  }
  
  static FirebaseMessaging get messaging {
    if (_isDemoMode) {
      throw Exception('Firebase is running in demo mode. Please configure valid API keys.');
    }
    return FirebaseMessaging.instance;
  }

  static bool get isInitialized => _isInitialized;
  static bool get isDemoMode => _isDemoMode;

  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (_isInitialized) {
        return;
      }

      // Try to initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Test if Firebase is properly initialized
      FirebaseAuth.instance;
      
      _isInitialized = true;
      _isDemoMode = false;
      
      print('✅ Firebase initialized successfully');
      
      // Clear chat cache when Firebase is initialized
      try {
        ChatService.clearAllCaches();
        print('✅ Chat cache cleared after Firebase initialization');
      } catch (e) {
        print('⚠️ Could not clear chat cache: $e');
      }
      
      // Initialize App Check for security
      await _initializeAppCheck();
      
      // Request notification permissions
      await _requestNotificationPermissions();
      
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      print('🔄 Running in demo mode without Firebase');
      
      _isInitialized = false;
      _isDemoMode = true;
      
      // Don't throw error, just run in demo mode
    }
  }

  static Future<void> _initializeAppCheck() async {
    try {
      if (_isDemoMode) return;
      
      // Skip App Check initialization to avoid API errors
      // App Check can be enabled later in Firebase Console
      print('⚠️ App Check skipped - can be enabled in Firebase Console');
      return;
      
      // Uncomment below when App Check API is enabled in Firebase Console:
      // await FirebaseAppCheck.instance.activate(
      //   androidProvider: AndroidProvider.debug,
      //   appleProvider: AppleProvider.debug,
      // );
      // print('✅ App Check initialized');
    } catch (e) {
      print('⚠️ App Check setup failed (non-critical): $e');
    }
  }

  static Future<void> _requestNotificationPermissions() async {
    try {
      if (_isDemoMode) return;
      
      final messaging = FirebaseMessaging.instance;
      
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      String? token = await messaging.getToken();
      print('FCM Token: $token');
    } catch (e) {
      print('Failed to setup notifications: $e');
    }
  }

  // Demo mode collections - return empty data
  static Map<String, dynamic> get demoCollectionReference => {};

  // Firestore collections (with demo mode fallback)
  static dynamic get usersCollection {
    if (_isDemoMode) {
      return DemoCollection('users');
    }
    return firestore.collection('users');
  }
  
  static dynamic get lostPetsCollection {
    if (_isDemoMode) {
      return DemoCollection('lost_pets');
    }
    return firestore.collection('lost_pets');
  }
  
  static dynamic get foundPetsCollection {
    if (_isDemoMode) {
      return DemoCollection('found_pets');
    }
    return firestore.collection('found_pets');
  }
  
  static dynamic get veterinaryChatsCollection {
    if (_isDemoMode) {
      return DemoCollection('veterinary_chats');
    }
    return firestore.collection('veterinary_chats');
  }
  
  static dynamic get veterinariansCollection {
    if (_isDemoMode) {
      return DemoCollection('veterinarians');
    }
    return firestore.collection('veterinarians');
  }
}

// Demo collection for when Firebase is not available
class DemoCollection {
  final String collectionName;
  
  DemoCollection(this.collectionName);
  
  // Return empty stream for demo mode
  Stream<List<Map<String, dynamic>>> snapshots() {
    return Stream.value([]);
  }
  
  Future<void> add(Map<String, dynamic> data) async {
    print('Demo mode: Would add to $collectionName: $data');
  }
  
  DemoDocument doc(String id) {
    return DemoDocument(id);
  }
  
  DemoQuery where(String field, {dynamic isEqualTo, dynamic arrayContains}) {
    return DemoQuery();
  }
}

class DemoDocument {
  final String id;
  
  DemoDocument(this.id);
  
  Future<void> set(Map<String, dynamic> data) async {
    print('Demo mode: Would set document $id: $data');
  }
  
  Future<void> update(Map<String, dynamic> data) async {
    print('Demo mode: Would update document $id: $data');
  }
  
  Future<DemoDocumentSnapshot> get() async {
    return DemoDocumentSnapshot(false);
  }
  
  DemoCollection collection(String path) {
    return DemoCollection(path);
  }
}

class DemoQuery {
  DemoQuery where(String field, {dynamic isEqualTo, dynamic arrayContains, dynamic isNotEqualTo}) {
    return this;
  }
  
  DemoQuery orderBy(String field, {bool descending = false}) {
    return this;
  }
  
  DemoQuery limit(int limit) {
    return this;
  }
  
  Stream<DemoQuerySnapshot> snapshots() {
    return Stream.value(DemoQuerySnapshot([]));
  }
  
  Future<DemoQuerySnapshot> get() async {
    return DemoQuerySnapshot([]);
  }
}

class DemoQuerySnapshot {
  final List<DemoDocumentSnapshot> docs;
  
  DemoQuerySnapshot(this.docs);
}

class DemoDocumentSnapshot {
  final bool exists;
  
  DemoDocumentSnapshot(this.exists);
  
  Map<String, dynamic> data() {
    return {};
  }
  
  String get id => 'demo_id';
} 