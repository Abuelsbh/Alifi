import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase/firebase_config.dart';
import '../../Models/pet_report_model.dart';
import 'auth_service.dart';
import 'location_service.dart';


class PetReportsService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final FirebaseStorage _storage = FirebaseConfig.storage;
  static final ImagePicker _picker = ImagePicker();

  // Get lost pets stream - Enhanced Real-time
  static Stream<List<Map<String, dynamic>>> getLostPetsStream() {
    print('📱 Starting real-time lost pets stream');
    
    // If in demo mode, return empty list (no mock animals)
    if (FirebaseConfig.isDemoMode) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('lost_pets')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit for performance
        .snapshots()
        .map((snapshot) {
          print('📱 Real-time update: ${snapshot.docs.length} lost pets received');
          final isAdmin = AuthService.isAdmin;
          final userEmail = AuthService.userEmail ?? 'no email';
          // Get user's selected location
          final userLocationId = LocationService.getUserLocation();
          print('👤 User check - Is Admin: $isAdmin, Email: $userEmail, Location: $userLocationId');
          return snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isActive'] != true) {
                  print('❌ Pet ${doc.id} is not active');
                  return false;
                }
                // Admin can see all, regular users only see approved
                if (!isAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  print('📋 Lost pet ${doc.id} approvalStatus: "$approvalStatus" (type: ${approvalStatus.runtimeType})');
                  // Only show approved reports - reject null, pending, and rejected
                  final isApproved = approvalStatus == 'approved';
                  if (!isApproved) {
                    print('❌ REJECTING lost pet ${doc.id} - status: "$approvalStatus" (not approved)');
                    return false;
                  }
                  print('✅ APPROVING lost pet ${doc.id} - status: "$approvalStatus"');
                  
                  // Filter by location if user has selected a location
                  if (userLocationId != null && userLocationId.isNotEmpty) {
                    final reportLocationId = data['location']?['locationId'] as String? ?? '';
                    // If report has no location specified, show to all (backward compatibility)
                    // If report has location, check if it matches user's location
                    if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                      print('❌ REJECTING lost pet ${doc.id} - location mismatch: report="$reportLocationId", user="$userLocationId"');
                      return false;
                    }
                    print('✅ Location match for lost pet ${doc.id}: "$reportLocationId"');
                  }
                }
                print('✅ Admin: showing pet ${doc.id}');
                return true; // Admin sees all (pending + approved)
              })
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Final safety check: ensure only approved reports for non-admins
                final isAdmin = AuthService.isAdmin;
                if (!isAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  if (approvalStatus != 'approved') {
                    print('⚠️ FINAL CHECK: Lost pet ${doc.id} has status "$approvalStatus" - REMOVING');
                    return null;
                  }
                  // Final location check
                  final userLocationId = LocationService.getUserLocation();
                  if (userLocationId != null && userLocationId.isNotEmpty) {
                    final reportLocationId = data['location']?['locationId'] as String? ?? '';
                    if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                      print('⚠️ FINAL CHECK: Lost pet ${doc.id} location mismatch - REMOVING');
                      return null;
                    }
                  }
                }
                return {
                  ...data,
                  'id': doc.id,
                };
              })
              .where((pet) => pet != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
  }

  // Get found pets stream - Enhanced Real-time
  static Stream<List<Map<String, dynamic>>> getFoundPetsStream() {
    print('📱 Starting real-time found pets stream');
    
    // If in demo mode, return empty list (no mock animals)
    if (FirebaseConfig.isDemoMode) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('found_pets')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit for performance
        .snapshots()
        .map((snapshot) {
          print('📱 Real-time update: ${snapshot.docs.length} found pets received');
          final isAdmin = AuthService.isAdmin;
          final userEmail = AuthService.userEmail ?? 'no email';
          // Get user's selected location
          final userLocationId = LocationService.getUserLocation();
          print('👤 User check - Is Admin: $isAdmin, Email: $userEmail, Location: $userLocationId');
          return snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['isActive'] != true) {
                  print('❌ Found pet ${doc.id} is not active');
                  return false;
                }
                // Admin can see all, regular users only see approved
                if (!isAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  print('📋 Found pet ${doc.id} approvalStatus: "$approvalStatus" (type: ${approvalStatus.runtimeType})');
                  // Only show approved reports - reject null, pending, and rejected
                  final isApproved = approvalStatus == 'approved';
                  if (!isApproved) {
                    print('❌ REJECTING found pet ${doc.id} - status: "$approvalStatus" (not approved)');
                    return false;
                  }
                  print('✅ APPROVING found pet ${doc.id} - status: "$approvalStatus"');
                  
                  // Filter by location if user has selected a location
                  if (userLocationId != null && userLocationId.isNotEmpty) {
                    final reportLocationId = data['location']?['locationId'] as String? ?? '';
                    // If report has no location specified, show to all (backward compatibility)
                    // If report has location, check if it matches user's location
                    if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                      print('❌ REJECTING found pet ${doc.id} - location mismatch: report="$reportLocationId", user="$userLocationId"');
                      return false;
                    }
                    print('✅ Location match for found pet ${doc.id}: "$reportLocationId"');
                  }
                }
                print('✅ Admin: showing found pet ${doc.id}');
                return true; // Admin sees all (pending + approved)
              })
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Double check: ensure only approved reports for non-admins
                if (!isAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  if (approvalStatus != 'approved') {
                    print('⚠️ WARNING: Found pet ${doc.id} passed filter but status is "$approvalStatus" - removing it');
                    return null; // This will be filtered out
                  }
                  // Final location check
                  final userLocationId = LocationService.getUserLocation();
                  if (userLocationId != null && userLocationId.isNotEmpty) {
                    final reportLocationId = data['location']?['locationId'] as String? ?? '';
                    if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                      print('⚠️ FINAL CHECK: Found pet ${doc.id} location mismatch - REMOVING');
                      return null;
                    }
                  }
                }
                return {
                  ...data,
                  'id': doc.id,
                };
              })
              .where((pet) => pet != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
  }

  // Get user's reports - Enhanced with both lost and found
  static Stream<List<Map<String, dynamic>>> getUserReportsStream(String userId) {
    print('📱 Starting real-time user reports stream for: $userId');

    final lostStream = _firestore
        .collection('lost_pets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final foundStream = _firestore
        .collection('found_pets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    late QuerySnapshot lastLost;
    late QuerySnapshot lastFound;
    var haveLost = false;
    var haveFound = false;
    StreamSubscription? lostSub;
    StreamSubscription? foundSub;

    late final StreamController<List<Map<String, dynamic>>> streamCtrl;

    void emitMerged() {
      if (!haveLost || !haveFound) return;
      if (streamCtrl.isClosed) return;

      final reports = <Map<String, dynamic>>[];

      for (final doc in lastLost.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        data['type'] = 'lost';
        reports.add(data);
      }
      for (final doc in lastFound.docs) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['id'] = doc.id;
        data['type'] = 'found';
        reports.add(data);
      }

      reports.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      print('📱 User reports update: ${reports.length} reports for user');
      streamCtrl.add(reports);
    }

    streamCtrl = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        lostSub = lostStream.listen(
          (snap) {
            lastLost = snap;
            haveLost = true;
            emitMerged();
          },
          onError: (e, st) => streamCtrl.addError(e, st),
        );
        foundSub = foundStream.listen(
          (snap) {
            lastFound = snap;
            haveFound = true;
            emitMerged();
          },
          onError: (e, st) => streamCtrl.addError(e, st),
        );
      },
      onCancel: () {
        lostSub?.cancel();
        foundSub?.cancel();
        lostSub = null;
        foundSub = null;
      },
    );

    return streamCtrl.stream;
  }

  /// All animals added by user: lost, found, adoption, breeding.
  /// Returns List<Map> with 'type' (lost|found|adoption|breeding), 'collection', 'id'.
  /// Uses where('userId') only (no orderBy) to avoid composite index; sorts in app.
  static Stream<List<Map<String, dynamic>>> getUserAllAnimalsStream(String userId) {
    print('📱 Starting user all-animals stream: $userId');

    final lostStream = _firestore
        .collection('lost_pets')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return lostStream.asyncMap((lostSnap) async {
      // Create fresh queries each time (cannot reuse .first() on same stream).
      final foundSnap = await _firestore
          .collection('found_pets')
          .where('userId', isEqualTo: userId)
          .get();
      final adoptionSnap = await _firestore
          .collection('adoption_pets')
          .where('userId', isEqualTo: userId)
          .get();
      final breedingSnap = await _firestore
          .collection('breeding_pets')
          .where('userId', isEqualTo: userId)
          .get();

      final list = <Map<String, dynamic>>[];

      for (var d in lostSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        data['type'] = 'lost';
        data['collection'] = 'lost_pets';
        list.add(data);
      }
      for (var d in foundSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        data['type'] = 'found';
        data['collection'] = 'found_pets';
        list.add(data);
      }
      for (var d in adoptionSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        if (data['isActive'] == false) continue;
        data['id'] = d.id;
        data['type'] = 'adoption';
        data['collection'] = 'adoption_pets';
        list.add(data);
      }
      for (var d in breedingSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        if (data['isActive'] == false) continue;
        data['id'] = d.id;
        data['type'] = 'breeding';
        data['collection'] = 'breeding_pets';
        list.add(data);
      }

      list.sort((a, b) {
        final aT = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bT = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bT.compareTo(aT);
      });

      print('📱 User all-animals update: ${list.length} (lost: ${lostSnap.docs.length}, found: ${foundSnap.docs.length}, adoption: ${adoptionSnap.docs.length}, breeding: ${breedingSnap.docs.length})');
      return list;
    });
  }

  // Search pets by filters
  static Stream<List<Map<String, dynamic>>> searchPets({
    required String type, // 'lost' or 'found' 
    String? petType,
    String? breed,
    String? area,
    String? color,
  }) {
    print('🔍 Searching $type pets with filters');
    
    Query query = _firestore
        .collection('${type}_pets')
        .orderBy('createdAt', descending: true)
        .limit(30);
    
    return query
        .snapshots()
        .map((snapshot) {
          final isAdmin = AuthService.isAdmin;
          final results = snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Filter for active pets
                if (data['isActive'] != true) return false;
                // Admin can see all, regular users only see approved
                if (!isAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  // Only show approved reports - reject null, pending, and rejected
                  if (approvalStatus != 'approved') {
                    print('❌ REJECTING ${type} pet ${doc.id} in search - status: "$approvalStatus" (not approved)');
                    return false;
                  }
                  print('✅ APPROVING ${type} pet ${doc.id} in search - status: "$approvalStatus"');
                }
                
                // Filter by pet type
                if (petType != null && petType.isNotEmpty) {
                  final docPetType = data['petDetails']?['type']?.toString() ?? '';
                  if (docPetType != petType) return false;
                }
                
                // Filter by area
                if (area != null && area.isNotEmpty) {
                  final docArea = data['location']?['area']?.toString() ?? '';
                  if (docArea != area) return false;
                }
                
                return true;
              })
              .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
              .where((pet) {
                // Additional filtering for breed and color
                if (breed != null && breed.isNotEmpty) {
                  final petBreed = pet['petDetails']?['breed']?.toString().toLowerCase() ?? '';
                  if (!petBreed.contains(breed.toLowerCase())) return false;
                }
                
                if (color != null && color.isNotEmpty) {
                  final petColor = pet['petDetails']?['color']?.toString().toLowerCase() ?? '';
                  if (!petColor.contains(color.toLowerCase())) return false;
                }
                
                return true;
              })
              .toList();
              
          print('🔍 Search results: ${results.length} pets found');
          return results;
        });
  }

  // Create lost pet report - Enhanced
  static Future<String> createLostPetReport({
    required Map<String, dynamic> report,
    required List<File> images,
  }) async {
    try {
      print('📤 Creating lost pet report for user: ${report['userId']}');
      
      // Upload images with progress
      final imageUrls = await _uploadImages(images, 'lost_pets');
      print('📷 Uploaded ${imageUrls.length} images for lost pet report');

      // Create comprehensive report data
      final reportData = Map<String, dynamic>.from(report);
      reportData.addAll({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'approvalStatus': 'pending', // New: requires admin approval
        'status': 'lost',
        'type': 'lost_pet',
        'viewCount': 0,
        'shareCount': 0,
        'helpCount': 0,
        'isUrgent': report['isUrgent'] ?? false,
        'reward': report['reward'] ?? 0,
        'contactInfo': {
          'phone': report['contactPhone'] ?? '',
          'email': report['contactEmail'] ?? '',
          'preferredContact': report['preferredContact'] ?? 'phone',
        },
        'location': {
          'address': report['lastSeenLocation'] ?? report['address'] ?? '',
          'coordinates': report['coordinates'] ?? null,
          'area': report['area'] ?? '',
          'landmark': report['landmark'] ?? '',
          'locationId': report['locationId'] ?? '', // User's selected location ID
        },
        'petDetails': {
          'name': report['petName'] ?? '',
          'type': report['petType'] ?? '',
          'breed': report['breed'] ?? '',
          'age': report['age'] ?? '',
          'gender': report['gender'] ?? '',
          'color': report['color'] ?? '',
          'size': report['size'] ?? '',
          'distinguishingMarks': report['distinguishingMarks'] ?? '',
          'personality': report['personality'] ?? '',
          'medicalConditions': report['medicalConditions'] ?? '',
        },
      });

      // Add to Firestore
      final docRef = await _firestore
          .collection('lost_pets')
          .add(reportData);

      print('✅ Lost pet report created successfully: ${docRef.id}');

      // Update user's reports count
      await _updateUserReports(report['userId'], docRef.id, 'lost');

      return docRef.id;
    } catch (e) {
      print('❌ Error creating lost pet report: $e');
      throw Exception('Failed to create lost pet report: $e');
    }
  }

  // Create found pet report - Enhanced
  static Future<String> createFoundPetReport({
    required Map<String, dynamic> report,
    required List<File> images,
  }) async {
    try {
      print('📤 Creating found pet report for user: ${report['userId']}');
      
      // Upload images with progress
      final imageUrls = await _uploadImages(images, 'found_pets');
      print('📷 Uploaded ${imageUrls.length} images for found pet report');

      // Create comprehensive report data
      final reportData = Map<String, dynamic>.from(report);
      reportData.addAll({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'approvalStatus': 'pending', // New: requires admin approval
        'status': 'found',
        'type': 'found_pet',
        'viewCount': 0,
        'shareCount': 0,
        'helpCount': 0,
        'isInShelter': report['isInShelter'] ?? false,
        'shelterInfo': report['shelterInfo'] ?? '',
        'contactInfo': {
          'phone': report['contactPhone'] ?? '',
          'email': report['contactEmail'] ?? '',
          'preferredContact': report['preferredContact'] ?? 'phone',
        },
        'location': {
          'address': report['foundLocation'] ?? report['address'] ?? '',
          'coordinates': report['coordinates'] ?? null,
          'area': report['area'] ?? '',
          'landmark': report['landmark'] ?? '',
          'locationId': report['locationId'] ?? '', // User's selected location ID
        },
        'petDetails': {
          'type': report['petType'] ?? '',
          'breed': report['breed'] ?? '',
          'approximateAge': report['approximateAge'] ?? '',
          'gender': report['gender'] ?? '',
          'color': report['color'] ?? '',
          'size': report['size'] ?? '',
          'distinguishingMarks': report['distinguishingMarks'] ?? '',
          'temperament': report['temperament'] ?? '',
          'healthStatus': report['healthStatus'] ?? '',
          'hasCollar': report['hasCollar'] ?? false,
          'collarDescription': report['collarDescription'] ?? '',
        },
      });

      // Add to Firestore
      final docRef = await _firestore
          .collection('found_pets')
          .add(reportData);

      print('✅ Found pet report created successfully: ${docRef.id}');

      // Update user's reports count
      await _updateUserReports(report['userId'], docRef.id, 'found');

      return docRef.id;
    } catch (e) {
      print('❌ Error creating found pet report: $e');
      throw Exception('Failed to create found pet report: $e');
    }
  }

  // Create adoption pet report - New
  static Future<String> createAdoptionPetReport({
    required Map<String, dynamic> report,
    required List<File> images,
  }) async {
    try {
      print('📤 Creating adoption pet report for user: ${report['userId']}');
      
      // Upload images with progress
      final imageUrls = await _uploadImages(images, 'adoption_pets');
      print('📷 Uploaded ${imageUrls.length} images for adoption pet report');

      // Create comprehensive report data
      final reportData = Map<String, dynamic>.from(report);
      reportData.addAll({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'approvalStatus': 'pending', // New: requires admin approval
        'status': 'adoption',
        'type': 'adoption_pet',
        'viewCount': 0,
        'shareCount': 0,
        'interestCount': 0,
        'adoptionFee': report['adoptionFee'] ?? 0.0,
        'reason': report['reason'] ?? '',
        'specialNeeds': report['specialNeeds'] ?? '',
        'contactInfo': {
          'name': report['contactName'] ?? '',
          'phone': report['contactPhone'] ?? '',
          'email': report['contactEmail'] ?? '',
          'preferredContact': report['preferredContact'] ?? 'phone',
        },
        'location': {
          'address': report['address'] ?? '',
          'coordinates': report['coordinates'] ?? null,
          'area': report['area'] ?? '',
          'landmark': report['landmark'] ?? '',
          'locationId': report['locationId'] ?? '', // User's selected location ID
        },
        'petDetails': {
          'name': report['petName'] ?? '',
          'type': report['petType'] ?? '',
          'breed': report['breed'] ?? '',
          'age': report['age'] ?? 0,
          'gender': report['gender'] ?? '',
          'color': report['color'] ?? '',
          'weight': report['weight'] ?? 0.0,
          'description': report['description'] ?? '',
          'temperament': report['temperament'] ?? '',
          'healthStatus': report['healthStatus'] ?? '',
          'isVaccinated': report['isVaccinated'] ?? false,
          'isNeutered': report['isNeutered'] ?? false,
          'microchipId': report['microchipId'] ?? '',
          'medicalHistory': report['medicalHistory'] ?? [],
        },
        'adoptionRequirements': {
          'goodWithKids': report['goodWithKids'] ?? true,
          'goodWithPets': report['goodWithPets'] ?? true,
          'isHouseTrained': report['isHouseTrained'] ?? false,
          'preferredHomeType': report['preferredHomeType'] ?? '',
        },
        'adoptionType': report['adoptionType'] ?? 'offering', // 'seeking' or 'offering'
      });

      // Add to Firestore
      final docRef = await _firestore
          .collection('adoption_pets')
          .add(reportData);

      print('✅ Adoption pet report created successfully: ${docRef.id}');

      // Update user's reports count
      await _updateUserReports(report['userId'], docRef.id, 'adoption');

      return docRef.id;
    } catch (e) {
      print('❌ Error creating adoption pet report: $e');
      throw Exception('Failed to create adoption pet report: $e');
    }
  }

  // Get adoption pets stream - New
  static Stream<List<Map<String, dynamic>>> getAdoptionPetsStream() {
    print('📱 Starting real-time adoption pets stream');
    
    // Use simple query without any compound index requirement
    return _firestore
        .collection('adoption_pets')
        .limit(50) // Simple limit only
        .snapshots()
        .map((snapshot) {
          print('📱 Real-time update: ${snapshot.docs.length} adoption pets received');
          
          // Filter and sort manually in app
          final isAdmin = AuthService.isAdmin;
          final userEmail = AuthService.userEmail ?? 'no email';
          // Get user's selected location
          final userLocationId = LocationService.getUserLocation();
          print('👤 User check - Is Admin: $isAdmin, Email: $userEmail, Location: $userLocationId');
          final docs = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isActive'] != true) return false;
            // Admin can see all, regular users only see approved
            if (!isAdmin) {
              final approvalStatus = data['approvalStatus'];
              // Only show approved reports - reject null, pending, and rejected
              if (approvalStatus != 'approved') {
                print('❌ REJECTING adoption pet ${doc.id} - status: "$approvalStatus" (not approved)');
                return false;
              }
              print('✅ APPROVING adoption pet ${doc.id} - status: "$approvalStatus"');
              
              // Filter by location if user has selected a location
              if (userLocationId != null && userLocationId.isNotEmpty) {
                final reportLocationId = data['location']?['locationId'] as String? ?? '';
                // If report has no location specified, show to all (backward compatibility)
                // If report has location, check if it matches user's location
                if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                  print('❌ REJECTING adoption pet ${doc.id} - location mismatch: report="$reportLocationId", user="$userLocationId"');
                  return false;
                }
                print('✅ Location match for adoption pet ${doc.id}: "$reportLocationId"');
              }
            }
            return true; // Admin sees all (pending + approved)
          }).toList();
          
          // Sort by createdAt manually
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime); // Descending order (newest first)
          });
          
          return docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Final safety check: ensure only approved reports for non-admins
                final currentIsAdmin = AuthService.isAdmin;
                if (!currentIsAdmin) {
                  final approvalStatus = data['approvalStatus'];
                  if (approvalStatus != 'approved') {
                    print('⚠️ FINAL CHECK: Adoption pet ${doc.id} has status "$approvalStatus" - REMOVING');
                    return null; // This will be filtered out
                  }
                  // Final location check
                  final userLocationId = LocationService.getUserLocation();
                  if (userLocationId != null && userLocationId.isNotEmpty) {
                    final reportLocationId = data['location']?['locationId'] as String? ?? '';
                    if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                      print('⚠️ FINAL CHECK: Adoption pet ${doc.id} location mismatch - REMOVING');
                      return null;
                    }
                  }
                  print('✅ FINAL CHECK: Adoption pet ${doc.id} is approved - KEEPING');
                }
                return {
                  ...data,
                  'id': doc.id,
                };
              })
              .where((pet) => pet != null)
              .cast<Map<String, dynamic>>()
              .toList();
        });
  }

  // Get adoption pets count only
  static Future<int> getAdoptionPetsCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('adoption_pets')
          .limit(100) // Get more to count active ones
          .get();
      
      // Count only active pets
      final activePets = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }).toList();
      
      return activePets.length;
    } catch (e) {
      print('❌ Error getting adoption pets count: $e');
      return 0;
    }
  }

  // Update report
  static Future<void> updateReport({
    required String reportId,
    required String collection,
    required Map<String, dynamic> updates,
    List<File>? newImages,
  }) async {
    try {
      final reportData = Map<String, dynamic>.from(updates);
      reportData['updatedAt'] = FieldValue.serverTimestamp();

      // Upload new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        final imageUrls = await _uploadImages(newImages, collection);
        reportData['imageUrls'] = imageUrls;
      }

      await _firestore
          .collection(collection)
          .doc(reportId)
          .update(reportData);
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  // Delete report (soft delete - sets isActive to false)
  static Future<void> deleteReport({
    required String reportId,
    required String collection,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(reportId)
          .update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Permanently delete report from database (Admin only)
  static Future<void> permanentlyDeleteReport({
    required String reportId,
    required String collection,
  }) async {
    try {
      print('🗑️ Permanently deleting report: $reportId from $collection');
      
      // Get the report first to access image URLs for deletion
      final doc = await _firestore.collection(collection).doc(reportId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
        
        // Delete images from Firebase Storage
        for (String imageUrl in imageUrls) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
            print('✅ Deleted image: $imageUrl');
          } catch (e) {
            print('⚠️ Warning: Could not delete image: $e');
            // Continue even if image deletion fails
          }
        }
        
        // Permanently delete the document
        await _firestore.collection(collection).doc(reportId).delete();
        print('✅ Report permanently deleted: $reportId');
      } else {
        throw Exception('Report not found');
      }
    } catch (e) {
      print('❌ Error permanently deleting report: $e');
      throw Exception('Failed to permanently delete report: $e');
    }
  }

  // Approve report (Admin only)
  static Future<void> approveReport({
    required String reportId,
    required String collection,
  }) async {
    try {
      print('🔍 Approving report in service:');
      print('   reportId: $reportId');
      print('   collection: $collection');
      
      // Verify document exists first
      final docRef = _firestore.collection(collection).doc(reportId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print('❌ Document does not exist: $collection/$reportId');
        throw Exception('Document not found: $collection/$reportId');
      }
      
      await docRef.update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Report approved successfully: $reportId');
    } catch (e) {
      print('❌ Error approving report: $e');
      throw Exception('Failed to approve report: $e');
    }
  }

  // Reject report (Admin only)
  static Future<void> rejectReport({
    required String reportId,
    required String collection,
  }) async {
    try {
      print('🔍 Rejecting report in service:');
      print('   reportId: $reportId');
      print('   collection: $collection');
      
      // Verify document exists first
      final docRef = _firestore.collection(collection).doc(reportId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print('❌ Document does not exist: $collection/$reportId');
        throw Exception('Document not found: $collection/$reportId');
      }
      
      await docRef.update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Report rejected successfully: $reportId');
    } catch (e) {
      print('❌ Error rejecting report: $e');
      throw Exception('Failed to reject report: $e');
    }
  }

  // Delete all reports (Admin only)
  static Future<void> deleteAllReports() async {
    try {
      print('🔍 Deleting all reports...');
      
      final collections = ['lost_pets', 'found_pets', 'adoption_pets', 'breeding_pets'];
      int totalDeleted = 0;
      const int batchLimit = 500; // Firestore batch limit
      
      for (final collectionName in collections) {
        Query? query = _firestore
            .collection(collectionName)
            .where('isActive', isEqualTo: true)
            .limit(batchLimit);
        
        QuerySnapshot snapshot = await query.get();
        
        // Process in batches if there are more than batchLimit documents
        while (snapshot.docs.isNotEmpty) {
          // Create batch for current set of documents
          WriteBatch batch = _firestore.batch();
          
          for (final doc in snapshot.docs) {
            batch.update(doc.reference, {
              'isActive': false,
              'deletedAt': FieldValue.serverTimestamp(),
            });
          }
          
          await batch.commit();
          totalDeleted += snapshot.docs.length;
          print('✅ Deleted ${snapshot.docs.length} reports from $collectionName');
          
          // If we got exactly batchLimit documents, there might be more
          if (snapshot.docs.length == batchLimit) {
            // Get next batch using the last document as cursor
            final lastDoc = snapshot.docs.last;
            query = _firestore
                .collection(collectionName)
                .where('isActive', isEqualTo: true)
                .startAfterDocument(lastDoc)
                .limit(batchLimit);
            snapshot = await query.get();
          } else {
            // No more documents
            break;
          }
        }
      }
      
      print('✅ Successfully deleted $totalDeleted reports in total');
    } catch (e) {
      print('❌ Error deleting all reports: $e');
      throw Exception('Failed to delete all reports: $e');
    }
  }

  // Get all reports for admin (including pending and inactive)
  static Stream<List<Map<String, dynamic>>> getAllReportsForAdmin() {
    print('📱 Starting admin reports stream');
    
    final collections = ['lost_pets', 'found_pets', 'adoption_pets', 'breeding_pets'];
    
    // Create a stream for each collection
    final streams = collections.map((collectionName) {
      return _firestore
          .collection(collectionName)
          .limit(50)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // IMPORTANT: Put ...data first, then override with doc.id and collection
                  // This ensures we use the actual Firestore document ID, not the 'id' field from data
                  // Include ALL reports (active and inactive) for admin
                  return {
                    ...data,
                    'id': doc.id, // Override any 'id' field from data with actual Firestore doc.id
                    'collection': collectionName, // Override any 'collection' field from data
                    'type': collectionName.replaceAll('_pets', ''),
                  };
                })
                .toList();
          });
    });

    // Use a timer-based approach to combine streams
    StreamController<List<Map<String, dynamic>>>? controller;
    Timer? timer;
    final subscriptions = <StreamSubscription>[];

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        final allReports = <Map<String, dynamic>>[];
        
        // Subscribe to all streams
        for (var i = 0; i < streams.length; i++) {
          final subscription = streams.elementAt(i).listen(
            (reports) {
              // Update reports for this collection
              allReports.removeWhere((r) => r['collection'] == collections[i]);
              allReports.addAll(reports);
              
              // Sort by creation date
              allReports.sort((a, b) {
                try {
                  final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return bTime.compareTo(aTime);
                } catch (e) {
                  return 0;
                }
              });
              
              if (controller != null && !controller!.isClosed) {
                controller!.add(List.from(allReports));
              }
            },
            onError: (error) {
              print('❌ Error in admin reports stream: $error');
            },
          );
          subscriptions.add(subscription);
        }
      },
      onCancel: () {
        timer?.cancel();
        for (var subscription in subscriptions) {
          subscription.cancel();
        }
        controller?.close();
      },
    );

    return controller.stream;
  }

  // Mark report as resolved
  static Future<void> markReportAsResolved({
    required String reportId,
    required String collection,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(reportId)
          .update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark report as resolved: $e');
    }
  }

  // Search reports
  static Future<List<Map<String, dynamic>>> searchReports({
    required String collection,
    String? petType,
    String? breed,
    String? location,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore
          .collection(collection)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      List<Map<String, dynamic>> reports = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Filter for active reports
            if (data['isActive'] != true) return false;
            
            // Filter by pet type
            if (petType != null && petType.isNotEmpty) {
              if (data['petType'] != petType) return false;
            }
            
            // Filter by breed
            if (breed != null && breed.isNotEmpty) {
              if (data['breed'] != breed) return false;
            }
            
            return true;
          })
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Filter by location and search query
      if (location != null && location.isNotEmpty) {
        reports = reports.where((report) =>
            (report['location'] as String?)?.toLowerCase().contains(location.toLowerCase()) ?? false).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        reports = reports.where((report) {
          final petName = report['petName'] as String?;
          final description = report['description'] as String?;
          final breed = report['breed'] as String?;
          
          return (petName?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                 (description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                 (breed?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        }).toList();
      }

      return reports;
    } catch (e) {
      throw Exception('Failed to search reports: $e');
    }
  }

  // Get report by ID
  static Future<Map<String, dynamic>?> getReportById({
    required String reportId,
    required String collection,
  }) async {
    try {
      final doc = await _firestore
          .collection(collection)
          .doc(reportId)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  // Pick images from gallery
  static Future<List<File>> pickImagesFromGallery({
    int maxImages = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.length > maxImages) {
        images.removeRange(maxImages, images.length);
      }

      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick images: $e');
    }
  }

  // Take photo with camera
  static Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload images to Firebase Storage
  static Future<List<String>> _uploadImages(
    List<File> images,
    String folder,
  ) async {
    try {
      final List<String> imageUrls = [];
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${folder}_${timestamp}_$i.jpg';
        final ref = _storage.ref().child('pet_reports/$folder/$fileName');

        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Update user's reports
  static Future<void> _updateUserReports(
    String userId,
    String reportId,
    String type,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'reports': FieldValue.arrayUnion([
          {
            'reportId': reportId,
            'type': type,
            'createdAt': FieldValue.serverTimestamp(),
          }
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw error for this, as it's not critical
      print('Failed to update user reports: $e');
    }
  }

  // Get nearby reports based on location
  static Future<List<Map<String, dynamic>>> getNearbyReports({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String collection,
  }) async {
    try {
      // This is a simplified version. In a real app, you'd use GeoFirestore
      // or implement proper geospatial queries
      final snapshot = await _firestore
          .collection(collection)
          .orderBy('createdAt', descending: true)
          .get();

      final reports = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] == true;
          })
          .map((doc) => doc.data())
          .toList();

      // Filter by distance (simplified)
      return reports.where((report) {
        final reportLat = report['latitude'] as double?;
        final reportLng = report['longitude'] as double?;
        if (reportLat == null || reportLng == null) return false;
        
        final distance = _calculateDistance(
          latitude,
          longitude,
          reportLat,
          reportLng,
        );
        
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get nearby reports: $e');
    }
  }

  // Calculate distance between two points (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get report statistics
  static Future<Map<String, dynamic>> getReportStatistics() async {
    try {
      final lostSnapshot = await _firestore
          .collection('lost_pets')
          .get();

      final foundSnapshot = await _firestore
          .collection('found_pets')
          .get();

      final resolvedLostSnapshot = await _firestore
          .collection('lost_pets')
          .where('isResolved', isEqualTo: true)
          .get();

      final resolvedFoundSnapshot = await _firestore
          .collection('found_pets')
          .where('isResolved', isEqualTo: true)
          .get();

      // Filter active reports
      final activeLostCount = lostSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true)
          .length;
      final activeFoundCount = foundSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true)
          .length;

      return {
        'totalLost': activeLostCount,
        'totalFound': activeFoundCount,
        'resolvedLost': resolvedLostSnapshot.docs.length,
        'resolvedFound': resolvedFoundSnapshot.docs.length,
        'totalActive': activeLostCount + activeFoundCount,
        'totalResolved': resolvedLostSnapshot.docs.length + resolvedFoundSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Mark report as resolved
  // static Future<void> markReportAsResolved({
  //   required String reportId,
  //   required String collection,
  // }) async {
  //   try {
  //     await _firestore.collection(collection).doc(reportId).update({
  //       'isResolved': true,
  //       'isActive': false,
  //       'resolvedAt': FieldValue.serverTimestamp(),
  //       'updatedAt': FieldValue.serverTimestamp(),
  //     });
  //
  //     print('✅ Report marked as resolved successfully');
  //   } catch (e) {
  //     print('❌ Error marking report as resolved: $e');
  //     throw Exception('Failed to mark report as resolved: $e');
  //   }
  // }

  // Delete report
  // static Future<void> deleteReport({
  //   required String reportId,
  //   required String collection,
  // }) async {
  //   try {
  //     // Get the report first to access image URLs for deletion
  //     final doc = await _firestore.collection(collection).doc(reportId).get();
  //
  //     if (doc.exists) {
  //       final data = doc.data() as Map<String, dynamic>;
  //       final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
  //
  //       // Delete images from Firebase Storage
  //       for (String imageUrl in imageUrls) {
  //         try {
  //           final ref = _storage.refFromURL(imageUrl);
  //           await ref.delete();
  //         } catch (e) {
  //           print('Warning: Could not delete image: $e');
  //           // Continue even if image deletion fails
  //         }
  //       }
  //
  //       // Delete the document
  //       await _firestore.collection(collection).doc(reportId).delete();
  //       print('✅ Report deleted successfully');
  //     }
  //   } catch (e) {
  //     print('❌ Error deleting report: $e');
  //     throw Exception('Failed to delete report: $e');
  //   }
  // }

  // Get user reports stream (for My Reports screen)
  // static Stream<List<Map<String, dynamic>>> getUserReportsStream(String userId) {
  //   print('📱 Starting real-time user reports stream for user: $userId');
  //
  //   // Create a combined stream of both lost and found pets
  //   final lostStream = _firestore
  //       .collection('lost_pets')
  //       .where('userId', isEqualTo: userId)
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) {
  //             final data = doc.data();
  //             data['id'] = doc.id;
  //             data['type'] = 'lost';
  //             return data;
  //           }).toList());
  //
  //   final foundStream = _firestore
  //       .collection('found_pets')
  //       .where('userId', isEqualTo: userId)
  //       .orderBy('createdAt', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) {
  //             final data = doc.data();
  //             data['id'] = doc.id;
  //             data['type'] = 'found';
  //             return data;
  //           }).toList());
  //
  //   return lostStream.combineLatest(foundStream, (lost, found) {
  //     final combined = <Map<String, dynamic>>[];
  //     combined.addAll(lost);
  //     combined.addAll(found);
  //
  //     // Sort by creation date (most recent first)
  //     combined.sort((a, b) {
  //       final aTime = a['createdAt'] as Timestamp?;
  //       final bTime = b['createdAt'] as Timestamp?;
  //       if (aTime == null || bTime == null) return 0;
  //       return bTime.compareTo(aTime);
  //     });
  //
  //     return combined;
  //   });
  // }

  // ========================= BREEDING PETS =========================

  /// Creates a new breeding pet report
  static Future<String> createBreedingPetReport({
    required Map<String, dynamic> report,
    required List<File> images,
  }) async {
    try {
      print('📤 Creating breeding pet report for user: ${report['userId']}');
      
      // Upload images with progress
      final imageUrls = await _uploadImages(images, 'breeding_pets');
      print('📷 Uploaded ${imageUrls.length} images for breeding pet report');

      // Create comprehensive report data
      final reportData = Map<String, dynamic>.from(report);
      reportData.addAll({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'approvalStatus': 'pending', // New: requires admin approval
        'status': 'breeding',
        'type': 'breeding_pet',
        'viewCount': 0,
        'shareCount': 0,
        'interestCount': 0,
        'breedingFee': report['breedingFee'] ?? 0.0,
        'specialRequirements': report['specialRequirements'] ?? '',
        'hasBreedingExperience': report['hasBreedingExperience'] ?? false,
        'breedingHistory': report['breedingHistory'] ?? '',
        'isRegistered': report['isRegistered'] ?? false,
        'registrationNumber': report['registrationNumber'] ?? '',
        'certifications': report['certifications'] ?? [],
        'breedingGoals': report['breedingGoals'] ?? '',
        'availabilityPeriod': report['availabilityPeriod'] ?? '',
        'willTravel': report['willTravel'] ?? false,
        'maxTravelDistance': report['maxTravelDistance'] ?? 0,
        'offspring': report['offspring'] ?? '',
        'previousOffspring': report['previousOffspring'] ?? [],
        'veterinarianContact': report['veterinarianContact'] ?? '',
        'contactInfo': {
          'name': report['contactName'] ?? '',
          'phone': report['contactPhone'] ?? '',
          'email': report['contactEmail'] ?? '',
          'preferredContact': report['preferredContact'] ?? 'phone',
        },
        'petInfo': {
          'name': report['petName'] ?? '',
          'type': report['petType'] ?? '',
          'breed': report['breed'] ?? '',
          'age': report['age'] ?? 0,
          'gender': report['gender'] ?? '',
          'color': report['color'] ?? '',
          'weight': report['weight'] ?? 0.0,
          'description': report['description'] ?? '',
          'healthStatus': report['healthStatus'] ?? 'جيد',
          'temperament': report['temperament'] ?? 'ودود',
          'isVaccinated': report['isVaccinated'] ?? false,
          'isNeutered': report['isNeutered'] ?? false,
        },
        'locationInfo': {
          'coordinates': report['location'] ?? const GeoPoint(0, 0),
          'address': report['address'] ?? '',
          'area': report['area'] ?? '',
          'landmark': report['landmark'] ?? '',
          'locationId': report['locationId'] ?? '', // User's selected location ID
        },
      });

      final docRef = await _firestore.collection('breeding_pets').add(reportData);
      print('✅ Breeding pet report created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating breeding pet report: $e');
      throw Exception('فشل في إنشاء تقرير التزاوج: $e');
    }
  }

  /// Gets a stream of breeding pets
  static Stream<List<BreedingPetModel>> getBreedingPetsStream() {
    try {
      print('🔄 Setting up breeding pets stream...');
      return _firestore
          .collection('breeding_pets')
          .limit(50)
          .snapshots()
          .map((snapshot) {
        print('📊 Received ${snapshot.docs.length} breeding pets documents');
        
        // Filter and sort manually to avoid Firebase index issues
        final isAdmin = AuthService.isAdmin;
        final userEmail = AuthService.userEmail ?? 'no email';
        // Get user's selected location
        final userLocationId = LocationService.getUserLocation();
        print('👤 User check - Is Admin: $isAdmin, Email: $userEmail, Location: $userLocationId');
        final activeDocs = snapshot.docs.where((doc) {
          try {
            final data = doc.data();
            if (data['isActive'] != true) return false;
            // Admin can see all, regular users only see approved
            if (!isAdmin) {
              final approvalStatus = data['approvalStatus'];
              // Only show approved reports - reject null, pending, and rejected
              if (approvalStatus != 'approved') {
                print('❌ REJECTING breeding pet ${doc.id} - status: "$approvalStatus" (not approved)');
                return false;
              }
              print('✅ APPROVING breeding pet ${doc.id} - status: "$approvalStatus"');
              
              // Filter by location if user has selected a location
              if (userLocationId != null && userLocationId.isNotEmpty) {
                final reportLocationId = data['locationInfo']?['locationId'] as String? ?? '';
                // If report has no location specified, show to all (backward compatibility)
                // If report has location, check if it matches user's location
                if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                  print('❌ REJECTING breeding pet ${doc.id} - location mismatch: report="$reportLocationId", user="$userLocationId"');
                  return false;
                }
                print('✅ Location match for breeding pet ${doc.id}: "$reportLocationId"');
              }
            }
            return true; // Admin sees all (pending + approved)
          } catch (e) {
            print('Error filtering breeding pet doc ${doc.id}: $e');
            return false;
          }
        }).toList();

        // Sort by createdAt manually
        activeDocs.sort((a, b) {
          try {
            final aData = a.data();
            final bData = b.data();
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          } catch (e) {
            print('Error sorting breeding pets: $e');
            return 0;
          }
        });

        // Convert to models with error handling
        final pets = <BreedingPetModel>[];
        for (final doc in activeDocs) {
          try {
            // Final safety check: ensure only approved reports for non-admins
            final isAdmin = AuthService.isAdmin;
            if (!isAdmin) {
              final data = doc.data();
              final approvalStatus = data['approvalStatus'];
              if (approvalStatus != 'approved') {
                print('⚠️ FINAL CHECK: Breeding pet ${doc.id} has status "$approvalStatus" - SKIPPING');
                continue; // Skip this pet
              }
              // Final location check
              final userLocationId = LocationService.getUserLocation();
              if (userLocationId != null && userLocationId.isNotEmpty) {
                final reportLocationId = data['locationInfo']?['locationId'] as String? ?? '';
                if (reportLocationId.isNotEmpty && reportLocationId != userLocationId) {
                  print('⚠️ FINAL CHECK: Breeding pet ${doc.id} location mismatch - SKIPPING');
                  continue; // Skip this pet
                }
              }
            }
            final pet = BreedingPetModel.fromFirestore(doc);
            pets.add(pet);
          } catch (e) {
            print('Error converting breeding pet doc ${doc.id}: $e');
          }
        }

        print('✅ Successfully converted ${pets.length} breeding pets');
        return pets;
      });
    } catch (e) {
      print('❌ Error setting up breeding pets stream: $e');
      return Stream.value([]);
    }
  }

  /// Gets count of active breeding pets
  static Future<int> getBreedingPetsCount() async {
    try {
      print('📊 Getting breeding pets count...');
      final querySnapshot = await _firestore
          .collection('breeding_pets')
          .limit(50)
          .get();

      // Filter active pets manually
      final activePets = querySnapshot.docs.where((doc) {
        try {
          final data = doc.data();
          return data['isActive'] == true;
        } catch (e) {
          print('Error filtering breeding pet for count: $e');
          return false;
        }
      }).length;

      print('✅ Found $activePets active breeding pets');
      return activePets;
    } catch (e) {
      print('❌ Error getting breeding pets count: $e');
      return 0;
    }
  }
} 