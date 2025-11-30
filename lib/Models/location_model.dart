import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class LocationModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int displayOrder;

  const LocationModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.displayOrder = 0,
  });

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      displayOrder: data['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'displayOrder': displayOrder,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      displayOrder: json['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'displayOrder': displayOrder,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isActive,
        createdAt,
        updatedAt,
        displayOrder,
      ];
}

