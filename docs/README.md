# Lucy TTS website (`/docs`)

This folder is the source of the public Lucy TTS website published at
<https://lucy-chapar.github.io/LucyTTS/>.

If you're looking for the project README, see
[`../README.md`](../README.md).

## What lives here

| File | Purpose |
|---|---|
| `_config.yml` | Site-wide settings (theme, title, navigation, URLs). |
| `index.md` | Landing page. |
| `setup-guide.md` | Step-by-step install + first sentence walkthrough. |
| `privacy.md` | Public Privacy Policy (the URL we give Apple App Store Connect). |
| `troubleshooting.md` | "When you see X, try Y" guide. |
| `feedback.md` | How beta testers send us things. |
| `STYLE.md` | Editorial rules for this site. **Read before writing.** |
| `images/` | Screenshots. PNG, kebab-case filenames, always include alt text. |

## How to edit

You can edit any `.md` file in this folder directly on GitHub.com:

1. Open the file in the GitHub web UI.
2. Click the pencil icon (Edit).
3. Make your change.
4. Scroll down, write a short commit message, click **Commit changes**.
5. The site rebuilds automatically within ~30 seconds.

No terminal, no git client, no local Jekyll required.

If you'd rather edit locally:

```sh
# In the repo root
cd docs
bundle install   # one time; needs Ruby and Bundler
bundle exec jekyll serve
# Then open http://localhost:4000/LucyTTS/
```

A `Gemfile` isn't checked in because GitHub Pages handles the build for us; add one
locally if you want a Jekyll preview.

## How publishing works

GitHub Pages is configured (via repo Settings → Pages) to publish from the `main`
branch, `/docs` folder. Any commit to `main` that touches `/docs` triggers a rebuild.
No GitHub Actions workflow required for publishing.

If publishing breaks, check:

1. **Settings → Pages** in the repo: the Source should be "Deploy from a branch", branch
   `main`, folder `/docs`.
2. The most recent **Pages** build under the **Actions** tab. Jekyll errors are usually
   typos in `_config.yml` or invalid front-matter in a page.

## Style and tone

See [`STYLE.md`](STYLE.md). Short version: write for someone who could assemble a
3D-printer kit, never claim features that don't ship today, never use marketing
superlatives, always tell the reader what they should see after each step.
