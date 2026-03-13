import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.followersCount,
    required this.followingCount,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : (data['email'] as String? ?? 'User'),
      email: data['email'] as String? ?? '',
      avatar: data['avatar'] as String?,
      followersCount: (data['followers'] as int?) ?? 0,
      followingCount: (data['following'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'avatar': avatar,
      'followers': followersCount,
      'following': followingCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

