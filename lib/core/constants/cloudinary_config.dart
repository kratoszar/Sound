class CloudinaryConfig {
  CloudinaryConfig._();

  /// Nombre del cloud de Cloudinary.
  static const String cloudName = 'm46ma3tm';

  /// Upload preset unsigned para media (video/audio/imágenes).
  /// Crea este preset en Cloudinary: Settings > Upload > Add upload preset > Unsigned.
  static const String uploadPresetVideo = 'soundwave_video_preset';

  /// Carpeta opcional donde se guardarán los videos.
  static const String videoFolder = 'soundwave/videos';

  /// Carpeta opcional para archivos de audio.
  static const String audioFolder = 'soundwave/audio';

  /// Carpeta opcional para portadas/imágenes.
  static const String coverFolder = 'soundwave/covers';
}
