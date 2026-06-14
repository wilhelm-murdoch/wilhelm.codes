# wilhelm.codes

The source for [wilhelm.codes](https://wilhelm.codes) — a personal blog built with [Hugo](https://gohugo.io). It has long-form posts (`/blog`, surfaced on the home and archive pages), short-form "bits" (`/bits`), and a live `/changelog` fed by the GitHub events API.

## Tech stack

| Concern        | Tool                                                                 |
| -------------- | -------------------------------------------------------------------- |
| Static site    | Hugo (**extended**) — `css.TailwindCSS` asset pipeline               |
| Styling        | Tailwind CSS v4 + `@tailwindcss/typography`, compiled by Hugo        |
| Fonts          | Self-hosted Inter & Rubik (woff2, `font-display: swap`)              |
| Icons          | Font Awesome (duotone + brands), loaded as deferred SVG/JS           |
| Formatting     | Prettier + `prettier-plugin-go-template` + `prettier-plugin-tailwindcss` |

There is no committed `tailwind.config.js`: Tailwind v4 is configured in CSS ([assets/css/main.css](assets/css/main.css)), and Hugo invokes the Tailwind CLI during the build via [`css.TailwindCSS`](https://gohugo.io/functions/css/tailwindcss/).

## Prerequisites

- **Hugo extended**, a recent release (`try`, `css.TailwindCSS`, and current front-matter keys are used — `brew install hugo`, verify with `hugo version` showing `+extended`).
- **Node.js** (any current LTS) — provides the Tailwind CLI and Prettier.

## Getting started

```sh
npm install        # installs Tailwind CLI, typography plugin, Prettier
hugo server        # dev server with live reload at http://localhost:1313
```

Hugo compiles `assets/css/main.css` through the Tailwind CLI on each build; there is no separate CSS build step to run.

### How the CSS pipeline fits together

- [assets/css/main.css](assets/css/main.css) is the Tailwind v4 entry point (`@import "tailwindcss"`, the typography `@plugin`, custom variants, and an `@source inline(...)` safelist for the color utilities composed dynamically from front matter).
- [layouts/partials/head/css.html](layouts/partials/head/css.html) builds it with `css.TailwindCSS` inside `templates.Defer`, so the build runs after `hugo_stats.json` (the list of classes Hugo emitted) is complete.
- `hugo.toml` enables `[build.buildStats]` and the CSS cache busters that trigger recompilation when templates or `assets/**.css` change.

## Building for production

```sh
hugo            # outputs the site to public/
```

Production builds minify and fingerprint the CSS and fetch the changelog from the live GitHub API. `public/` and `resources/` are build artifacts and are git-ignored.

## Project structure

```
archetypes/   front-matter template for `hugo new`
assets/       Tailwind entry (css/) and Font Awesome bundles (processed by Hugo)
content/      Markdown — blog/, bits/, and the archive/changelog pages
layouts/      Go templates (per-type baseof, partials, shortcodes)
static/       Verbatim files — fonts, images, favicon, github.json fixture
hugo.toml     Site configuration
```

## Authoring content

Create a new post from the archetype:

```sh
hugo new content/blog/my-post/index.md
```

Posts and bits use a few custom front-matter fields the templates read:

- `highlight` — accent color (e.g. `blue`, `emerald`, `rose`); drives the `.highlight-*` styles and dynamically composed color utilities.
- `pack` + `icon` — Font Awesome family and icon name (e.g. `pack: duotone`, `icon: code`).

Bits live in `content/bits/*.md` and are rendered inline on `/bits` (they are marked `build.render: never` via cascade in `content/bits/_index.md`, so they are listed but have no standalone page). The `/changelog` page reads the live GitHub events API in production and the committed `static/github.json` fixture
in development.

## Formatting & checks

```sh
npx prettier --write .    # format templates (respects .prettierignore)
npx prettier --check .    # CI-friendly check
hugo                      # the build is the test: it must finish with no warnings
```

Prettier is scoped by [.prettierignore](.prettierignore) to templates and config only — it never touches authored content, data fixtures, build output, or the pre-minified Font Awesome bundles.

There is no separate test suite; a clean `hugo` build (no errors **or** warnings) plus `prettier --check` is the bar before deploying.

## Deployment

`public/` is the deployable artifact. Deployment is not codified in this repo; [scripts/sync.sh](scripts/sync.sh) is a local `fswatch` + `rsync` helper for syncing a directory to a destination.
