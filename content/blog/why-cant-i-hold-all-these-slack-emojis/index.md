---
title: Why can't I hold all these Slack emojis?
draft: false
date: 2022-09-28
category: Random Bullshit
tags:
  - slack
  - emoji
  - bash
  - api
---
Previously, [last blog post](https://wilhelm.codes/liberating-custom-slack-emojis) I wrote covered how to make a quick escape with your precious hoard of custom Slack emojis. It was fairly well-received, but didn’t quite cover the next step in the migration process; how do you upload your millions of little images to your *new* Slack workspace? 

<!--more-->

## Gathering Requirements

Since we’re doing some destructive operations, we’ll need to make sure our Slack user has the appropriate permissions to manage emoji; adding & deleting. This means using a different section of the Slack interface which uses an entirely seperate set of API endpoints.

You’ll still be using the following, which can be found using instructions from [the previous article](https://wilhelm.codes/liberating-custom-slack-emojis#heading-some-investigative-work):

- An API request token.
- A session cookie.
- A workspace, or team, id.

In addition, you will need your workspaces’s subdomain, or URL. This can easily be found within the Slack app itself:

![slack-emoji-toolkit-workspace-url.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1664349744760/PDjwLi9t4.png align="left")

## ****Testing Your Findings****

This is an incredibly straight-forward process as it’s quite similar to what we already know. The primary difference is this is a `multipart/form-data` upload. So, instead of shipping of a JSON payload, it’s a form with associated fields. 

With the information gathered above, you can upload directly to Slack using a simple cURL command like so:

```bash
curl -s --compressed "https://<domain>.slack.com/api/emoji.add" \
  -H 'content-type: multipart/form-data' \
  -H "cookie: d=<cookie>;" \
  -F "token=<token>" \
  -F "name=<name>" \
  -F mode=data \
  -F "image=@<local-emoji-path>"
```

Replace the following:

- `<domain>` is your workspace’s, or team’s, private URL.
- `<cookie>` is your session cookie value.
- `<token>` is your request token.
- `<name>` will be the named reference of your new emoji.
- `<path>` is the relative, or absolute, local path of your emoji file to upload.

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

: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}
: ${SLACK_DOMAIN:=}

files=$(find . -iname \*.gif -o -iname \*.png -o -iname \*.png -maxdepth 1)
[[ "${files}" == "" ]] && exit 1

echo "${files}" | while read -r path; do 
  name=$(basename "${path%.*}")

  result=$(
    curl -s --compressed "https://${SLACK_DOMAIN}.slack.com/api/emoji.add" \
      -H 'content-type: multipart/form-data' \
      -H "cookie: d=${SLACK_COOKIE};" \
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

While perfectly functional, there’s not a lot of flexibility. No error checking, filtering or confirmation checks. If you’re looking for something a bit more fleshed out, look no further!

%[https://github.com/wilhelm-murdoch/slack-emoji-toolkit]

## The Final Piece ...

So far, we’ve gone over how to download and upload large sets of emoji, but what if you want to nuke them from orbit? The final article in this series will cover how to bulk delete while using advanced filters to pin-point specific sets of emoji you wish to remove.

Hope you’ve learned something useful!