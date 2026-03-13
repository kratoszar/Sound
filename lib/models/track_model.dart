import 'package:cloud_firestore/cloud_firestore.dart';

class Track {
  final String id;
  final String title;
  final String artist;
  final String userId;
  final String audioUrl;
  final String? coverUrl;
  final int likesCount;
  final Duration duration;
  final DateTime createdAt;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.userId,
    required this.audioUrl,
    required this.coverUrl,
    required this.likesCount,
    required this.duration,
    required this.createdAt,
  });

  factory Track.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Track(
      id: doc.id,
      title: data['title'] as String? ?? '',
      artist: data['artist'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      coverUrl: data['coverUrl'] as String?,
      likesCount: (data['likes'] as int?) ?? 0,
      duration: Duration(
        milliseconds: (data['duration'] as int?) ?? 0,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'artist': artist,
      'userId': userId,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'likes': likesCount,
      'duration': duration.inMilliseconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? userId,
    String? audioUrl,
    String? coverUrl,
    int? likesCount,
    Duration? duration,
    DateTime? createdAt,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      userId: userId ?? this.userId,
      audioUrl: audioUrl ?? this.audioUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      likesCount: likesCount ?? this.likesCount,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

