# Account Lifecycle

StudyLens now supports the full email/password account lifecycle.

## Registration and verification

- Registration creates the Firebase Auth account and the matching Firestore
  profile.
- A verification email is sent immediately after profile creation. Failure to
  send it does not roll back the account; it can be resent from Profile.
- Profile shows whether the email is verified and exposes resend and
  **Refresh status** actions. Refresh reloads the Auth user and updates the
  badge without signing out.
- Verification is intentionally non-blocking for the semester demo. A stricter
  release can gate app access on `emailVerified`.

## Password reset

- Login exposes **Forgot password?**.
- The reset uses the entered email address and always shows a neutral
  confirmation, avoiding account enumeration.
- Firebase rate-limit and network failures map to user-safe messages.

## Account deletion

Deletion requires the current password so Firebase can perform a recent
reauthentication. The client then deletes data in this order:

```text
messages -> sessions -> quizzes -> quizResults -> profile -> Auth account
```

Rules allow delete only for the owning user on every collection. If data cleanup
fails, the Auth account is kept and the user can retry; the app never reports a
successful deletion after a partial cleanup.

The deletion flow is a client-side best-effort cleanup. For a production launch
with large histories, replace it with a callable Cloud Function or Admin SDK job
that deletes the user tree server-side after reauthentication.

## UI

- **Login**: password reset action with a neutral result snackbar.
- **Profile**: verified/unverified email chip, resend action, and a destructive
  delete action guarded by a password confirmation dialog.
- **Sign out** remains separate from deletion.

## Tests

- Repository: verification on registration, reset forwarding, reauth-before-
  cleanup ordering, and no cleanup when reauthentication fails.
- Controller: reset, resend, delete success/failure, and error normalization.
- Data cleaner: message/session/quiz/result/profile deletion order.
- Widgets: resend verification, delete confirmation, password reset.
- Firestore rules: owner-only delete for profiles, sessions, messages, quizzes,
  and results.
