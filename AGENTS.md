# AGENTS.md

Guidance for coding agents working in this repo.

## Project Purpose

Lucy TTS is a lightweight live text-to-speech app for fast communication while the user cannot comfortably speak. The core UX priority is uninterrupted typing:

- Type text, press Enter/Speak, clear the input immediately.
- Keep typing while previous audio is generating or playing.
- Queue utterances and speak them in order.
- Never block the text input during generation/playback.

## Repo Layout

- `Sources/LucyTTS/`: macOS SwiftUI app and shared code.
- `Sources/LucyTTSiOS/`: iPhone companion SwiftUI app.
- `Sources/LucyTTS/API/`: Fish Audio API client and Msgpack encoder.
- `Sources/LucyTTS/Queue/`: macOS queue manager.
- `Sources/LucyTTSiOS/iOSSpeechQueueManager.swift`: iOS queue manager.
- `Sources/LucyTTS/Settings/`: Keychain, app settings, voice presets.
- `Sources/LucyTTS/Phrases/PhrasePresetCatalog.swift`: shared local-first phrase preset model/store.
- `LucyTTS.xcodeproj`: iOS build project.
- `scripts/build-direct.sh` and `scripts/run-direct.sh`: macOS fallback build/run helpers.

## Security Rules

- Never hardcode, log, commit, screenshot, or document a real Fish Audio API key.
- Normal API key storage is Keychain.
- Dev-only fallback env var is `FISH_AUDIO_API_KEY`.
- `.env` and `*.local` must remain ignored.
- README examples must use placeholders only.

## Licensing / Commercial Posture

- Code is AGPL-3.0-or-later. Keep `LICENSE` as the unmodified GNU AGPLv3 text.
- Docs and free starter phrase content are CC BY 4.0 unless marked otherwise.
- "Lucy TTS", app icons, logos, and related marks are reserved; see `TRADEMARKS.md`.
- Basic accessibility-critical communication features stay free.
- Commercial layers may include tips/donations, phrase sync/backups, curated phrase packs, workflow templates, setup/support, and organizational deployment help.
- Do not describe Lucy as a Fish reseller, Fish API proxy, hosted speech gateway, or bundled voice-credit provider.
- Do not mention future Lucy Cloud, included Fish quotas, managed Fish generation, reseller plans, or bundled Fish usage.

## Fish Audio Defaults

- TTS endpoint: `POST https://api.fish.audio/v1/tts`
- Auth: `Authorization: Bearer <api_key>`
- Model header default: `s2-pro`
- Voice field: `reference_id`
- Default reference ID: `11a3219f88c346929ecb671d695e5a97`
- Default format: `mp3`

Do not add unsupported Fish request fields. Pitch/resonance are not currently documented controls; use voice selection, speed, volume, and S2-Pro style cues instead.

Fish Audio compliance:

- Lucy is BYOK: users bring their own Fish account, API key, and voice/model IDs.
- Lucy is not affiliated with, sponsored by, or endorsed by Fish Audio.
- Users are responsible for Fish costs, plan limits, voice/model rights, generated audio rights, and Fish terms compliance.
- Never store user Fish API keys on Lucy servers.
- Future server-side key storage, Fish proxying, hosted Fish generation, or bundled Fish usage is out of scope and requires Fish written approval plus attorney review.
- Do not use Fish output to train or improve competing TTS models.
- Do not bundle Fish public voices, cloned voices, celebrity-like voices, or user-submitted models without documented rights.
- Do not scrape Fish discovery pages if official API/search endpoints are available.

## UX Priorities

- Keep the main input readable and focused by default.
- Enter submits; Shift+Enter/newline behavior should remain deliberate per platform.
- Stop must not erase current typed text.
- Clear should remove queued items only.
- Replay should replay the last spoken text.
- Captions should show currently generating/playing speech for someone reading along.
- Phrase presets supplement freeform typing; they must not replace it.
- On iPhone, avoid layouts where the keyboard hides the input or primary buttons.

## Phrase Presets

Phrase presets are shared through `PhrasePresetCatalog` and loaded with `PhrasePresetStore`.

- Keep default phrase text exact unless the user requests edits.
- Preserve stable category and phrase IDs for future sync.
- Local edits should be stored locally first.
- Design future editing/sync as data-layer changes, not view-only hardcoding.
- Existing phrase/history UI should use the shared catalog when practical.

## Build/Run (use the wrappers)

The owner does not program. Always use the wrappers below. They auto-detect
the installed Xcode and set `DEVELOPER_DIR` even when `xcode-select -p`
points at the Command Line Tools, which is the default state on this
machine. Never run bare `swift build`, `swift test`, or `xcodebuild`
without `DEVELOPER_DIR` already exported. If you do, you will see
`xcrun: error: unable to lookup item 'PlatformPath'` and may incorrectly
conclude that something is broken.

Preferred entry points:

| Task | Command |
|------|---------|
| Build macOS app | `make build` |
| Run macOS test suite | `make test` |
| Launch Lucy TTS as a real .app bundle | `make run` |
| Smoke-build the iOS target (simulator) | `make ios-build` |
| Diagnose toolchain issues | `make doctor` |
| Remove build artifacts | `make clean` |

Each `make` target is a one-line call into `scripts/*.sh`; the shell
scripts can be invoked directly with the same effect (e.g.
`./scripts/build.sh`). All of them source `scripts/_select_xcode.sh`.

If `make doctor` reports `ERROR: Could not find an Xcode installation`,
that is a real environment problem (Xcode is not installed in any standard
location). Otherwise trust the wrappers.

### iOS device install/launch

`make ios-build` only builds for the iOS Simulator without code signing.
To deploy to a real iPhone, use Xcode itself or run the longer device
commands below. Source the helper first so `DEVELOPER_DIR` is set:

```sh
source scripts/_select_xcode.sh && select_xcode

xcodebuild -project LucyTTS.xcodeproj \
  -scheme LucyTTSiOS \
  -destination 'id=<device-id>' \
  -configuration Debug \
  -allowProvisioningUpdates build

xcrun devicectl device install app --device <device-id> \
  ~/Library/Developer/Xcode/DerivedData/LucyTTS-<hash>/Build/Products/Debug-iphoneos/LucyTTSiOS.app

xcrun devicectl device process launch --device <device-id> \
  --terminate-existing com.lucianchapar.LucyTTS.dev
```

If launch fails with a `Locked` CoreDevice error, the app may still have
installed successfully; unlock the iPhone and launch again.

## Validation Checklist

Run what matches the touched code:

- Shared/macOS Swift: `make build && make test`
- iOS target: `make ios-build`
- Whitespace sanity: `git diff --check`

For iPhone UX changes, prefer installing on device when possible because
keyboard/safe-area behavior is the point.

## CI

`.github/workflows/ci.yml` runs `swift build`, `swift test`, and the iOS
simulator build on every push to `main` and every pull request. Keep it
green. CI uses GitHub's `macos-15` runners where `xcode-select -p` is
already correct, so the workflow does not need the `_select_xcode.sh`
helper.

## Git Notes

- Current active development has been on `codex/ios-compatible-v2`.
- Do not revert unrelated user changes.
- Keep commits scoped and descriptive.
- Only push when the user asks or the current task clearly includes publishing.
