import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';

class DataSeedingService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  
  // Initialize sample veterinarians data
  static Future<void> initializeVeterinarians() async {
    try {
      if (FirebaseConfig.isDemoMode) {
        print('🔄 Demo mode: Skipping veterinarians initialization');
        return;
      }

      // Check if veterinarians already exist
      final existingVets = await _firestore
          .collection('veterinarians')
          .limit(1)
          .get();

      if (existingVets.docs.isNotEmpty) {
        print('✅ Veterinarians already exist, skipping initialization');
        return;
      }

      print('🔄 Initializing sample veterinarians...');

      // Sample veterinarian data
      final vets = [
        {
          'name': 'د. أحمد محمد',
          'email': 'ahmed@petcare.com',
          'specialization': 'الطب البيطري العام',
          'phoneNumber': '+201234567890',
          'address': 'القاهرة، مصر الجديدة',
          'rating': 4.8,
          'reviewCount': 124,
          'isOnline': true,
          'isAvailable': true,
          'isActive': true,
          'profilePhoto': null,
          'experience': '10 سنوات خبرة في الطب البيطري',
          'description': 'طبيب بيطري متخصص في علاج الكلاب والقطط',
          'workingHours': 'السبت - الخميس: 9 صباحاً - 6 مساءً',
          'languages': ['العربية', 'الإنجليزية'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'د. فاطمة علي',
          'email': 'fatima@petcare.com',
          'specialization': 'جراحة بيطرية',
          'phoneNumber': '+201234567891',
          'address': 'الجيزة، الدقي',
          'rating': 4.9,
          'reviewCount': 89,
          'isOnline': false,
          'isAvailable': true,
          'isActive': true,
          'profilePhoto': null,
          'experience': '8 سنوات خبرة في الجراحة البيطرية',
          'description': 'جراحة بيطرية متخصصة في العمليات المعقدة',
          'workingHours': 'السبت - الخميس: 10 صباحاً - 4 مساءً',
          'languages': ['العربية', 'الإنجليزية', 'الفرنسية'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'د. محمود حسن',
          'email': 'mahmoud@petcare.com',
          'specialization': 'طب الطيور',
          'phoneNumber': '+201234567892',
          'address': 'الإسكندرية، سموحة',
          'rating': 4.7,
          'reviewCount': 156,
          'isOnline': true,
          'isAvailable': true,
          'isActive': true,
          'profilePhoto': null,
          'experience': '12 سنة خبرة في طب الطيور',
          'description': 'متخصص في علاج الطيور والحيوانات الأليفة الصغيرة',
          'workingHours': 'السبت - الخميس: 8 صباحاً - 8 مساءً',
          'languages': ['العربية'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'د. سارة أحمد',
          'email': 'sara@petcare.com',
          'specialization': 'طب القطط',
          'phoneNumber': '+201234567893',
          'address': 'القاهرة، المعادي',
          'rating': 4.6,
          'reviewCount': 67,
          'isOnline': true,
          'isAvailable': false,
          'isActive': true,
          'profilePhoto': null,
          'experience': '6 سنوات خبرة في طب القطط',
          'description': 'طبيبة بيطرية متخصصة في علاج القطط',
          'workingHours': 'السبت - الخميس: 2 مساءً - 10 مساءً',
          'languages': ['العربية', 'الإنجليزية'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'د. خالد عمر',
          'email': 'khaled@petcare.com',
          'specialization': 'طب الكلاب',
          'phoneNumber': '+201234567894',
          'address': 'الجيزة، 6 أكتوبر',
          'rating': 4.5,
          'reviewCount': 203,
          'isOnline': false,
          'isAvailable': true,
          'isActive': true,
          'profilePhoto': null,
          'experience': '15 سنة خبرة في طب الكلاب',
          'description': 'طبيب بيطري متخصص في علاج الكلاب بجميع أنواعها',
          'workingHours': 'الأحد - الخميس: 9 صباحاً - 5 مساءً',
          'languages': ['العربية', 'الإنجليزية', 'الألمانية'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add veterinarians to Firestore
      final batch = _firestore.batch();
      for (final vet in vets) {
        final docRef = _firestore.collection('veterinarians').doc();
        batch.set(docRef, vet);
      }

      await batch.commit();
      print('✅ Successfully initialized ${vets.length} veterinarians');

    } catch (e) {
      print('❌ Error initializing veterinarians: $e');
      // Don't throw error, just log it
    }
  }

  // Initialize sample lost pets data
  static Future<void> initializeSampleLostPets() async {
    try {
      if (FirebaseConfig.isDemoMode) {
        print('🔄 Demo mode: Skipping lost pets initialization');
        return;
      }

      // Check if lost pets already exist
      final existingReports = await _firestore
          .collection('lost_pets')
          .limit(1)
          .get();

      if (existingReports.docs.isNotEmpty) {
        print('✅ Lost pets already exist, skipping initialization');
        return;
      }

      print('🔄 Initializing sample lost pets...');

      final lostPets = [
        {
          'userId': 'demo_user_1',
          'petDetails': {
            'name': 'لولو',
            'type': 'Dog',
            'breed': 'جولدن ريتريفر',
            'age': '3',
            'gender': 'Male',
            'color': 'ذهبي',
            'size': 'كبير',
            'distinguishingMarks': 'بقعة بيضاء على الصدر',
            'personality': 'ودود ونشيط',
            'medicalConditions': 'لا توجد',
          },
          'location': {
            'address': 'القاهرة الجديدة، التجمع الخامس',
            'coordinates': const GeoPoint(30.0444, 31.2357),
            'area': 'التجمع الخامس',
            'landmark': 'بجوار مول سيتي ستارز',
          },
          'contactInfo': {
            'phone': '+201234567890',
            'email': 'owner1@example.com',
            'preferredContact': 'phone',
          },
          'imageUrls': [],
          'lastSeenDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'lastSeenLocation': 'التجمع الخامس',
          'isUrgent': true,
          'reward': 500.0,
          'isActive': true,
          'status': 'lost',
          'type': 'lost_pet',
          'viewCount': 45,
          'shareCount': 12,
          'helpCount': 8,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': 'demo_user_2',
          'petDetails': {
            'name': 'مشمش',
            'type': 'Cat',
            'breed': 'شيرازي',
            'age': '2',
            'gender': 'Female',
            'color': 'أبيض وبرتقالي',
            'size': 'متوسط',
            'distinguishingMarks': 'عيون زرقاء',
            'personality': 'هادئة وخجولة',
            'medicalConditions': 'مطعمة',
          },
          'location': {
            'address': 'الجيزة، الدقي',
            'coordinates': const GeoPoint(30.0626, 31.2126),
            'area': 'الدقي',
            'landmark': 'بجوار مترو الدقي',
          },
          'contactInfo': {
            'phone': '+201234567891',
            'email': 'owner2@example.com',
            'preferredContact': 'phone',
          },
          'imageUrls': [],
          'lastSeenDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'lastSeenLocation': 'الدقي',
          'isUrgent': false,
          'reward': 200.0,
          'isActive': true,
          'status': 'lost',
          'type': 'lost_pet',
          'viewCount': 32,
          'shareCount': 5,
          'helpCount': 3,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add lost pets to Firestore
      final batch = _firestore.batch();
      for (final pet in lostPets) {
        final docRef = _firestore.collection('lost_pets').doc();
        batch.set(docRef, pet);
      }

      await batch.commit();
      print('✅ Successfully initialized ${lostPets.length} lost pets');

    } catch (e) {
      print('❌ Error initializing lost pets: $e');
    }
  }

  // Initialize sample found pets data
  static Future<void> initializeSampleFoundPets() async {
    try {
      if (FirebaseConfig.isDemoMode) {
        print('🔄 Demo mode: Skipping found pets initialization');
        return;
      }

      // Check if found pets already exist
      final existingReports = await _firestore
          .collection('found_pets')
          .limit(1)
          .get();

      if (existingReports.docs.isNotEmpty) {
        print('✅ Found pets already exist, skipping initialization');
        return;
      }

      print('🔄 Initializing sample found pets...');

      final foundPets = [
        {
          'userId': 'demo_user_3',
          'petDetails': {
            'type': 'Dog',
            'breed': 'مجهول',
            'approximateAge': '5',
            'gender': 'Male',
            'color': 'أسود وبني',
            'size': 'متوسط',
            'distinguishingMarks': 'أذنان مقطعتان',
            'temperament': 'ودود',
            'healthStatus': 'جيد',
            'hasCollar': true,
            'collarDescription': 'طوق أحمر بدون اسم',
          },
          'location': {
            'address': 'القاهرة، مدينة نصر',
            'coordinates': const GeoPoint(30.0618, 31.3379),
            'area': 'مدينة نصر',
            'landmark': 'بجوار جنينة مول',
          },
          'contactInfo': {
            'phone': '+201234567892',
            'email': 'finder1@example.com',
            'preferredContact': 'phone',
          },
          'imageUrls': [],
          'foundDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
          'foundLocation': 'مدينة نصر',
          'isInShelter': false,
          'shelterInfo': '',
          'isActive': true,
          'status': 'found',
          'type': 'found_pet',
          'viewCount': 28,
          'shareCount': 7,
          'helpCount': 15,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add found pets to Firestore
      final batch = _firestore.batch();
      for (final pet in foundPets) {
        final docRef = _firestore.collection('found_pets').doc();
        batch.set(docRef, pet);
      }

      await batch.commit();
      print('✅ Successfully initialized ${foundPets.length} found pets');

    } catch (e) {
      print('❌ Error initializing found pets: $e');
    }
  }

  // Initialize all demo data (veterinarians only - no sample pets)
  static Future<void> initializeAllDemoData() async {
    print('🔄 Starting demo data initialization...');
    
    await Future.wait([
      initializeVeterinarians(),
      // initializeSampleLostPets() - disabled: no auto sample animals
      // initializeSampleFoundPets() - disabled: no auto sample animals
    ]);
    
    print('✅ Demo data initialization completed');
  }

  // Clear all demo data (for testing purposes)
  static Future<void> clearAllDemoData() async {
    try {
      if (FirebaseConfig.isDemoMode) {
        print('🔄 Demo mode: Skipping data clearing');
        return;
      }

      print('🔄 Clearing all demo data...');

      final batch = _firestore.batch();

      // Clear veterinarians
      final vets = await _firestore.collection('veterinarians').get();
      for (final doc in vets.docs) {
        batch.delete(doc.reference);
      }

      // Clear lost pets
      final lostPets = await _firestore.collection('lost_pets').get();
      for (final doc in lostPets.docs) {
        batch.delete(doc.reference);
      }

      // Clear found pets
      final foundPets = await _firestore.collection('found_pets').get();
      for (final doc in foundPets.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All demo data cleared successfully');

    } catch (e) {
      print('❌ Error clearing demo data: $e');
    }
  }
} 