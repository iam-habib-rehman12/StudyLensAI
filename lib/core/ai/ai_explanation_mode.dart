enum AiExplanationMode { simple, normal, detailed, exam }

extension AiExplanationModeLabel on AiExplanationMode {
  String get label => switch (this) {
    AiExplanationMode.simple => 'Simple',
    AiExplanationMode.normal => 'Normal',
    AiExplanationMode.detailed => 'Detailed',
    AiExplanationMode.exam => 'Exam',
  };
}
