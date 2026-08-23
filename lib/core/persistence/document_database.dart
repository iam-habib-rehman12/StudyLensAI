class StoredDocument {
  const StoredDocument({required this.id, required this.data});

  final String id;
  final Map<String, Object?> data;
}

class ServerTimestampValue {
  const ServerTimestampValue._();
}

const serverTimestamp = ServerTimestampValue._();

abstract interface class DocumentDatabase {
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
    bool merge = false,
  });

  Future<Map<String, Object?>?> getDocument(String path);

  Stream<List<StoredDocument>> watchCollection({
    required String path,
    required String orderBy,
    bool descending = false,
    int? limit,
  });
}
