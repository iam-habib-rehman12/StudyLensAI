import 'package:studylens_ai/core/persistence/document_database.dart';

class DatabaseWrite {
  const DatabaseWrite({
    required this.path,
    required this.data,
    required this.merge,
  });

  final String path;
  final Map<String, Object?> data;
  final bool merge;
}

class FakeDocumentDatabase implements DocumentDatabase {
  final Map<String, Map<String, Object?>> documents = {};
  final Map<String, List<StoredDocument>> collections = {};
  final List<DatabaseWrite> writes = [];
  final List<String> deleted = [];

  @override
  Future<Map<String, Object?>?> getDocument(String path) async {
    return documents[path];
  }

  @override
  Future<List<StoredDocument>> getCollection({
    required String path,
    int? limit,
  }) async {
    final values = collections[path] ?? const <StoredDocument>[];
    return limit == null
        ? values
        : values.take(limit).toList(growable: false);
  }

  @override
  Future<void> deleteDocument(String path) async {
    deleted.add(path);
    documents.remove(path);
  }

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
    bool merge = false,
  }) async {
    writes.add(DatabaseWrite(path: path, data: data, merge: merge));
    documents[path] = merge
        ? {...?documents[path], ...data}
        : Map<String, Object?>.from(data);
  }

  @override
  Stream<List<StoredDocument>> watchCollection({
    required String path,
    required String orderBy,
    bool descending = false,
    int? limit,
  }) {
    final values = collections[path] ?? const [];
    return Stream.value(
      limit == null ? values : values.take(limit).toList(growable: false),
    );
  }
}
