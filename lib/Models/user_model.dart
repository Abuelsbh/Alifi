import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? profilePhoto;
  final String? phoneNumber;
  final String? address;
  final List<PetModel> pets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhoto,
    this.phoneNumber,
    this.address,
    this.pets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePhoto: data['profilePhoto'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      pets: (data['pets'] as List<dynamic>? ?? [])
          .map((pet) => PetModel.fromMap(pet))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'profilePhoto': profilePhoto,
      'phoneNumber': phoneNumber,
      'address': address,
      'pets': pets.map((pet) => pet.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profilePhoto: json['profilePhoto'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      pets: (json['pets'] as List<dynamic>? ?? [])
          .map((pet) => PetModel.fromMap(pet))
          .toList(),
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
      'email': email,
      'username': username,
      'profilePhoto': profilePhoto,
      'phoneNumber': phoneNumber,
      'address': address,
      'pets': pets.map((pet) => pet.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? profilePhoto,
    String? phoneNumber,
    String? address,
    List<PetModel>? pets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      pets: pets ?? this.pets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        profilePhoto,
        phoneNumber,
        address,
        pets,
        createdAt,
        updatedAt,
      ];
}

class PetModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String gender;
  final List<String> photos;
  final List<String> vaccinations;
  final String? description;

  const PetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    this.photos = const [],
    this.vaccinations = const [],
    this.description,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      photos: List<String>.from(map['photos'] ?? []),
      vaccinations: List<String>.from(map['vaccinations'] ?? []),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'photos': photos,
      'vaccinations': vaccinations,
      'description': description,
    };
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      vaccinations: List<String>.from(json['vaccinations'] ?? []),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'photos': photos,
      'vaccinations': vaccinations,
      'description': description,
    };
  }

  PetModel copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    int? age,
    String? gender,
    List<String>? photos,
    List<String>? vaccinations,
    String? description,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      vaccinations: vaccinations ?? this.vaccinations,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        breed,
        age,
        gender,
        photos,
        vaccinations,
        description,
      ];
}
