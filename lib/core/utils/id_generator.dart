import 'dart:math';

abstract interface class IdGenerator {
  String next(String prefix);
}

class SecureIdGenerator implements IdGenerator {
  SecureIdGenerator() : _random = Random.secure();

  final Random _random;

  @override
  String next(String prefix) {
    final normalizedPrefix = prefix.trim();
    if (normalizedPrefix.isEmpty || normalizedPrefix.contains('/')) {
      throw ArgumentError.value(prefix, 'prefix', 'Must be one path segment.');
    }
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = _random.nextInt(0x7fffffff).toRadixString(36);
    return '${normalizedPrefix}_$time$random';
  }
}
