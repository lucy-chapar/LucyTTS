---
title: Privacy Policy
description: Exactly what leaves your device when you use Lucy, and what doesn't.
permalink: /privacy/
---

**Effective date:** TBD before public release. Last updated: {{ "now" | date: "%B %d, %Y" }}.

## The short version

Lucy TTS does not have servers that store anything about you.

- The text you type goes from your device **directly** to Fish Audio (the third-party
  service you signed up for). It does not pass through us.
- **The text you type will never be stored on a Lucy server.** This is a hard
  commitment that does not change as the product evolves.
- Your Fish Audio API key is stored only on your device, in the system Keychain.
- Today Lucy contains **no** analytics, advertising, tracking, telemetry, or
  crash-reporting SDKs. Lucy does not phone home. We have no way to count installs,
  sessions, voices used, characters spoken, or any other usage data.
- If we ever add any form of usage measurement to help improve the app, it will follow
  the standards Apple expects for user privacy (anonymized, on-device aggregation where
  possible, properly disclosed in the App Privacy details), and we will update this
  page and the in-app release notes before it ships. See
  [Future measurement](#future-measurement-if-and-when) below.

If you want the long version with specifics, read on.

---

## Who this policy applies to

This policy describes Lucy TTS, an open-source app for macOS and iOS by Lucian Chapar.
The full source is available at <https://github.com/lucy-chapar/LucyTTS>.

This policy **does not** apply to Fish Audio, Apple, or any other third party. See the
[Third parties](#third-parties) section below.

## What Lucy stores on your device

| Data | Where it's stored | Why |
|---|---|---|
| Your Fish Audio API key | System Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | So Lucy can call Fish on your behalf. Never leaves your device except to authenticate with Fish. |
| Voice presets (name, Fish voice ID, your notes) | `UserDefaults` | So you can switch between voices. |
| Lucy settings (speed, volume, format, latency, style cue, output device, meeting mode, spelling/grammar toggles) | `UserDefaults` | So your preferences persist between launches. |
| Phrase preset edits | `UserDefaults` | So your custom quick-phrases persist. |
| A flag indicating that an API key is saved, plus a masked suffix of that key (e.g. `********xYz`) | `UserDefaults` | So the settings screen can show "you have a key on file" without exposing the key itself. |
| The current session's typing queue and recently spoken history | In memory only, cleared when Lucy quits | So the queue and the "Replay last" button work. |
| Generated audio for the current sentence | In memory only, played, then discarded | Lucy never writes audio to disk. |

Everything in the table above stays on your device. None of it is sent to us; we have no
servers to send it to.

## What Lucy sends over the network

Lucy makes network requests **only** to Fish Audio, **only** when you ask it to
synthesize a sentence, test your API key, browse Fish's voice catalog, or preview a
voice sample.

| Destination | When | What's sent |
|---|---|---|
| `https://api.fish.audio/v1/tts` | When you press Speak or use "Test connection" | The text you typed, your API key (in an `Authorization` header), and the synthesis settings you chose (voice ID, speed, volume, format, latency, style cue). |
| `https://api.fish.audio/model` | When you open Lucy's built-in voice browser | Your API key, and the search/list parameters you chose. |
| `https://api.fish.audio/model/{voice_id}` | When Lucy needs the name/notes for a specific voice | Your API key. |
| Voice sample audio URLs returned by Fish (typically Fish-operated CDN hosts) | When you tap a voice in the browser to preview it | An HTTPS request to a URL Fish gave us. |

That's the entire list of network destinations Lucy currently uses. Lucy does not
contact any other server. There is no Lucy backend, no analytics endpoint, no crash
reporter, no update server, no third-party SDK.

## What Lucy does **not** do today

- We do not collect personally identifiable information.
- We do not collect device identifiers (IDFA, IDFV, MAC, IMEI, or similar).
- We do not collect approximate or precise location.
- We do not collect contacts, calendars, photos, microphone audio, or files.
- We do not use cookies, web views, or embedded browsers.
- We do not display ads.
- We do not sell, rent, or share data with third parties for marketing.
- We do not log anywhere off-device. There are no `print`, `NSLog`, or `os.Logger`
  calls in shipped builds, and Lucy does not write logs to disk.
- We do not train AI models on anything you type.

## Future measurement, if and when

We may eventually add lightweight measurement to help improve the app — for example, an
anonymized count of how often a particular error type occurs across all users, or an
on-device count of crashes that you opt to share when you encounter one. If we do, it
will follow these rules:

1. **Hard line:** the actual text you type to synthesize will never be sent to a Lucy
   server, no matter what. Any future measurement will exclude user-generated text.
2. It will use the privacy standards Apple expects for the App Store — anonymized,
   aggregated where possible, declared accurately in the App Privacy details, and
   compliant with applicable international privacy law (GDPR, UK GDPR, CCPA/CPRA).
3. It will be disclosed on this page **before** it ships, not after.
4. Where the law requires consent (most of the EU/UK), it will be opt-in. Elsewhere it
   will at minimum be disclosed and toggleable.
5. The change will appear in the in-app release notes the first time you open a build
   that introduces it.

If those rules are ever broken, that's a bug we want to fix immediately. Open an issue.

## Third parties

### Fish Audio

Lucy is a bring-your-own-key client for [Fish Audio](https://fish.audio). When you use
Lucy to generate speech, you are using Fish's service under their terms and privacy
policy, which you accepted directly when you signed up with them.

- Fish receives the text you ask Lucy to synthesize, your API key, and your synthesis
  parameters.
- Fish bills your Fish account directly. Lucy is not part of that billing relationship
  and does not see or store any payment information.
- See Fish's own [Terms](https://fish.audio/terms) and
  [Privacy Policy](https://fish.audio/privacy) for what they do with that data.
- Lucy is not affiliated with, sponsored by, or endorsed by Fish Audio.

### Apple

If you install Lucy from TestFlight or (in the future) the App Store, Apple has its own
relationship with you for app distribution, crash reports, and (in TestFlight) beta
feedback. Apple's privacy policy applies to that relationship. Lucy does not enable
Apple's optional crash-and-usage sharing beyond what your device defaults are.

### GitHub (this website)

This site is hosted on GitHub Pages. GitHub may log standard web server information
(IP address, user agent, requested URL) when you visit. We do not run analytics on
top of that and do not have access to it. See
[GitHub's Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)
for details.

## Children

Lucy is not directed at children under 13. We do not knowingly collect data from
children. (To be clear: we don't knowingly collect data from anyone, but the legal
language matters.)

## Developer escape hatch (macOS only)

When developers run Lucy from a terminal using the Swift command-line tools (e.g.
`swift run LucyTTS`), they would normally have to paste their Fish Audio API key
into the app each time they relaunch a freshly-built debug binary, since the macOS
Keychain entry is per-installed-app. To avoid that friction, Lucy on macOS will read an
environment variable named `FISH_AUDIO_API_KEY` and use it as a fallback when no key is
in the Keychain.

This is a developer convenience, not a feature normal users interact with. The variable
is only honored on macOS. iOS does not have this fallback. Normal installed `.app` /
TestFlight builds will not have this environment variable set unless someone explicitly
launches them from a shell that defined it. If you did not set this variable yourself,
it is not set.

## Changes to this policy

If we ever change what Lucy collects, transmits, or stores, we will:

1. Update this page with a new "Last updated" date and a brief note explaining what
   changed.
2. Note the change in the Lucy release notes.
3. For changes that meaningfully expand what we do with your data, surface the change
   inside the app the next time you open it.

## Contact

- **Bug reports and feature requests:** [GitHub Issues](https://github.com/lucy-chapar/LucyTTS/issues/new) — tag with `bug` or `feature request`.
- **Privacy questions, security disclosures, and private messages:** `lucychapar@pm.me`.

## Verifying these claims

Lucy is open source under [AGPL-3.0](https://github.com/lucy-chapar/LucyTTS/blob/main/LICENSE).
You don't have to take our word for any of this. The relevant code is:

- API key storage:
  [`Sources/LucyTTS/Settings/KeychainService.swift`](https://github.com/lucy-chapar/LucyTTS/blob/main/Sources/LucyTTS/Settings/KeychainService.swift)
- Network requests:
  [`Sources/LucyTTS/API/FishAudioClient.swift`](https://github.com/lucy-chapar/LucyTTS/blob/main/Sources/LucyTTS/API/FishAudioClient.swift)
- Audio handling (no disk writes):
  [`Sources/LucyTTS/Audio/AudioPlaybackService.swift`](https://github.com/lucy-chapar/LucyTTS/blob/main/Sources/LucyTTS/Audio/AudioPlaybackService.swift)
- Settings persistence:
  [`Sources/LucyTTS/Settings/SettingsStore.swift`](https://github.com/lucy-chapar/LucyTTS/blob/main/Sources/LucyTTS/Settings/SettingsStore.swift)

If you find a place where Lucy's behavior contradicts this policy, please open a
[GitHub issue](https://github.com/lucy-chapar/LucyTTS/issues/new) — that's a bug we
want to fix immediately. For sensitive disclosures, email `lucychapar@pm.me` instead.
