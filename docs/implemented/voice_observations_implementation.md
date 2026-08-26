> # IMPLEMENTED — 2026-08-26
>
> This brief has been built. See TD-024 in `DECISIONS.md` and
> `lib/data/local/speech/speech_recognition_service.dart`.
>
> One deliberate departure: the mic ended up in the **chat composer**, not on
> the observations field. That field was removed when the result screen was
> restructured (TD-020) — speaking a question has an obvious purpose, speaking
> into a box you were asked to fill in before being told anything did not.
>
> Still unverified, as this brief asked: Sinhala and Tamil recognition has
> never been tested on physical hardware.

# Implementation brief — speak observations (voice transcription)

> Written for an agent that has not seen this codebase. Every path, class and
> constraint below was verified against the tree at the time of writing; if
> something contradicts the code, **the code wins** — re-verify before building.
>
> Placeholder currently in place: `_VoiceInputPlaceholder` inside
> `_ObservationsCard` in
> `lib/presentation/diagnosis/diagnosis_result_screen.dart`. It renders a mic
> row with a "Coming soon" pill and shows a SnackBar on tap. Replace it.

---

## 1. What this feature is

On the diagnosis screen there is an optional free-text "what have you
noticed" field (`_ObservationsCard`, backed by `_observationsController`).
Its contents are sent as `userObservations` to the treatment endpoint and
pre-fill the WhatsApp expert-escalation message.

This feature lets the farmer **speak** those observations instead of typing
them, transcribing into the same `TextEditingController`.

## 2. Why this matters more than it looks

Typing is the single worst interaction in this app for its actual audience:

- Sinhala and Tamil on-screen keyboards are slow and unfamiliar to many users;
  the app already ships bundled Noto fonts for these scripts precisely because
  the text pipeline needed care (`pubspec.yaml` → `fonts:`).
- The user is standing in a field, often one-handed, phone in the other.
- Literacy is an explicit design constraint across this codebase — it is why
  read-aloud (TTS) is a first-class full-width button on the result screen and
  why `AccessibilityScreen` exists.

Voice input is the input-side counterpart to the TTS that already exists.
**Transcription must therefore work in Sinhala and Tamil, not only English** —
an English-only implementation solves the problem for the users who least need
it. If the chosen engine cannot do si/ta on-device, that is a finding to
report, not to paper over.

## 3. Non-negotiable constraints from this codebase

1. **Offline-first.** `lib/services/connectivity_service.dart` exists because
   users are offline for long stretches. Decide explicitly: on-device
   recognition (works offline, weaker) vs cloud (better, needs network and
   uploads audio). Whatever the choice, the UI must state plainly when
   transcription is unavailable rather than failing silently.
2. **Privacy.** Audio of a person speaking is more sensitive than a leaf photo.
   If audio leaves the device, say so in the UI at the point of recording and
   reflect it in `TermsPrivacyScreen`
   (`lib/presentation/settings/terms_privacy_screen.dart`). Do not retain audio
   after transcription unless there is an explicit product decision to.
3. **Trilingual UI.** All strings into all three maps in
   `lib/presentation/onboarding/localization/app_localizations.dart`
   (`context.tr('key')`; `en` fallback; no ARB/intl — `DECISIONS.md` TD-007).
4. **Architecture.** Presentation → Cubit → use case → repository interface →
   impl. Manual constructor injection from `lib/main.dart` (TD-001). No new DI
   or codegen packages.
5. **No raw exceptions in the UI** — see `AppErrorView.technicalDetail` in
   `lib/presentation/shared/widgets/app_state_views.dart`.

## 4. Platform work required — currently missing

**`android/app/src/main/AndroidManifest.xml` does NOT declare `RECORD_AUDIO`.**
Verified: it declares `CAMERA`, `INTERNET`, `ACCESS_NETWORK_STATE`,
`RECEIVE_BOOT_COMPLETED` only. You must add:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

The file already has a `<queries>` block (added for TTS, per `DECISIONS.md`).
On Android 11+ speech recognition needs its own entry there:

```xml
<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

Do not remove the existing `PROCESS_TEXT` / `TTS_SERVICE` entries — TTS breaks
without them.

`permission_handler: ^11.0.0` is already a dependency and is the established
way permissions are requested here.

## 5. Reuse the existing permission pattern — do not invent a new one

`lib/application/scan/scan_cubit.dart` defines:

```dart
abstract class CameraPermissionService {
  Future<ph.PermissionStatus> checkPermission();
  Future<ph.PermissionStatus> requestPermission();
  Future<bool> openAppSettings();
}
class DefaultCameraPermissionService implements CameraPermissionService { ... }
```

Mirror this exactly for microphone (`MicrophonePermissionService` /
`DefaultMicrophonePermissionService`, `ph.Permission.microphone`). The
abstraction exists so tests can inject a fake — do so.

Handle **permanently denied** properly: `CaptureScreen`'s
`_PermissionDeniedView` is the reference implementation (explanation, "grant"
button, "open app settings" button, and a still-usable fallback — here, typing).
Note: `ScanCubit`'s permission methods wrap calls in a blanket `catch (_)` that
conflates plugin failure with genuine denial. **Do not copy that part** — it is
a known weakness, not a pattern to spread.

## 6. Reuse for UI

| Need | Use | Path |
|---|---|---|
| Cards / banners / chips | `AppCard`, `AppBanner`, `AppStatusChip` | `lib/presentation/shared/widgets/app_components.dart` |
| Loading / error views | `app_state_views.dart` | same folder |
| Tokens | `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius` | `lib/core/theme/` |
| Play/stop toggle precedent | read-aloud button (`ValueListenableBuilder<bool>` on `TtsService.isPlaying`) | `diagnosis_result_screen.dart`, `_TreatmentLoadedCard` |
| Haptics preference | `AccessibilityCubit` / `AccessibilityState` | `lib/application/settings/` |

The read-aloud button is the closest existing analogue for a
recording/not-recording control — match its treatment so the two read as a
pair. `AccessibilityState` already carries a haptics toggle; respect it if you
add haptic feedback on record start/stop.

## 7. Package choice

No speech package is currently a dependency — verified against
`pubspec.yaml`. Candidates: `speech_to_text` (on-device, uses the platform
recognizer, offline capability varies by device and installed language packs)
or a cloud STT via the existing FastAPI backend.

Check Sinhala/Tamil support **empirically on a real low-end Android device**
before committing — do not rely on a package README's language list. Report
what you find; if si/ta are unusable, surface that rather than shipping an
English-only mic button, which would be worse than no button for the users
this is aimed at.

Whatever you add goes in `pubspec.yaml` under `dependencies:`; the project
targets Dart SDK `^3.12.2`, Flutter 3.44.x.

## 8. Suggested shape

```
lib/data/local/speech/speech_recognition_service.dart
    abstract class SpeechRecognitionService {
      Future<bool> initialize();
      Future<void> startListening({required String languageCode, required ValueChanged<String> onResult});
      Future<void> stopListening();
      ValueListenable<bool> get isListening;
      void dispose();
    }
    class DefaultSpeechRecognitionService implements SpeechRecognitionService { ... }
```

Mirrors `TtsService` / `TextToSpeechService`
(`lib/data/local/tts/text_to_speech_service.dart`), including the
`ValueNotifier<bool>` + `dispose()` shape. That file is the pattern to copy.

Feed the active language code from
`LocalizationProvider.of(context)?.languageCode` into `startListening` — the
same value TTS already uses for locale selection.

**No new database table is needed.** Transcription writes into the existing
`_observationsController`, which already flows to
`ResolveTreatmentUseCase(userObservations:)` and to `EscalationScreen`'s
`initialNotes`. Do not persist raw audio.

**Wiring:** inject the service into `DiagnosisResultScreen` the way
`ttsService` already is (optional constructor parameter, defaulting to the real
implementation, overridable in tests). `DiagnosisResultScreen` already accepts
`TtsService? ttsService` — follow it exactly.

## 9. Interaction detail worth getting right

- Append to, or replace, existing text? Decide and make it obvious. Appending
  is usually right — a farmer may type a little then speak more.
- Show interim results live while speaking; a mic with no visible feedback
  feels broken.
- Provide a clear stop control; do not rely solely on silence detection, which
  is unreliable in wind and field noise.
- Keep the text field editable after transcription — recognition **will**
  make mistakes with agricultural vocabulary and place names.
- Recording UI must meet the 48dp minimum target (`AppSpacing.minTouchTarget`).

## 10. Testing

- Fake `SpeechRecognitionService` in widget tests, as `TtsService` is faked
  today — see `test/data/local/tts/text_to_speech_service_test.dart` and
  `test/presentation/diagnosis/diagnosis_result_screen_test.dart`.
- Cover: permission granted / denied / permanently denied; transcription
  populating the controller; stop mid-recording; unsupported-language path.
- Full suite: `flutter test`. Keep `flutter analyze` clean — the project runs
  `flutter_lints ^6.0.0` and `lib/` is currently warning-free.

## 11. Explicitly out of scope

Voice control of app navigation; voice in the chat feature (separate brief —
`docs/future/chat_with_result_implementation.md`); speaker identification;
storing audio recordings.
