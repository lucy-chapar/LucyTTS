---
title: Troubleshooting
description: Common snags and what to do about them, in plain English.
permalink: /troubleshooting/
---

This page is organized by **what you're seeing**, not by what's broken internally. If
your problem isn't here, please
[open a GitHub issue](https://github.com/lucy-chapar/LucyTTS/issues/new) tagged `bug`
and we'll add it.

## Known beta-period limitations

These are deliberate rough edges in the current beta. We mention them up front so they
don't surprise you. Each one links to its tracking issue.

- **Stop sometimes still speaks the cancelled sentence.** If you press Stop while Lucy
  is generating (not yet playing) a sentence, the generation finishes in the background
  and the sentence plays anyway. Workaround: press Stop a second time when playback
  starts.
  ([#3](https://github.com/lucy-chapar/LucyTTS/issues/3))
- **No persistent history yet.** Anything you typed in a previous session is gone when
  Lucy quits. Replay only remembers the most recent sentence within the current
  session.
  ([#5](https://github.com/lucy-chapar/LucyTTS/issues/5))
- **No in-app usage display or daily character cap.** Today the strongest guardrail
  against surprise Fish bills is the balance you choose to top up on Fish.
  ([#4](https://github.com/lucy-chapar/LucyTTS/issues/4))
- **No in-app phrase editing.** The starter phrase catalog is read-only inside Lucy
  for now.
  ([#6](https://github.com/lucy-chapar/LucyTTS/issues/6))
- **"Monitor locally" toggle is disabled.** This is intentional for now — the feature
  isn't built yet. Ignore the toggle.
- **Meeting Mode is a label, not a behavior.** Today Lucy doesn't auto-route audio for
  meetings. You still need to manually pick a virtual audio device (e.g. BlackHole,
  Loopback) as the output device.

---

## API key problems

### "Test connection" failed right after I pasted my key

Most common causes, in order:

1. **A space at the start or end of the key.** Re-copy from Fish; don't double-tap to
   select (which can include trailing whitespace). Try paste again.
2. **You copied only part of the key.** API keys are long. Make sure your clipboard has
   the whole string.
3. **Your Fish account has no credit.** Open your Fish dashboard and confirm a positive
   balance. Even a "test connection" costs a tiny fraction of a cent.
4. **The key was revoked or deleted on Fish.** Go to your Fish dashboard → API keys and
   confirm the key still exists. If not, create a new one and paste it into Lucy.
5. **Fish is having an outage.** Try again in a few minutes.

### Lucy says "Missing Fish Audio API key" even though I saved one

Open **Settings → API key** and look at the status row. If it says **Saved** but Lucy
still complains, hit **Replace key** and re-paste. This re-syncs the Keychain entry.
Your previous key is overwritten, not stored alongside.

### I want to remove my key entirely

Open **Settings → API key → Replace key**. Then close the dialog without saving a new
one. The Keychain entry is deleted and Lucy returns to the first-run setup screen.

---

## Voice and audio problems

### The voice sounds wrong, slow, robotic, or has the wrong accent

You're hearing the voice that the **Reference ID** in your active voice preset points
at. Open **Settings → Voices** and either:

- Pick a different preset.
- Tap **Browse Fish voices** and try another voice from Fish's catalog.
- Paste a different Reference ID into your active preset.

Voice quality varies dramatically across Fish's library — that's a Fish thing, not a
Lucy thing. The default Lucy ships with is a reasonable starting point but is not the
best Fish has to offer.

### Volume is too low or too high

Two places to adjust:

1. **Lucy's volume slider** in Settings → Tuning. Note: Fish Audio's volume parameter is
   an offset from default, not a percentage. Small values matter more than they look.
2. **Your system output volume.** Lucy routes through whatever output device you pick.

### Speech speed is wrong

**Settings → Tuning → Speed.** 1.0 is normal. 0.8 is noticeably slower; 1.2 is
noticeably faster.

### I hear myself in the meeting instead of Lucy

You probably routed Lucy's output to your microphone's monitor instead of through a
virtual audio device. Recommended setup:

1. Install [BlackHole](https://existential.audio/blackhole/) (free) or
   [Loopback](https://rogueamoeba.com/loopback/) (paid).
2. In Lucy → Settings → Output device, pick BlackHole / Loopback.
3. In your meeting app (Zoom, Meet, etc.), pick BlackHole / Loopback as the microphone.
4. To still hear Lucy yourself, create a multi-output device in macOS Audio MIDI Setup
   that contains both your speakers/headphones **and** BlackHole, and pick that as
   Lucy's output instead.

### Audio cuts off mid-sentence

If this happens consistently with one specific sentence, it may be a Fish-side issue
with that voice + that text. Try splitting the sentence into two shorter ones.

If it happens randomly, it's most often a network blip during the audio download. Lucy
will mark the item as an error and move on; you can retype and try again.

---

## Queue problems

### Sentences are playing in the wrong order

They shouldn't — the queue is strict FIFO. If you see this, please
[open an issue](https://github.com/lucy-chapar/LucyTTS/issues/new) tagged `bug` with
the exact sequence of what you typed.

### I cleared the queue but the current sentence still played

That's expected. **Clear** only removes items that are still waiting. To stop what's
currently being generated or played, use **Stop**. (See the Known Limitations note
about Stop-during-generation above.)

### The queue is getting really long and Lucy is sluggish

Quit and reopen Lucy to clear the session. Automatic pruning of completed items will
arrive with the [persistent history feature](https://github.com/lucy-chapar/LucyTTS/issues/5).

---

## Cost problems

### My Fish bill is higher than I expected

Things to check, in order:

1. **Long sentences cost more than short sentences**, proportionally to character
   count. A 500-character paragraph costs roughly 5× a 100-character sentence.
2. **The "Test connection" button costs about a cent each time** because it does a real
   tiny TTS request.
3. **Voice previews** count if Fish renders them on demand. Most previews in Fish's
   catalog are pre-rendered samples and likely don't bill, but check Fish's terms.
4. **Background or automated input.** If something else on your machine was pasting or
   driving Lucy, that's a likely culprit. Quit and relaunch.

### I want a hard guardrail against accidental overspending

Until the [Lucy-side daily cap](https://github.com/lucy-chapar/LucyTTS/issues/4) ships,
the strongest guardrail is the **Fish account balance**. Only top up the amount you're
willing to spend in a given period. When that balance is gone, Fish stops generating
audio.

---

## Installation problems

### TestFlight says the build expired

TestFlight builds expire every 90 days. Email `lucychapar@pm.me` and we'll send a new
invite for the next build.

### macOS says "Lucy can't be opened because it is from an unidentified developer"

For the friends-and-family beta period, the macOS app may not be fully notarized.
Workaround:

1. Locate Lucy in Finder.
2. Right-click (or Ctrl-click) → **Open**.
3. macOS shows a warning; click **Open**.

You only have to do this once per install.

The shipping macOS build will be Developer-ID signed and notarized so this prompt
disappears.

---

## Accessibility

Lucy is a typing-to-speech app for people who can type comfortably. It is **not**
designed around screen-reader use and **does not include VoiceOver / screen-reader
integration**. Adding that integration is not on the current roadmap.

What does work today:

- ✅ Keyboard typing and submitting (Enter to speak, Shift+Enter for newline).
- ✅ The text input uses native AppKit / UIKit, so spelling and grammar features work.

If you rely on a screen reader as your primary way to use your device, Lucy is unlikely
to be the right tool, and we'd point you toward established AAC apps designed around
that workflow instead.

---

## Reporting a bug we should know about

If your problem isn't on this page, please
[open a GitHub issue](https://github.com/lucy-chapar/LucyTTS/issues/new) tagged `bug`
with:

- What you were trying to do.
- What you saw instead.
- Your platform (Mac model + macOS version, or iPhone model + iOS version).
- Lucy's version (visible in **Settings → About**).
- A screenshot if possible.

For security disclosures or other private matters, email `lucychapar@pm.me` instead.
