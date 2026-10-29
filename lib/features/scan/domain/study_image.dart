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

  String? get resolvedMimeType {
    final declared = mimeType?.toLowerCase().split(';').first.trim();
    if (const {'image/jpeg', 'image/png', 'image/webp'}.contains(declared)) {
      return declared;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }
}

extension StudyImageSourceLabel on StudyImageSource {
  String get label => switch (this) {
    StudyImageSource.camera => 'Camera',
    StudyImageSource.gallery => 'Gallery',
  };
}
