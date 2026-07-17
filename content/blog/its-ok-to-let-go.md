---
title: It's OK to Let <span>Go</span>
title_safe: It's OK to Let Go
highlight: rose
pack: duotone
icon: heart-crack
toc: false
date: 2026-07-17
category: Projects
tags:
  - go
  - open-source
---
So, I'm a sucker for wordplay and puns. Anyway...

There's a line in my shell history that goes back to 2022: `go get github.com/wilhelm-murdoch/go-collection`. For years it was the first dependency into almost every Go project I tinkered with, sometimes before I'd even give the idea a solid shape. I'd open Neovim, initialise a module and then my little collection library got pulled in. Just like muscle memory.


Today I'm archiving it. Not because it broke and not because I got bored of it, but because the Go standard library quietly walked up and did its job better than it ever could. This post is part explanation and part eulogy, because I think we're generally quite bad at ending software on purpose and it's worth practising in public.

## Why even write it in the first place?

Waaaay back in 2022 Go 1.18 had just shipped generics after roughly a decade of the community asking, arguing and writing increasingly unhinged `interface{}` workarounds. I wanted to actually *learn* the new type parameter machinery rather than just read about it and I was also deeply tired of writing the same `for` loop to check whether a slice contained a thing for the hundredth time.

So [go-collection](https://github.com/wilhelm-murdoch/go-collection) happened. A single generic `Collection[T]` type wrapping a slice, with all the conveniences I kept reaching for: `Contains`, `Find`, `Filter`, `Map`, `Sort`, `Batch`, `Push`, `Pop` and a few dozen friends. All chainable, fluent, tested and small.

{{< blockquote "There are far more comprehensive modules out there, but this one works quite well for my purposes." "me, in the README, setting expectations appropriately for once" >}}

That sentence was doing more work than I realised at the time. It wasn't trying to compete with the big functional-utility libraries. It was scratching a personal itch and for a few years it scratched it well. Then Go's standard library grew slurped most of it up.

## Taking a trip to the morgue.

Cause of death is easy to establish here, because it happened in three well-documented releases. Go 1.21 shipped the `slices` package. Go 1.22 and 1.23 finished the job. Let's walk through it, method by method, like the nerds we are.

### Does it have the thing?

The bread and butter. Probably eighty percent of my actual usage of this library was some flavour of "is this thing in there?":

```go
fruits := collection.New("apple", "orange", "strawberry")

fruits.Contains("orange") // true

fruits.FindIndex(func(i int, item string) bool {
	return strings.HasPrefix(item, "str")
}) // 2
```

As of Go 1.21, the standard library does both on a plain slice with no wrapper type in sight:

```go
fruits := []string{"apple", "orange", "strawberry"}

slices.Contains(fruits, "orange") // true

slices.IndexFunc(fruits, func(item string) bool {
	return strings.HasPrefix(item, "str")
}) // 2
```

No `New`, no `.Items()` to unwrap at the end when some other API wants a real slice. It's just my function with better ergonomics and a compiler team maintaining it. I'm fine with this.

### Sorting, where I don't even get to feel bitter.

Here's my `Sort`. I want you to look at what using it actually required:

```go
numbers := collection.New(3, 1, 4, 1, 5)

numbers.Sort(func(i, j int) bool {
	left, _ := numbers.At(i)
	right, _ := numbers.At(j)
	return left < right
})
```

Index-based comparators, so you had to reach *back into the collection you were currently sorting* to get at the values. I inherited that design from the old `sort.Slice` idiom and it was clunky then too. The modern equivalent:

```go
numbers := []int{3, 1, 4, 1, 5}
slices.Sort(numbers)
```

And when you're sorting something with actual structure, `SortFunc` hands you the two elements directly, with `cmp.Compare` doing the boring part:

```go
slices.SortFunc(people, func(a, b Person) int {
	return cmp.Compare(a.Age, b.Age)
})
```

This isn't a case of the standard library catching up to my library. It blew my version right out of the water.

### The killing blow came with iterators.

Go 1.22 added `slices.Concat`, which retired my `Concat`. Fine, that one was three lines anyway. But Go 1.23 shipped range-over-function iterators and with them `slices.Chunk`, and that's the release where I stopped pretending this was still a contest. `Batch` was one of the few methods I was genuinely proud of:

```go
records.Batch(func(batch, index int, item Record) {
	// process item as part of batch N
}, 100)
```

Now it's a language feature wearing a standard library hat:

```go
for chunk := range slices.Chunk(records, 100) {
	// chunk is a []Record of up to 100 items
}
```

A real `for` loop. You can `break` out of it, `continue` past things and return early. My callback-based version couldn't do any of that without contorting itself. The trouble is that a wrapper library can only ever be as expressive as the language it wraps and the language just grew.

### The stuff that never needed a library.

An honest confession while we're standing over the body: a decent chunk of the API never deserved to exist in the first place. `Push`, `Pop`, `Shift`, `Unshift`. I wrote JavaScript for years before Go was ever a public thing and apparently nobody walks away from that unscathed.

```go
c.Push("e")         // s = append(s, "e")
item, ok := c.Pop() // item = s[len(s)-1]; s = s[:len(s)-1]
```

The comments on the right are the entire implementation. Idiomatic Go slice handling was already good at this in 2012. Those methods existed because my fingers missed `Array.prototype`, not because Go was missing anything.

### The "survivors", if you could even call them that.

Here's the wrinkle that makes this more interesting than a straight obituary. `Map`, `Filter`, `Reduce`, `Some`, `None`; the functional stalwarts *still* aren't in the standard library, all these years later. On paper, that's the corner of the market my little module could have retired to. A niche! Sustained relevance!

Except, no. First, because my `Map` had a secret shame:

```go
func (c *Collection[T]) Map(f func(int, T) T) (out Collection[T])
```

See it? `T` in, `T` out. Go methods can't introduce new type parameters, so a method-based `Map` can never change the element type. Strings to strings, ints to ints. A `Map` that can only map onto itself is a `Map` in vibes only; the moment you want lengths of strings you're back to writing a loop anyway.

And second, more fundamentally: the Go community collectively shrugged and decided the loop was fine. The proposal discussions happened, the experiments ran and the ecosystem largely settled on this:

```go
names := make([]string, 0, len(ducks))
for _, duck := range ducks {
	names = append(names, strings.ToUpper(duck))
}
```

Four lines. Obvious to anyone who's read any Go at all, no import, nothing to learn, nothing to maintain and debugger-friendly. Even where `go-collection` wasn't superseded, it turned out to be unnecessary, which is somehow a more thorough defeat.

## Software is a tool, not a legacy.

So that's the technical half. Here's the part I actually wanted to write about.

We don't really have a culture of *finishing* software. A project is either "actively maintained" or it's "abandoned", with all the guilt that word drags behind it. Issues accumulate, badges rot and the README slowly becomes a lie because nobody wants to be the person who admits the thing is done, or no longer necessary. I've had this module sitting in that limbo for a while now, still getting pulled into new projects out of habit while a strictly better replacement sat in the standard library the whole time.

But software isn't a legacy; it's a tool. Tools serve a purpose. This one's purpose was to teach me generics in their first year of existence and to spare me a few thousand `for` loops while the language sorted itself out. Purpose served on both counts. And of all the ways for a library to die, being absorbed by the standard library is the best one available. It means the gap you filled was real and now it's just *gone*, fixed at the correct layer, for everyone and forever. That's not a failure state. That's the mission succeeding so hard the mission ceases to exist.

Keeping it alive from here would mean maintaining a slightly worse, slightly slower, personally-branded copy of `slices` out of pure sentiment. Nobody needs that, least of all me. I'm busy enough and would much rather move on to newer, more interesting things.

## The practical bits.

So today, the repo gets the full send-off:

* A deprecation notice at the top of the README, pointing anyone who lands there at the [slices](https://pkg.go.dev/slices) package and at this post.
* The repository gets [archived](https://github.com/wilhelm-murdoch/go-collection) on GitHub. Read-only, clearly signposted and locked in eternal statis.

If you're one of the however-many people with this module in a `go.mod` somewhere nothing breaks. The Go module proxy caches published versions more or less permanently, so `v1.0.11` will keep resolving long after we're all dust. Archiving just makes the end of our relationship official rather than leaving it implied.

If you've got a little module of your own in the same situation that has been superseded, purpose spent, kept alive out of habit, then consider this your permission slip. Write the notice, hit archive and go build that next thing. An honest ending is a kindness to your users and to yourself. It's OK to let go.

## In closing ...

Thanks, little buddy. You were there before the ecosystem knew what generics were supposed to look like, you appeared in more of my `go.mod` files than any dependency I didn't write, and you were, right to the end, exactly as comprehensive as I needed you to be.

`go get` in peace.
