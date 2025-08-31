import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// This script creates a veterinarian account in Firebase
// Run this script once to set up the demo veterinarian account

Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    print('🔵 Creating veterinarian account...');
    
    // Create veterinarian account
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'doctor@gmail.com',
      password: '000111',
    );
    
    print('✅ Firebase Auth account created successfully. UID: ${userCredential.user!.uid}');
    
    // Update display name
    await userCredential.user!.updateDisplayName('د. أحمد محمد');
    
    // Create veterinarian profile in Firestore
    await FirebaseFirestore.instance.collection('veterinarians').doc(userCredential.user!.uid).set({
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
    });
    
    print('✅ Veterinarian profile created successfully in Firestore');
    print('✅ Veterinarian account setup completed!');
    print('');
    print('📋 Account Details:');
    print('   Email: doctor@gmail.com');
    print('   Password: 000111');
    print('   Name: د. أحمد محمد');
    print('   Specialization: الطب البيطري العام');
    print('   Experience: 10 سنوات');
    
  } catch (e) {
    print('❌ Error creating veterinarian account: $e');
    
    // Check if user already exists
    if (e.toString().contains('email-already-in-use')) {
      print('ℹ️  Veterinarian account already exists. Checking profile...');
      
      try {
        // Try to sign in to get the user
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'doctor@gmail.com',
          password: '000111',
        );
        
        // Check if profile exists
        final profileDoc = await FirebaseFirestore.instance
            .collection('veterinarians')
            .doc(userCredential.user!.uid)
            .get();
        
        if (profileDoc.exists) {
          print('✅ Veterinarian profile already exists and is ready to use');
        } else {
          print('⚠️  Profile missing, creating it now...');
          
          // Create the profile
          await FirebaseFirestore.instance.collection('veterinarians').doc(userCredential.user!.uid).set({
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
          });
          
          print('✅ Veterinarian profile created successfully');
        }
        
        // Sign out
        await FirebaseAuth.instance.signOut();
        
      } catch (signInError) {
        print('❌ Error signing in: $signInError');
      }
    }
  }
  
  exit(0);
} 