# Implementation brief — "Ask about this result" (chat)

> Written for an agent that has not seen this codebase. Every path, class and
> constraint below was verified against the tree at the time of writing; if
> something contradicts the code, **the code wins** — re-verify before building.
>
> Placeholder currently in place: `_ChatWithResultPlaceholder` in
> `lib/presentation/diagnosis/diagnosis_result_screen.dart`. It renders an
> inert card with a "Coming soon" pill and shows a SnackBar on tap. Replace it;
> do not leave it alongside the real feature.

---

## 1. What this feature is

After a diagnosis, a farmer can ask follow-up questions in their own words
about *that specific scan* — "can I still eat the fruit?", "how long before it
spreads?", "I already sprayed last week, what now?" — and get answers grounded
in the diagnosis, the crop, and any observations they entered.

It is **not** a general chatbot. It is scoped to one `Diagnosis` and must stay
scoped to it.

## 2. Non-negotiable constraints from this codebase

These are properties of the app, not preferences. Violating them breaks
things that already work.

1. **Offline-first.** Read `lib/services/connectivity_service.dart`. Users are
   routinely offline for long stretches. Chat requires the network, so it must
   degrade honestly: disable the entry point with a stated reason, never spin
   forever, never queue a question and silently drop it. Decide deliberately
   whether unanswered questions are queued in the outbox (see §5) or refused
   outright — do not leave it implicit.
2. **Trilingual (en / si / ta).** Every user-visible string goes in
   `lib/presentation/onboarding/localization/app_localizations.dart` in all
   three maps. Read the file first: it is a plain `Map<String, Map<String,
   String>>` with a `context.tr('key')` extension and an
   `en → key` fallback chain. There is no ARB/intl tooling (see `DECISIONS.md`
   TD-007). **Key parity is enforced by review, not tooling** — a missing key
   renders the raw key string to the user.
   The model must answer *in the user's language*; pass the active language
   code (`LocalizationProvider.of(context)?.languageCode`) to the backend.
3. **Layered architecture, no shortcuts.** Presentation → Application (Cubit)
   → Domain (use case) → Repository interface → Data impl. `DECISIONS.md`
   TD-001: no DI framework — everything is constructed in `lib/main.dart` and
   passed down as constructor parameters. Do not add `get_it`, `riverpod`,
   `freezed` or `equatable`; states are hand-written classes (TD-002).
4. **The model is unreliable and the UI says so.** The diagnosis is a
   closed-set softmax guess with no true out-of-distribution detection (see
   `lib/data/local/ml/ml_inference_service.dart` header comment and
   `ValidateImageUseCase`'s content gate). Chat answers must not launder a
   shaky diagnosis into confident prose. Carry the existing AI-disclaimer
   framing into the chat surface.
5. **Never render a raw exception to a user.** See
   `lib/presentation/shared/widgets/app_state_views.dart` (`AppErrorView` has a
   `technicalDetail` slot that is collapsed by default). Follow that pattern.

## 3. Existing pieces to reuse — do not rebuild these

| Need | Use | Path |
|---|---|---|
| Backend HTTP client pattern | `TreatmentApiClient` | `lib/data/remote/treatment_api_client.dart` |
| Online-then-offline fallback pattern | `TreatmentRepositoryImpl.getTreatmentGuidance` | `lib/data/repositories/treatment_repository_impl.dart` |
| Auth token for API calls | `AuthRepository.getStoredToken()` | `lib/data/repositories/auth_repository_impl.dart` |
| Cubit + hand-written state classes | `DiagnosisCubit` / `DiagnosisState` | `lib/application/diagnosis/` |
| Cards, banners, chips, section headers | `AppCard`, `AppBanner`, `AppStatusChip`, `AppSectionHeader` | `lib/presentation/shared/widgets/app_components.dart` |
| Loading / empty / error views | `AppLoadingView`, `AppEmptyView`, `AppErrorView` | `lib/presentation/shared/widgets/app_state_views.dart` |
| Colour / type / spacing / radius tokens | `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius` | `lib/core/theme/` |
| Read-aloud of answers | `TtsService` / `TextToSpeechService` | `lib/data/local/tts/text_to_speech_service.dart` |
| Offline outbox pattern (if queuing) | `SyncOperationTable` + `SyncRepositoryImpl` | `lib/data/local/database/tables.dart`, `lib/data/repositories/sync_repository_impl.dart` |

**Read `lib/core/theme/app_colors.dart` before choosing any colour.** Raw
`Colors.*` literals are being actively removed from this codebase; do not add
new ones.

## 4. Context the model needs

Assemble server-side from what the app sends. The app has all of this already:

- `Diagnosis` (`lib/domain/entities/diagnosis.dart`): `diseaseId`,
  `confidence`, `resultState`, `severity`, `alternatives`.
  **`resultState` and `confidence` matter** — a `lowConfidence` diagnosis
  should produce more hedged answers.
- `Scan` (`lib/domain/entities/scan.dart`): `cropId`, `capturedAt`.
- Farmer observations: the free-text field on the diagnosis screen
  (`_ObservationsCard`, backed by `_observationsController`).
- `DiseaseExplanation` (`lib/domain/entities/disease_explanation.dart`) — the
  offline explanation content, if present on the device.
- Any `TreatmentResponse` already fetched (`lib/domain/entities/treatment.dart`).
- Active language code.

Do **not** send the scan image unless product explicitly asks: image upload
already has its own signed-URL path in `SyncApiClient` and is metered-data
sensitive.

## 5. Suggested shape

**Schema** (`lib/data/local/database/tables.dart`, then bump
`AppDatabase.schemaVersion` and add an `onUpgrade` branch — currently at
**6**; see the migration block in `lib/data/local/database/app_database.dart`
and follow the existing style exactly, including re-running `_createIndexes`):

```
ChatMessageTable
  id            text PK
  diagnosisId   text  → diagnosis.id
  role          text  'USER' | 'ASSISTANT'
  content       text
  languageCode  text
  status        text  'PENDING' | 'SENT' | 'FAILED'   (if queuing offline)
  createdAt     text  ISO8601
```
Index `chat_message(diagnosis_id)` — every read is by diagnosis.

After editing tables run: `dart run build_runner build`
(`--delete-conflicting-outputs` has been removed from this build_runner
version and is ignored).

**Layers to add:**
- `lib/domain/entities/chat_message.dart`
- `lib/domain/repositories/chat_repository.dart`
- `lib/data/repositories/chat_repository_impl.dart`
- `lib/data/remote/chat_api_client.dart` — mirror `TreatmentApiClient`'s
  constructor/error style, including a typed exception
- `lib/domain/usecases/chat/send_chat_message_use_case.dart`,
  `get_chat_history_use_case.dart`
- `lib/application/chat/chat_cubit.dart` + `chat_state.dart`
- `lib/presentation/chat/chat_screen.dart`

**Wiring:** construct in `lib/main.dart` beside
`getDiseaseExplanationUseCase`, then thread down the existing chain:
`main.dart → CropCareApp (lib/app.dart) → HomeScreen → _AppShell →
DiagnosisResultScreen`, and also `CaptureScreen → DiagnosisResultScreen`.
Both routes to the result screen must pass it or chat will be silently
missing depending on how the user arrived. Follow how
`getDiseaseExplanationUseCase` is threaded — it is the most recent example.

**Entry point:** replace `_ChatWithResultPlaceholder`. Keep its position
(after treatment guidance, before the bottom actions) unless there is a
reason to move it. Push a full screen rather than an inline expander — the
result screen is already long.

## 6. Backend

The existing backend is a FastAPI service (`TreatmentApiClient` posts to
`/interpret-diagnosis`; base URL is in that file). A chat endpoint does not
exist yet. Confirm with the backend owner before assuming a contract —
**do not invent an endpoint shape and build against it.**

## 7. Testing

Existing suite: `flutter test` (was 138 passing / 5 failing at the time of
writing — the 5 are a known bottom-nav provider-scope issue and stale
home-screen assertions, unrelated to chat). Mirror these patterns:

- Cubit tests with hand-written fakes: `test/application/diagnosis/diagnosis_cubit_test.dart`
- Repository tests on in-memory Drift: `AppDatabase.forTesting(NativeDatabase.memory())` — see `test/data/repositories/treatment_repository_impl_test.dart`
- Migration test: `test/data/local/database/app_database_test.dart` — **add a 6→7 case**
- Widget tests: `test/presentation/diagnosis/diagnosis_result_screen_test.dart`

Cover at minimum: offline send behaviour, a failed send surfacing a usable
message, history persisting across screen reopen, and language propagation.

## 8. Explicitly out of scope

Cross-scan/general chat; voice input (separate brief —
`docs/future/voice_observations_implementation.md`); streaming responses
unless the backend supports it; any change to diagnosis inference.
