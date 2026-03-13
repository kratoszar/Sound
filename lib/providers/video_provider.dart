import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/video_model.dart';
import '../services/firestore_service.dart';
import '../services/video_service.dart';

class VideoProvider extends ChangeNotifier {
  bool isLoadingFeed = false;
  String? errorMessage;

  List<AppVideo> feed = const <AppVideo>[];
  int currentIndex = 0;

  final FirestoreService _firestore;
  final VideoService _videoService;

  StreamSubscription? _feedSub;

  final Map<String, VideoPlayerController> controllers = {};

  VideoProvider({
    FirestoreService? firestoreService,
    VideoService? videoService,
  })  : _firestore = firestoreService ?? FirestoreService.instance,
        _videoService = videoService ?? VideoService.instance {
    listenToFeed();
  }

  void listenToFeed() {
    _feedSub?.cancel();
    isLoadingFeed = true;
    errorMessage = null;
    notifyListeners();

    _feedSub = _firestore.videos
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) async {
        feed = snap.docs.map((d) => AppVideo.fromFirestore(d)).toList();
        isLoadingFeed = false;
        notifyListeners();
        await _warmControllersAround(currentIndex);
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoadingFeed = false;
        notifyListeners();
      },
    );
  }

  Future<void> onPageChanged(int index) async {
    currentIndex = index;
    notifyListeners();

    final current = (index >= 0 && index < feed.length) ? feed[index] : null;
    await _warmControllersAround(index);
    await _videoService.pauseAllExcept(current?.id);
    if (current != null) {
      final ctrl = controllers[current.id];
      if (ctrl != null && ctrl.value.isInitialized) {
        await ctrl.play();
      }
    }
  }

  Future<void> _warmControllersAround(int index) async {
    if (feed.isEmpty) return;

    final candidates = <int>{
      index,
      index - 1,
      index + 1,
    }..removeWhere((i) => i < 0 || i >= feed.length);

    for (final i in candidates) {
      final v = feed[i];
      if (controllers.containsKey(v.id)) continue;
      try {
        final ctrl = await _videoService.getController(
          videoId: v.id,
          url: v.videoUrl,
        );
        controllers[v.id] = ctrl;
        notifyListeners();
      } catch (e) {
        // If a single video fails, we keep the feed usable.
      }
    }
  }

  VideoPlayerController? controllerFor(String videoId) => controllers[videoId];

  Future<void> toggleLike(AppVideo video) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final videoRef = _firestore.videos.doc(video.id);
    final likeRef = videoRef.collection('likes').doc(uid);

    await _firestore.db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final videoSnap = await tx.get(videoRef);
      final currentLikes = (videoSnap.data()?['likes'] as int?) ?? 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(videoRef, <String, dynamic>{
          'likes': FieldValue.increment(-1),
        });
        _updateLocalLikes(video.id, currentLikes - 1);
      } else {
        tx.set(likeRef, <String, dynamic>{
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(videoRef, <String, dynamic>{
          'likes': FieldValue.increment(1),
        });
        _updateLocalLikes(video.id, currentLikes + 1);
      }
    });
  }

  void _updateLocalLikes(String videoId, int likes) {
    feed = feed
        .map((v) => v.id == videoId ? v.copyWith(likesCount: likes) : v)
        .toList(growable: false);
    notifyListeners();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String videoId) {
    return _firestore.videos
        .doc(videoId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> postComment({
    required String videoId,
    required String text,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final t = text.trim();
    if (t.isEmpty) return;

    await _firestore.videos.doc(videoId).collection('comments').add({
      'userId': uid,
      'text': t,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> followUser(String targetUserId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (uid == targetUserId) return;

    final meRef = _firestore.users.doc(uid);
    final targetRef = _firestore.users.doc(targetUserId);
    final followingRef = meRef.collection('following').doc(targetUserId);
    final followerRef = targetRef.collection('followers').doc(uid);

    await _firestore.db.runTransaction((tx) async {
      final f1 = await tx.get(followingRef);
      if (f1.exists) return;
      tx.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.set(followerRef, {'createdAt': FieldValue.serverTimestamp()});
      tx.update(meRef, {'following': FieldValue.increment(1)});
      tx.update(targetRef, {'followers': FieldValue.increment(1)});
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (uid == targetUserId) return;

    final meRef = _firestore.users.doc(uid);
    final targetRef = _firestore.users.doc(targetUserId);
    final followingRef = meRef.collection('following').doc(targetUserId);
    final followerRef = targetRef.collection('followers').doc(uid);

    await _firestore.db.runTransaction((tx) async {
      final f1 = await tx.get(followingRef);
      if (!f1.exists) return;
      tx.delete(followingRef);
      tx.delete(followerRef);
      tx.update(meRef, {'following': FieldValue.increment(-1)});
      tx.update(targetRef, {'followers': FieldValue.increment(-1)});
    });
  }

  Future<bool> isFollowing(String targetUserId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await _firestore.users
        .doc(uid)
        .collection('following')
        .doc(targetUserId)
        .get();
    return snap.exists;
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }
}

