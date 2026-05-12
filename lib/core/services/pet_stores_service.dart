import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../utils/localized_content.dart';
import 'location_service.dart';

class PetStoresService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static const String _collection = 'petStores';

  // Test Firebase connection
  static Future<void> testFirebaseConnection() async {
    try {
      print('🧪 Testing Firebase connection...');
      final testDoc = await _firestore.collection('test').doc('connection').get();
      print('✅ Firebase connection test successful');
    } catch (e) {
      print('❌ Firebase connection test failed: $e');
    }
  }

  // Check if petStores collection exists and has data
  static Future<void> checkCollectionExists() async {
    try {
      print('📋 Checking petStores collection...');
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      print('📋 Collection exists. Document count: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        print('📋 Sample document: ${snapshot.docs.first.data()}');
      }
    } catch (e) {
      print('❌ Error checking collection: $e');
    }
  }

  // Create a test store (for debugging)
  static Future<void> createTestStore() async {
    try {
      print('🧪 Creating test store...');
      await _firestore.collection(_collection).add({
        'name': 'Test Pet Store',
        'category': 'pet_food',
        'phone': '01234567890',
        'email': 'test@petstore.com',
        'address': 'Test Address, Test City',
        'city': 'Test City',
        'isActive': true,
        'rating': 4.5,
        'description': 'A test pet store for debugging',
        'workingHours': '9:00 AM - 10:00 PM',
        'deliveryAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Test store created successfully');
    } catch (e) {
      print('❌ Error creating test store: $e');
    }
  }

  // Get all active pet stores
  static Future<List<Map<String, dynamic>>> getActivePetStores() async {
    try {
      print('🔥 Firebase connection status: ${FirebaseConfig.isInitialized}');
      print('🔥 Firebase demo mode: ${FirebaseConfig.isDemoMode}');
      print('🔥 Querying collection: $_collection');
      
      // Check if Firebase is initialized
      if (!FirebaseConfig.isInitialized) {
        print('❌ Firebase is not initialized');
        return [];
      }
      
      if (FirebaseConfig.isDemoMode) {
        print('❌ Firebase is in demo mode');
        return [];
      }
      
      // Try multiple query strategies
      QuerySnapshot snapshot;
      try {
        // Strategy 1: With where and orderBy
        snapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();
        print('🔥 Query with where + orderBy successful');
      } catch (indexError) {
        print('⚠️ orderBy failed, trying simple where query: $indexError');
        try {
          // Strategy 2: Just where clause
          snapshot = await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .get();
          print('🔥 Simple where query successful');
        } catch (whereError) {
          print('⚠️ where query failed, trying get all: $whereError');
          // Strategy 3: Get all documents (fallback)
          snapshot = await _firestore
              .collection(_collection)
              .get();
          print('🔥 Get all query successful');
        }
      }

      print('🔥 Query completed. Found ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isNotEmpty) {
        print('🔥 Sample document data: ${snapshot.docs.first.data()}');
      }

      final stores = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .where((store) => store['isActive'] == true) // Filter active stores in code
          .toList();
      
      print('🔥 Returning ${stores.length} stores');
      return stores;
    } catch (e) {
      print('❌ Error getting pet stores: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // Return empty list instead of demo data
      return [];
    }
  }

  /// Get active pet stores filtered by user's selected location.
  /// Only shows stores that are either in "all" locations or in the user's region.
  static Future<List<Map<String, dynamic>>> getActivePetStoresForUserLocation() async {
    final allStores = await getActivePetStores();
    final userLocationId = LocationService.getUserLocation();

    final filtered = allStores.where((store) {
      final locations = store['locations'];
      return LocationService.shouldShowForLocation(
        locations is List ? List<dynamic>.from(locations) : null,
        userLocationId,
      );
    }).toList();

    print('🏪 Filtered ${filtered.length} stores for location: ${userLocationId ?? "none"} (from ${allStores.length} total)');
    return filtered;
  }

  // Get pet stores by category
  static Future<List<Map<String, dynamic>>> getPetStoresByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting pet stores by category: $e');
      return [];
    }
  }

  // Get pet stores by city
  static Future<List<Map<String, dynamic>>> getPetStoresByCity(String city) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: city)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting pet stores by city: $e');
      return [];
    }
  }

  // Search pet stores (filtered by user location)
  static Future<List<Map<String, dynamic>>> searchPetStores(String query) async {
    try {
      final stores = await getActivePetStoresForUserLocation();
      final searchQuery = query.toLowerCase();

      return stores.where((store) {
        final category = store['category']?.toString().toLowerCase() ?? '';
        if (category.contains(searchQuery)) return true;
        const textKeys = [
          'name',
          'nameEn',
          'nameAr',
          'nameHe',
          'description',
          'descriptionEn',
          'descriptionAr',
          'descriptionHe',
          'city',
          'cityEn',
          'cityAr',
          'cityHe',
          'address',
          'addressEn',
          'addressAr',
          'addressHe',
        ];
        for (final k in textKeys) {
          final v = store[k]?.toString().toLowerCase() ?? '';
          if (v.contains(searchQuery)) return true;
        }
        return false;
      }).toList();
    } catch (e) {
      print('Error searching pet stores: $e');
      return [];
    }
  }

  // Get store by ID
  static Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(storeId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting store by ID: $e');
      return null;
    }
  }

  // Get available categories
  static Future<List<String>> getAvailableCategories() async {
    try {
      final stores = await getActivePetStores();
      return getCategoriesFromStores(stores);
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get available categories from a list of stores (e.g. filtered by location)
  static List<String> getCategoriesFromStores(List<Map<String, dynamic>> stores) {
    final categories = stores
        .map((store) => store['category']?.toString() ?? '')
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  // Get available cities
  static Future<List<String>> getAvailableCities() async {
    try {
      final stores = await getActivePetStores();
      return getCitiesFromStores(stores);
    } catch (e) {
      print('Error getting cities: $e');
      return [];
    }
  }

  // Canonical city key for filtering (prefers English field when present).
  static String cityCanonical(Map<String, dynamic> store) {
    final en = store['cityEn']?.toString().trim() ?? '';
    if (en.isNotEmpty) return en;
    return store['city']?.toString().trim() ?? '';
  }

  static String storeLocalized(
    Map<String, dynamic> store,
    String languageCode,
    String baseKey,
  ) {
    return LocalizedContent.pickFromMap(store, languageCode, baseKey: baseKey);
  }

  static String cityLabelForCanonical(
    List<Map<String, dynamic>> stores,
    String canonical,
    String languageCode,
  ) {
    for (final store in stores) {
      if (cityCanonical(store) == canonical) {
        return storeLocalized(store, languageCode, 'city');
      }
    }
    return canonical;
  }

  // Get available cities from a list of stores (e.g. filtered by location)
  static List<String> getCitiesFromStores(List<Map<String, dynamic>> stores) {
    final cities = stores
        .map(cityCanonical)
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  // Format category name for display
  static String formatCategoryName(String category) {
    switch (category) {
      case 'pet_food':
        return 'Pet Food';
      case 'pet_accessories':
        return 'Pet Accessories';
      case 'veterinary_supplies':
        return 'Veterinary Supplies';
      case 'pet_toys':
        return 'Pet Toys';
      case 'pet_care':
        return 'Pet Care';
      case 'general':
        return 'General Store';
      default:
        return category.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Get category icon
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'pet_food':
        return '🍖';
      case 'pet_accessories':
        return '🎾';
      case 'veterinary_supplies':
        return '💊';
      case 'pet_toys':
        return '🧸';
      case 'pet_care':
        return '🧴';
      case 'general':
        return '🏪';
      default:
        return '🏪';
    }
  }

  // Demo data for when Firebase is not available
  static List<Map<String, dynamic>> _getDemoStores() {
    return [
      {
        'id': 'demo_store_1',
        'name': 'Pet Paradise',
        'category': 'general',
        'phone': '+201234567890',
        'email': 'info@petparadise.com',
        'address': '123 Tahrir Square',
        'city': 'Cairo',
        'website': 'https://petparadise.com',
        'workingHours': '9:00 AM - 9:00 PM',
        'deliveryAvailable': true,
        'description': 'Complete pet supplies store with everything you need for your furry friends. We offer high-quality food, toys, accessories, and care products.',
        'imageUrl': 'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=500',
        'rating': 4.5,
        'isActive': true,
      },
      {
        'id': 'demo_store_2',
        'name': 'Healthy Paws Clinic Store',
        'category': 'veterinary_supplies',
        'phone': '+201234567891',
        'email': 'store@healthypaws.com',
        'address': '456 Zamalek Street',
        'city': 'Cairo',
        'website': 'https://healthypaws.com',
        'workingHours': '8:00 AM - 8:00 PM',
        'deliveryAvailable': true,
        'description': 'Professional veterinary supplies and medications. Trusted by veterinarians across Egypt.',
        'imageUrl': 'https://images.unsplash.com/photo-1559181567-c3190ca9959b?w=500',
        'rating': 4.8,
        'isActive': true,
      },
      {
        'id': 'demo_store_3',
        'name': 'Paw-some Toys & Treats',
        'category': 'pet_toys',
        'phone': '+201234567892',
        'email': 'fun@pawsome.com',
        'address': '789 Maadi Corniche',
        'city': 'Cairo',
        'website': 'https://pawsome.com',
        'workingHours': '10:00 AM - 10:00 PM',
        'deliveryAvailable': false,
        'description': 'The best selection of pet toys, treats, and entertainment accessories. Keep your pets happy and active!',
        'imageUrl': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=500',
        'rating': 4.3,
        'isActive': true,
      },
      {
        'id': 'demo_store_4',
        'name': 'Premium Pet Food Store',
        'category': 'pet_food',
        'phone': '+201234567893',
        'email': 'nutrition@premiumpet.com',
        'address': '321 Heliopolis Avenue',
        'city': 'Cairo',
        'website': 'https://premiumpet.com',
        'workingHours': '7:00 AM - 11:00 PM',
        'deliveryAvailable': true,
        'description': 'Premium quality pet food from international brands. Specialized nutrition for all types of pets.',
        'imageUrl': 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500',
        'rating': 4.7,
        'isActive': true,
      },
      {
        'id': 'demo_store_5',
        'name': 'Alexandria Pet Center',
        'category': 'general',
        'phone': '+201234567894',
        'email': 'alex@petcenter.com',
        'address': '555 Corniche Road',
        'city': 'Alexandria',
        'website': 'https://alexpet.com',
        'workingHours': '9:00 AM - 8:00 PM',
        'deliveryAvailable': true,
        'description': 'Alexandria\'s largest pet store. Full range of products and services for all your pet needs.',
        'imageUrl': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=500',
        'rating': 4.4,
        'isActive': true,
      },
    ];
  }
} 