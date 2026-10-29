# Day 12 - History and Progress

Day 12 connects the saved Firestore records to the Home, History, and Progress
tabs. All three screens share one `StudyOverviewController`, so they show the
same live data and only open one subscription per collection.

## Data sources

```text
StudySessionRepository.watchRecentSessions(uid, limit: 50)
QuizRepository.watchRecentQuizzes(uid, limit: 50)
QuizResultRepository.watchRecentResults(uid, limit: 500)
```

The overview waits for the first emission from all three streams before it
reports ready. Each stream stays live, so a new session or quiz result appears
without a manual refresh.

## History feed

`HistoryEntry.build` joins sessions and completed quiz results:

- sessions use their material type, title, completion state, and `updatedAt`;
- quiz results use the saved quiz title (falling back to `Quiz result`),
  score, accuracy, XP, and `completedAt`;
- entries are sorted newest-first and capped at 50.

## Derived progress

Progress is calculated from the 500 most recent saved quiz results; no aggregate
is written to the student profile:

```text
questions   = sum(result.totalQuestions)
correct     = sum(result.correctAnswers)
accuracy    = correct / questions
XP          = sum(result.xpEarned)
level       = 1 + XP ~/ 200
level XP    = XP % 200
today       = results completed in the current local calendar day
```

Each correct answer is worth 10 XP (`QuizScoring`). The profile document keeps
its original read-only aggregate fields; the rules do not need to allow updates.

## Screens

- **Home**: three most recent history entries and today's questions, quizzes,
  accuracy, total XP, and level.
- **History**: the full 50-entry feed with material-specific icons.
- **Progress**: level, XP total, level progress bar, accuracy, correct answers,
  questions answered, and the ten most recent quiz results.

Loading, empty, offline, and generic failure states are handled centrally by
`OverviewLoading` / `OverviewFailure`; failure screens offer a retry that
re-subscribes all three streams.

## Tests

- Pure progress aggregation, level boundaries, and same-day filtering.
- History joining, sorting, title fallback, and limits.
- Overview controller readiness, offline failure, retry, and disposal.
- Home, History, and Progress widget rendering plus failure/retry behavior.
- Relative timestamp formatting.
