# Day 13 - Reliability and Visual Polish

Day 13 hardens the existing flows rather than adding new features.

## Markdown answers

Tutor, image, and PDF answers now render a safe Markdown subset instead of
showing raw markers:

- headings from `#` through `###`;
- bullet and numbered lists;
- block quotes and fenced code blocks;
- inline bold, italic, and code spans.

Plain responses still render as a normal `Text` widget, so simple answers keep
their original layout. Unmatched markers remain readable text. Rendering is
local; no HTML or WebView is involved.

## Media limits and memory

- PDFs are limited to **10 MB** (about 13.3 MB after base64 expansion), leaving
  room under Gemini's 20 MB inline request limit.
- Images keep the existing 12 MB and 2400 px intake limits.
- The image-analysis header decodes a `cacheWidth` thumbnail instead of a
  full-resolution bitmap.

## Picker recovery

- Document and image pickers now time out after two minutes with a retryable,
  user-safe message instead of leaving the UI busy forever.
- The Android document picker reports interruption from `onDestroy` when the
  activity is destroyed before a result arrives.
- `registerForActivityResult` is not available because `FlutterActivity`
  extends `android.app.Activity`; the existing `startActivityForResult` path is
  retained and documented, with the Dart timeout as the recovery boundary.

## Accessibility and responsiveness

- Icon-only actions expose tooltips or semantic labels.
- Selected images have semantic labels.
- The Home action grid grows taller as text scaling increases.
- A widget test renders Home, History, and Progress at 1.6x text scale and
  asserts no overflow.
- Light and dark themes continue to follow the system setting.

## Existing safeguards

- Controllers reject duplicate submissions while saving or streaming.
- Request tokens prevent stale results from updating a disposed or superseded
  screen.
- Retry actions reuse validated IDs and persisted questions.
- Offline, permission, rate-limit, configuration, malformed, and persistence
  failures map to user-safe messages with recovery actions.
