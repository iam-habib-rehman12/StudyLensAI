# Day 9 - PDF Intelligence

StudyLens now selects one PDF through the Android document picker and keeps its
bytes only in memory. Cloud Storage is not required.

## Validation

Before AI or Firestore is used, the document layer verifies:

- the `.pdf` filename extension;
- a non-empty file no larger than 10 MB;
- a PDF header within the first 1,024 bytes;
- a PDF end marker within the final 2,048 bytes.

These checks reject common unsupported, renamed, empty, oversized, truncated,
and damaged inputs. Gemini can still report page-level unreadable content; the
centralized document prompt requires it to state that limitation instead of
inventing content.

## AI and persistence

The validated bytes are sent inline as `application/pdf` through `AiService`.
The user can request a summary, important topics, revision notes, or custom Q&A.
Only the study session and completed conversation messages are persisted in the
user's Firestore path. PDF bytes and device paths are never persisted.

## Failure behavior

Picker, malformed document, oversized document, offline, App Check,
rate-limit, empty AI response, and Firestore save failures have explicit user
states. AI retries reuse the saved student request and do not create duplicate
messages.
