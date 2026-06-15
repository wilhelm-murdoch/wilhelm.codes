---
title: A <span>Year</span> in <span>Circles</span>
title_safe: A Year in Circles
highlight: emerald
pack: duotone
icon: calendar-week
draft: false
toc: true
date: 2026-06-15
category: Development
tags:
  - hugo
  - css
  - tailwindcss
---
If you scroll up to the top of the home page, you'll find a pair of little rows of green circles. It's my own dumbed-down take on GitHub's contribution graph. Effectively, it's the same idea, except instead of a year of days it's a year of _weeks_. Two rows of twenty-six with one circle per week, with each circle coloured a deeper shade of green the busier that week was.

<!--more-->

I wanted something that summed up "Has Wilhelm actually been doing anything lately?" at a glance, without the density of 365 tiny day cells. Fifty-two circles felt about right. Coarse enough to read across the room, fine enough to still give a picture.

## What counts as a "week's worth of activity"?

The short answer is _everything_. The [changelog](https://wilhelm.codes/blog/a-changelog-that-builds-itself/) already pulls my GitHub activity at build time, so I reuse that exact same data. Then, I throw in the things GitHub doesn't know about; every type of blog post on this site.

Because the changelog fetching already lives in a tidy little partial, sourcing the everything is just a matter of asking for each one and collecting all the publish dates:

```go
{{ $dates := slice }}
{{ range partial "changelog/fetch.html" (dict "url" $commitsUrl "fixture" $fixture) }}
  {{ $dates = $dates | append (time.AsTime .commit.author.date) }}
{{ end }}
{{ range where site.RegularPages "Section" "blog" }}
  {{ $dates = $dates | append .Date }}
{{ end }}
```

Nothing crazy going on here. I'm just creating a big list of timestamps from wherever I happen to leave a trail.

## Sorting a pile of dates into weekly buckets.

Each of these dates now need to land in one of fifty-two buckets. Working out which week a given date belongs to is just some boring epoch arithmetic; how many whole weeks ago was it?

```go
{{ $ago := int (div (sub now.Unix $d.Unix) 604800) }}
{{ if and (ge $ago 0) (lt $ago 52) }}
  {{ $counts.Add (printf "%d" (sub 51 $ago)) 1 }}
{{ end }}
```

That `604800` is the number of seconds in a week. And yes, I did have to look that up. Anything older than fifty-two weeks just falls off the back and is quietly ignored.

## Painting the circles.

My favourite part of this is there's no JS involved. The whole thing is a CSS grid of twenty-six columns, and because each circle is `aspect-square`, the rows just work and the circles stretch to fill whatever container I drop the partial into:

```html
<div class="grid grid-cols-26 gap-1.5">
  <!-- 52 of these green little dudes -->
  <div class="aspect-square rounded-full bg-emerald-400"></div>
</div>
```

Working out the shade was the fiddly bit. My first attempt simply scaled each week against the busiest one, which sounds sensible right up until you remember my data is basically one enormous week and a whole lot of flat nothing. That single monster week hogged the dark end and squashed everything else into the same pale green. So I did what GitHub does and reached for [quartiles](https://en.wikipedia.org/wiki/Quartile) instead. You rank the weeks that actually saw some activity, chop them into four groups, and let a week's colour come from where it lands in the pack rather than from some absolute number. Empty weeks stay a faint `emerald-100`; the rest climb through four steps of green up to `emerald-600`. The part I like is that it's relative to _me_; a busy week is only busy compared to my _other_ weeks.

The little tooltip that pops up when you hover over a circle is also pure CSS. A `group` on the wrapper, a `group-hover:opacity-100` on the popup, a `transition` is all I needed. Each circle now gives a little `scale` on hover too, just because it's nice.

## The graph's painful honesty.

Now on to the more embarrassing part. When I first rendered it with real data, I got _one_ lonely green circle and fifty-one empty ones. Surely, you've noticed it on the front page.

At the time I assumed I'd done something wrong. But, to my great shame, I hadn't. Turns out that when you vanish from your own website for close to 18 months and then cram an [entire renovation](https://wilhelm.codes/blog/some-long-overdue-housekeeping/) into a single week, the graph renders exactly that. A long, flat, pale stretch of road ending with one pathetic little green emerald.

There's an extra little indignity baked into the quartiles, too. They need a _spread_ to rank against, and with exactly one active week there's nothing to compare it to. So my massive renovation-cramming week doesn't even get to be properly dark green. It turns up as a polite, middling shade. 

I effectively built a little a tool whose entire job is to hold up a mirror to my own lack of consistency and commitment. Very cool! 😬👌

## Drop it in anywhere.

This whole thing is a single self-contained partial. It was waaaay easier to build out than I had originally thought. And, thanks to Tailwind I didn't even have to fall back on any JS! I count that as a bonus.

For the moment, it'll live on the home page, but I can now just place this anywhere in my Hugo site and it'll work:

```go
{{ partial "activity-graph.html" . }}
```

I might even build it out a bit more to support different colour schemes or specificy types of targeted site content. So, the more I write, the more those circles fill in. 

Consider yourself warned, _me_.
