import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoService {
  VideoService._();

  static final VideoService instance = VideoService._();

  final LinkedHashMap<String, VideoPlayerController> _controllers =
      LinkedHashMap<String, VideoPlayerController>();

  int maxControllers = 6;

  Future<VideoPlayerController> getController({
    required String videoId,
    required String url,
  }) async {
    final existing = _controllers[videoId];
    if (existing != null) return existing;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.setLooping(true);

    _controllers[videoId] = controller;
    _evictIfNeeded();
    return controller;
  }

  void _evictIfNeeded() {
    while (_controllers.length > maxControllers) {
      final firstKey = _controllers.keys.first;
      final ctrl = _controllers.remove(firstKey);
      ctrl?.dispose();
    }
  }

  Future<void> pauseAllExcept(String? keepVideoId) async {
    for (final entry in _controllers.entries) {
      if (entry.key == keepVideoId) continue;
      final ctrl = entry.value;
      if (ctrl.value.isPlaying) {
        await ctrl.pause();
      }
    }
  }

  @mustCallSuper
  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.dispose();
    }
    _controllers.clear();
  }
}

