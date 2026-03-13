import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/track_model.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTapPlay;
  final VoidCallback onTapLike;
  final bool isPlaying;

  const TrackTile({
    super.key,
    required this.track,
    required this.onTapPlay,
    required this.onTapLike,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Cover(coverUrl: track.coverUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: AppColors.accent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${track.likesCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmt(track.duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTapLike,
            icon: const Icon(Icons.favorite_border_rounded),
            color: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: onTapPlay,
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              size: 34,
            ),
            color: AppColors.primary,
          ),
        ],
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

class _Cover extends StatelessWidget {
  final String? coverUrl;
  const _Cover({required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: 56,
        width: 56,
        color: const Color(0xFF101027),
        child: coverUrl == null || coverUrl!.isEmpty
            ? const Icon(Icons.music_note_rounded,
                color: AppColors.textSecondary)
            : CachedNetworkImage(
                imageUrl: coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}
