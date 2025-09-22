import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/core/firebase/firebase_config.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🔍 Testing Firebase Advertisements...');
  
  try {
    // Test direct Firebase query
    final snapshot = await FirebaseFirestore.instance
        .collection('advertisements')
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder', descending: false)
        .limit(10)
        .get();
    
    print('📊 Found ${snapshot.docs.length} advertisements');
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      print('📄 Ad ID: ${doc.id}');
      print('   Title: ${data['title']}');
      print('   Image URL: ${data['imageUrl']}');
      print('   Display Order: ${data['displayOrder']}');
      print('   Is Active: ${data['isActive']}');
      print('   ---');
    }
    
    if (snapshot.docs.isEmpty) {
      print('❌ No advertisements found!');
      print('💡 Make sure to:');
      print('   1. Add advertisements from web dashboard');
      print('   2. Set isActive to true');
      print('   3. Check Firestore rules');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
