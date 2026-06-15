---
title: Breaking Up <span>Log</span> <span>Output</span> Using Bash
title_safe: Breaking Up Log Output Using Bash
highlight: slate
pack: duotone
icon: code
draft: false
toc: false
date: 2025-01-09
category: Development
tags:
  - bash
  - snippets
  - tutorials
---
I tend to look at a _lot_ of log output throughout the day as part of my role as platform engineer. This obviously extends to any backend, or ops-related, role. One little niggle that always gets to me is tailing output where the lines only change when something interesting happens.

<!--more-->

I have no idea if time is actually passing. Obviously, I can eyeball timestamps if available, but there are times when so many lines zip through the buffer that it's easy to lose track or even go cross-eyed.

It can be tricky to notice that lines are still being tailed if the output doesn't drastically change in some meaningful or noticeable way. Something I like to is intercept each line and then output some kind of divider whenever `n` lines have been added to the buffer.

It's as simple as:

```bash
#!/usr/bin/env bash

lines=0
while IFS= read -r line; do
	echo "${line}"
	((lines++))

	if ((lines % 5 == 0)); then
		echo "----------"
	fi
done
```

Effectively, all this does is:
1. Intercept each line of output being piped into the script. 
2. Keep a running tally of lines we've intercepted so far; `$lines++`.
3. If the current tally is divisible by `n`, or in this case `5`, spit out an additional line containing a divider.
4. Keep doing this forever until the process is terminated.

If you were to save this in a file named as `divider.sh` and set it to execute with something like `chmod a+x` you could test it by doing something like: 

```bash
$ while true; do echo "emitting a noop"; sleep 1; done | ./divider.sh
```

And you'll see something like the following:
```text
emitting a noop
emitting a noop
emitting a noop
emitting a noop
emitting a noop
----------
emitting a noop
emitting a noop
emitting a noop
emitting a noop
emitting a noop
----------
```

This is pretty dumb, but now you can see that output is still being placed in your terminal buffer. I've set it to every `5` lines, but you can update the script to make that configurable. You could also play a sound when the script places a divider in the buffer using something like `tput bel`.

Anyway... Enjoy.

