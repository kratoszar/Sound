import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/track_model.dart';
import '../../providers/music_provider.dart';
import '../../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Inicia sesión para ver tu historial.'));
    }

    final q = FirestoreService.instance
        .userDoc(uid)
        .collection('history')
        .orderBy('playedAt', descending: true)
        .limit(50);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
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
                  'Aún no hay reproducciones.\nReproduce algo en el feed de música.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final title = (d['title'] as String?) ?? '';
              final artist = (d['artist'] as String?) ?? '';
              final audioUrl = (d['audioUrl'] as String?) ?? '';
              final coverUrl = d['coverUrl'] as String?;
              final trackId = (d['trackId'] as String?) ?? docs[i].id;
              final durationMs = (d['duration'] as int?) ?? 0;

              return ListTile(
                title: Text(title),
                subtitle: Text(artist),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () {
                  final track = Track(
                    id: trackId,
                    title: title,
                    artist: artist,
                    userId: uid,
                    audioUrl: audioUrl,
                    coverUrl: coverUrl,
                    likesCount: 0,
                    duration: Duration(milliseconds: durationMs),
                    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                  );
                  context.read<MusicProvider>().playTrack(track);
                },
              );
            },
          );
        },
      ),
    );
  }
}

