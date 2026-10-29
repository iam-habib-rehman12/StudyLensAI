# Multimodal image learning

Day 8 connects camera/gallery images to Firebase AI Logic without Cloud
Storage. The selected `StudyImage` remains in memory and its bytes are sent as
inline Gemini input alongside each question.

## User flow

1. Open **Scan & Learn** and capture or choose a clear image.
2. Confirm the preview and tap **Ask StudyLens**.
3. Select Simple, Normal, Detailed, or Exam mode.
4. Choose a prompt chip or enter a custom question.
5. Continue asking follow-up questions about the same image.

Only the text conversation and typed image session metadata are saved in
Firestore. Image bytes are never written to Firestore or Cloud Storage.

## Reliability rules

- JPEG, PNG, and WebP are accepted; MIME type is verified or detected from the
  file signature.
- The same image bytes are resent for every follow-up so visual context is not
  lost when a new AI chat request is created.
- Recent complete text turns are bounded by the shared conversation policy.
- Prompts require the model to identify unreadable details and avoid inventing
  image contents.
- Questions are persisted before AI execution. Retrying an offline, rate-limit,
  empty, or AI failure does not duplicate the saved question.
- A completed answer is persisted only after non-empty output is validated.

## Firebase setup

The feature uses the existing Firebase AI Logic and App Check configuration.
No Storage bucket or paid persistent file-storage setup is required. On a
physical debug device, register the App Check debug token before testing AI.
