# ExpiryVault

Never miss a document expiry again.

ExpiryVault is a private, on-device vault for the documents that expire —
PUC, vehicle insurance, driving licence, RC / registration certificate,
passport, and anything else. Add a document with its number and expiry
date, attach a photo of it, and ExpiryVault reminds you **30 days, 7 days
and 1 day before it expires** — so you renew on time instead of paying a
fine.

## Features

- **Add documents** — type (PUC, vehicle insurance, driving licence, RC,
  passport, other), document number, issuing authority (optional), expiry
  date, and a photo from the camera or gallery.
- **Manual date entry** — the expiry date is entered by you with a date
  picker. There is deliberately no OCR: a misread date is worse than no
  date at all.
- **Dashboard** — all documents sorted by expiry date, with status badges:
  **Valid** (green), **Expiring Soon** (amber, ≤ 30 days), **Expired**
  (red), plus a days-remaining counter on every document.
- **Local reminders** — notifications at 30, 7 and 1 day(s) before expiry,
  at 9:00am local time, via `flutter_local_notifications` + `timezone`.
  Reminders are rescheduled automatically when a document is edited or
  renewed, and cancelled when it is deleted.
- **Detail view** — full-screen photo viewer, all fields, edit, delete,
  and **Mark renewed**: pick the new expiry date and the old one is kept
  in a renewal history.
- **Search & filter** — search by name, number or issuer; filter by
  document type and by status.
- **First-run onboarding** — a short 3-page walkthrough on first launch.
- **Starts empty** — no sample documents. Everything you see is yours.
- **Private by design** — all data lives in a local SQLite database and
  photos are stored in the app's private documents directory. No account,
  no cloud, nothing uploaded.

## Tech

- Flutter 3.50 (Android)
- `sqflite` — local document + renewal-history storage
- `path_provider` + `image_picker` — photos stored in the app documents
  directory
- `flutter_local_notifications` + `timezone` — zoned local reminders
- Pure-Dart expiry math in `lib/utils/expiry_logic.dart` (fully unit-tested)

## Build & run

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Release APK (from the project root):

```bash
flutter build apk --release
```

## Project structure

```
lib/
  main.dart                     App entry, routes, theme
  models/document.dart          ExpiryDocument, RenewalRecord, DocumentType
  utils/expiry_logic.dart       Days-remaining, status, reminder-date math
  services/
    database_service.dart       SQLite CRUD + renewal history
    notification_service.dart   30/7/1-day zoned reminders
    photo_service.dart          Camera/gallery pick + private storage
    onboarding_service.dart     First-run flag
  screens/
    onboarding_screen.dart      First-run walkthrough
    home_screen.dart            Dashboard, search, filters
    add_edit_screen.dart        Add / edit form + photo
    detail_screen.dart          Photo viewer, fields, renew, delete
  widgets/
    document_card.dart          Dashboard row
    status_badge.dart           Valid / Expiring Soon / Expired badge
test/
  expiry_logic_test.dart        Status, days-remaining, reminders, leap years
  document_model_test.dart      Model serialisation round-trips
  widget_test.dart              Onboarding, add/edit form, cards, badges
```

## Permissions (Android)

- `INTERNET` — Flutter engine requirement
- `CAMERA` — photographing documents
- `POST_NOTIFICATIONS` — expiry reminders (Android 13+, requested at runtime)
- `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` —
  reminder scheduling support

## License

MIT — see [LICENSE](LICENSE).
