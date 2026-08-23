# Firestore Schema

Day 5 establishes a user-owned schema without Cloud Storage. Image and PDF
bytes remain local/ephemeral in later intake milestones; only structured study
records belong in Firestore.

## Hierarchy

```text
users/{userId}
  sessions/{sessionId}
    messages/{messageId}
  quizzes/{quizId}
  quizResults/{resultId}
```

Every stored document repeats its own ID and `userId`. Repositories verify that
those values match the document path before returning a model.

## Documents

### Student profile

```text
uid, name, email, createdAt, xp, level, totalQuestions, correctAnswers
```

### Study session

```text
id, userId, title, materialType, status, createdAt, updatedAt
```

`materialType` is `text`, `image`, or `pdf`. `status` moves only from `active`
to `completed`.

### Study message

```text
id, userId, sessionId, role, content, createdAt
```

`role` is `student` or `assistant`. Messages are immutable after creation.

### Quiz

```text
id, userId, sessionId?, title, questionCount, questions[], createdAt
```

Each question contains `id`, `question`, exactly four unique `options`, a
`correctOptionIndex`, and a non-empty `explanation`. Domain validation rejects
empty, duplicate, inconsistent, or malformed quiz data before presentation.

### Quiz result

```text
id, userId, quizId, sessionId?, selectedOptionIndexes,
correctAnswers, totalQuestions, completedAt, xpEarned
```

Completed results are immutable. Atomic profile progress updates are scheduled
with quiz completion in Day 11.

## Reliability and security

- Firebase values and server timestamps are translated in the centralized
  document database service.
- Permission-denied, offline, malformed-document, and persistence failures map
  to user-safe application errors.
- Security rules restrict every read and write to the authenticated path owner.
- Writes validate allowed keys, ownership, sizes, state transitions, and parent
  document existence.
- Cloud Storage remains outside the core MVP dependency path.

Publish `firestore.rules` in Firebase Console before exercising these
repositories against the live project. The optional Firebase Emulator Suite
uses Auth port `9099` and Firestore port `8080`, matching the application
configuration.
