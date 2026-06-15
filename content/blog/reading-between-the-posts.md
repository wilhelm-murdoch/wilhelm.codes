---
title: Reading <span>Between</span> the <span>Posts</span>
title_safe: Reading Between the Posts
highlight: purple
pack: duotone
icon: timeline
draft: true
toc: true
date: 2026-06-16
category: Development
tags:
  - hugo
  - css
---
The front page of this site has always been a plain list of articles. Which would be fine, except I write proper articles roughly never, while I commit code and fire off little [bits](https://wilhelm.codes/bits/) constantly. So the list told a bit of a lie; two posts sat next to each other as if nothing happened in between, when in reality there was a whole year of quiet tinkering hiding in the gap.

<!--more-->

I wanted to fill those gaps in. Not with more full-fat rows, but with a small, honest line between each pair of articles; something like "_1 bit and 41 changelog events in between_". A receipt for all the work that never quite became a blog post.

## One pile of events

The trick to merging things that don't look alike is to make them look alike first. I already pull my GitHub activity for the [changelog](https://wilhelm.codes/blog/a-changelog-that-builds-itself/), so I reused that, threw the bits in alongside it, and normalised the whole lot into one boring, uniform shape:

```go
{{ $events = $events | append (dict
  "kind"  "commit"
  "date"  (time.AsTime .commit.author.date)
  "title" (index (split .commit.message "\n") 0)
  "url"   .html_url
  "icon"  "code-commit"
  "colour" "green"
  "data"  .)
}}
```

A commit, a pull request, a bit; they all come out the other side wearing the same hat. A `kind`, a `date`, a `title`, a link, and enough leftover metadata to do something cleverer with later if I feel like it. I made a point of keeping the original object tucked away in `data` too, so future-me isn't boxed in by whatever past-me thought was important today.

## Minding the gaps

With one big sorted pile of events, the rest is just bookkeeping. Walk the articles newest to oldest, and for each one work out the window between it and the article above it; then scoop up every event that falls inside:

```go
{{ $upper := $now }}
{{ if gt $i 0 }}{{ $upper = (index $articles (sub $i 1)).Date }}{{ end }}
{{ range $e := $events }}
  {{ if and ($e.date.After $article.Date) (not ($e.date.After $upper)) }}
    {{ $group = $group | append $e }}
  {{ end }}
{{ end }}
```

The newest article's "window" runs all the way up to _now_, so whatever I've been doing since the last post shows up at the very top. And if a gap is empty - which, let's be honest, plenty of them are - the whole line just quietly doesn't render. No "0 events" guilt trips.

## Click to see the receipts

A summary is nice, but I wanted to be able to actually _see_ the events without leaving the page. Normally that's where a pile of JavaScript shows up. Not today. The humble `<details>` element does the entire job for free:

```html
<details class="group">
  <summary>... 41 changelog events in between ...</summary>
  <ul>
    <!-- one little row per event, complete with icon and link -->
  </ul>
</details>
```

Click the summary, the gap unfolds into a tidy little list of every commit, PR and bit, each linked off to wherever it lives. The disclosure triangle gets binned and replaced with a chevron that flips on open, courtesy of Tailwind's `group-open:` variant. Still no JavaScript. I remain quietly smug about that.

## The lazy answer, for once, is the right one

Then came the responsive question. All these thin dividers and fold-out lists look great on a wide screen and turn into a cramped mess on a phone.

I thought about it for a while, weighed up some clever reflowing, and then did the only sensible thing: hid the whole timeline below the `sm` breakpoint. `hidden sm:block`, done. On a phone you get the clean list of articles, same as ever; on a desktop you get the full story between them. Sometimes the right amount of effort is _none_, and the discipline is in admitting it.

## In the end

What I like about this is that it turns my worst blogging habit - vanishing for months and then resurfacing in a flurry - into something the site can actually narrate. The big rows are the headlines; the quiet lines between them are everything else.

It's also wired up so I can grow it later without unpicking anything. Right now it counts and lists. Tomorrow it could filter, or colour-code, or do something I haven't thought of yet, all off the same pile of events.

For now, though, the gaps have stories in them. Which is a much nicer thing to scroll past than a year of silence.
