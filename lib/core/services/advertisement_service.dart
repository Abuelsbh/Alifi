import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../utils/localized_content.dart';
import 'location_service.dart';

class Advertisement {
  final String id;
  final String? title;
  final String? description;
  final String? titleEn;
  final String? titleAr;
  final String? titleHe;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionHe;
  final String imageUrl;
  final int displayOrder;
  final bool isActive;
  final String? clickUrl;
  final List<String>? locations; // List of location IDs, null/empty means "all"
  final int views;
  final int clickCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Advertisement({
    required this.id,
    this.title,
    this.description,
    this.titleEn,
    this.titleAr,
    this.titleHe,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionHe,
    required this.imageUrl,
    required this.displayOrder,
    required this.isActive,
    this.clickUrl,
    this.locations,
    required this.views,
    required this.clickCount,
    required this.createdAt,
    this.updatedAt,
  });

  String? displayTitle(String languageCode) {
    final s = LocalizedContent.pickFromMap({
      'title': title,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'titleHe': titleHe,
    }, languageCode, baseKey: 'title');
    return s.isEmpty ? null : s;
  }

  String? displayDescription(String languageCode) {
    final s = LocalizedContent.pickFromMap({
      'description': description,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'descriptionHe': descriptionHe,
    }, languageCode, baseKey: 'description');
    return s.isEmpty ? null : s;
  }

  factory Advertisement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Advertisement(
      id: doc.id,
      title: data['title']?.toString().trim().isEmpty == true ? null : data['title'],
      description: data['description']?.toString().trim().isEmpty == true ? null : data['description'],
      titleEn: data['titleEn']?.toString().trim().isEmpty == true ? null : data['titleEn']?.toString(),
      titleAr: data['titleAr']?.toString().trim().isEmpty == true ? null : data['titleAr']?.toString(),
      titleHe: data['titleHe']?.toString().trim().isEmpty == true ? null : data['titleHe']?.toString(),
      descriptionEn: data['descriptionEn']?.toString().trim().isEmpty == true ? null : data['descriptionEn']?.toString(),
      descriptionAr: data['descriptionAr']?.toString().trim().isEmpty == true ? null : data['descriptionAr']?.toString(),
      descriptionHe: data['descriptionHe']?.toString().trim().isEmpty == true ? null : data['descriptionHe']?.toString(),
      imageUrl: data['imageUrl'] ?? '',
      displayOrder: data['displayOrder'] ?? 1,
      isActive: data['isActive'] ?? true,
      clickUrl: data['clickUrl']?.toString().trim().isEmpty == true ? null : data['clickUrl'],
      locations: data['locations'] != null 
          ? List<String>.from(data['locations'])
          : null,
      views: data['views'] ?? 0,
      clickCount: data['clickCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'titleHe': titleHe,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'descriptionHe': descriptionHe,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'clickUrl': clickUrl,
      'locations': locations ?? ['all'], // Default to 'all' if not specified
      'views': views,
      'clickCount': clickCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }
}

class AdvertisementService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static const String _collection = 'advertisements';

  // Get active advertisements for mobile app display
  static Stream<List<Advertisement>> getActiveAdvertisementsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder', descending: false)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final userLocationId = LocationService.getUserLocation();
      return snapshot.docs
          .map((doc) => Advertisement.fromFirestore(doc))
          .where((ad) {
            // Filter by location
            return LocationService.shouldShowForLocation(ad.locations, userLocationId);
          })
          .toList();
    });
  }

  // Get active advertisements as a one-time fetch
  static Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      print('🔍 Fetching active advertisements from Firebase...');
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder', descending: false)
          .limit(10)
          .get();

      print('📊 Found ${snapshot.docs.length} advertisements');
      
      final userLocationId = LocationService.getUserLocation();
      print('📍 User location: $userLocationId');
      
      final ads = snapshot.docs
          .map((doc) {
            print('📄 Processing ad: ${doc.id}');
            return Advertisement.fromFirestore(doc);
          })
          .where((ad) {
            // Filter by location
            return LocationService.shouldShowForLocation(ad.locations, userLocationId);
          })
          .toList();
      
      print('✅ Successfully loaded ${ads.length} advertisements (filtered by location)');
      return ads;
    } catch (e) {
      print('❌ Error fetching active advertisements: $e');
      return [];
    }
  }

  // Get all advertisements (for admin)
  static Future<List<Advertisement>> getAllAdvertisements() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Advertisement.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all advertisements: $e');
      return [];
    }
  }

  // Increment advertisement view count
  static Future<void> incrementAdView(String adId) async {
    try {
      await _firestore.collection(_collection).doc(adId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing ad view: $e');
    }
  }

  // Increment advertisement click count
  static Future<void> incrementAdClick(String adId) async {
    try {
      await _firestore.collection(_collection).doc(adId).update({
        'clickCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing ad click: $e');
    }
  }

  // Create new advertisement (admin only)
  static Future<String?> createAdvertisement(Advertisement ad) async {
    try {
      // Check if maximum number of ads reached
      final count = await getAdvertisementsCount();
      if (count >= 10) {
        throw Exception('Maximum of 10 advertisements allowed');
      }

      final docRef = await _firestore.collection(_collection).add(ad.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating advertisement: $e');
      return null;
    }
  }

  // Update advertisement (admin only)
  static Future<bool> updateAdvertisement(String id, Advertisement ad) async {
    try {
      await _firestore.collection(_collection).doc(id).update(ad.toFirestore());
      return true;
    } catch (e) {
      print('Error updating advertisement: $e');
      return false;
    }
  }

  // Delete advertisement (admin only)
  static Future<bool> deleteAdvertisement(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting advertisement: $e');
      return false;
    }
  }

  // Toggle advertisement active status (admin only)
  static Future<bool> toggleAdvertisementStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling advertisement status: $e');
      return false;
    }
  }

  // Get advertisements count
  static Future<int> getAdvertisementsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting advertisements count: $e');
      return 0;
    }
  }

  // Get advertisement by ID
  static Future<Advertisement?> getAdvertisementById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Advertisement.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting advertisement by ID: $e');
      return null;
    }
  }

  // Listen to advertisements changes (for admin dashboard)
  static Stream<List<Advertisement>> getAdvertisementsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Advertisement.fromFirestore(doc))
          .toList();
    });
  }

  // Check if advertisements collection exists and has data
  static Future<bool> hasAdvertisements() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking advertisements existence: $e');
      return false;
    }
  }

  // Get advertisements statistics
  static Future<Map<String, int>> getAdvertisementStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      
      int totalAds = snapshot.docs.length;
      int activeAds = 0;
      int totalViews = 0;
      int totalClicks = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isActive'] == true) activeAds++;
        totalViews += (data['views'] as int? ?? 0);
        totalClicks += (data['clickCount'] as int? ?? 0);
      }

      return {
        'total': totalAds,
        'active': activeAds,
        'views': totalViews,
        'clicks': totalClicks,
      };
    } catch (e) {
      print('Error getting advertisement stats: $e');
      return {
        'total': 0,
        'active': 0,
        'views': 0,
        'clicks': 0,
      };
    }
  }
}
