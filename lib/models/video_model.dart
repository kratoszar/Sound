import 'package:cloud_firestore/cloud_firestore.dart';

class AppVideo {
  final String id;
  final String userId;
  final String videoUrl;
  final String caption;
  final int likesCount;
  final DateTime createdAt;

  const AppVideo({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.caption,
    required this.likesCount,
    required this.createdAt,
  });

  factory AppVideo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppVideo(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      likesCount: (data['likes'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'videoUrl': videoUrl,
      'caption': caption,
      'likes': likesCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppVideo copyWith({
    String? id,
    String? userId,
    String? videoUrl,
    String? caption,
    int? likesCount,
    DateTime? createdAt,
  }) {
    return AppVideo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

