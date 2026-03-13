import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/track_model.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';

class MusicProvider extends ChangeNotifier {
  final FirestoreService _firestore;
  final AudioService _audio;

  MusicProvider({
    FirestoreService? firestoreService,
    AudioService? audioService,
  })  : _firestore = firestoreService ?? FirestoreService.instance,
        _audio = audioService ?? AudioService.instance {
    _bindPlayerStreams();
    listenToFeed();
  }

  bool isLoadingFeed = false;
  String? errorMessage;

  List<Track> feed = const <Track>[];

  Track? get currentTrack => _audio.currentTrack;

  PlayerState? playerState;
  Duration position = Duration.zero;
  Duration? duration;

  StreamSubscription? _feedSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  void _bindPlayerStreams() {
    _playerStateSub = _audio.playerStateStream.listen((s) {
      playerState = s;
      notifyListeners();
    });
    _posSub = _audio.positionStream.listen((p) {
      position = p;
      notifyListeners();
    });
    _durSub = _audio.durationStream.listen((d) {
      duration = d;
      notifyListeners();
    });
  }

  void listenToFeed() {
    _feedSub?.cancel();
    isLoadingFeed = true;
    errorMessage = null;
    notifyListeners();

    _feedSub = _firestore.tracks
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        feed = snap.docs.map((d) => Track.fromFirestore(d)).toList();
        isLoadingFeed = false;
        notifyListeners();
      },
      onError: (e) {
        errorMessage = e.toString();
        isLoadingFeed = false;
        notifyListeners();
      },
    );
  }

  Future<void> playTrack(Track track) async {
    errorMessage = null;
    notifyListeners();
    try {
      await _audio.setTrack(track, autoplay: true);
      await _logHistory(track);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() => _audio.togglePlayPause();

  Future<void> seek(Duration p) => _audio.seek(p);

  Future<void> stop() async {
    await _audio.stop();
    notifyListeners();
  }

  Future<void> toggleLike(Track track) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final trackRef = _firestore.tracks.doc(track.id);
    final likeRef = trackRef.collection('likes').doc(uid);

    await _firestore.db.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final trackSnap = await tx.get(trackRef);
      final currentLikes = (trackSnap.data()?['likes'] as int?) ?? 0;

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(trackRef, <String, dynamic>{
          'likes': FieldValue.increment(-1),
        });
        _updateLocalLikes(track.id, currentLikes - 1);
      } else {
        tx.set(likeRef, <String, dynamic>{
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(trackRef, <String, dynamic>{
          'likes': FieldValue.increment(1),
        });
        _updateLocalLikes(track.id, currentLikes + 1);
      }
    });
  }

  void _updateLocalLikes(String trackId, int likes) {
    feed = feed
        .map(
          (t) => t.id == trackId ? t.copyWith(likesCount: likes) : t,
        )
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> _logHistory(Track track) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final historyRef = _firestore.userDoc(uid).collection('history');
    await historyRef.add(<String, dynamic>{
      'trackId': track.id,
      'playedAt': FieldValue.serverTimestamp(),
      'title': track.title,
      'artist': track.artist,
      'coverUrl': track.coverUrl,
      'audioUrl': track.audioUrl,
    });
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    _playerStateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    super.dispose();
  }
}

