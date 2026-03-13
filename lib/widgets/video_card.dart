import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/constants/app_colors.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final AppVideo video;
  final VideoPlayerController? controller;
  final VoidCallback onTapLike;
  final VoidCallback onTapComments;
  final VoidCallback onTapFollow;
  final bool isFollowing;

  const VideoCard({
    super.key,
    required this.video,
    required this.controller,
    required this.onTapLike,
    required this.onTapComments,
    required this.onTapFollow,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final vp = controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (vp != null && vp.value.isInitialized)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: vp.value.size.width,
              height: vp.value.size.height,
              child: VideoPlayer(vp),
            ),
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(color: AppColors.background),
            child: Center(child: CircularProgressIndicator()),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.25),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 84,
          bottom: 28,
          child: _CaptionBlock(video: video),
        ),
        Positioned(
          right: 12,
          bottom: 90,
          child: _Actions(
            likes: video.likesCount,
            onTapLike: onTapLike,
            onTapComments: onTapComments,
            onTapFollow: onTapFollow,
            isFollowing: isFollowing,
          ),
        ),
      ],
    );
  }
}

class _CaptionBlock extends StatelessWidget {
  final AppVideo video;
  const _CaptionBlock({required this.video});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@${video.userId}',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          video.caption,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.textPrimary),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final int likes;
  final VoidCallback onTapLike;
  final VoidCallback onTapComments;
  final VoidCallback onTapFollow;
  final bool isFollowing;

  const _Actions({
    required this.likes,
    required this.onTapLike,
    required this.onTapComments,
    required this.onTapFollow,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    const iconColor = AppColors.textPrimary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundIcon(
          icon: Icons.favorite_rounded,
          label: '$likes',
          color: AppColors.accent,
          onTap: onTapLike,
        ),
        const SizedBox(height: 14),
        _RoundIcon(
          icon: Icons.mode_comment_rounded,
          label: 'Com',
          color: iconColor,
          onTap: onTapComments,
        ),
        const SizedBox(height: 14),
        _RoundIcon(
          icon: isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
          label: isFollowing ? 'Sig.' : 'Seg.',
          color: isFollowing ? AppColors.success : AppColors.secondary,
          onTap: onTapFollow,
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoundIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
