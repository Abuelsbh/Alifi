import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firebase_config.dart';

class VeterinarySetupService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseAuth _auth = FirebaseConfig.auth;

  // Create veterinarian account and profile
  static Future<Map<String, dynamic>> createVeterinarianAccount() async {
    try {
      print('🔵 Creating veterinarian account...');
      
      // Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'doctor@gmail.com',
        password: '000111',
      );
      
      print('✅ Firebase Auth account created successfully. UID: ${userCredential.user!.uid}');
      
      // Update display name
      await userCredential.user!.updateDisplayName('د. أحمد محمد');
      
      // Create veterinarian profile in Firestore
      final vetData = {
        'uid': userCredential.user!.uid,
        'email': 'doctor@gmail.com',
        'name': 'د. أحمد محمد',
        'specialization': 'الطب البيطري العام',
        'experience': '10 سنوات',
        'phone': '+201234567890',
        'profileImage': null,
        'bio': 'طبيب بيطري متخصص في علاج الكلاب والقطط مع خبرة 10 سنوات في الطب البيطري',
        'isOnline': false,
        'rating': 4.8,
        'totalRatings': 124,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userType': 'veterinarian',
        'address': 'القاهرة، مصر الجديدة',
        'workingHours': 'السبت - الخميس: 9 صباحاً - 6 مساءً',
        'languages': ['العربية', 'الإنجليزية'],
      };
      
      await _firestore.collection('veterinarians').doc(userCredential.user!.uid).set(vetData);
      
      print('✅ Veterinarian profile created successfully in Firestore');
      
      // Sign out after creation
      await _auth.signOut();
      
      return {
        'success': true,
        'message': 'تم إنشاء حساب الطبيب البيطري بنجاح',
        'data': vetData,
      };
      
    } catch (e) {
      print('❌ Error creating veterinarian account: $e');
      
      // Check if user already exists
      if (e.toString().contains('email-already-in-use')) {
        return await _handleExistingAccount();
      }
      
      return {
        'success': false,
        'message': 'فشل في إنشاء حساب الطبيب البيطري: $e',
      };
    }
  }

  // Handle existing account
  static Future<Map<String, dynamic>> _handleExistingAccount() async {
    try {
      print('ℹ️  Veterinarian account already exists. Checking profile...');
      
      // Try to sign in to get the user
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: 'doctor@gmail.com',
        password: '000111',
      );
      
      // Check if profile exists
      final profileDoc = await _firestore
          .collection('veterinarians')
          .doc(userCredential.user!.uid)
          .get();
      
      if (profileDoc.exists) {
        print('✅ Veterinarian profile already exists and is ready to use');
        await _auth.signOut();
        
        return {
          'success': true,
          'message': 'حساب الطبيب البيطري موجود بالفعل وجاهز للاستخدام',
          'data': profileDoc.data(),
        };
      } else {
        print('⚠️  Profile missing, creating it now...');
        
        // Create the profile
        final vetData = {
          'uid': userCredential.user!.uid,
          'email': 'doctor@gmail.com',
          'name': 'د. أحمد محمد',
          'specialization': 'الطب البيطري العام',
          'experience': '10 سنوات',
          'phone': '+201234567890',
          'profileImage': null,
          'bio': 'طبيب بيطري متخصص في علاج الكلاب والقطط مع خبرة 10 سنوات في الطب البيطري',
          'isOnline': false,
          'rating': 4.8,
          'totalRatings': 124,
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'veterinarian',
          'address': 'القاهرة، مصر الجديدة',
          'workingHours': 'السبت - الخميس: 9 صباحاً - 6 مساءً',
          'languages': ['العربية', 'الإنجليزية'],
        };
        
        await _firestore.collection('veterinarians').doc(userCredential.user!.uid).set(vetData);
        
        print('✅ Veterinarian profile created successfully');
        await _auth.signOut();
        
        return {
          'success': true,
          'message': 'تم إنشاء ملف الطبيب البيطري بنجاح',
          'data': vetData,
        };
      }
      
    } catch (signInError) {
      print('❌ Error signing in: $signInError');
      return {
        'success': false,
        'message': 'فشل في تسجيل الدخول: $signInError',
      };
    }
  }

  // Create a demo chat for testing
  static Future<Map<String, dynamic>> createDemoChat() async {
    try {
      // First, get the veterinarian
      final vetResult = await _auth.signInWithEmailAndPassword(
        email: 'doctor@gmail.com',
        password: '000111',
      );
      
      final vetId = vetResult.user!.uid;
      
      // Create a demo user ID
      final demoUserId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create chat document
      final chatData = {
        'participants': [demoUserId, vetId],
        'participantNames': {
          demoUserId: 'أحمد محمد',
          vetId: 'د. أحمد محمد',
        },
        'lastMessage': 'مرحباً دكتور، كلبي لا يأكل منذ يومين',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSender': demoUserId,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          demoUserId: 0,
          vetId: 1,
        },
      };
      
      final chatRef = await _firestore.collection('veterinary_chats').add(chatData);
      
      // Add demo messages
      final messages = [
        {
          'senderId': demoUserId,
          'message': 'مرحباً دكتور، كلبي لا يأكل منذ يومين',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
        },
        {
          'senderId': vetId,
          'message': 'مرحباً، هل هناك أعراض أخرى؟',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
        },
        {
          'senderId': demoUserId,
          'message': 'نعم، يبدو خاملاً ولا يلعب كالمعتاد',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'text',
        },
      ];
      
      // Add messages to the chat
      for (final message in messages) {
        await chatRef.collection('messages').add(message);
      }
      
      await _auth.signOut();
      
      return {
        'success': true,
        'message': 'تم إنشاء محادثة تجريبية بنجاح',
        'chatId': chatRef.id,
      };
      
    } catch (e) {
      print('❌ Error creating demo chat: $e');
      return {
        'success': false,
        'message': 'فشل في إنشاء المحادثة التجريبية: $e',
      };
    }
  }

  // Check if veterinarian account exists
  static Future<Map<String, dynamic>> checkVeterinarianAccount() async {
    try {
      // Try to sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: 'doctor@gmail.com',
        password: '000111',
      );
      
      // Check if profile exists
      final profileDoc = await _firestore
          .collection('veterinarians')
          .doc(userCredential.user!.uid)
          .get();
      
      await _auth.signOut();
      
      if (profileDoc.exists) {
        return {
          'success': true,
          'exists': true,
          'message': 'حساب الطبيب البيطري موجود وجاهز للاستخدام',
          'data': profileDoc.data(),
        };
      } else {
        return {
          'success': true,
          'exists': false,
          'message': 'الحساب موجود في Authentication لكن لا يوجد ملف في Firestore',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'exists': false,
        'message': 'فشل في التحقق من الحساب: $e',
      };
    }
  }

  // Get account status
  static Future<Map<String, dynamic>> getAccountStatus() async {
    try {
      // Check if user exists in Auth
      final authResult = await _auth.fetchSignInMethodsForEmail('doctor@gmail.com');
      final authExists = authResult.isNotEmpty;
      
      if (!authExists) {
        return {
          'auth_exists': false,
          'profile_exists': false,
          'message': 'الحساب غير موجود في Authentication',
        };
      }
      
      // Try to sign in to check profile
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: 'doctor@gmail.com',
        password: '000111',
      );
      
      final profileDoc = await _firestore
          .collection('veterinarians')
          .doc(userCredential.user!.uid)
          .get();
      
      await _auth.signOut();
      
      return {
        'auth_exists': true,
        'profile_exists': profileDoc.exists,
        'message': profileDoc.exists 
          ? 'الحساب موجود في Authentication وFirestore'
          : 'الحساب موجود في Authentication فقط',
        'uid': userCredential.user!.uid,
      };
      
    } catch (e) {
      return {
        'auth_exists': false,
        'profile_exists': false,
        'message': 'خطأ في التحقق: $e',
      };
    }
  }

  // Check all veterinarians in the system
  static Future<Map<String, dynamic>> checkAllVeterinarians() async {
    try {
      final snapshot = await _firestore.collection('veterinarians').get();
      
      final veterinarians = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'غير محدد',
          'email': data['email'] ?? 'غير محدد',
          'isVerified': data['isVerified'] ?? false,
          'isOnline': data['isOnline'] ?? false,
          'specialization': data['specialization'] ?? 'غير محدد',
        };
      }).toList();
      
      return {
        'success': true,
        'total_count': veterinarians.length,
        'verified_count': veterinarians.where((v) => v['isVerified'] == true).length,
        'online_count': veterinarians.where((v) => v['isOnline'] == true).length,
        'veterinarians': veterinarians,
        'message': 'تم فحص ${veterinarians.length} طبيب بيطري في النظام',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في فحص الأطباء البيطريين: $e',
        'total_count': 0,
        'verified_count': 0,
        'online_count': 0,
        'veterinarians': [],
      };
    }
  }

  // Update veterinarian online status
  static Future<Map<String, dynamic>> updateVeterinarianOnlineStatus(String vetId, bool isOnline) async {
    try {
      await _firestore.collection('veterinarians').doc(vetId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'تم تحديث حالة الاتصال بنجاح',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث حالة الاتصال: $e',
      };
    }
  }
} 