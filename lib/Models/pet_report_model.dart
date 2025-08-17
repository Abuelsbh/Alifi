import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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