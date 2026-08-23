import 'package:cloud_firestore/cloud_firestore.dart';

import '../errors/app_exception.dart';
import 'document_database.dart';

class FirestoreDocumentDatabase implements DocumentDatabase {
  FirestoreDocumentDatabase([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> setDocument({
    required String path,
    required Map<String, Object?> data,
    bool merge = false,
  }) async {
    try {
      await _instance.doc(path).set(_encodeMap(data), SetOptions(merge: merge));
    } on FirebaseException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  @override
  Future<Map<String, Object?>?> getDocument(String path) async {
    try {
      final snapshot = await _instance.doc(path).get();
      final data = snapshot.data();
      return data == null ? null : _decodeMap(data);
    } on FirebaseException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  @override
  Stream<List<StoredDocument>> watchCollection({
    required String path,
    required String orderBy,
    bool descending = false,
    int? limit,
  }) async* {
    try {
      Query<Map<String, dynamic>> query = _instance
          .collection(path)
          .orderBy(orderBy, descending: descending);
      if (limit != null) query = query.limit(limit);

      await for (final snapshot in query.snapshots()) {
        yield snapshot.docs
            .map(
              (document) => StoredDocument(
                id: document.id,
                data: _decodeMap(document.data()),
              ),
            )
            .toList(growable: false);
      }
    } on FirebaseException catch (error) {
      throw _mapFirebaseError(error);
    }
  }

  Map<String, dynamic> _encodeMap(Map<String, Object?> data) {
    return data.map((key, value) => MapEntry(key, _encodeValue(value)));
  }

  Object? _encodeValue(Object? value) {
    return switch (value) {
      ServerTimestampValue() => FieldValue.serverTimestamp(),
      Map<String, Object?>() => _encodeMap(value),
      List<Object?>() => value.map(_encodeValue).toList(growable: false),
      _ => value,
    };
  }

  Map<String, Object?> _decodeMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _decodeValue(value)));
  }

  Object? _decodeValue(Object? value) {
    return switch (value) {
      Timestamp() => value.toDate(),
      Map<String, dynamic>() => _decodeMap(value),
      List<Object?>() => value.map(_decodeValue).toList(growable: false),
      _ => value,
    };
  }

  AppException _mapFirebaseError(FirebaseException error) {
    final type = switch (error.code) {
      'permission-denied' => AppErrorType.permissionDenied,
      'unavailable' || 'deadline-exceeded' => AppErrorType.offline,
      _ => AppErrorType.persistence,
    };
    final message = switch (type) {
      AppErrorType.permissionDenied =>
        'You do not have permission to access this study data.',
      AppErrorType.offline =>
        'Study data is unavailable while you are offline. Try again when connected.',
      _ =>
        'StudyLens could not save or load your study data. Please try again.',
    };
    return AppException(type: type, message: message, cause: error);
  }
}
