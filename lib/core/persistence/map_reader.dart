class MapReader {
  const MapReader(this.data);

  final Map<String, Object?> data;

  String string(String key, {bool allowEmpty = false}) {
    final value = data[key];
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FormatException('Expected a non-empty string at "$key".');
    }
    return value;
  }

  String? nullableString(String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected a string or null at "$key".');
    }
    return value;
  }

  int integer(String key, {int? minimum, int? maximum}) {
    final value = data[key];
    if (value is! int ||
        (minimum != null && value < minimum) ||
        (maximum != null && value > maximum)) {
      throw FormatException('Expected a valid integer at "$key".');
    }
    return value;
  }

  DateTime dateTime(String key) {
    final value = data[key];
    if (value is! DateTime) {
      throw FormatException('Expected a timestamp at "$key".');
    }
    return value;
  }

  List<Object?> list(String key) {
    final value = data[key];
    if (value is! List<Object?>) {
      throw FormatException('Expected a list at "$key".');
    }
    return value;
  }
}
