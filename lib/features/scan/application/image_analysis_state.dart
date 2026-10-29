import '../../../core/ai/ai_explanation_mode.dart';
import '../../tutor/domain/study_message.dart';

enum ImageAnalysisStatus { ready, savingQuestion, streaming, savingAnswer }

class ImageAnalysisState {
  const ImageAnalysisState({
    this.status = ImageAnalysisStatus.ready,
    this.mode = AiExplanationMode.normal,
    this.messages = const [],
    this.sessionId,
    this.streamingText = '',
    this.errorMessage,
    this.canRetry = false,
  });

  final ImageAnalysisStatus status;
  final AiExplanationMode mode;
  final List<StudyMessage> messages;
  final String? sessionId;
  final String streamingText;
  final String? errorMessage;
  final bool canRetry;

  bool get isBusy => status != ImageAnalysisStatus.ready;

  ImageAnalysisState copyWith({
    ImageAnalysisStatus? status,
    AiExplanationMode? mode,
    List<StudyMessage>? messages,
    String? sessionId,
    String? streamingText,
    String? errorMessage,
    bool clearError = false,
    bool? canRetry,
  }) => ImageAnalysisState(
    status: status ?? this.status,
    mode: mode ?? this.mode,
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    streamingText: streamingText ?? this.streamingText,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    canRetry: canRetry ?? this.canRetry,
  );
}
