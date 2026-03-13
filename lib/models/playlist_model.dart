import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String userId;
  final String title;
  final List<String> trackIds;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.userId,
    required this.title,
    required this.trackIds,
    required this.createdAt,
  });

  factory Playlist.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Playlist(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      trackIds: List<String>.from(
        (data['tracks'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'title': title,
      'tracks': trackIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Playlist copyWith({
    String? id,
    String? userId,
    String? title,
    List<String>? trackIds,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

