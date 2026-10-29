# Day 10 - Structured Quiz Generation

Day 10 adds reliable multiple-choice quiz generation from a student-entered
topic, passage, or set of notes. Quiz completion and scoring remain the Day 11
milestone.

## Generation boundary

Presentation widgets call `QuizGenerationController`. The controller calls a
quiz-generation repository, which is the only layer allowed to coordinate
Firebase AI Logic and Firestore. Widgets never call either SDK.

The AI model uses:

- a centralized quiz system instruction and prompt;
- `application/json` response MIME type;
- a Firebase AI response schema with an exact question count;
- a lower quiz-specific temperature for more deterministic output.

## Validation

Schema output is treated as untrusted. Before a quiz can be shown or saved,
StudyLens requires:

- exactly the requested 5, 10, or 15 questions;
- only the expected JSON fields;
- non-empty bounded title, question text, options, and explanations;
- exactly four unique options per question;
- one correct zero-based index from 0 through 3;
- unique question text and locally generated IDs.

Malformed output is discarded and shown as a retryable error. If generation
succeeds but Firestore saving fails, retry saves the already validated quiz
without making another AI request.

## Persistence

Only a fully validated `Quiz` is saved under
`users/{uid}/quizzes/{quizId}`. The source notes are sent for the generation
request but are not persisted by this feature.

## Starting the quiz

The validated preview exposes **Start quiz**, which opens the Day 11 player
with the saved quiz. See [the quiz player](QUIZ_PLAYER.md).
