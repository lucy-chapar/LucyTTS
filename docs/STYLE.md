# Editorial style for the Lucy TTS site

Rules for anyone (human or AI) writing for `/docs/`. Keep this file short on purpose.

## Audience

The default reader is someone who could assemble a 3D-printer kit. They:

- Follow numbered steps.
- Look at screenshots.
- Get frustrated by missing context.
- Are not professional software developers.
- Will not "just figure it out."
- Will close the tab if the first paragraph reads like marketing copy.

Write for that person. If you find yourself writing for an investor, a journalist, or a
fellow engineer, stop and rewrite.

## Tone

- Honest. If something is rough, say so. Reader trust is the whole game.
- Calm. No exclamation points outside of literal UI text.
- Concrete. Use numbers, screenshots, exact button names.
- Plural-of-respect for the user. "You" not "users."
- Singular "we" for Lucy. Lucy is built by one person + AI; the site can still say "we"
  for warmth as long as it doesn't lie about team size.

## Hard rules

1. **Never claim a feature works if it doesn't ship today.** Mark unbuilt things as
   "coming" or "planned." A reader who tries the feature and finds it broken loses
   trust permanently.
2. **Never quote a price.** Always link to Fish Audio's current pricing page. Prices
   drift; the page is the source of truth.
3. **Never write or paste a real API key**, not even in an example. Use `paste-your-key-here`
   or `sk_...` style placeholders.
4. **Never use marketing superlatives.** No "blazingly fast," "best in class,"
   "revolutionary," "magical." The audience hates this.
5. **Never speak for disabled users.** Don't claim Lucy is accessible. Describe what
   works and what doesn't, and invite people who rely on assistive tech to test and tell
   us what's missing.
6. **Always define jargon on first use, per page.** TTS, API key, TestFlight, Keychain,
   reference ID, virtual audio device, BYOK. Even if it's obvious, someone reading the
   page in isolation deserves the definition.
7. **Always end an instruction with "What you should see now."** The 3D-printer-kit
   reader self-verifies after every step.
8. **Always provide a fallback for "If something's off."** Even if you only know one
   common cause.

## Formatting conventions

- Use sentence case for headings, not title case.
- Use real em-dashes (—), not "--".
- Inline `code` for UI button labels, settings names, file names, and code identifiers.
- Tables for "X | Y | Z" relationships; bulleted lists for short enumerations.
- Screenshots: store as PNG in `docs/images/`. Filenames `descriptive-kebab-case.png`.
  Always include alt text (`![alt text](images/file.png)`).
- Link to repo files using their full GitHub URL (`https://github.com/lucy-chapar/LucyTTS/blob/main/PATH`),
  not relative paths — the docs site is served from a subdirectory.
- Internal links on this site: use the `permalink` from the page's front-matter
  (`/LucyTTS/setup-guide/`), not the filename. This survives reorganization.

## Things to avoid

- Acronyms without definitions.
- Long paragraphs. Short blocks scan better.
- "Simply." Nothing is simple. Drop the word.
- "Just." Same as above.
- Apologies for things that aren't problems.
- Promises of features without dates.
- Anything that reads like an App Store description.

## When in doubt

The setup guide is the canonical example of the right voice and structure. Match it.
