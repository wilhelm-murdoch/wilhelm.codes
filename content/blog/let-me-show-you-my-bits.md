---
title: Let Me Show You My <span>Bits</span>
title_safe: Let Me Show You My Bits
highlight: rose
pack: duotone
icon: shapes
draft: false
toc: true
date: 2026-06-18
category: Development
tags:
  - hugo
  - css
  - tailwindcss
---
A while back, in [Reading Between the Posts](https://wilhelm.codes/blog/reading-between-the-posts/), I wired up the home page so the quiet gaps between articles would narrate themselves - "_1 bit and 41 changelog events in between_". There was just one tiny problem with that sentence. At the time I had written exactly _zero_ bits. 

<!--more-->

So let me finally show you my bits.

## What even is a bit?

A bit is the smallest unit of "I made a thing" I'm willing to commit to. It could be a quote that stuck with me, a link worth keeping, the odd YouTube video, or a one-line thought too small to earn its own long-form entry. Each one is a little markdown file in `/bits` and  the only thing it really has to declare is what _kind_ of bit it is:

```yaml
---
type: quote
date: 2026-06-17
source: "Edsger Dijkstra"
---
"Simplicity is a great virtue but it requires hard work to achieve it."
```

`type` is the whole trick that everything else hangs off.

## One shape per thought.

The thing I didn't want was for a pithy quote to render like a bare link or to render like a video. They're different shapes of thought, so they ought to look different.

I'd already learned this lesson building the [changelog](https://wilhelm.codes/blog/a-changelog-that-builds-itself/), which leans on one tiny partial per event type. So I stole from myself. There's a single lookup table mapping each `type` to an icon, an accent colour and a label:

```go
{{ $meta := dict
  "quote" (dict "icon" "quote-right"    "colour" "rose"    "label" "quote")
  "link"  (dict "icon" "arrow-up-right" "colour" "blue"    "label" "link")
  "video" (dict "icon" "youtube"        "colour" "red"     "label" "video")
  "blurb" (dict "icon" "pen-nib"        "colour" "emerald" "label" "blurb")
}}
```

It then matches a micro-partial per type that decides how the content actually renders. Adding a brand new kind of bit is now "add one row, add one tiny template", which is about as many steps as I'm willing to tolerate.

![](/blog/let-me-show-you-my-bits/bits.png)

## Hugo, why are you like this?

My bits started life with two perfectly reasonable front-matter fields: `type` and `url`. Hugo took one look and quietly robbed me of both.

It turns out `url` is a _reserved_ key which Hugo uses to treat as the page's permalink. So, the moment I put a `https://...` in there, the build fell over with a stern little message about unsupported protocols. `type` doesn't even have the decency to error. It silently moves out of `.Params.type` and into `.Type`, which _also_ hijacks the layout lookup. So my `.Params.type` was resolving to nothing and every single bit was quietly rendering as the fallback.

Turns out hte fix for this was simply to rename `url` to `link` and  read `.Type` instead of `.Params.type`. Half an hour of my life dedicated to two words I didn't know were already spoken for.

Coding is my passion.

## Bits flapping in the wind.

Rather than dumping bits into the same fold-out list as the GitHub noise, I pulled them out as their own first-class timeline rows. The lower-signal changelog chatter stays tucked behind the "_N changelog events in between_" disclosure. So, the home page now reads in three tiers: 

- the loud headline articles
- the medium-volume bits
- the quiet changelog hum 

The same interstitial machinery I built last time, but bits just get to stand a little taller than a commit.

![](/blog/let-me-show-you-my-bits/home.png)

## The tag that went nowhere.

Bits are deliberately `render: never` in Hugo. They live inline on the bits page and never get their own URL. Except "no page" also quietly means "no place in the taxonomy", which means a tag only ever used by a bit has no `/tags/...` page to point at. If I link it anyway I've shipped a `404`.

So, the tags only become links if there's actually somewhere to go:

```go
{{ with site.GetPage (printf "/tags/%s" (urlize .)) }}
  <a href="{{ .RelPermalink }}">#{{ .Data.Term }}</a>
{{ else }}
  <span>#{{ . }}</span>
{{ end }}
```

A tag with a real page becomes a link and a bit-only tag stays as plain text. No broken links and the nice part is it heals itself the moment a proper article picks up the same tag.

## In closing ...

The front page has quietly turned into a proper little stream. Long-form when I've actually got something to say, bits when I don't and  a [year of squircles](https://wilhelm.codes/blog/a-year-in-circles/) up top keeping a tally of it all.

Which is the entire point. The less effort it takes to post a half-formed thought, the more likely I am to actually post it. And the more I post, the more those gaps fill in.

And, as always, you can check everything out for yourself in the [repo](https://github.com/wilhelm-murdoch/wilhelm.codes).
