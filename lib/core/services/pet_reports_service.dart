import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../Models/pet_report_model.dart';

class PetReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Post a lost pet report
  Future<String> postLostPet(LostPetModel lostPet) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('lost_pets')
          .add(lostPet.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error posting lost pet: $e');
      throw Exception('Failed to post lost pet report');
    }
  }

  // Post a found pet report
  Future<String> postFoundPet(FoundPetModel foundPet) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('found_pets')
          .add(foundPet.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error posting found pet: $e');
      throw Exception('Failed to post found pet report');
    }
  }

  // Get lost pets with location filter
  Future<List<LostPetModel>> getLostPets({
    GeoPoint? userLocation,
    double radiusInKm = 50.0,
    String? petType,
    String? breed,
    bool activeOnly = true,
  }) async {
    try {
      Query query = _firestore.collection('lost_pets');

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      if (petType != null && petType.isNotEmpty) {
        query = query.where('petType', isEqualTo: petType);
      }

      if (breed != null && breed.isNotEmpty) {
        query = query.where('breed', isEqualTo: breed);
      }

      query = query.orderBy('createdAt', descending: true);

      QuerySnapshot querySnapshot = await query.get();
      List<LostPetModel> lostPets = [];

      for (DocumentSnapshot doc in querySnapshot.docs) {
        LostPetModel lostPet = LostPetModel.fromFirestore(doc);
        
        // Filter by location if user location is provided
        if (userLocation != null) {
          double distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            lostPet.location.latitude,
            lostPet.location.longitude,
          ) / 1000; // Convert to kilometers

          if (distance <= radiusInKm) {
            lostPets.add(lostPet);
          }
        } else {
          lostPets.add(lostPet);
        }
      }

      return lostPets;
    } catch (e) {
      print('Error getting lost pets: $e');
      throw Exception('Failed to get lost pets');
    }
  }

  // Get found pets with location filter
  Future<List<FoundPetModel>> getFoundPets({
    GeoPoint? userLocation,
    double radiusInKm = 50.0,
    String? petType,
    String? breed,
    bool activeOnly = true,
  }) async {
    try {
      Query query = _firestore.collection('found_pets');

      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }

      if (petType != null && petType.isNotEmpty) {
        query = query.where('petType', isEqualTo: petType);
      }

      if (breed != null && breed.isNotEmpty) {
        query = query.where('breed', isEqualTo: breed);
      }

      query = query.orderBy('createdAt', descending: true);

      QuerySnapshot querySnapshot = await query.get();
      List<FoundPetModel> foundPets = [];

      for (DocumentSnapshot doc in querySnapshot.docs) {
        FoundPetModel foundPet = FoundPetModel.fromFirestore(doc);
        
        // Filter by location if user location is provided
        if (userLocation != null) {
          double distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            foundPet.location.latitude,
            foundPet.location.longitude,
          ) / 1000; // Convert to kilometers

          if (distance <= radiusInKm) {
            foundPets.add(foundPet);
          }
        } else {
          foundPets.add(foundPet);
        }
      }

      return foundPets;
    } catch (e) {
      print('Error getting found pets: $e');
      throw Exception('Failed to get found pets');
    }
  }

  // Get user's lost pet reports
  Future<List<LostPetModel>> getUserLostPets(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('lost_pets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => LostPetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user lost pets: $e');
      throw Exception('Failed to get user lost pets');
    }
  }

  // Get user's found pet reports
  Future<List<FoundPetModel>> getUserFoundPets(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('found_pets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FoundPetModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user found pets: $e');
      throw Exception('Failed to get user found pets');
    }
  }

  // Update lost pet report
  Future<void> updateLostPet(LostPetModel lostPet) async {
    try {
      await _firestore
          .collection('lost_pets')
          .doc(lostPet.id)
          .update(lostPet.toFirestore());
    } catch (e) {
      print('Error updating lost pet: $e');
      throw Exception('Failed to update lost pet report');
    }
  }

  // Update found pet report
  Future<void> updateFoundPet(FoundPetModel foundPet) async {
    try {
      await _firestore
          .collection('found_pets')
          .doc(foundPet.id)
          .update(foundPet.toFirestore());
    } catch (e) {
      print('Error updating found pet: $e');
      throw Exception('Failed to update found pet report');
    }
  }

  // Delete lost pet report
  Future<void> deleteLostPet(String lostPetId) async {
    try {
      await _firestore.collection('lost_pets').doc(lostPetId).delete();
    } catch (e) {
      print('Error deleting lost pet: $e');
      throw Exception('Failed to delete lost pet report');
    }
  }

  // Delete found pet report
  Future<void> deleteFoundPet(String foundPetId) async {
    try {
      await _firestore.collection('found_pets').doc(foundPetId).delete();
    } catch (e) {
      print('Error deleting found pet: $e');
      throw Exception('Failed to delete found pet report');
    }
  }

  // Mark lost pet as found (deactivate)
  Future<void> markLostPetAsFound(String lostPetId) async {
    try {
      await _firestore.collection('lost_pets').doc(lostPetId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking lost pet as found: $e');
      throw Exception('Failed to mark lost pet as found');
    }
  }

  // Mark found pet as claimed (deactivate)
  Future<void> markFoundPetAsClaimed(String foundPetId) async {
    try {
      await _firestore.collection('found_pets').doc(foundPetId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking found pet as claimed: $e');
      throw Exception('Failed to mark found pet as claimed');
    }
  }

  // Get pet types for filtering
  Future<List<String>> getPetTypes() async {
    try {
      QuerySnapshot lostPetsSnapshot = await _firestore.collection('lost_pets').get();
      QuerySnapshot foundPetsSnapshot = await _firestore.collection('found_pets').get();

      Set<String> petTypes = {};

      // Add pet types from lost pets
      for (DocumentSnapshot doc in lostPetsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['petType'] != null) {
          petTypes.add(data['petType']);
        }
      }

      // Add pet types from found pets
      for (DocumentSnapshot doc in foundPetsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['petType'] != null) {
          petTypes.add(data['petType']);
        }
      }

      return petTypes.toList()..sort();
    } catch (e) {
      print('Error getting pet types: $e');
      return ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Hamster', 'Other'];
    }
  }

  // Get breeds for filtering
  Future<List<String>> getBreeds({String? petType}) async {
    try {
      Query query = _firestore.collection('lost_pets');
      if (petType != null && petType.isNotEmpty) {
        query = query.where('petType', isEqualTo: petType);
      }

      QuerySnapshot querySnapshot = await query.get();
      Set<String> breeds = {};

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['breed'] != null) {
          breeds.add(data['breed']);
        }
      }

      return breeds.toList()..sort();
    } catch (e) {
      print('Error getting breeds: $e');
      return [];
    }
  }
} 