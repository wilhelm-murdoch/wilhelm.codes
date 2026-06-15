---
title: A <span>Changelog</span> That Builds <span>Itself</span>
title_safe: A Changelog That Builds Itself
highlight: slate
pack: duotone
icon: clock-rotate-left
draft: false
toc: true
date: 2026-06-14
category: Development
tags:
  - hugo
  - github
  - api
---
This site has a [changelog](https://wilhelm.codes/changelog/) page. It's not one I write by hand as it builds itself from my activity on GitHub every time the site deploys. I think it's a neat little trick. It also spent a solid afternoon teaching me that "works on my machine" and "works in production" are, once again, two very different things.

<!--more-->

If you use Github, you know it quietly records nearly everything you do as a stream of [events](https://docs.github.com/en/rest/activity/events). Better still, for a public repository, that stream is available over a public, unauthenticated API endpoint through a simple `GET` request.

So the plan more or less writes itself. We fetch the stream at build time, group the events by day, and let Hugo render them. Hugo even has a tidy [little function](https://gohugo.io/functions/resources/getremote/) for pulling in remote resources that works like so:

```go
{{ $url := "https://api.github.com/repos/wilhelm-murdoch/wilhelm.codes/events" }}
{{ with try (resources.GetRemote $url) }}
  {{ $events := .Value | transform.Unmarshal }}
  {{/* ...range over them and render... */}}
{{ end }}
```

Because this all happens at _build_ time, the visitor never waits on GitHub. By the time the page reaches a browser it's just static HTML like everything else. The changelog is always current as of the last deploy, and I never have to think about it.

That's the part that worked. Now for the parts that didn't.

## ... Then, production happened.

I've been more or less absent from this site for close to a year, but this past week I've decided to breathe a bit more life into it. I made a few changes to [modernise](https://wilhelm.codes/blog/some-long-overdue-housekeeping/) the stack, pushed my changes up and waited on Cloudflare to do its thing and...

```text
ERROR error building site: ... error calling GetRemote:
failed to fetch remote resource from 'https://api.github.com/...': Forbidden
```

I was greeted with a `403`. Except... I could paste that exact URL into my browser and get a perfectly happy wall of JSON back. So what gives?

Rate limiting, that's what. GitHub's unauthenticated API is capped at **60 requests per hour, per IP address**. My build doesn't run on _my_ IP. It runs on a shared build machine alongside who-knows-how-many other people's deploys, all of them hammering GitHub from the same handful of addresses. By the time my build rolled around, that bucket was bone dry. 

Honestly, a `429` instead here would have saved me a bit of investigating, but I digress.

The solution was to created a properly scoped Github PAT. Using an authenticated request gets **5000 requests per hour**, so I went about implementing support and handed it to the build as an environment variable, and taught the template to send it along:

```go
{{ $opts := dict }}
{{ with os.Getenv "HUGO_GITHUB_TOKEN" }}
  {{ $opts = dict "headers" (dict "Authorization" (printf "Bearer %s" .)) }}
{{ end }}
{{ $remote := try (resources.GetRemote $url $opts) }}
```

It's worth noting that Hugo won't read just _any_ environment variable. Its security policy only lets `os.Getenv` see variables prefixed with `HUGO_`. Name your token `GITHUB_TOKEN` and you'll get a confusing fistful of nothing; name it `HUGO_GITHUB_TOKEN` and it works. Ask me how I know.
## Hark! Another Footgun!

With the token in place, the fetch succeeded and the build promptly fell over somewhere new:

```text
error calling len: reflect: call of reflect.Value.Type on zero Value
```

This never showed up locally, which tells me I should do myself a favour and do a quick local _production_ deployment as a preflight _before_ I push to Github and trigger an automated build. Originally, in development I rendered the changelog from a single large fixture file stored locally on disk. This was before I implemented the PAT so I wouldn't rate limit myself locally when testing. The live stream, however, contains event shapes my fixture simply didn't. One of them was a `push` event carrying no `commits` at all, and my template did this without a second thought:

```go
{{ if eq (len .payload.commits) 1 }}
```

Call `len` on something that exists and isn't there and Go has a small panic about it. The fix is boring; stop assuming the field is there. Hugo's `with` only enters the block when its argument is actually... something:

```go
{{ with .payload.commits }}
  {{ if eq (len .) 1 }}
    {{/* the one-commit case */}}
  {{ else }}
    {{/* the many-commits case */}}
  {{ end }}
{{ end }}
```

Since I've implemented PAT support, I'm not so concerned about being rate-limited during local development, though I now use the fixtures as a fallback if any request fails. This allows me to keep working locally without disruption.
## Don't let someone else's server break your build.

The real personal lesson is the moment your build depends on a third party at build time, you've effectively ceded control of your deployment to them. GitHub rate-limits you, or has a wobble, or changes a payload shape, and suddenly your perfectly good site won't deploy and you'll have a hard time.

So the changelog no longer treats GitHub as load-bearing. If the fetch fails for _any_ reason it shrugs, logs a warning, and falls back to that saved fixture instead of taking the whole deploy down with it:

```go
{{ $remote := try (resources.GetRemote $url $opts) }}
{{ with $remote.Err }}
  {{ warnf "changelog: GitHub fetch failed (%s); using the fixture" . }}
  {{ $response = os.ReadFile "static/github.json" | transform.Unmarshal }}
{{ else with $remote.Value }}
  {{ $response = . | transform.Unmarshal }}
{{ end }}
```

The `try` keyword is the hero here as it catches the error that `GetRemote` would otherwise throw and hands it back to me as a value I can actually _do_ something with, rather than a smoking crater where my build used to be. Worst case, the page shows slightly stale history. That's a trade I'll take every single time over a red deploy or disruption to my local flow.

## In conclusion...

Ironically, this is something I've dealt with quite frequently at work. Github & AWS API rate limits ( yes, we frequently got rate limited by the VPC API of all things ), [Yarn](https://yarnpkg.com/) will throw a `5xx` and even Sentry will chimp out during source map uploads. All of these things can disrupt deployments.

The point is just assume these things will happen and then build defensively around them. I, ehhhh, just need to apply this wisdom to my personal stuff. 😅

Anyway, the changelog still builds itself. It just doesn't get to take the rest of the site down with it anymore.
