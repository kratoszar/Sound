import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../models/track_model.dart';

class AudioService {
  AudioService._() {
    _player.playerStateStream.listen((_) {
      _playerStateController.add(_player.playerState);
    });
    _player.positionStream.listen((p) {
      _positionController.add(p);
    });
    _player.durationStream.listen((d) {
      _durationController.add(d);
    });
    _player.processingStateStream.listen((_) {});
  }

  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();

  Track? _currentTrack;

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  Track? get currentTrack => _currentTrack;
  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;

  Future<void> setTrack(Track track, {bool autoplay = true}) async {
    if (_currentTrack?.id == track.id) {
      if (autoplay && !_player.playing) {
        await _player.play();
      }
      return;
    }

    _currentTrack = track;
    await _player.setUrl(track.audioUrl);
    if (autoplay) {
      await _player.play();
    }
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}

