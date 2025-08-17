import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Request notification permissions
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
      print('Firebase initialization failed: $e');
      print('Running in demo mode without Firebase');
    }
  }

  // Firestore collections
  static CollectionReference get usersCollection => 
      firestore.collection('users');
  
  static CollectionReference get lostPetsCollection => 
      firestore.collection('lost_pets');
  
  static CollectionReference get foundPetsCollection => 
      firestore.collection('found_pets');
  
  static CollectionReference get veterinaryChatsCollection => 
      firestore.collection('veterinary_chats');
  
  static CollectionReference get chatMessagesCollection => 
      firestore.collection('chat_messages');
  
  static CollectionReference get veterinariansCollection => 
      firestore.collection('veterinarians');
} 