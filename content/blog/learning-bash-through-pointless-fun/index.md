---
title: Learning Bash Through <span>Pointless Fun</span>
title_safe: Learning Bash Through Pointless Fun
highlight: purple
pack: duotone
icon: mushroom
comments: true
date: 2022-10-05
category: Development
tags:
  - bash
---
Responding to company chat messages in a mocking and sarcastic tone is one of my favourite past times. Classic engineer snark as it were. We’re all in on the joke. However, the artful nuances of snark via online chat tend to get confused by others; Did they *mean* to sound sarcastic?

<!--more-->

Let’s leave out all doubt regarding our god-tier levels of snarkiness. 

Today, we’re going to write a laughably-simple Bash script that lets our coworkers know *[exactly](https://knowyourmeme.com/memes/mocking-spongebob)* what we think. Along the way, you’ll learn a little bit more about Bash such as:

1. Setting some default flags.
2. Reading text from `stdin`.
3. Parameter expansion.
4. Looping through each character of a string.
5. Creating random numbers.
6. Swapping character types using the `tr` command.
7. And, finally, making your long-suffering coworkers’ eyes roll.

---

## Here We Go!

First, I’m going to just paste the entire script here and then we’ll go through all the important bits line-by-line:
```bash
#!/usr/bin/env bash

set -eo pipefail

read text

for (( i=0; i < "${#text}"; i++ )); do
  if [[ $(( "${RANDOM}" % 2 )) -eq 0 ]]; then
    echo -n "${text:${i}:1}" | tr '[:lower:]' '[:upper:]'
  else
    echo -n "${text:${i}:1}" | tr '[:upper:]' '[:lower:]'
  fi
done

echo
```
Alright, let’s take it from the top. All Bash scripts should start with a [“shebang line”](https://en.wikipedia.org/wiki/Shebang_(Unix)). This tells your terminal which environments and runtimes your script should run under. There are more traditional versions of this — `#!/bin/bash`, for instance — but, our way is considered to be the most portable overall.
```bash
#!/usr/bin/env bash
```
Next, we setup some environmental flags. I use at least the following for *all* of my personal scripts:
```bash
set -eo pipefail
```
Here is what they do:

1. `set -e`: Instructs Bash to immediately exit if any command has a non-zero exit status. This is how it works in most languages, but with Bash, it just keeps on trying to execute subsequent commands. This is generally acceptable on the command line, but not in a script. If we encounter an error, we want to exit immediately.
2. `set -o pipefail`: This tells Bash *not* to mask errors that may appear in a pipeline of commands. We want any failed command’s exit code in a pipeline to bubble up to the script itself and then exit with that code.

Speaking of pipelines, we want to be able to pipe text to this script so we can do something like the following:
```bash
echo "wilhelm, i asked you to patch the server." | ./spongebob
wiLHELm, I AsKEd yOu TO PatCh The seRvEr.
```
Let's halt the script and wait for user input and then assign that input to variable `text`:
```bash
read text
```
Now that we have some text, we need to start randomly-swapping between upper and lower case characters. In order to do that, we need to know the number of characters in our string so we can build a nice loop:
```bash
for (( i=0; i < "${#text}"; i++ )); do
  # ... sweet code goes here 
done
```
We could do something in a sub-shell here like `$(echo "${text}" | wc -c)` to get the character count, but why do that when we could get the same result with `"${#text}"`. This lovely bit of [“shell parameter expansion”](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) helps us avoid sub-commands and sub-shells.

Next, we want to be able to randomly swap the capitalisation of each character in the string to get the appropriate effect. A character is either upper- or lower-case, so minimum we need only to swap randomly between 2 values; `0` and `1`. We can get this effect in Bash by using the internal [`${RANDOM}` function](https://tldp.org/LDP/abs/html/randomvar.html) like so with the [modulo](https://tldp.org/LDP/abs/html/ops.html) ( or “mod” ) operator:
```bash
if [[ $(( "${RANDOM}" % 2 )) -eq 0 ]]; then
  # ... do something
else
  # ... do the opposite
fi
```
We’re now at the point where we want to modify the character associated with the `for` loop’s current iteration, but how do we get it from the `text` variable? Once again we use some parameter expansion in the form of `${text:offset:length}`. We have the value for “offset” already; it’s `${i}`. We only want a single character returned, so we use `1` for “length”.
```bash
echo -n "${text:${i}:1}"
```
This spits out the current character for each iteration of our loop. The `-n` in the `echo` statement simply stops Bash from adding a newline to the end of the result. Otherwise, you’d get a line per character as output.  

Finally, we want to do case swapping. For this, we pipe the output of the above `echo` command into the `tr` command. Within the above `if` statement, if our random number equals `0`, let’s swap a *lowercase* `[:lower:]` character with an *uppercase* `[:upper:]`:
```bash
echo -n "${text:${i}:1}" | tr '[:lower:]' '[:upper:]'
```
And, then, we do the opposite for any other result:
```bash
echo -n "${text:${i}:1}" | tr '[:upper:]' '[:lower:]'
```
You’ll notice a final `echo` command at the bottom of the script. Thanks to the final `echo -n ...` command from the previous `for` loop, you may find your results prepended to your command prompt. This ensures a newline makes it to the end of your 🧽 output.
## Testing Time
Save the script as `spongebob` and make it executable with `chmod a+x spongebob`. That should be it! Here are a few of my results:
```bash
$ echo "abandon all hope, ye who enter here." | ./spongebob
abaNDON ALl Hope, yE wHO EnTer heRE.
$ echo "Wilhelm, that last deployment failed. Could you roll it back, please?" | ./spongebob
WilhelM, THAT LASt dEployMeNT fAILED. coUlD YOu RoLL It BaCk, PlEaSE?
$ echo "Wilhelm, I am your manager. Please, stop mocking me." | ./spongebob
wIlHElM, i aM yOUr MANagER. PlEasE, sTOP mOCKINg mE.
$ echo "Wilhelm, should we use Kubernetes for this?" | ./spongebob
WilHELM, should We Use KuBerNeTEs for THiS?
```
## In Conclusion…
Ok, obviously this was all a clever ploy to get you to learn a few more Bash things. Definitely do *not* use this new knowledge to frustrate and annoy your coworkers. Please, be considerate of other people’s mental well being. 
I mean, what I _meant_ to say was:

{{< blockquote "DefInIteLY dO Not UsE THis nEw knoWleDGE to FRUStRATe aND aNnOY YoUR cOWorkers. pLeAsE, be ConsiDeRAtE oF oThEr peOPle’s mEnTal well beiNG." "Me." >}}

There are any number of ways you could change this script. Instead of liberal use of `echo`, you could just build a string assigned to a variable and spit that out at the end. Instead of using `else` you could use `continue` to skip the final `if` fallback. Try a few and see what changes.

For the purposes of this article I felt the above sequence of commands was clear enough for most people to follow along.

I hope you learned something!