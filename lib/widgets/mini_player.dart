import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/music_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final track = music.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying = music.playerState?.playing ?? false;
    final duration = music.duration ?? track.duration;
    final pos = music.position;
    final progress = (duration.inMilliseconds <= 0)
        ? 0.0
        : (pos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 44,
                    color: const Color(0xFF101027),
                    child: (track.coverUrl == null || track.coverUrl!.isEmpty)
                        ? const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textSecondary,
                          )
                        : CachedNetworkImage(
                            imageUrl: track.coverUrl!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: music.togglePlayPause,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    size: 34,
                  ),
                  color: AppColors.primary,
                ),
                IconButton(
                  onPressed: music.stop,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: progress.isNaN ? 0.0 : progress,
                backgroundColor: const Color(0xFF101027),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(_fmt(pos), style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  _fmt(duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.secondary,
                inactiveTrackColor: const Color(0xFF101027),
                thumbColor: AppColors.secondary,
                overlayColor: AppColors.secondary.withValues(alpha: 0.15),
                trackHeight: 2,
              ),
              child: Slider(
                value: progress.isNaN ? 0.0 : progress,
                onChanged: (v) async {
                  final targetMs =
                      (duration.inMilliseconds * v).round().clamp(0, duration.inMilliseconds);
                  await music.seek(Duration(milliseconds: targetMs));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }
}

