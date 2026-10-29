enum ImagePromptSuggestion {
  explain('Explain this', 'Explain the material in this image.'),
  summarize('Summarize this', 'Summarize the material in this image.'),
  solve('Solve this', 'Solve the problem shown and explain every step.'),
  concepts('Key concepts', 'Identify and explain the key concepts shown.'),
  exam('Exam questions', 'Create likely exam questions from this material.'),
  simple('Explain simply', 'Explain this in very simple language.');

  const ImagePromptSuggestion(this.label, this.question);

  final String label;
  final String question;
}
