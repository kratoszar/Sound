import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/mini_player.dart';
import '../music/music_feed_screen.dart';
import '../videos/video_feed_screen.dart';
import '../playlist/playlists_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../upload/upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const MusicFeedScreen(),
      const VideoFeedScreen(),
      const PlaylistsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(child: pages[_index]),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MiniPlayer(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const UploadScreen(),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_rounded),
            label: 'Música',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_display_rounded),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_music_rounded),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
