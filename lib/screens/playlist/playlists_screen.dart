import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/playlist_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/playlist_card.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Inicia sesión para ver tus playlists.'));
    }

    final playlistsQuery = FirestoreService.instance.playlists
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            onPressed: () => _createPlaylist(context, uid),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: playlistsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no tienes playlists.\nCrea la primera con el botón +.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = docs.map((d) => Playlist.fromFirestore(d)).toList();
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return PlaylistCard(
                playlist: p,
                onTap: () => _openPlaylist(context, p),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context, String uid) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Nueva playlist'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Nombre'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    final title = ctrl.text.trim();
    ctrl.dispose();
    if (title.isEmpty) return;

    await FirestoreService.instance.playlists.add({
      'userId': uid,
      'title': title,
      'tracks': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }
}

class _PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistDetailScreen({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(playlist.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${playlist.trackIds.length} tracks',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: playlist.trackIds.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay tracks en esta playlist.\n(Agregar tracks se integra en el módulo Upload/Music).',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: playlist.trackIds.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => ListTile(
                        title: Text(playlist.trackIds[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

