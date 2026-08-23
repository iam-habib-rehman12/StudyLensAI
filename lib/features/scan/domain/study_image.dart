import 'dart:typed_data';

enum StudyImageSource { camera, gallery }

class StudyImage {
  StudyImage({
    required this.name,
    required Uint8List bytes,
    required this.source,
    this.mimeType,
  }) : bytes = Uint8List.fromList(bytes);

  final String name;
  final Uint8List bytes;
  final StudyImageSource source;
  final String? mimeType;

  int get byteLength => bytes.lengthInBytes;
}

extension StudyImageSourceLabel on StudyImageSource {
  String get label => switch (this) {
    StudyImageSource.camera => 'Camera',
    StudyImageSource.gallery => 'Gallery',
  };
}
