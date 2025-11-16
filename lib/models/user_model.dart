import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model matching Firestore schema
class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String? profilePhotoUrl;
  final String gender;
  final String major;
  final String universityId;
  final bool isVerifiedEdu;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    this.profilePhotoUrl,
    required this.gender,
    required this.major,
    required this.universityId,
    required this.isVerifiedEdu,
    required this.createdAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      profilePhotoUrl: data['profilePhotoUrl'],
      gender: data['gender'] ?? '',
      major: data['major'] ?? '',
      universityId: data['universityId'] ?? '',
      isVerifiedEdu: data['isVerifiedEdu'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserModel to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'gender': gender,
      'major': major,
      'universityId': universityId,
      'isVerifiedEdu': isVerifiedEdu,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? displayName,
    String? email,
    String? profilePhotoUrl,
    String? gender,
    String? major,
    String? universityId,
    bool? isVerifiedEdu,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      gender: gender ?? this.gender,
      major: major ?? this.major,
      universityId: universityId ?? this.universityId,
      isVerifiedEdu: isVerifiedEdu ?? this.isVerifiedEdu,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// University model
class UniversityModel {
  final String id;
  final String name;
  final List<String> domains;

  UniversityModel({
    required this.id,
    required this.name,
    required this.domains,
  });

  factory UniversityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UniversityModel(
      id: doc.id,
      name: data['name'] ?? '',
      domains: List<String>.from(data['domains'] ?? []),
    );
  }

  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      domains: List<String>.from(json['domains'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'domains': domains,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domains': domains,
    };
  }
}

