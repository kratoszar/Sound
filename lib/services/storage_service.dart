import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  FirebaseStorage get _storage => FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final task = ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );

    task.snapshotEvents.listen((snap) {
      final total = snap.totalBytes;
      if (total <= 0) return;
      final p = snap.bytesTransferred / total;
      onProgress?.call(p.clamp(0.0, 1.0));
    });

    await task;
    return await ref.getDownloadURL();
  }
}

