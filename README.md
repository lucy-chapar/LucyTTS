# Lucy TTS

Lucy TTS is a lightweight macOS-first live text-to-speech app for fast conversation use. Type text, press Enter or click Speak, and the app immediately clears the input while it generates and plays queued speech in order.

The v1 app is native SwiftUI for macOS. Its core pieces are split into reusable layers so a future iPhone companion can reuse the Fish Audio API client, queue model, and secure settings approach without inheriting Mac-only audio routing.

Lucy TTS is accessibility-focused software. It is intended to support communication, but it is not medical advice and is provided without warranty.

## License

- Source code is licensed under the GNU Affero General Public License v3.0 or later. See [LICENSE](LICENSE).
- Documentation and free starter phrase content are licensed under Creative Commons Attribution 4.0 International (CC BY 4.0), unless a file says otherwise.
- "Lucy TTS", app icons, logos, and related product marks are reserved project branding. See [TRADEMARKS.md](TRADEMARKS.md).
- Notices and third-party service notes live in [NOTICE](NOTICE).

GitHub notes that public repositories need an explicit open-source license for others to freely use, change, and distribute the software. AGPLv3 is used here because Lucy TTS may later include networked sync or account components, and AGPLv3 is designed to keep modified network-service versions source-available to their users.

Licensing notes in this repository are drafting guidance, not legal advice. Please have an attorney review the project before commercial launch.

## Commercial Model

Core accessibility-critical communication features should remain free. Communication should not be held hostage.

Commercial sustainability should come from non-Fish layers, such as:

- Optional tips and donations.
- Optional hosted phrase sync/backups.
- Curated phrase packs.
- Workflow templates.
- Setup and support.
- Organizational deployment help.

Lucy TTS must not be documented or designed as a Fish Audio reseller, Fish API proxy, hosted speech gateway, or bundled voice-credit provider. The app does not include Fish Audio usage, Fish credits, hosted Fish generation, managed Fish API keys, or bundled Fish voice access.

## Fish Audio API

Lucy TTS can use Fish Audio Text to Speech as a third-party cloud dependency. The user brings their own Fish Audio account, API key, and voice/model IDs.

This app currently uses Fish Audio's documented API shape:

- Endpoint: `POST https://api.fish.audio/v1/tts`
- Auth header: `Authorization: Bearer <your_api_key>`
- Model header: `model: s2-pro`
- Voice parameter: `reference_id`
- Default reference ID: `11a3219f88c346929ecb671d695e5a97`
- Default output: `mp3`

Fish Audio's OpenAPI document currently lists `/v1/tts`, `/v1/tts/stream/with-timestamp`, `/model`, and `/model/{id}` endpoints. The `/v1/tts` endpoint accepts `application/json` and `application/msgpack`, requires bearer authentication, recommends `s2-pro`, and documents `reference_id`, speed/volume prosody, output format, bitrate, sample rate, latency, and related generation controls.

Fish Audio publishes its own pricing, rate limits, model policies, and terms. Users are responsible for their own Fish Audio account, API key, usage costs, plan limits, voice/model rights, generated audio rights, and compliance with Fish Audio's current terms. Lucy TTS does not grant commercial rights to Fish Audio voices, cloned voices, public voices, generated audio, API keys, or self-hosted models.

Lucy TTS is not affiliated with, sponsored by, or endorsed by Fish Audio.

No real API key is stored in source code or examples. Saved keys are stored on-device in Keychain. Do not store user Fish API keys on Lucy servers. Any future server-side API key storage, Fish proxying, hosted Fish speech generation, or bundled Fish usage is out of scope and would require written Fish Audio approval plus attorney review.

Do not use Fish Audio output to train or improve a competing TTS model. Do not bundle Fish public voices, cloned voices, celebrity-like voices, or user-submitted voice models unless rights are clearly documented. Do not scrape Fish discovery pages when official API/search endpoints are available. If the app accepts Fish model URLs, it should parse the voice/model ID from the URL and store only what is needed.

## Install Dependencies

You need macOS 13 or later and Apple’s Swift toolchain/Xcode Command Line Tools.

```sh
xcode-select --install
swift --version
```

## Run Dev Mode

```sh
cd lucytts
swift run LucyTTS
```

On first launch, open the settings/setup screen and paste your Fish Audio API key. The key is stored in macOS Keychain.

For development only, you may also launch with:

```sh
FISH_AUDIO_API_KEY=your_api_key_here swift run LucyTTS
```

Normal use does not require Terminal environment variables after saving the key in the app.

If SwiftPM fails with an `xcrun --show-sdk-platform-path` error, repair or reinstall Xcode Command Line Tools:

```sh
sudo xcode-select --reset
xcode-select --install
```

As a local fallback, the app can also be compiled directly against the installed macOS SDK:

```sh
cd lucytts
./scripts/run-direct.sh
```

The fallback runner builds a local `.app` bundle and launches it with `open` so macOS gives the app normal keyboard focus.

## Build

```sh
cd lucytts
swift build -c release
```

The release executable is written under `.build/release/LucyTTS`.

Fallback direct build:

```sh
cd lucytts
./scripts/build-direct.sh
```

## Run On iPhone

The repository includes an Xcode project for the iPhone companion app:

```sh
open LucyTTS.xcodeproj
```

In Xcode:

1. Select the `LucyTTSiOS` scheme.
2. Open the target settings and choose your Apple ID team under Signing & Capabilities.
3. Connect your iPhone or select a paired wireless iPhone.
4. Press Run.

The iPhone app includes:

- Fish Audio API key setup in iOS Keychain
- Voice preset selection and editing
- Fish voice name import/fetch
- Speed, volume, output format, latency, and S2-Pro style cue settings
- Type, submit, immediately keep typing
- Sequential queue playback through iPhone speaker, wired audio, AirPods, or Bluetooth

The iPhone app does not include Meeting Mode. iOS does not support this app acting as a same-device virtual microphone for Google Meet or other apps.

## App Usage

- Enter submits the current text.
- Shift+Enter inserts a newline.
- The text input clears immediately after submit and remains focused.
- New submissions are added to the queue while previous audio is generating or playing.
- Only one utterance plays at a time.
- Stop current stops playback without touching the text currently being typed.
- Clear queue removes pending queued items.
- Failed queue items are marked as errors and the queue continues.
- Spell checking is available in the main text field. Underlined words use the standard macOS context menu for suggestions.

## Settings

Settings include:

- Fish Audio API key setup, save, replace, and test
- API key status: Not configured, Saved, Tested successfully, or Test failed
- Voice/reference ID
- Voice presets with local names, notes, and Fish model title fetching
- Model, default `s2-pro`
- Speed, default `1.0`
- Volume, default `0 dB`
- S2-Pro style cue, for example `[speaks in a warm, feminine tone]`
- Output format, default `mp3`
- Latency mode, default `balanced`
- Output audio device
- Meeting Mode
- Typing assistance: spell checking, optional autocorrect, and optional grammar checking

The app never displays the full saved API key. Saved keys are shown only as a masked value.

Fish currently documents prosody controls for speed and volume. Pitch and resonance are not documented request fields, so this app does not send unsupported pitch/resonance parameters. For a more feminine sound, prefer selecting the closest voice/reference model and optionally add a gentle S2-Pro bracket style cue.

## Google Meet Meeting Mode

Lucy TTS does not install or implement a custom macOS audio driver. For video calls, use an existing virtual audio device.

1. Install [BlackHole](https://existential.audio/blackhole/) or [Loopback](https://rogueamoeba.com/loopback/).
2. Open Lucy TTS settings.
3. Select the virtual device as the app output device, for example `BlackHole 2ch`.
4. Turn Meeting Mode on.
5. In Google Meet, select the same virtual device as the microphone.
6. Use Test meeting audio to generate a short phrase through the selected output.

If no virtual audio device is selected, the app still works through default speakers/headphones and shows a setup message for Meeting Mode.

Local monitoring is shown as a planned setting. For v1, monitoring through a second output is not implemented because `AVAudioPlayer` routes each playback instance to one output device.

## Security

- Do not commit a real Fish Audio API key.
- Do not put a real key in screenshots, logs, README examples, or tests.
- `.env` and `*.local` are ignored.
- Use `.env.example` only as a placeholder template.
- The saved API key lives in macOS Keychain.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Contributions are inbound=outbound: code contributions are AGPL-3.0-or-later, and documentation/free starter phrase content contributions are CC BY 4.0 unless a file says otherwise.

## Future iPhone Companion

The included iPhone companion keeps the same fast flow:

- Type text.
- Submit to Fish Audio.
- Queue utterances.
- Play speech through the iPhone speaker or connected Bluetooth audio.
- Store the API key securely with Keychain.
- Use native iOS audio playback APIs.

iOS is treated as a companion, not desktop parity. Do not assume an iPhone app can become a system-wide virtual microphone for Google Meet or other apps on the same device. Practical workflows are:

- Use the iPhone as a standalone speech device in the room.
- Use the MacBook app for Google Meet virtual microphone routing.
- Use the iPhone app for in-person communication.
- Possibly join a meeting from iPhone separately, but do not rely on that for v1.

## Official Docs Used

- [Fish Audio Text to Speech](https://docs.fish.audio/developer-guide/core-features/text-to-speech)
- [Fish Audio API Reference: Text to Speech](https://docs.fish.audio/api-reference/endpoint/openapi-v1/text-to-speech)
- [Fish Audio OpenAPI JSON](https://api.fish.audio/openapi.json)
- [Fish Audio Quick Start](https://docs.fish.audio/developer-guide/getting-started/quickstart)
- [Fish Audio Pricing & Rate Limits](https://docs.fish.audio/developer-guide/models-pricing/pricing-and-rate-limits)
- [Fish Audio Terms of Service](https://fish.audio/terms/)
- [GitHub Docs: Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
- [GNU AGPLv3](https://www.gnu.org/licenses/agpl-3.0)
