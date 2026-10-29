# Day 11 - Quiz Player and Results

Day 11 turns a validated generated quiz into a complete study attempt.

## Flow

```text
Generated quiz preview -> Start quiz -> answer every question
-> submit -> deterministic score -> save result -> review answers
```

The player is reached from the quiz preview and receives the validated `Quiz`
as a route argument. A missing quiz or unauthenticated user resolves to the
safe "page not found" screen.

## Answering

- One question is shown at a time with numbered navigation chips.
- Previous/next navigation preserves every selected answer.
- Submission stays disabled until every question has an answer.
- Selecting an answer never sends data to AI or Firestore.

## Scoring

`QuizScoring.grade` is pure and deterministic:

- every question contributes exactly one correct or incorrect answer;
- selected indexes must be inside each question's option list;
- the answer count must equal the question count;
- `xpEarned = correctAnswers * 10`.

The result reuses the quiz's optional `sessionId`, is stamped with the current
UTC time, and is written to `users/{uid}/quizResults/{resultId}` with a server
timestamp. Profile-level XP and level aggregates are calculated on read in
Day 12; each result already stores its earned XP.

## Reliability

- The result ID is generated once per attempt and reused when a save is retried,
  so an ambiguous Firestore failure cannot create a duplicate result.
- A failed save keeps the score and review visible with an explicit retry action.
- Submission is ignored while a save is in flight and after completion.
- Empty or incomplete answer sets are rejected before any repository call.

## Tests

- Pure scoring: all correct, partial, all incorrect, invalid lengths/indexes.
- Controller: navigation, retained answers, incomplete submission, success,
  save failure, retry idempotency.
- Widget: answer flow, score/review rendering, failed-save retry.
- Persistence: user-scoped path, server timestamp, ownership validation.
