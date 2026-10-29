import '../../tutor/domain/study_message.dart';
import '../domain/study_document.dart';

enum DocumentAnalysisStatus {
  ready,
  selecting,
  savingRequest,
  streaming,
  savingAnswer,
}

class DocumentAnalysisState {
  const DocumentAnalysisState({
    this.status = DocumentAnalysisStatus.ready,
    this.document,
    this.messages = const [],
    this.sessionId,
    this.streamingText = '',
    this.errorMessage,
    this.canRetry = false,
  });

  final DocumentAnalysisStatus status;
  final StudyDocument? document;
  final List<StudyMessage> messages;
  final String? sessionId;
  final String streamingText;
  final String? errorMessage;
  final bool canRetry;

  bool get isBusy => status != DocumentAnalysisStatus.ready;

  DocumentAnalysisState copyWith({
    DocumentAnalysisStatus? status,
    StudyDocument? document,
    bool clearDocument = false,
    List<StudyMessage>? messages,
    String? sessionId,
    String? streamingText,
    String? errorMessage,
    bool clearError = false,
    bool? canRetry,
  }) => DocumentAnalysisState(
    status: status ?? this.status,
    document: clearDocument ? null : document ?? this.document,
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    streamingText: streamingText ?? this.streamingText,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    canRetry: canRetry ?? this.canRetry,
  );
}
