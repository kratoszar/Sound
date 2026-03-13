import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/video_provider.dart';
import '../../widgets/video_card.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _controller = PageController();
  final Map<String, bool> _followingCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vp = context.read<VideoProvider>();
      await vp.onPageChanged(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openComments(BuildContext context, String videoId) async {
    final provider = context.read<VideoProvider>();
    final textCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Comentarios', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Flexible(
                  child: StreamBuilder(
                    stream: provider.commentsStream(videoId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('Sé el primero en comentar.'),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          final text = (d['text'] as String?) ?? '';
                          final uid = (d['userId'] as String?) ?? '';
                          return ListTile(
                            dense: true,
                            title: Text(
                              text,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              uid,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un comentario…',
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () async {
                        await provider.postComment(videoId: videoId, text: textCtrl.text);
                        textCtrl.clear();
                      },
                      icon: const Icon(Icons.send_rounded),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    textCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VideoProvider>();

    if (vp.isLoadingFeed) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vp.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            vp.errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (vp.feed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no hay videos. Sube el primero en Upload.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      onPageChanged: (i) => vp.onPageChanged(i),
      itemCount: vp.feed.length,
      itemBuilder: (context, index) {
        final video = vp.feed[index];
        final ctrl = vp.controllerFor(video.id);

        final cached = _followingCache[video.userId];
        final followFuture = cached != null ? null : vp.isFollowing(video.userId);

        return FutureBuilder<bool>(
          future: followFuture,
          initialData: cached ?? false,
          builder: (context, snap) {
            final isFollowing = snap.data ?? false;
            _followingCache[video.userId] = isFollowing;

            return VideoCard(
              video: video,
              controller: ctrl,
              isFollowing: isFollowing,
              onTapLike: () => vp.toggleLike(video),
              onTapComments: () => _openComments(context, video.id),
              onTapFollow: () async {
                final now = _followingCache[video.userId] ?? false;
                if (now) {
                  await vp.unfollowUser(video.userId);
                  _followingCache[video.userId] = false;
                } else {
                  await vp.followUser(video.userId);
                  _followingCache[video.userId] = true;
                }
                if (mounted) setState(() {});
              },
            );
          },
        );
      },
    );
  }
}

