import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/utils/localized_content.dart';

class LocationModel extends Equatable {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameAr;
  final String? nameHe;
  final String? description;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionHe;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int displayOrder;

  const LocationModel({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameAr,
    this.nameHe,
    this.description,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionHe,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.displayOrder = 0,
  });

  String localizedName(String languageCode) {
    return LocalizedContent.pickFromMap({
      'name': name,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'nameHe': nameHe,
    }, languageCode, baseKey: 'name');
  }

  String? localizedDescription(String languageCode) {
    final s = LocalizedContent.pickFromMap({
      'description': description,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'descriptionHe': descriptionHe,
    }, languageCode, baseKey: 'description');
    return s.isEmpty ? null : s;
  }

  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn']?.toString(),
      nameAr: data['nameAr']?.toString(),
      nameHe: data['nameHe']?.toString(),
      description: data['description'],
      descriptionEn: data['descriptionEn']?.toString(),
      descriptionAr: data['descriptionAr']?.toString(),
      descriptionHe: data['descriptionHe']?.toString(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      displayOrder: data['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'nameHe': nameHe,
      'description': description,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'descriptionHe': descriptionHe,
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
      nameEn: json['nameEn']?.toString(),
      nameAr: json['nameAr']?.toString(),
      nameHe: json['nameHe']?.toString(),
      description: json['description'],
      descriptionEn: json['descriptionEn']?.toString(),
      descriptionAr: json['descriptionAr']?.toString(),
      descriptionHe: json['descriptionHe']?.toString(),
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
      'nameEn': nameEn,
      'nameAr': nameAr,
      'nameHe': nameHe,
      'description': description,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'descriptionHe': descriptionHe,
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
        nameEn,
        nameAr,
        nameHe,
        description,
        descriptionEn,
        descriptionAr,
        descriptionHe,
        isActive,
        createdAt,
        updatedAt,
        displayOrder,
      ];
}
