---
title: Why I built Plant Smart
draft: false
date: 2023-01-08
category: Thoughts & Musings
tags:
  - svelte
  - projects
---
Simply put, I love plants and I love animals. I can't count how many times I've been to a plant nursery and had to stop and do a Google search to see if something was safe enough to bring home and keep around our little Pandora, or 🐼 for short.

<!--more-->
### It's as simple as that?

That was the idea, at least. I just wanted a single place that had all the information I needed so I could make informed purchasing decisions. I also figured I couldn't possibly be the only person who has this problem. So, I set off to make this project during the holiday break of 2022.

However, I didn't want to make it *too* easy for myself...

### A challenge!

I work as a weird combination of [SRE](https://en.wikipedia.org/wiki/Site_reliability_engineering) and [DevOps engineer](https://en.wikipedia.org/wiki/DevOps). I have plenty of smarts when it comes to the technical side of hosting and running things, but it's been years since I've done any front-end work. Career-wise, I need to be able to speak the same language as the teams I have to support. So, understanding how far behind that portion of my skillset had become, I thought this would be the perfect opportunity to brush up.

#### The Requirements:

* Must keep operational costs as close to zero as possible. The only money I've put down on this so far is the $20 AUD to purchase the domain name.
* Must be hosted on [Cloudflare Pages](https://pages.cloudflare.com/). I could've chosen [Github Pages](https://pages.github.com/) to keep everything in one place, but automated Cloudflare builds & deployments work out of the box with minimal configuration. Besides, I've already worked with the latter and I wanted the challenge of trying something new.
* Must be completely static. There should be no server-side rendering, processing or other explicit backend dependencies to manage. For this, I use the pre-rendering functionality that comes packaged with [SvelteKit](https://kit.svelte.dev/). I've been working with this for only a few weeks now and I'm a full convert.
* All data must be served statically as well. The entirety of the data set is contained within a single JSON file, which you can view at [/plants.json](https://plantsm.art/plants.json). This is the source of truth for all derivative data sets and lookup tables used on this site. It's effectively what I call a "dumb API". Check out the [API documentation](http://localhost:5173/api) if you'd like to know more about it.
* Must use [SvelteKit](https://kit.svelte.dev/), [TypeScript](https://www.typescriptlang.org/), [TailwindCSS](https://tailwindcss.com/) and [Vite](https://vitejs.dev/). I had zero working knowledge of any of these and my frontend peers can't seem to shut up about them. So... why not?
* Must be *fast*. Everything is static, compressed, cached and sitting behind a world-class CDN. I've worked in a network performance and load testing SaaS for close to 5 years now. I wouldn't be able to look myself in the mirror if I couldn't easily do this one. 😅
* Must be open-source and community-driven. At one point, I would like to take the hands off the wheel and see if other interested parties would like to get involved and help out with managing datasets and fixing bugs. GitHub allows for pretty much all of this. Check how to [contribute](http://plantsm.art/contribute) or see the [latest contributions](http://plantsm.art/updates).

So far, it's going quite well. I haven't had any issues with meeting any of these self-imposed development constraints.

#### Any Caveats?

Definitely. The most obvious one would be image storage which has a direct effect on not only repository size — which currently clocks in at over 1.5GB — but, also build and deployment speeds. I could shell out $5 - $10 for object storage and image processing, but that would go against the first constraint. For now, image data will live in the GitHub repository as a perfectly reasonable compromise.

### Where did you source all this data?

There are quite a few sources I've collated from, but these are the main ones.

1. [iNaturalist](https://www.inaturalist.org/) is the best source of high-quality, community-driven creative commons license photography. All images have been sourced from this site along with licensing and attribution data.
2. [ASPCA](https://www.aspca.org/) was used to initially prime the first dataset. This is also where I sourced most of the common name and symptom data.
3. [Wikipedia](https://en.wikipedia.org/wiki/Plant) is the best source of scientific classification data out there.

All of this disparate data was collated and munged together by several processing scripts written in [Go](https://go.dev/) as [Magefiles](https://magefile.org/). It got me about 95% there, but it still needs quite a bit of handraulic finessing.

### Where to go from here?

I think I've met most, if not all, of my requirements. The datasets for the project still need a lot of love and I plan on supporting listings for a variety of other pet species. I already have the data; just need to go through it with a fine-toothed comb. Not to mention responsiveness for smaller screens needs a solid amount of work.

I'm having loads of fun at the moment learning new things. I hope I can keep doing this for a while longer. However, I do have other things planned for the future and will be using what I've learned here as a kind of launching pad.

I sincerely hope you find [Plant Smart](https://plantsm.art) as useful as I had fun making it.