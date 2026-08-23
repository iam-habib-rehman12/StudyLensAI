import '../domain/study_message.dart';

enum TutorStatus { ready, savingQuestion, streaming, savingAnswer }

class TutorState {
  const TutorState({
    this.status = TutorStatus.ready,
    this.messages = const [],
    this.sessionId,
    this.streamingText = '',
    this.errorMessage,
    this.canRetry = false,
  });

  final TutorStatus status;
  final List<StudyMessage> messages;
  final String? sessionId;
  final String streamingText;
  final String? errorMessage;
  final bool canRetry;

  bool get isBusy => status != TutorStatus.ready;

  TutorState copyWith({
    TutorStatus? status,
    List<StudyMessage>? messages,
    String? sessionId,
    String? streamingText,
    String? errorMessage,
    bool clearError = false,
    bool? canRetry,
  }) {
    return TutorState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      streamingText: streamingText ?? this.streamingText,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      canRetry: canRetry ?? this.canRetry,
    );
  }
}
