import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
}

class ChatModel extends Equatable {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos; // صور المشاركين
  final Map<String, String> participantTypes; // نوع المستخدم: 'veterinarian' أو 'user'
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSender;
  final Map<String, int> unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? petReportId;
  final String? petReportType; // 'lost', 'found', 'adoption', 'breeding'

  const ChatModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.participantPhotos = const {},
    this.participantTypes = const {},
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSender,
    required this.unreadCount,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.petReportId,
    this.petReportType,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(data['participantPhotos'] ?? {}),
      participantTypes: Map<String, String>.from(data['participantTypes'] ?? {}),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSender: data['lastMessageSender'] ?? '',
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      petReportId: data['petReportId'] as String?,
      petReportType: data['petReportType'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'participantTypes': participantTypes,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (petReportId != null) 'petReportId': petReportId,
      if (petReportType != null) 'petReportType': petReportType,
    };
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse timestamp (supports both ISO8601 string and milliseconds int)
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try parsing as milliseconds
          final ms = int.tryParse(value);
          if (ms != null) {
            return DateTime.fromMillisecondsSinceEpoch(ms);
          }
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ChatModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantNames: Map<String, String>.from(json['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(json['participantPhotos'] ?? {}),
      participantTypes: Map<String, String>.from(json['participantTypes'] ?? {}),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: parseTimestamp(json['lastMessageAt']),
      lastMessageSender: json['lastMessageSender'] ?? '',
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: parseTimestamp(json['updatedAt']),
      petReportId: json['petReportId'] as String?,
      petReportType: json['petReportType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'participantTypes': participantTypes,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessageSender': lastMessageSender,
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (petReportId != null) 'petReportId': petReportId,
      if (petReportType != null) 'petReportType': petReportType,
    };
  }

  ChatModel copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    Map<String, String>? participantTypes,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSender,
    Map<String, int>? unreadCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? petReportId,
    String? petReportType,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      participantTypes: participantTypes ?? this.participantTypes,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      petReportId: petReportId ?? this.petReportId,
      petReportType: petReportType ?? this.petReportType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        participantNames,
        participantPhotos,
        participantTypes,
        lastMessage,
        lastMessageAt,
        lastMessageSender,
        unreadCount,
        isActive,
        createdAt,
        updatedAt,
        petReportId,
        petReportType,
      ];
}

class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String senderType; // 'veterinarian' or 'user'
  final String message;
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final bool isRead;
  final DateTime timestamp;
  final String? messageId;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    this.senderType = 'user',
    required this.message,
    required this.type,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.isRead = false,
    required this.timestamp,
    this.messageId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhoto: data['senderPhoto'],
      senderType: data['senderType'] ?? 'user',
      message: data['message'] ?? '',
      type: _parseMessageType(data['type'] ?? 'text'),
      mediaUrl: data['mediaUrl'] ?? data['imageUrl'] ?? data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageId: data['messageId'],
    );
  }

  static MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'audio':
        return MessageType.audio;
      case 'file':
        return MessageType.file;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'senderType': senderType,
      'message': message,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageId': messageId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Helper to parse timestamp (supports both ISO8601 string and milliseconds int)
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try parsing as milliseconds
          final ms = int.tryParse(value);
          if (ms != null) {
            return DateTime.fromMillisecondsSinceEpoch(ms);
          }
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ChatMessage(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderPhoto: json['senderPhoto'],
      senderType: json['senderType'] ?? 'user',
      message: json['message'] ?? '',
      type: _parseMessageType(json['type'] ?? 'text'),
      mediaUrl: json['mediaUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      isRead: json['isRead'] ?? false,
      timestamp: parseTimestamp(json['timestamp']),
      messageId: json['messageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'senderType': senderType,
      'message': message,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
      'messageId': messageId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhoto,
    String? senderType,
    String? message,
    MessageType? type,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    bool? isRead,
    DateTime? timestamp,
    String? messageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhoto: senderPhoto ?? this.senderPhoto,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        senderPhoto,
        senderType,
        message,
        type,
        mediaUrl,
        fileName,
        fileSize,
        isRead,
        timestamp,
        messageId,
      ];
}

class VeterinarianModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profilePhoto;
  final String specialization;
  final String? phoneNumber;
  final String? address;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VeterinarianModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    required this.specialization,
    this.phoneNumber,
    this.address,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.isAvailable = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VeterinarianModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VeterinarianModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      profilePhoto: data['profilePhoto'],
      specialization: data['specialization'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isOnline: data['isOnline'] ?? false,
      isAvailable: data['isAvailable'] ?? true,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'specialization': specialization,
      'phoneNumber': phoneNumber,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory VeterinarianModel.fromJson(Map<String, dynamic> json) {
    return VeterinarianModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'],
      specialization: json['specialization'] ?? '',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      isAvailable: json['isAvailable'] ?? true,
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
      'name': name,
      'email': email,
      'profilePhoto': profilePhoto,
      'specialization': specialization,
      'phoneNumber': phoneNumber,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  VeterinarianModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhoto,
    String? specialization,
    String? phoneNumber,
    String? address,
    double? rating,
    int? reviewCount,
    bool? isOnline,
    bool? isAvailable,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VeterinarianModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      specialization: specialization ?? this.specialization,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profilePhoto,
        specialization,
        phoneNumber,
        address,
        rating,
        reviewCount,
        isOnline,
        isAvailable,
        isActive,
        createdAt,
        updatedAt,
      ];
} 