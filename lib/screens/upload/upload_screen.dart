import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Music
  final _titleCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  File? _audioFile;
  File? _coverFile;

  // Video
  final _captionCtrl = TextEditingController();
  File? _videoFile;

  bool _busy = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
    );
    final path = res?.files.single.path;
    if (path == null) return;
    setState(() {
      _audioFile = File(path);
      _error = null;
    });
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _coverFile = File(x.path);
      _error = null;
    });
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final x = await picker.pickVideo(source: ImageSource.gallery);
    if (x == null) return;
    setState(() {
      _videoFile = File(x.path);
      _error = null;
    });
  }

  Future<void> _uploadMusic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Debes iniciar sesión.');
      return;
    }

    final title = _titleCtrl.text.trim();
    final artist = _artistCtrl.text.trim();
    if (title.isEmpty || artist.isEmpty) {
      setState(() => _error = 'Completa título y artista.');
      return;
    }
    if (_audioFile == null) {
      setState(() => _error = 'Selecciona un archivo de audio.');
      return;
    }

    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });

    try {
      final doc = FirestoreService.instance.tracks.doc();
      final trackId = doc.id;

      final audioUrl = await StorageService.instance.uploadFile(
        file: _audioFile!,
        path: 'tracks/$uid/$trackId/audio.${_audioFile!.path.split('.').last}',
        contentType: 'audio/*',
        onProgress: (p) => setState(() => _progress = p * 0.8),
      );

      String? coverUrl;
      if (_coverFile != null) {
        coverUrl = await StorageService.instance.uploadFile(
          file: _coverFile!,
          path: 'tracks/$uid/$trackId/cover.jpg',
          contentType: 'image/jpeg',
          onProgress: (p) => setState(() => _progress = 0.8 + p * 0.2),
        );
      } else {
        setState(() => _progress = 1.0);
      }

      await doc.set({
        'title': title,
        'artist': artist,
        'userId': uid,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'likes': 0,
        'duration': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track subido correctamente.')),
      );
      setState(() {
        _audioFile = null;
        _coverFile = null;
        _titleCtrl.clear();
        _artistCtrl.clear();
        _progress = 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _uploadVideo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'Debes iniciar sesión.');
      return;
    }
    if (_videoFile == null) {
      setState(() => _error = 'Selecciona un video.');
      return;
    }

    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });

    try {
      final doc = FirestoreService.instance.videos.doc();

      final url = await CloudinaryService.instance.uploadVideo(
        _videoFile!,
        onProgress: (p) => setState(() => _progress = p),
      );

      await doc.set({
        'userId': uid,
        'videoUrl': url,
        'caption': _captionCtrl.text.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video subido correctamente.')),
      );
      setState(() {
        _videoFile = null;
        _captionCtrl.clear();
        _progress = 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Música'),
            Tab(text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MusicUpload(
            titleCtrl: _titleCtrl,
            artistCtrl: _artistCtrl,
            audioFile: _audioFile,
            coverFile: _coverFile,
            busy: _busy,
            progress: _progress,
            error: _error,
            onPickAudio: _pickAudio,
            onPickCover: _pickCover,
            onUpload: _uploadMusic,
          ),
          _VideoUpload(
            captionCtrl: _captionCtrl,
            videoFile: _videoFile,
            busy: _busy,
            progress: _progress,
            error: _error,
            onPickVideo: _pickVideo,
            onUpload: _uploadVideo,
          ),
        ],
      ),
    );
  }
}

class _MusicUpload extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController artistCtrl;
  final File? audioFile;
  final File? coverFile;
  final bool busy;
  final double progress;
  final String? error;
  final Future<void> Function() onPickAudio;
  final Future<void> Function() onPickCover;
  final Future<void> Function() onUpload;

  const _MusicUpload({
    required this.titleCtrl,
    required this.artistCtrl,
    required this.audioFile,
    required this.coverFile,
    required this.busy,
    required this.progress,
    required this.error,
    required this.onPickAudio,
    required this.onPickCover,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: titleCtrl,
          enabled: !busy,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: artistCtrl,
          enabled: !busy,
          decoration: const InputDecoration(labelText: 'Artista'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy ? null : onPickAudio,
          icon: const Icon(Icons.audiotrack_rounded),
          label: Text(audioFile == null ? 'Seleccionar audio' : 'Audio listo'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: busy ? null : onPickCover,
          icon: const Icon(Icons.image_rounded),
          label: Text(coverFile == null ? 'Seleccionar portada' : 'Portada lista'),
        ),
        const SizedBox(height: 16),
        if (busy) ...[
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 10),
        ],
        if (error != null) ...[
          Text(
            error!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: busy ? null : onUpload,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Subir track'),
        ),
      ],
    );
  }
}

class _VideoUpload extends StatelessWidget {
  final TextEditingController captionCtrl;
  final File? videoFile;
  final bool busy;
  final double progress;
  final String? error;
  final Future<void> Function() onPickVideo;
  final Future<void> Function() onUpload;

  const _VideoUpload({
    required this.captionCtrl,
    required this.videoFile,
    required this.busy,
    required this.progress,
    required this.error,
    required this.onPickVideo,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: captionCtrl,
          enabled: !busy,
          decoration: const InputDecoration(labelText: 'Caption'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy ? null : onPickVideo,
          icon: const Icon(Icons.video_file_rounded),
          label: Text(videoFile == null ? 'Seleccionar video' : 'Video listo'),
        ),
        const SizedBox(height: 16),
        if (busy) ...[
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
          const SizedBox(height: 10),
        ],
        if (error != null) ...[
          Text(
            error!,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: busy ? null : onUpload,
          icon: const Icon(Icons.cloud_upload_rounded),
          label: const Text('Subir video'),
        ),
      ],
    );
  }
}

