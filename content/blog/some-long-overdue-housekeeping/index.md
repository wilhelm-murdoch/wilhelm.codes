---
title: Some Long Overdue <span>Housekeeping</span>
title_safe: Some Long Overdue Housekeeping
highlight: orange
pack: duotone
icon: broom
draft: false
toc: true
date: 2026-06-14
category: Development
tags:
  - hugo
  - tailwindcss
  - css
  - refactoring
credit: Photo by <a href="https://unsplash.com/@bobvanaubel">Bob van Aubel</a> on <a href="https://unsplash.com/photos/red-and-brown-brush-on-white-wooden-table-hUWlPaOHyAI">Unsplash</a>
---
This blog has been quietly chugging along for a while now without me paying it much attention. Which is, I suppose, the whole point of a [set-and-forget](https://wilhelm.codes/blog/my-blog-publishing-setup/) setup. But "set-and-forget" has a sneaky way of becoming "forgotten", and the longer you leave something untouched, the more it quietly rots behind your back. So I rolled up my sleeves and gave the whole thing a proper tune-up.

<!--more-->
## Confession Time
While poking around the build, I discovered something a little embarrassing. My Tailwind setup - the source, the config, and the _entire_ `node_modules` directory - was living inside Hugo's `static/` folder.

If you know Hugo, you already know where this is going. Everything in `static/` gets copied, verbatim, into the final site. Which means I had been cheerfully publishing my whole build toolchain - megabytes of it - to the live site on every single deploy. So, yeah. Production was shipping `node_modules`. Coding is my passion.

Nobody noticed, nothing broke, and the world kept turning. But it's the kind of thing that, once you see it, you can't _un_-see. To be fair to myself, when I originally put this Hugo site together, I only learned enough to get something shipped.
## Letting Hugo do the heavy lifting.
The reason that mess existed in the first place was that I'd wired up Tailwind as a separate, manual build step that spat out a compiled stylesheet for Hugo to pick up. It worked, but it was a second moving part I had to remember existed.

The good news is that recent versions of Hugo can drive [Tailwind](https://gohugo.io/functions/css/tailwindcss/) itself, natively, as part of the normal asset pipeline. Combined with Tailwind v4 - which finally ditches the JavaScript config file in favour of configuring everything in CSS - I got to delete a _lot_ of stuff:

```bash
$ git diff --shortstat main...modernize
64 files changed, 1872 insertions(+), 40197 deletions(-)
```

The whole stylesheet now starts its life as a single entry point:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
@source "hugo_stats.json";
```

That `hugo_stats.json` bit is the clever part. Hugo writes out a list of every utility class it actually emits, and Tailwind reads _that_ to decide what to generate. No more pointing Tailwind at my templates and hoping it guesses right.

Then a small partial hands it all off to Hugo to compile, minify and fingerprint:

```go
{{- with (templates.Defer (dict "key" "css")) }}
  {{- with resources.Get "css/main.css" }}
    {{- $opts := dict "minify" (not hugo.IsDevelopment) }}
    {{- with . | css.TailwindCSS $opts }}
      {{- /* ...do very cool things... */ -}}
    {{- end }}
  {{- end }}
{{- end }}
```

The `templates.Defer` wrapper is there because the CSS can't compiled ( transpiled? ) until Hugo has finished rendering every page and knows the full list of classes. So, in a very real way, Hugo solves an annoying 🐔 and 🥚 problem.

This means no more standalone Tailwind config, no committed stylesheet, no `node_modules` in `static/`, and no build toolchain leaking onto the live site. Very cool!

## So. Many. Deprecations.

Of course, nothing that's been left alone for a year comes back to life cleanly. Bumping Hugo to the latest release lit up the console like a Christmas tree.

A few of my templates were leaning on things that have since been politely shown the door:

- `resources.GetRemote ... .Err` for the [changelog page](https://wilhelm.codes/changelog/) - that pattern was removed in favour of a shiny new `try` keyword.
- `.Language.LanguageCode` and `.Language.LanguageDirection`, both deprecated in favour of `.Locale` and `.Direction`.
- The `_build` and `cascade._target` front matter keys, now just `build` and `cascade.target`.

None of it was hard to fix, but it's a good reminder that "it still builds" and "it builds _without complaints_" are two very different bars.

## A Footgun!

Here's a fun one. The changelog page pulls in a Github event fixture file during local development by fetching it over `http://localhost:1313`. Effectively, from the very dev server that's _trying to build the page_.

Those of you who are familiar with such things can probably see the problem. Hugo builds the site _before_ it starts listening on that port, so the build sits there waiting for a server that doesn't exist yet. A deadlock of my own making. The obvious fix was to just read the file off disk instead of asking the network nicely.

## Some honourable mentions.

A grab-bag of smaller wins while I had the hood up:

- Fonts are now served as `woff2` instead of raw `ttf`, with `font-display: swap` so text shows up immediately instead of hanging around invisible. This alone shaved the font payload down by about 60%.
- I also deleted a few MB of fluff that wasn't being loaded by anything.
- Prettier got a nice version bump and I taught it to sort my Tailwind classes, so I can stop pretending I do that consistently by hand.

## Was the juice worth the squeeze?

The site should look _exactly_ the same as it did before. Not a single pixel out of place. Which is, weirdly, the whole point; all of this work was about the parts you can't see. I got a leaner build, faster page loads, and a project I can come back to in another year without wincing; famous last words, etc...

For now, the house is clean. Very nice.
