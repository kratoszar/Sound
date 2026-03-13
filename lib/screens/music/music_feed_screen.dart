import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/music_provider.dart';
import '../../widgets/track_tile.dart';

class MusicFeedScreen extends StatelessWidget {
  const MusicFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>();
    final current = music.currentTrack;
    final isPlaying = music.playerState?.playing ?? false;

    return RefreshIndicator(
      onRefresh: () async => music.listenToFeed(),
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text('Música'),
          ),
          if (music.isLoadingFeed)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (music.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  music.errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (music.feed.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no hay música. Sube tu primer track en Upload.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: music.feed.length,
              itemBuilder: (context, index) {
                final track = music.feed[index];
                final tilePlaying = (current?.id == track.id) && isPlaying;
                return TrackTile(
                  track: track,
                  isPlaying: tilePlaying,
                  onTapPlay: () => music.playTrack(track),
                  onTapLike: () => music.toggleLike(track),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
