import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../../Models/location_model.dart';
import '../../Utilities/shared_preferences.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static const String _collection = 'locations';

  // Get all active locations
  static Stream<List<LocationModel>> getActiveLocationsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder', descending: false)
        .orderBy('name', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get all active locations (one-time fetch)
  static Future<List<LocationModel>> getActiveLocations() async {
    try {
      QuerySnapshot snapshot;
      
      // Try with orderBy first
      try {
        snapshot = await _firestore
            .collection(_collection)
            .where('isActive', isEqualTo: true)
            .orderBy('displayOrder', descending: false)
            .orderBy('name', descending: false)
            .get();
      } catch (e) {
        // Fallback: try with just where clause
        print('⚠️ OrderBy failed, trying simple query: $e');
        try {
          snapshot = await _firestore
              .collection(_collection)
              .where('isActive', isEqualTo: true)
              .get();
        } catch (e2) {
          // Fallback: get all and filter manually
          print('⚠️ Where query failed, getting all: $e2');
          snapshot = await _firestore.collection(_collection).get();
        }
      }

      final locations = snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .where((location) => location.isActive)
          .toList();
      
      // Sort manually if needed
      locations.sort((a, b) {
        if (a.displayOrder != b.displayOrder) {
          return a.displayOrder.compareTo(b.displayOrder);
        }
        return a.name.compareTo(b.name);
      });
      
      print('✅ Loaded ${locations.length} active locations');
      return locations;
    } catch (e) {
      print('❌ Error fetching active locations: $e');
      return [];
    }
  }

  // Get all locations (for admin)
  static Future<List<LocationModel>> getAllLocations() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('displayOrder', descending: false)
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all locations: $e');
      return [];
    }
  }

  // Get location by ID
  static Future<LocationModel?> getLocationById(String locationId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(locationId).get();
      if (doc.exists) {
        return LocationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching location by ID: $e');
      return null;
    }
  }

  // Create location (admin only)
  static Future<String?> createLocation(LocationModel location) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(location.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating location: $e');
      return null;
    }
  }

  // Update location (admin only)
  static Future<bool> updateLocation(String id, LocationModel location) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(location.toFirestore());
      return true;
    } catch (e) {
      print('Error updating location: $e');
      return false;
    }
  }

  // Delete location (admin only)
  static Future<bool> deleteLocation(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting location: $e');
      return false;
    }
  }

  // Toggle location active status (admin only)
  static Future<bool> toggleLocationStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling location status: $e');
      return false;
    }
  }

  // Cache user's selected location
  static Future<bool> saveUserLocation(String locationId) async {
    try {
      await SharedPref.setUserLocation(locationId: locationId);
      // Verify it was saved
      final saved = SharedPref.getUserLocation();
      if (saved != locationId) {
        print('⚠️ Warning: Location was not saved correctly. Expected: $locationId, Got: $saved');
        return false;
      }
      print('✅ Location saved successfully: $locationId');
      return true;
    } catch (e) {
      print('❌ Error saving user location: $e');
      return false;
    }
  }

  // Get user's selected location from cache
  static String? getUserLocation() {
    try {
      return SharedPref.getUserLocation();
    } catch (e) {
      print('❌ Error getting user location: $e');
      return null;
    }
  }

  // Get user's selected location model
  static Future<LocationModel?> getUserLocationModel() async {
    try {
      final locationId = getUserLocation();
      if (locationId != null) {
        return await getLocationById(locationId);
      }
      return null;
    } catch (e) {
      print('Error getting user location model: $e');
      return null;
    }
  }

  // Clear user's selected location
  static Future<bool> clearUserLocation() async {
    try {
      await SharedPref.clearUserLocation();
      return true;
    } catch (e) {
      print('Error clearing user location: $e');
      return false;
    }
  }

  // Check if location should be visible to user
  // Returns true if:
  // - locations array contains "all" 
  // - locations array contains the user's selected location
  // - locations array is empty or null (for backward compatibility)
  static bool shouldShowForLocation(
    List<dynamic>? locations,
    String? userLocationId,
  ) {
    if (locations == null || locations.isEmpty) {
      // Backward compatibility: if no locations specified, show to all
      return true;
    }

    // If "all" is in the list, show to everyone
    if (locations.contains('all')) {
      return true;
    }

    // If user has no location selected, don't show
    if (userLocationId == null) {
      return false;
    }

    // Check if user's location is in the list
    return locations.contains(userLocationId);
  }
}
