import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/cloudinary_config.dart';

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  Future<String> uploadVideo(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    const cloud = CloudinaryConfig.cloudName;
    const preset = CloudinaryConfig.uploadPresetVideo;
    if (cloud == 'YOUR_CLOUD_NAME' || preset == 'YOUR_UNSIGNED_VIDEO_PRESET') {
      throw StateError(
        'Configura CloudinaryConfig.cloudName y CloudinaryConfig.uploadPresetVideo antes de subir videos.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloud/video/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['folder'] = CloudinaryConfig.videoFolder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();

    final total = streamed.contentLength ?? 0;
    int received = 0;

    final bytes = <int>[];
    await for (final chunk in streamed.stream) {
      bytes.addAll(chunk);
      if (total > 0) {
        received += chunk.length;
        final p = received / total;
        onProgress?.call(p.clamp(0.0, 1.0));
      }
    }

    final body = utf8.decode(bytes);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(
        'Error al subir a Cloudinary (${streamed.statusCode}): $body',
      );
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Respuesta de Cloudinary sin secure_url: $body');
    }
    onProgress?.call(1.0);
    return url;
  }
}
