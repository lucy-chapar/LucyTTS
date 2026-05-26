# LiveFishTTS

LiveFishTTS is a lightweight macOS-first live text-to-speech app for fast conversation use. Type text, press Enter or click Speak, and the app immediately clears the input while it generates and plays queued speech in order.

The v1 app is native SwiftUI for macOS. Its core pieces are split into reusable layers so a future iPhone companion can reuse the Fish Audio API client, queue model, and secure settings approach without inheriting Mac-only audio routing.

## Fish Audio API

This app uses Fish Audio Text to Speech:

- Endpoint: `POST https://api.fish.audio/v1/tts`
- Auth header: `Authorization: Bearer <your_api_key>`
- Model header: `model: s2-pro`
- Voice parameter: `reference_id`
- Default reference ID: `11a3219f88c346929ecb671d695e5a97`
- Default output: `mp3`

No real API key is stored in source code or examples.

## Install Dependencies

You need macOS 13 or later and Apple’s Swift toolchain/Xcode Command Line Tools.

```sh
xcode-select --install
swift --version
```

## Run Dev Mode

```sh
cd LiveFishTTS
swift run LiveFishTTS
```

On first launch, open the settings/setup screen and paste your Fish Audio API key. The key is stored in macOS Keychain.

For development only, you may also launch with:

```sh
FISH_AUDIO_API_KEY=your_api_key_here swift run LiveFishTTS
```

Normal use does not require Terminal environment variables after saving the key in the app.

If SwiftPM fails with an `xcrun --show-sdk-platform-path` error, repair or reinstall Xcode Command Line Tools:

```sh
sudo xcode-select --reset
xcode-select --install
```

As a local fallback, the app can also be compiled directly against the installed macOS SDK:

```sh
cd LiveFishTTS
./scripts/run-direct.sh
```

The fallback runner builds a local `.app` bundle and launches it with `open` so macOS gives the app normal keyboard focus.

## Build

```sh
cd LiveFishTTS
swift build -c release
```

The release executable is written under `.build/release/LiveFishTTS`.

Fallback direct build:

```sh
cd LiveFishTTS
./scripts/build-direct.sh
```

## Run On iPhone

The repository includes an Xcode project for the iPhone companion app:

```sh
open LiveFishTTS.xcodeproj
```

In Xcode:

1. Select the `LiveFishTTSiOS` scheme.
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

LiveFishTTS does not install or implement a custom macOS audio driver. For video calls, use an existing virtual audio device.

1. Install [BlackHole](https://existential.audio/blackhole/) or [Loopback](https://rogueamoeba.com/loopback/).
2. Open LiveFishTTS settings.
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
- [Fish Audio Quick Start](https://docs.fish.audio/developer-guide/getting-started/quickstart)
