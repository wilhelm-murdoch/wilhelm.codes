---
title: Printing <span>Ordinal</span> <span>Numbers</span> in Hugo
title_safe: Printing Ordinal Numbers in Hugo
highlight: blue
pack: duotone
icon: code
draft: false
toc: false
date: 2025-01-17
category: Development
tags:
  - hugo
  - snippets
credit: Logo by <a href="https://gohugo.io//">Hugo</a>
---
I've been having such a good time building up this website and [Hugo](https://gohugo.io) has been incredibly fun – and relatively simple – to work with. Though, from time to time, I find myself scratching my head at the absence of a few bits and bobs.

<!--more-->

In this case, what I really needed was a simple way to assign an ordinal to an arbitrary number. For instance, if I have a value of `2`, I might want to tack on a `nd` as a suffix, eg; `1st`, `540th` or  `9001st` and so on.

Specifically, I'd like to use this with dates, but from what I can tell, Hugo doesn't support this out-of-the-box. Luckily, the framework gives you a few options to extend its functionality. 
## Shortcodes
With [shortcodes](https://gohugo.io/content-management/shortcodes/) you can create snippets that act as functions which can be used to dynamically inject HTML – among other things – directly into your rendered markdown. You can even pass both named and positional arguments through the shortcode to modify their behaviour as needed.

For instance, I have [this custom](https://github.com/wilhelm-murdoch/wilhelm.codes/blob/main/layouts/shortcodes/blockquote.html) shortcode used for displaying styled block quotes like:

{{< blockquote "Out of all the things I have lost, I miss my mind the most." "Mark Twain" >}}

I also have [this one](https://github.com/wilhelm-murdoch/wilhelm.codes/blob/main/layouts/shortcodes/callouts.html) that let's me print out some fancy callouts:

{{< callout warning "You should probably pay attention." >}}

{{< callout info "This may be of some small interest." >}}

{{< callout error "Yeah, so, we're all gonna die." >}}

Hugo ships with a [default set](https://gohugo.io/content-management/shortcodes/#embedded-shortcodes) of shortcodes covering a variety of additional kinds of embeddings. 

Unfortunately, for my purposes, I'm not planning on using dynamic numeric ordinals in my markdown files. I need this to work with templates and for that, we use...

{{< callout notice "... that while you cannot use partials directly in your markdown files, a shortcode _could_ reference a partial indirectly." >}}
## Partials
Unlike shortcodes, [partials]() are small re-usable HTML components that are typically used to keep code duplication down. They are effectively context-aware templates that can accept arbitrary data which can be used in generating desired output.

[Here](https://github.com/wilhelm-murdoch/wilhelm.codes/blob/main/layouts/partials/views/small.html) is a small example of how I use partials for this blog. It's a small data card component you might find scattered throughout the site. Partials let you quickly change a UI component in one place while having it propagate everywhere else.

For the purpose of this article, they can also be used to create custom template "functions" like this which solves my very specific problem:
```html
{{- if and ( eq ( mod . 10 ) 1 ) ( ne ( mod . 100 ) 11 ) -}}
    st
{{ else if and ( eq ( mod . 10 ) 2 ) ( ne ( mod . 100 ) 12 ) -}}
    nd
{{ else if and ( eq ( mod . 10 ) 3 ) ( ne ( mod . 100 ) 13 ) -}}
    rd
{{ else -}}
    th
{{ end -}}
```

This may look a bit unreadable to people who aren't super-familiar with Hugo's template functionality, but it effectively resolves to:
```javascript
const number = 10
let ordinal = "th"
if (number % 10 == 1 && number % 100 != 11) {
	ordinal = "st"
} else if (number % 10 == 2 && number % 100 != 12) {
	ordinal = "nd"
} else if (number % 10 == 3 && number % 100 != 13) {
	ordinal = "rd"
}

console.log(number + ordinal)

// prints 10th
```

Anyways, I have this saved as `partials/functions/ordinal.html` and can reference this in any of my templates like so:
```html
{{ partial "functions/ordinal.html" $number }}
```

Where `$number` is any arbitrary number I'd like an ordinal suffix for. Take the following example template which generates a random range of numbers and prints them out using my ordinal partial:
```html
{{ range seq 10 }}
  {{.}}{{ partial "functions/ordinal.html" . }} 
{{ end }}
```
Which generates:
```text
1st 2nd 3rd 4th 5th 6th 7th 8th 9th 10th
```

Ground-breaking work! I can finally use ordinals in dates. Not exactly something I expected to write an article about, but here we are. 🤷