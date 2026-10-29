enum DocumentStudyAction { summary, importantTopics, revisionNotes, question }

extension DocumentStudyActionLabel on DocumentStudyAction {
  String get label => switch (this) {
    DocumentStudyAction.summary => 'Document summary',
    DocumentStudyAction.importantTopics => 'Important topics',
    DocumentStudyAction.revisionNotes => 'Revision notes',
    DocumentStudyAction.question => 'Document question and answer',
  };

  String get prompt => switch (this) {
    DocumentStudyAction.summary =>
      'Summarize this document for a university student.',
    DocumentStudyAction.importantTopics =>
      'Identify and prioritize the most important topics in this document.',
    DocumentStudyAction.revisionNotes =>
      'Create structured revision notes from this document.',
    DocumentStudyAction.question => '',
  };
}
