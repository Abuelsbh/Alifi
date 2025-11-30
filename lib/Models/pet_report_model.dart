import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReportType {
  lost,
  found,
  adoption,
  breeding,
}

class LostPetModel extends Equatable {
  final String id;
  final String userId;
  final String petName;
  final String petType;
  final String breed;
  final int age;
  final String gender;
  final String color;
  final List<String> photos;
  final String description;
  final GeoPoint location;
  final String address;
  final DateTime lostDate;
  final String contactPhone;
  final String contactName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LostPetModel({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.age,
    required this.gender,
    required this.color,
    required this.photos,
    required this.description,
    required this.location,
    required this.address,
    required this.lostDate,
    required this.contactPhone,
    required this.contactName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LostPetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LostPetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      color: data['color'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      description: data['description'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      lostDate: (data['lostDate'] as Timestamp).toDate(),
      contactPhone: data['contactPhone'] ?? '',
      contactName: data['contactName'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'photos': photos,
      'description': description,
      'location': location,
      'address': address,
      'lostDate': Timestamp.fromDate(lostDate),
      'contactPhone': contactPhone,
      'contactName': contactName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LostPetModel.fromJson(Map<String, dynamic> json) {
    return LostPetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      petName: json['petName'] ?? '',
      petType: json['petType'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      color: json['color'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      description: json['description'] ?? '',
      location: json['location'] != null 
          ? GeoPoint(json['location']['latitude'], json['location']['longitude'])
          : const GeoPoint(0, 0),
      address: json['address'] ?? '',
      lostDate: json['lostDate'] != null 
          ? DateTime.parse(json['lostDate']) 
          : DateTime.now(),
      contactPhone: json['contactPhone'] ?? '',
      contactName: json['contactName'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'photos': photos,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'lostDate': lostDate.toIso8601String(),
      'contactPhone': contactPhone,
      'contactName': contactName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  LostPetModel copyWith({
    String? id,
    String? userId,
    String? petName,
    String? petType,
    String? breed,
    int? age,
    String? gender,
    String? color,
    List<String>? photos,
    String? description,
    GeoPoint? location,
    String? address,
    DateTime? lostDate,
    String? contactPhone,
    String? contactName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LostPetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      color: color ?? this.color,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      lostDate: lostDate ?? this.lostDate,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petName,
        petType,
        breed,
        age,
        gender,
        color,
        photos,
        description,
        location,
        address,
        lostDate,
        contactPhone,
        contactName,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class FoundPetModel extends Equatable {
  final String id;
  final String userId;
  final String petType;
  final String breed;
  final String color;
  final List<String> photos;
  final String description;
  final GeoPoint location;
  final String address;
  final DateTime foundDate;
  final String contactPhone;
  final String contactName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoundPetModel({
    required this.id,
    required this.userId,
    required this.petType,
    required this.breed,
    required this.color,
    required this.photos,
    required this.description,
    required this.location,
    required this.address,
    required this.foundDate,
    required this.contactPhone,
    required this.contactName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoundPetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FoundPetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      petType: data['petType'] ?? '',
      breed: data['breed'] ?? '',
      color: data['color'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      description: data['description'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      foundDate: (data['foundDate'] as Timestamp).toDate(),
      contactPhone: data['contactPhone'] ?? '',
      contactName: data['contactName'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petType': petType,
      'breed': breed,
      'color': color,
      'photos': photos,
      'description': description,
      'location': location,
      'address': address,
      'foundDate': Timestamp.fromDate(foundDate),
      'contactPhone': contactPhone,
      'contactName': contactName,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FoundPetModel.fromJson(Map<String, dynamic> json) {
    return FoundPetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      petType: json['petType'] ?? '',
      breed: json['breed'] ?? '',
      color: json['color'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      description: json['description'] ?? '',
      location: json['location'] != null 
          ? GeoPoint(json['location']['latitude'], json['location']['longitude'])
          : const GeoPoint(0, 0),
      address: json['address'] ?? '',
      foundDate: json['foundDate'] != null 
          ? DateTime.parse(json['foundDate']) 
          : DateTime.now(),
      contactPhone: json['contactPhone'] ?? '',
      contactName: json['contactName'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'petType': petType,
      'breed': breed,
      'color': color,
      'photos': photos,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'foundDate': foundDate.toIso8601String(),
      'contactPhone': contactPhone,
      'contactName': contactName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FoundPetModel copyWith({
    String? id,
    String? userId,
    String? petType,
    String? breed,
    String? color,
    List<String>? photos,
    String? description,
    GeoPoint? location,
    String? address,
    DateTime? foundDate,
    String? contactPhone,
    String? contactName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoundPetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petType: petType ?? this.petType,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      foundDate: foundDate ?? this.foundDate,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petType,
        breed,
        color,
        photos,
        description,
        location,
        address,
        foundDate,
        contactPhone,
        contactName,
        isActive,
        createdAt,
        updatedAt,
      ];
} 

class AdoptionPetModel extends Equatable {
  final String id;
  final String userId;
  final String petName;
  final String petType;
  final String breed;
  final int age;
  final String gender;
  final String color;
  final List<String> photos;
  final String description;
  final GeoPoint location;
  final String address;
  final String contactPhone;
  final String contactName;
  final String contactEmail;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional adoption-specific fields
  final bool isVaccinated;
  final bool isNeutered;
  final String healthStatus;
  final String temperament;
  final double weight;
  final String specialNeeds;
  final String reason;
  final double adoptionFee;
  final bool goodWithKids;
  final bool goodWithPets;
  final bool isHouseTrained;
  final String preferredHomeType;
  final List<String> medicalHistory;
  final String microchipId;
  final String adoptionType; // 'seeking' (أبحث عن حيوان) or 'offering' (أعرض حيوان للتبني)

  const AdoptionPetModel({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.age,
    required this.gender,
    required this.color,
    required this.photos,
    required this.description,
    required this.location,
    required this.address,
    required this.contactPhone,
    required this.contactName,
    this.contactEmail = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isVaccinated = false,
    this.isNeutered = false,
    this.healthStatus = 'جيد',
    this.temperament = 'ودود',
    this.weight = 0.0,
    this.specialNeeds = '',
    this.reason = '',
    this.adoptionFee = 0.0,
    this.goodWithKids = true,
    this.goodWithPets = true,
    this.isHouseTrained = false,
    this.preferredHomeType = '',
    this.medicalHistory = const [],
    this.microchipId = '',
    this.adoptionType = 'offering', // Default to offering (أعرض حيوان للتبني)
  });

  factory AdoptionPetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdoptionPetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      color: data['color'] ?? '',
      photos: List<String>.from(data['imageUrls'] ?? data['photos'] ?? []),
      description: data['description'] ?? '',
      location: _parseLocation(data['location']),
      address: data['address'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactName: data['contactName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVaccinated: data['isVaccinated'] ?? false,
      isNeutered: data['isNeutered'] ?? false,
      healthStatus: data['healthStatus'] ?? 'جيد',
      temperament: data['temperament'] ?? 'ودود',
      weight: (data['weight'] ?? 0.0).toDouble(),
      specialNeeds: data['specialNeeds'] ?? '',
      reason: data['reason'] ?? '',
      adoptionFee: (data['adoptionFee'] ?? 0.0).toDouble(),
      goodWithKids: data['goodWithKids'] ?? true,
      goodWithPets: data['goodWithPets'] ?? true,
      isHouseTrained: data['isHouseTrained'] ?? false,
      preferredHomeType: data['preferredHomeType'] ?? '',
      medicalHistory: List<String>.from(data['medicalHistory'] ?? []),
      microchipId: data['microchipId'] ?? '',
      adoptionType: data['adoptionType'] ?? 'offering',
    );
  }

  // Helper method to parse location data
  static GeoPoint _parseLocation(dynamic locationData) {
    if (locationData == null) {
      return const GeoPoint(0, 0);
    }
    
    if (locationData is GeoPoint) {
      return locationData;
    }
    
    if (locationData is Map<String, dynamic>) {
      final latitude = locationData['latitude'] ?? 0.0;
      final longitude = locationData['longitude'] ?? 0.0;
      return GeoPoint(latitude.toDouble(), longitude.toDouble());
    }
    
    return const GeoPoint(0, 0);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'imageUrls': photos,  // Save to imageUrls for consistency
      'photos': photos,     // Keep photos for backward compatibility
      'description': description,
      'location': location,
      'address': address,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVaccinated': isVaccinated,
      'isNeutered': isNeutered,
      'healthStatus': healthStatus,
      'temperament': temperament,
      'weight': weight,
      'specialNeeds': specialNeeds,
      'reason': reason,
      'adoptionFee': adoptionFee,
      'goodWithKids': goodWithKids,
      'goodWithPets': goodWithPets,
      'isHouseTrained': isHouseTrained,
      'preferredHomeType': preferredHomeType,
      'medicalHistory': medicalHistory,
      'microchipId': microchipId,
      'adoptionType': adoptionType,
    };
  }

  factory AdoptionPetModel.fromJson(Map<String, dynamic> json) {
    return AdoptionPetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      petName: json['petName'] ?? '',
      petType: json['petType'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      color: json['color'] ?? '',
      photos: List<String>.from(json['imageUrls'] ?? json['photos'] ?? []),
      description: json['description'] ?? '',
      location: _parseLocation(json['location']),
      address: json['address'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      contactName: json['contactName'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isVaccinated: json['isVaccinated'] ?? false,
      isNeutered: json['isNeutered'] ?? false,
      healthStatus: json['healthStatus'] ?? 'جيد',
      temperament: json['temperament'] ?? 'ودود',
      weight: (json['weight'] ?? 0.0).toDouble(),
      specialNeeds: json['specialNeeds'] ?? '',
      reason: json['reason'] ?? '',
      adoptionFee: (json['adoptionFee'] ?? 0.0).toDouble(),
      goodWithKids: json['goodWithKids'] ?? true,
      goodWithPets: json['goodWithPets'] ?? true,
      isHouseTrained: json['isHouseTrained'] ?? false,
      preferredHomeType: json['preferredHomeType'] ?? '',
      medicalHistory: List<String>.from(json['medicalHistory'] ?? []),
      microchipId: json['microchipId'] ?? '',
      adoptionType: json['adoptionType'] ?? 'offering',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'photos': photos,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVaccinated': isVaccinated,
      'isNeutered': isNeutered,
      'healthStatus': healthStatus,
      'temperament': temperament,
      'weight': weight,
      'specialNeeds': specialNeeds,
      'reason': reason,
      'adoptionFee': adoptionFee,
      'goodWithKids': goodWithKids,
      'goodWithPets': goodWithPets,
      'isHouseTrained': isHouseTrained,
      'preferredHomeType': preferredHomeType,
      'medicalHistory': medicalHistory,
      'microchipId': microchipId,
      'adoptionType': adoptionType,
    };
  }

  AdoptionPetModel copyWith({
    String? id,
    String? userId,
    String? petName,
    String? petType,
    String? breed,
    int? age,
    String? gender,
    String? color,
    List<String>? photos,
    String? description,
    GeoPoint? location,
    String? address,
    String? contactPhone,
    String? contactName,
    String? contactEmail,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVaccinated,
    bool? isNeutered,
    String? healthStatus,
    String? temperament,
    double? weight,
    String? specialNeeds,
    String? reason,
    double? adoptionFee,
    bool? goodWithKids,
    bool? goodWithPets,
    bool? isHouseTrained,
    String? preferredHomeType,
    List<String>? medicalHistory,
    String? microchipId,
    String? adoptionType,
  }) {
    return AdoptionPetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      color: color ?? this.color,
      photos: photos ?? this.photos,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVaccinated: isVaccinated ?? this.isVaccinated,
      isNeutered: isNeutered ?? this.isNeutered,
      healthStatus: healthStatus ?? this.healthStatus,
      temperament: temperament ?? this.temperament,
      weight: weight ?? this.weight,
      specialNeeds: specialNeeds ?? this.specialNeeds,
      reason: reason ?? this.reason,
      adoptionFee: adoptionFee ?? this.adoptionFee,
      goodWithKids: goodWithKids ?? this.goodWithKids,
      goodWithPets: goodWithPets ?? this.goodWithPets,
      isHouseTrained: isHouseTrained ?? this.isHouseTrained,
      preferredHomeType: preferredHomeType ?? this.preferredHomeType,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      microchipId: microchipId ?? this.microchipId,
      adoptionType: adoptionType ?? this.adoptionType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        petName,
        petType,
        breed,
        age,
        gender,
        color,
        photos,
        description,
        location,
        address,
        contactPhone,
        contactName,
        contactEmail,
        isActive,
        createdAt,
        updatedAt,
        isVaccinated,
        isNeutered,
        healthStatus,
        temperament,
        weight,
        specialNeeds,
        reason,
        adoptionFee,
        goodWithKids,
        goodWithPets,
        isHouseTrained,
        preferredHomeType,
        medicalHistory,
        microchipId,
        adoptionType,
      ];
} 

// ========================= BREEDING PET MODEL =========================

class BreedingPetModel extends Equatable {
  final String id;
  final String userId;
  final String petName;
  final String petType;
  final String breed;
  final int age;
  final String gender;
  final String color;
  final List<String> photos;
  final String description;
  final GeoPoint location;
  final String address;
  final String contactPhone;
  final String contactName;
  final String contactEmail;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Breeding-specific fields
  final bool isVaccinated;
  final bool isNeutered; // For female pets - if spayed
  final String healthStatus;
  final String temperament;
  final double weight;
  final String specialRequirements;
  final double breedingFee;
  final bool hasBreedingExperience;
  final String breedingHistory;
  final bool isRegistered; // Has pedigree/registration papers
  final String registrationNumber;
  final List<String> certifications; // Health certifications, tests done
  final String breedingGoals; // What qualities looking for in mate
  final String availabilityPeriod; // When available for breeding
  final bool willTravel; // Will travel for breeding
  final int maxTravelDistance; // In kilometers
  final String offspring; // Plans for offspring (keep, share, sell)
  final List<String> previousOffspring; // Photos/info of previous litters
  final String veterinarianContact; // Vet contact for breeding verification

  const BreedingPetModel({
    required this.id,
    required this.userId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.age,
    required this.gender,
    required this.color,
    required this.photos,
    required this.description,
    required this.location,
    required this.address,
    required this.contactPhone,
    required this.contactName,
    this.contactEmail = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isVaccinated = false,
    this.isNeutered = false,
    this.healthStatus = 'جيد',
    this.temperament = 'ودود',
    this.weight = 0.0,
    this.specialRequirements = '',
    this.breedingFee = 0.0,
    this.hasBreedingExperience = false,
    this.breedingHistory = '',
    this.isRegistered = false,
    this.registrationNumber = '',
    this.certifications = const [],
    this.breedingGoals = '',
    this.availabilityPeriod = '',
    this.willTravel = false,
    this.maxTravelDistance = 0,
    this.offspring = '',
    this.previousOffspring = const [],
    this.veterinarianContact = '',
  });

  factory BreedingPetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BreedingPetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      petName: data['petName'] ?? '',
      petType: data['petType'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      color: data['color'] ?? '',
      photos: List<String>.from(data['imageUrls'] ?? data['photos'] ?? []),
      description: data['description'] ?? '',
      location: _parseLocation(data['location']),
      address: data['address'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      contactName: data['contactName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVaccinated: data['isVaccinated'] ?? false,
      isNeutered: data['isNeutered'] ?? false,
      healthStatus: data['healthStatus'] ?? 'جيد',
      temperament: data['temperament'] ?? 'ودود',
      weight: (data['weight'] ?? 0.0).toDouble(),
      specialRequirements: data['specialRequirements'] ?? '',
      breedingFee: (data['breedingFee'] ?? 0.0).toDouble(),
      hasBreedingExperience: data['hasBreedingExperience'] ?? false,
      breedingHistory: data['breedingHistory'] ?? '',
      isRegistered: data['isRegistered'] ?? false,
      registrationNumber: data['registrationNumber'] ?? '',
      certifications: List<String>.from(data['certifications'] ?? []),
      breedingGoals: data['breedingGoals'] ?? '',
      availabilityPeriod: data['availabilityPeriod'] ?? '',
      willTravel: data['willTravel'] ?? false,
      maxTravelDistance: data['maxTravelDistance'] ?? 0,
      offspring: data['offspring'] ?? '',
      previousOffspring: List<String>.from(data['previousOffspring'] ?? []),
      veterinarianContact: data['veterinarianContact'] ?? '',
    );
  }

  // Helper method to parse location data (shared with other models)
  static GeoPoint _parseLocation(dynamic locationData) {
    if (locationData == null) {
      return const GeoPoint(0, 0);
    }
    
    if (locationData is GeoPoint) {
      return locationData;
    }
    
    if (locationData is Map<String, dynamic>) {
      final latitude = locationData['latitude'] ?? 0.0;
      final longitude = locationData['longitude'] ?? 0.0;
      return GeoPoint(latitude.toDouble(), longitude.toDouble());
    }
    
    return const GeoPoint(0, 0);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'imageUrls': photos,  // Save to imageUrls for consistency
      'photos': photos,     // Keep photos for backward compatibility
      'description': description,
      'location': location,
      'address': address,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVaccinated': isVaccinated,
      'isNeutered': isNeutered,
      'healthStatus': healthStatus,
      'temperament': temperament,
      'weight': weight,
      'specialRequirements': specialRequirements,
      'breedingFee': breedingFee,
      'hasBreedingExperience': hasBreedingExperience,
      'breedingHistory': breedingHistory,
      'isRegistered': isRegistered,
      'registrationNumber': registrationNumber,
      'certifications': certifications,
      'breedingGoals': breedingGoals,
      'availabilityPeriod': availabilityPeriod,
      'willTravel': willTravel,
      'maxTravelDistance': maxTravelDistance,
      'offspring': offspring,
      'previousOffspring': previousOffspring,
      'veterinarianContact': veterinarianContact,
    };
  }

  factory BreedingPetModel.fromJson(Map<String, dynamic> json) {
    return BreedingPetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      petName: json['petName'] ?? '',
      petType: json['petType'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      color: json['color'] ?? '',
      photos: List<String>.from(json['imageUrls'] ?? json['photos'] ?? []),
      description: json['description'] ?? '',
      location: _parseLocation(json['location']),
      address: json['address'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      contactName: json['contactName'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isVaccinated: json['isVaccinated'] ?? false,
      isNeutered: json['isNeutered'] ?? false,
      healthStatus: json['healthStatus'] ?? 'جيد',
      temperament: json['temperament'] ?? 'ودود',
      weight: (json['weight'] ?? 0.0).toDouble(),
      specialRequirements: json['specialRequirements'] ?? '',
      breedingFee: (json['breedingFee'] ?? 0.0).toDouble(),
      hasBreedingExperience: json['hasBreedingExperience'] ?? false,
      breedingHistory: json['breedingHistory'] ?? '',
      isRegistered: json['isRegistered'] ?? false,
      registrationNumber: json['registrationNumber'] ?? '',
      certifications: List<String>.from(json['certifications'] ?? []),
      breedingGoals: json['breedingGoals'] ?? '',
      availabilityPeriod: json['availabilityPeriod'] ?? '',
      willTravel: json['willTravel'] ?? false,
      maxTravelDistance: json['maxTravelDistance'] ?? 0,
      offspring: json['offspring'] ?? '',
      previousOffspring: List<String>.from(json['previousOffspring'] ?? []),
      veterinarianContact: json['veterinarianContact'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'petName': petName,
      'petType': petType,
      'breed': breed,
      'age': age,
      'gender': gender,
      'color': color,
      'photos': photos,
      'description': description,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'address': address,
      'contactPhone': contactPhone,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isVaccinated': isVaccinated,
      'isNeutered': isNeutered,
      'healthStatus': healthStatus,
      'temperament': temperament,
      'weight': weight,
      'specialRequirements': specialRequirements,
      'breedingFee': breedingFee,
      'hasBreedingExperience': hasBreedingExperience,
      'breedingHistory': breedingHistory,
      'isRegistered': isRegistered,
      'registrationNumber': registrationNumber,
      'certifications': certifications,
      'breedingGoals': breedingGoals,
      'availabilityPeriod': availabilityPeriod,
      'willTravel': willTravel,
      'maxTravelDistance': maxTravelDistance,
      'offspring': offspring,
      'previousOffspring': previousOffspring,
      'veterinarianContact': veterinarianContact,
    };
  }

  @override
  List<Object?> get props => [
    id, userId, petName, petType, breed, age, gender, color, photos,
    description, location, address, contactPhone, contactName, contactEmail,
    isActive, createdAt, updatedAt, isVaccinated, isNeutered, healthStatus,
    temperament, weight, specialRequirements, breedingFee, hasBreedingExperience,
    breedingHistory, isRegistered, registrationNumber, certifications,
    breedingGoals, availabilityPeriod, willTravel, maxTravelDistance,
    offspring, previousOffspring, veterinarianContact,
  ];
} 