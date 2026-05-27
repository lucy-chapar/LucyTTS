---
title: Setup guide
description: Step-by-step instructions to install Lucy and get to your first sentence spoken out loud.
permalink: /setup-guide/
---

This guide walks you through everything from "I just heard about Lucy" to "Lucy spoke a
sentence in my chosen voice." If you can build an IKEA shelf or a 3D-printer kit, you
can do this. Plan on **about 15 minutes** the first time.

> **Heads up.** Lucy needs a Fish Audio account, which costs money to use (a few cents
> per long sentence). You don't pay us. Top up about **$5** at Fish to test comfortably.

## What you'll need

| Item | Notes |
|---|---|
| A Mac (macOS 13+) **or** iPhone (iOS 16+) | You can install Lucy on both later. Start with whichever you'll use first. |
| A Fish Audio account | Free to create. https://fish.audio |
| About **$5** of Fish Audio credit | This is for Fish, not for us. You'll add this on Fish's website. |
| 15 minutes |  |
| An email you can check | Required for both Fish signup and Apple's TestFlight invite. |

You do **not** need:

- A developer account, Xcode, the terminal, or any code knowledge.
- A credit card on file with us (we don't have a payment system).
- A subscription to anything Lucy-related.

---

## Step 1 — Create your Fish Audio account

1. Open **<https://fish.audio>** in a web browser.
2. Click **Sign up** in the top right.
3. Use the email and password method (the simplest), or sign in with Google.
4. Verify your email if Fish asks you to.

> _Screenshot placeholder: Fish Audio signup page with the Sign up button circled._

**What you should see now:** You're logged into the Fish Audio dashboard.

**If something's off:** If Fish's site is slow or down, try again in a few minutes. Fish
is a separate company; if their service is having an outage, Lucy can't synthesize
voices until they recover.

---

## Step 2 — Add a little credit

Lucy doesn't include any free Fish usage. You pay Fish directly for what you use.

1. In the Fish dashboard, click **Billing** (or **Pricing**, depending on Fish's current
   layout).
2. Add about **$5** of credit to start. This will be plenty for several days of testing.
3. Optional but recommended: turn on a **low-balance email alert** in Fish so you know
   before you run out.

> _Screenshot placeholder: Fish Audio billing page._

**What you should see now:** A positive credit balance on your Fish dashboard.

---

## Step 3 — Generate an API key

An API key is just a long string of letters and numbers that proves Lucy is allowed to
use your Fish account.

1. In the Fish dashboard, look for **API keys** (sometimes under **Developer**,
   sometimes under **Settings**).
2. Click **Create API key** (or similar). Give it a name like `Lucy on iPhone` so you
   remember.
3. **Copy the whole key.** This is the only time Fish will show it to you in full. If
   you lose it, you'll need to create a new one.
4. Treat this key like a password. Don't share it, screenshot it, or email it. Lucy will
   store it in your device's secure Keychain, not on any server.

> _Screenshot placeholder: Fish Audio API keys page with the "Create API key" button circled._

**What you should see now:** A long string copied to your clipboard. You haven't done
anything with it yet — that's fine.

---

## Step 4 — Install Lucy

### On iPhone (via TestFlight)

1. Request a TestFlight invite by emailing `lucychapar@pm.me` with the subject
   "TestFlight invite". Include the email address tied to your Apple ID.
2. You'll get an email from Apple's TestFlight system.
3. Install Apple's free **TestFlight** app from the App Store if you don't already have
   it.
4. Open the TestFlight email on your iPhone and tap **View in TestFlight**.
5. Tap **Install**.

> _Screenshot placeholder: TestFlight invite email and TestFlight install screen._

**What you should see now:** A new app icon on your home screen named **Lucy**.

**If something's off:** TestFlight builds expire every 90 days. If Lucy says the build
is expired, email `lucychapar@pm.me` and we'll send a new invite.

### On Mac (direct download)

> _Coming soon. The macOS build is currently shared on a per-tester basis. Email
> `lucychapar@pm.me` and we'll send you a signed download link._

---

## Step 5 — Paste your key into Lucy

1. Open Lucy. The first screen asks for your Fish Audio API key.
2. Paste the key you copied in Step 3.
3. Tap **Test connection**. Lucy will send a tiny test sentence to Fish to confirm the
   key works. This costs about a cent.
4. If the test succeeds, tap **Save and continue**. Lucy stores the key in your device's
   Keychain (not on any server).

> _Screenshot placeholder: Lucy's first-run key entry screen._

**What you should see now:** Lucy's main screen — a text input, a Speak button, and a
queue area.

**If "Test connection" failed:**
- Most common: a typo or extra space. Re-copy the key from Fish and try again.
- Less common: your Fish account has no credit. Top up in the Fish dashboard.
- Rare: Fish is having an outage. Wait a few minutes and retry.

---

## Step 6 — Pick a voice and say hello

1. Open **Settings → Voices** in Lucy.
2. Lucy ships with a default voice. To change it, browse Fish's catalog and paste any
   voice's reference ID into a new voice preset.
3. Back on the main screen, type **"Hello, this is my new voice."** and press Enter.
4. The first time, you'll hear a brief silence while Lucy generates the audio. Then
   playback starts.

**What you should see and hear now:** Your typed sentence, spoken out loud in the
selected voice.

---

## You're done. Now what?

- **Read** the [troubleshooting page](/LucyTTS/troubleshooting/) so you know what to do
  when something acts up.
- **Skim** the [privacy page](/LucyTTS/privacy/) so you know exactly what's leaving your
  device.
- **Send feedback.** Bugs and feature requests go on
  [GitHub Issues](https://github.com/lucy-chapar/LucyTTS/issues/new); please tag with
  `bug` or `feature request`. Security or private matters go to `lucychapar@pm.me`.
- **Keep your Fish account balance modest.** A Lucy-side daily character cap is
  [planned](https://github.com/lucy-chapar/LucyTTS/issues/4) but not built yet, so for
  now your strongest guardrail against surprise bills is the balance you choose to top
  up on Fish.

Welcome to the beta. Thank you for testing.
