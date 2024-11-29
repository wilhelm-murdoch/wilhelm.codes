---
params:
    author: Wilhelm Murdoch
title: Why Can't I Hold All These Slack Emojis?
summary: Or, more stupid tricks while messing with Slack’s API.
draft: false
date: 28 Sep 2023
tags:
  - slack
  - emoji
  - bash
  - api
---
**TL;DR** if you want to skip all this and just get to the good stuff, **[click here](https://github.com/wilhelm-murdoch/slack-emoji-toolkit)**
 to download and run the `slack-emoji-toolkit`.

---

## First Things First

The [last blog post](https://wilhelm.codes/liberating-custom-slack-emojis) I wrote covered how to make a quick escape with your precious hoard of custom Slack emojis. It was fairly well-received, but didn’t quite cover the next step in the migration process; how do you upload your millions of little images to your *new* Slack workspace? 

## Gathering Requirements

Since we’re doing some destructive operations, we’ll need to make sure our Slack user has the appropriate permissions to manage emoji; adding & deleting. This means using a pload.

The JSON response to this request will have the following structure if all goes well:

```json
{ "ok": true }
```

And, if something went wrong:

```json
{ 
	"ok": false,
	"error": "err_code"
}
```

That’s it! Now that we know how to upload from the command line.

## The Implementation

If you’re only uploading a handful of emojis, it might make sense to just do it via Slack’s UI. However, this can get a bit tedious if you have dozens, or even hundreds, to upload.  We can  automate things even further by:

- Gathering all supported images from a specific source directory.
- Iterating through our findings and bulk-upload them all in one go.

So, let’s do just that. But, first, let’s set up some environmental variables so we can easily configure out script:

```bash
: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}
: ${SLACK_DOMAIN:=}
```

Slack only supports `png`, `gif` and `jpg` image formats, so lets see what we can find from our present working directory:

```bash
files=$(find . -iname \*.gif -o -iname \*.png -o -iname \*.png -maxdepth 1)
[[ "${files}" == "" ]] && exit 0
```

Exit if we can’t find any results. No need to continue if we haven’t a thing to upload.

Next, we just iterate through our findings using `read` and some more [Bash parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) to determine what will be the new emoji’s reference name:

```bash
echo "${files}" | while read -r path; do 
  name=$(basename "${path%.*}")
done
```

We can easily parse the response bodies with `jq` for some error checking and we’re good to go:

```bash
if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
  echo "${result}" | jq -r ".error"
  exit 1
fi
```

We now have all the information we need to upload each file in bulk. Put it all together and you’ve got a working bulk emoji uploader:

```bash
#!/usr/bin/env bash

set -eo pipefail
                                                                                                                                                                      ookie: d=${SLACK_COOKIE};" \
      -F "token=${SLACK_TOKEN}" \
      -F "name=${name}" \
      -F mode=data \
      -F "image=@${path}" 
  )

  if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
    echo "${result}" | jq -r ".error"
    exit 1
  fi

  echo "uploaded :${name}:!"
done
```

There you go! To test it out yourself, save this as an executable script and make sure your present working directory has some supported images in it. Pass through the your environmental variables when executing and you’re off:

```bash
$ SLACK_DOMAIN=*** SLACK_COOKIE=*** SLACK_TOKEN=*** ./upload.sh
uploaded :stonks:!
uploaded :boop:!
uploaded :derp:!
uploaded :booyah:!
uploaded :merp-flakes:!
```

Nice! 😊

## Once Again, Something Better!

While perfectly functional                                                                                                                                                                     , there’s not a lot of flexibility. No error checking, filtering or confirmation checks. If you’re looking for something a bit more fleshed out, look no further!

[https://github.com/wilhelm-murdoch/slack-emoji-toolkit](https://github.com/wilhelm-murdoch/slack-emoji-toolkit)

## The Final Piece ...

So far, we’ve gone over how to download and upload large sets of emoji, but what if you want to nuke them from orbit? The final article in this series will cover how to bulk delete while using advanced filters to pin-point specific sets of emoji you wish to remove.

Hope you’ve learned something useful!