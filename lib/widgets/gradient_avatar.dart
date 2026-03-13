import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GradientAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? fallbackText;

  const GradientAvatar({
    super.key,
    required this.imageUrl,
    this.size = 44,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    const border = 2.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(border),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent, AppColors.secondary],
        ),
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFF101027),
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Center(
                  child: Text(
                    (fallbackText ?? 'U').trim().isEmpty
                        ? 'U'
                        : (fallbackText!.trim()[0]).toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
