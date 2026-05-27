---
title: Lucy TTS
description: Type what you want to say. Lucy speaks it out loud in the voice you picked.
permalink: /
---

Lucy TTS is a small Mac and iPhone app for people who would rather type than speak in
the moment. You type, press Enter, and Lucy speaks the line out loud in a voice you
chose. While Lucy is speaking, you can keep typing. The next line goes in a queue and
plays in order. Nothing gets lost.

Lucy uses [Fish Audio](https://fish.audio) for the actual voice generation. You bring
your own Fish Audio account and API key. Lucy doesn't have its own servers; nothing you
type ever goes through us.

> **Beta status.** Lucy is in private beta as of {{ "now" | date: "%B %Y" }}. The macOS
> app is usable. The iPhone app is invite-only via TestFlight. Open issues are tracked
> on [GitHub](https://github.com/lucy-chapar/LucyTTS/issues).

## Start here

1. **[Setup guide →](/LucyTTS/setup-guide/)** — what you need, what it costs, and how to install Lucy step by step.
2. **[Privacy →](/LucyTTS/privacy/)** — exactly what leaves your device and what doesn't.
3. **[Troubleshooting →](/LucyTTS/troubleshooting/)** — common snags, in plain English.

## Who Lucy is for

- People who can type comfortably but find speaking out loud tiring, painful, slow, or
  socially difficult — temporarily or long-term.
- People who use Lucy to participate in video calls, in-person meetings, or one-on-one
  conversations.
- People who already have (or are willing to create) a Fish Audio account and pay Fish's
  per-character usage fees.
- People who are comfortable following kit-style instructions with screenshots.

## Who Lucy (currently) isn't for

- People who need a clinical AAC (augmentative and alternative communication) device.
  Lucy is a communication aid, not certified medical equipment.
- People who rely on a screen reader to use their device. Lucy does not include
  VoiceOver/screen-reader integration and that is not on the roadmap. If that's what you
  need, please look at established AAC apps designed around it.
- People who want a single all-in-one subscription. Lucy is BYOK (bring your own key)
  and you pay Fish Audio directly.
- People who are not comfortable installing apps outside the App Store. The macOS build
  is currently distributed as a signed `.app` you download yourself. The iPhone build is
  distributed through Apple's TestFlight, which is also outside the regular App Store.

## What Lucy costs

Lucy itself is free and the source code is open under
[AGPL-3.0](https://github.com/lucy-chapar/LucyTTS/blob/main/LICENSE). You don't pay us.

You **do** pay Fish Audio for the actual voice generation, on their own pricing. As a
rough sanity check, a typical conversation sentence is around 80–150 characters; Fish
typically bills well under a cent per sentence at current rates. A reasonable starting
budget for testing is about **$5** of Fish credit. Always check
[Fish's pricing page](https://fish.audio/pricing) for the current rate.

To avoid surprise bills, keep your Fish account balance low and top it up as needed. A
Lucy-side daily character cap is [planned](https://github.com/lucy-chapar/LucyTTS/issues/4)
but not yet built.

## What's on the roadmap

These are tracked as GitHub issues so you can follow progress:

- [Cancel TTS in flight when Stop is pressed during generation](https://github.com/lucy-chapar/LucyTTS/issues/3) — today, Stop only halts playback; a cancelled sentence may still play.
- [Daily character cap and in-app usage display](https://github.com/lucy-chapar/LucyTTS/issues/4) — so a stuck loop or a long paste can't spike your Fish bill.
- [Persistent on-device speech history](https://github.com/lucy-chapar/LucyTTS/issues/5) — today, history is cleared when Lucy quits.
- [In-app editing of phrase presets](https://github.com/lucy-chapar/LucyTTS/issues/6) — today, phrases are read-only.

## Want to suggest something?

Open a [GitHub issue](https://github.com/lucy-chapar/LucyTTS/issues/new) with the
**`feature request`** label. We read every one.

For security or private matters, see the [Contact](#contact) section below.

## Contact

- **Bug reports and feature requests:** [GitHub Issues](https://github.com/lucy-chapar/LucyTTS/issues/new) — please tag with `bug` or `feature request`.
- **Security disclosures and private messages:** `lucychapar@pm.me`.

## Honest disclaimers

- Lucy is built and maintained by one person with AI assistance. Response times will
  vary. We will not silently abandon the project, but we also will not pretend to be a
  larger team.
- Lucy is not affiliated with, sponsored by, or endorsed by Fish Audio. Fish Audio is a
  separate company with their own [Terms](https://fish.audio/terms) and
  [Privacy Policy](https://fish.audio/privacy), and you agree to those directly when you
  sign up with them.
- "Lucy TTS" and the Lucy logo are reserved marks; see
  [TRADEMARKS.md](https://github.com/lucy-chapar/LucyTTS/blob/main/TRADEMARKS.md).
