# Contributing

Thank you for helping make Lucy TTS better. This project exists to make live
communication faster, calmer, and more accessible.

## Licensing

By submitting a contribution, you agree that your contribution is licensed under
the same license as the material you modify:

- Code contributions are licensed under the GNU Affero General Public License
  v3.0 or later.
- Documentation and free starter phrase content contributions are licensed under
  Creative Commons Attribution 4.0 International (CC BY 4.0), unless a file says
  otherwise.

There is no Contributor License Agreement at this time. The project uses an
inbound=outbound contribution model.

## Accessibility First

Basic communication features should stay free and should not be artificially
crippled. Paid services, if added later, should fund convenience, maintenance,
sync, content, and support rather than holding communication hostage.

When changing UI, prioritize:

- Fast type-to-speak flow.
- Readable text input, especially on iPhone with the keyboard open.
- Clear queue state and recoverable errors.
- Low-friction settings.
- Respectful, affirming language.

## Fish Audio Boundaries

Lucy TTS is a bring-your-own-key client for Fish Audio. Contributions must not
turn the project into a Fish Audio reseller, proxy, hosted speech gateway, or
bundled voice-credit provider.

Do not:

- Commit or log real Fish Audio API keys.
- Store user Fish API keys on Lucy servers.
- Bundle Fish public voices, cloned voices, celebrity-like voices, or
  user-submitted models without documented rights.
- Scrape Fish discovery pages when official API endpoints are available.
- Use Fish Audio output to train or improve a competing TTS model.
- Add server-side Fish proxying, bundled Fish usage, or managed Fish API keys
  without written Fish approval and attorney review.

If accepting Fish model URLs, parse out and store only the model/voice ID needed
for API requests.

## Development Checks

Always use the wrappers in `scripts/` (or the equivalent `make` targets)
rather than bare `swift` / `xcodebuild` commands. The wrappers auto-detect
your installed Xcode and set `DEVELOPER_DIR` for you, so the build works
even if `xcode-select -p` is pointing at the Command Line Tools (which is
common on developer machines).

Run the checks that match your changes:

```sh
make build         # macOS SwiftPM build
make test          # macOS unit tests
make ios-build     # iOS simulator smoke build
git diff --check   # whitespace sanity
```

If you hit toolchain trouble, run `make doctor` to see exactly which
Xcode the wrappers selected and what versions of `swift` / `xcodebuild`
are in use.

Use a real iPhone for keyboard/safe-area UI fixes when practical; the
simulator build only proves the iOS code compiles.

CI (`.github/workflows/ci.yml`) runs the same `swift build`, `swift test`,
and iOS simulator build on every push and pull request.

## Security

Never include secrets in source code, docs, test fixtures, logs, screenshots, or
issues. Use placeholders such as `your_api_key_here`.

## Not Legal Advice

Licensing and compliance notes in this repository are drafting guidance, not
legal advice. Review with an attorney before commercial launch.
