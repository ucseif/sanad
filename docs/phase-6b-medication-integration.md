# Phase 6B — Existing Flutter medication backend integration

Implemented against the actual Phase 6A v1 medication contract. The Laravel
repository, database schema and business rules were not changed during Phase 6B.
The user reported that the development medication migration had already been
applied. No migrations, database resets, scheduler activation, real notifications,
commits, pushes or deployment were performed.

## Delivered interactions

- The existing medication tab and settings shortcut continue to use the same
  navigation and widget layout. Home forwards its existing AuthService to the
  medication component; the component obtains the actual authenticated profile
  and server ID rather than trusting a local cache identity.
- The existing medicine cards, dose chips, summary/progress and Up Next now use
  server records, occurrences, versions, statuses, totals and allowed actions.
  No local recurrence, automatic Missed classification or intake counters remain.
- Add uses the existing bottom sheet and options. Tap a medicine card's **title**
  to fetch details and reuse the prefilled bottom sheet for editing. Pending
  prescription edits are prefilled while today's cards retain the current
  prescription. Backend next-day effective boundaries remain authoritative.
- Swipe-to-archive waits for server confirmation and then refreshes the list.
  Today's retained historical totals remain visible even when no active medicines
  remain. No local deletion is presented as a completed archive.
- Patient Taken uses the existing check/chip tap; patient Skipped uses the existing
  long press. Both submit the occurrence ID/version and refresh dashboard plus
  affected medication/dose. Repeated taps are blocked while a mutation is pending.
- Dose openings on resolved or Missed chips fetch details without recording Taken.
  Missed opens provide a localized explanation that the explicit late-reporting
  interaction is not available yet. Returned event history is retained in controller
  state for the separately approved history interaction.
- Reminder and consent controls use their separate documented endpoints/versions.
  Caregiver consent and delay controls are disabled; caregiver create payloads
  omit patient-consent fields entirely. Ordinary reminder management remains allowed.
- A refresh action, server refresh while the visible app is resumed, and a
  foreground minute refresh keep displayed state server-backed. No offline mutation
  queue, local medication schedule, push transport or notification claim was added.

The existing form colors, fonts, dose/form/frequency choices, spacing, time picking,
meal instructions and RTL/LTR structure were retained. Minimal integration additions
are the refresh action and explicit timezone dialog. A few empty-state labels now
say no upcoming/actionable doses rather than falsely claiming missed doses completed.
No Missed Dose card or new history/navigation design was introduced.

## Caregiver entry blocker — intentionally not invented

This checkout has **no selected linked-patient state or selector**. Its existing
relationship DTO/API exposes counterpart name/username, not the patient server ID
required by `/api/v1/patients/{patientId}`. The relationship implementation was
left untouched, as requested.

The repository/controller and existing medication component support an explicit
`selectedPatientId`; HealthDashboard forwards that optional value. This path is
tested with caregiver authentication, including denied intake and access revocation.
However, the current Home host has no authorized patient-selection value to supply.
Consequently, a caregiver entering the root medication tab receives a localized
selection-required state and **no medication request is made using the caregiver's
own ID**.

Completing the caregiver entry path requires separately authorizing a reliable
patient-ID-bearing selection contract and its host wiring. Names, usernames, local
indexes, hardcoded IDs, direct database lookup and nonexistent API endpoints are not
used as substitutes. The two-caregiver backend rule is unchanged; no changes were
made to the existing caregiving Dart files.

## Transport, identity and mutation safety

- Uses existing ApiClient, SANAD_API_BASE_URL origin validation, Sanctum Bearer token
  and secure TokenStore. Medication paths include `/api/v1` exactly once.
- ApiClient gained PATCH and an optional validated UUID idempotency header for
  POST/PATCH. Existing authentication calls remain unchanged.
- Each new mutation has a secure UUIDv4. An unchanged create-form retry preserves
  its intention key after a timeout/uncertain result; changing the form intention
  creates a new key. No automatic write retries are performed.
- Actual medication, preferences, settings and occurrence versions come from API
  responses; they are never replaced with fixed expected versions.
- Conflict responses refresh authoritative data and close the obsolete edit form.
  The localized message requires reopening/reviewing the refreshed record. No
  caregiver's concurrent changes are silently overwritten.
- Partial saves across prescription/reminder/consent endpoints are reconciled;
  these endpoints are not represented as one atomic backend transaction. Errors
  remain visible. An obsolete edit form cannot keep resending stale versions.
- Token binding and generation checks discard both successes and failures from a
  previous session. Revocation/authorization failures clear private medication and
  event data, and close affected forms. Unknown-result failures require server
  reconciliation before another mutation is enabled.
- Allowed actions and authenticated role jointly control UI actions; the server
  remains the authority on every operation. 401/403/404/409/422/429 use localized
  error handling; raw server error bodies are not rendered as localization keys.

## Timezone and calendar behavior

Patient bootstrap reads medication-settings and requires explicit confirmation
before relying on a default. A small dialog suggests the device's IANA identifier
when available, accepts an explicitly entered valid identifier, and PATCHes the
patient settings using its returned version. It never silently chooses Africa/Cairo
or sends an abbreviation such as EET.

The existing `sanad/device` native channel gained `getTimezone` on Android and iOS;
the existing battery method is preserved. Missing/invalid platform suggestions
remain null and require explicit input. This channel was mocked in Dart tests;
physical Android/iOS execution was not verified.

Caregivers use a confirmed patient default where available; otherwise the same
small interaction requests an explicit **schedule** timezone, without impersonating
patient default confirmation. Editing preserves the schedule's original timezone.
Phone-zone changes do not revise backend schedules.

One dependency was added: `timezone: 0.11.2`. Its IANA database converts the server's
absolute `server_now` into the requested viewer calendar day, including DST and
cross-midnight conversion. The phone clock does not determine dose status or the
authoritative Today request. Original schedule-local date/time and UTC timestamps
are retained separately. New-form dates use the server day in the schedule zone;
historical prescription start dates remain valid date-picker selections.
Package reference: [timezone documentation](https://pub.dev/documentation/timezone/latest/).

## API coverage

All suffixes below use `/api/v1/patients/{actualTargetId}`:

| API | Integration |
|---|---|
| GET/PATCH medication-settings | Read default and explicit patient bootstrap |
| GET medications | Active list, bounded pagination aggregation |
| POST medications | Existing add form, including PRN schedule definition |
| GET/PATCH medications/{id} | Existing card-title edit interaction |
| POST medications/{id}/archive | Existing swipe action |
| GET medication-dashboard | Summary, cards, original times/statuses, Up Next, separate missed data |
| GET medication-doses | Repository date-range access for existing/future consumers |
| GET medication-doses/{id} | Read-only opening and post-intake reconciliation |
| POST medication-doses/{id}/taken | Existing patient check/chip |
| POST medication-doses/{id}/skipped | Existing patient long press |
| PATCH medications/{id}/reminder-preferences | Existing ordinary reminder switch |
| PATCH medications/{id}/escalation-consent | Existing patient-only consent/delay |
| POST medication-doses/{id}/late-intake, corrections | Correct repository methods; no unsuitable replacement UI invented |
| GET medications/{id}/adherence | Repository date-range history access; no corresponding screen exists |

Dashboard/list pages are aggregated with a 100-page safety bound. Summary/Up Next
remain server values and are not derived from page contents. Missed data remains
separate in the controller and is not substituted for Up Next. Large histories may
hit server limits; pagination UI is a future explicit design decision.

## UI capabilities requiring separate approval

- The caregiver patient-selection/ID entry path described above.
- An explicit late-intake interaction collecting actual intake time and confirmation.
- A correction interaction collecting reason, target status and optional corrected
  actual time; the old local toggle-to-pending behavior is not treated as audited
  correction consent.
- PRN manual intake/void interaction and medication adherence/event-history screen.
- A separate Missed Dose warning card. Data is available; no new card was designed.
- Any existing-local-cache migration/import. Old secure-storage medication entries
  are no longer read, written or uploaded as an independent source of truth.

## Verification evidence

Commands ran from the Flutter repository:

```powershell
dart format <the 16 changed/new Dart files only>
flutter analyze --no-pub
flutter test --no-pub --reporter json
```

- Analyzer: **No issues found**.
- New medication coverage: **33 passed**, including DTO/schema validation, enum
  mapping, server counts/Up Next, IANA/DST/clock handling, actual server IDs,
  caregiver restrictions, headers/versions, same-key retries, conflicts, session
  changes, add/edit/archive widgets, history-only totals and Arabic/RTL bootstrap.
- Existing auth/service/transport/storage and auth-screen group: **156 passed**;
  this includes **4 session-navigation tests**.
- Full Flutter suite: **225 passed / 11 failed**. Baseline before changes was
  **192 passed / the same 11 failed**. Comparison found **zero newly failing tests**.
- Independent read-only review found four issues, each reproduced RED then fixed
  GREEN: uncertain-create retry keys, stale conflicted forms, damaged Arabic text,
  and retained daily totals after archiving the final active medicine.

The unchanged baseline failures are:

1. floating dock overlays the viewport and leaves the final content visible
2. selection indicator travels smoothly between destinations
3. reduced motion changes destination without animating the dock
4. bottom navigation opens all five pages including the account
5. complete reference screens fit en at 320.0
6. complete reference screens fit en at 390.0
7. complete reference screens fit ar at 320.0
8. complete reference screens fit ar at 390.0
9. profile retains real account fields and signs out through splash
10. Home and Profile open same section and preserve five navigation tabs
11. render complete reference dashboard screens

These belong to existing dashboard/navigation/visual work (including stale
`nav-profile` expectations). They were not changed to conceal failures or redesign
the navigation. Baseline/final test output, analyzer output and comparison summary
are retained under `artifacts/phase6b/`.

Tests use mocked HTTP and synthetic records. No physical-device API smoke test,
native build verification, real-medication mutation or real notification delivery
is claimed. Existing unrelated and uncommitted work was preserved.

## Phase 6B changed-file inventory

Existing files changed for integration (some already had unrelated user changes):

- lib/data/network/api_client.dart
- lib/data/network/api_exception.dart
- lib/presentation/widgets/home_widgets/medications_content.dart (pre-existing untracked design)
- lib/presentation/widgets/home_widgets/health_dashboard.dart
- lib/presentation/screens/home_screen/home_screen.dart
- android/app/src/main/kotlin/com/sanad/sanad/MainActivity.kt
- ios/Runner/AppDelegate.swift
- pubspec.yaml
- pubspec.lock

New source files:

- lib/domain/models/medication.dart
- lib/data/mappers/medication_form_mapper.dart
- lib/application/medication/medication_repository.dart
- lib/application/medication/medications_controller.dart
- lib/application/medication/medication_timezone.dart

New tests and report:

- test/medication/medication_fixtures.dart
- test/medication/medication_transport_test.dart
- test/medication/medication_models_test.dart
- test/medication/medication_controller_test.dart
- test/medication/medications_widget_test.dart
- test/medication/medication_timezone_test.dart
- docs/phase-6b-medication-integration.md

The inventory covers **21 source/config/test/report files**, plus generated
verification artifacts under the dedicated Phase 6B artifact directory.
