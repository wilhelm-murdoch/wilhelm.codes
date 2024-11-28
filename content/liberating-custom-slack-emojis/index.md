---
params:
    author: Wilhelm Murdoch
title: Liberating Custom Slack Emojis
summary: Or, I'm bored. Let's learn some stupid stuff!
draft: false
date: 20 Sep 2022
tags:
  - emoji
  - api
  - bash
  - api
---
**TL;DR** if you want to skip all this and just get to the good stuff, [click here](https://github.com/wilhelm-murdoch/slack-emoji-toolkit) to download and run the `slack-emoji-toolkit`.

---

As is stupid tradition, whenever I start at a new company, one of the first things I like to do while getting settled in is upload my favourite emojis to whatever real-time messaging platform is in use. I know it’s childish, but silly memes and emojis are great ways for you to break the ice with your new coworkers. 

But, when it comes time to part ways it’s only understandable to want to gather your stuff for the next place to start the process again. Over the years one can collect and curate quite a nice hoard of stupid images.

I’ve been using Slack prolifically for the past few years. Unfortunately, there is no simple way of exporting your precious collection outside of the old “right-click and save” method. This is effective for smaller collections of a couple dozen or so, but becomes impractical when there are hundreds or even thousands.

And, of course, I’m not alone. There have been a non-zero number of times when someone left the company only to hit me up later asking for an emoji archive.

Yes, this really happens and something *must* be done about it!

What follows is an unnecessarily long dive into a little bit of reverse engineering one of Slack’s API endpoints, subverting it for our own use and writing a stupid little tool to help ourselves ( and others ) automate this process for the future.

## Some s you whether the request was successful or not. If it returns `false` there will be an additional field named `error` that should clue you into what went wrong.
- `next_marker` tells you where in the list of custom emoji the *next* page of results should start. We use this as the value of `marker` in subsequent request payloads ( see below ). This is effectively how you page through large lists of emoji.
- `results` should be obvious, but it contains an array of objects with `name` and `value` fields.
    - `name` is the alias of the emoji.
    - `value` is the direct CDN URL to the emoji.

You may see other fields, but `next_marker` and `value` are the only fields we really care about.

Next, If you take a look at the “Payload” tab in the “Network” panel fsociated value to help page through subsequent results. Keep doing this in a loop until your response no longer returns a `marker_next` field. 

Once that happens, you’re at the end of the list.

With a little bit of help from `jq` to parse and filter the JSON responses, we can grab a simple list of URLs. 

```bash
$ <previous_curl_command> | jq -r '.results[].value'
https://emoji.slack-edge.com/T0XXXX/no/060fca9aa2581a93.png
https://emoji.slack-edge.com/T0XXXX/nods/c7fe54342ab5b8b6.gif
https://emoji.slack-edge.com/T0XXXX/nods-back/fbd1b5384cdd0905.gif
https://emoji.slack-edge.com/T0XXXX/nomnomnom/612cfc74c785010d.gif
https://emoji.slack-edge.com/T0XXXX/octocat/627964d7c9.png
https://emoji.slack-edge.com/T0XXXX/ohyou/6a352df984d9c076.gif
https://emoji.slack-edge.com/T0XXXX/one-sec-cooking/e749627cb088859d.png
https://emoji.slack-edge.com/T0XXXX/oof/db94710445cbb206.png
https://emoji.slack-edge.com/T0XXXX/petrol/35ed3db238f795fc.png
https://emoji.slack-edge.com/T0XXXX/piggy/b7762ee8cd.png
```

We now understand how to collect everything we need, so let’s automate this a bit more.

## The Implementation

We’re going to write a little script that’ll download all the custom emojis from the target Slack workspace. It’s going to perform the following steps:

1. Define a starting JSON payload. 
2. Create a run loop. 
3. With each loop we make a request using the API endpoint. 
4. Do some error checking.
5. Iterate through the results and save them to disk. 
6. If the results contain a `next_marker` update the JSON payload with a `marker` field and continue the run loop.
7. Keep going until the last request no longer provides a `next_marker`.

First, we want to define some environmental variables so we can easily configure the script:

```bash
: ${SLACK_WORKSPACE_ID:=}
: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}
```

Now we define our JSON payload object. We use `jq` here to keep things eae also targeting our workspace:

```bash
while true; do
  result=$(
    curl -s --compressed "https://edgeapi.slack.com/cache/${SLACK_WORKSPACE_ID}/emojis/list?fp=97" \
      -H "cookie: d=${SLACK_COOKIE};" \
      --data-raw "${payload}" 
  )
done                                                                            ; all done. However, if we do get a value, we take the previous payload we constructed and *add* the `marker` field. 

The next loop will pick this change up and pass it on through to the API request tellin -s --compressed "https://edgeapi.slack.com/cache/${SLACK_WORKSPACE_ID}/emojis/list?fp=97" \
      -H "cookie: d=${SLACK_COOKIE};" \
      --data-raw "${payload}"                                                                 f, makehashnode.com/res/hashnode/image/upload/v1663601487957/aTOrHhP9G.png align="left")
 the script executable, define the environmental variables and fire it off like so:

```bash
$ SLACK_WORKSPACE_ID=*** SLACK_COOKIE=*** SLACK_TOKEN=*** ./fetch.sh
```

## An Even Better Version!

I know I just made you read through all this, but you also could’ve just downloaded the tool from here. It’s got heaps more bells and whistles ( if you’re into that sort of thing):

%[https://github.com/wilhelm-murdoch/slack-emoji-toolkit]

## The Bitter Irony

In typical bored engineer fashion, I’ve spent more time writing this article, documenting and publishing the code than I ever would have personally just “handraulically” doing this from time to time.

Hopefully, you’ve learned something new! 🤞

## Bonus Relevant XKCD Image

![Untitled.png](https://cdn.
  )

  if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
    echo "${result}" | jq -r ".error"
    exit 1
  fi

  echo "${result}"  | jq -r '.results[].value' | while read -r url; do 
    name=$(basename $(dirname "${url}"))
    curl -s -o "${name}.${url##*.}" "${url}"
  done 

  marker=$(echo "${result}" | jq -r ".next_marker")
  [[ "${marker}" == "null" ]] && exit 0

  payload=$(echo "${payload}" | jq --arg marker "${marker}" '. + { marker: $marker }')
done
```

This is pretty much it. A barebones script that downloads all findings to its present working directory. To test it out yourselg Slack to give us the next page of precious emojis.

```bash
marker=$(echo "${result}" | jq -r ".next_marker")
[[ "${marker}" == "null" ]] && exit 0

payload=$(echo "${payload}" | jq --arg marker "${marker}" '. + { marker: $marker }')
```

## The Finished Product

```bash
#!/usr/bin/env bash

set -eo pipefail

: ${SLACK_WORKSPACE_ID:=}
: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}

payload=$(
  jq -nc \
    --arg     token "${SLACK_TOKEN}" \
    --argjson count "100" \
    '{
      token: $token, 
      count: $count
    }'
)

while true; do
  result=$(
    curl
```

We obviously want to do some simple error checking so we know what we did wrong if the requests fail. Grab the error, spit it out and terminate the script.

```bash
if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
  echo "${result}" | jq -r ".error"
  exit 1
fi
```

We now start iterating through any of the results we got from the initial request. We really only care about the `value` field as the URL gives us all the pieces we need to give our emojis a human-readable filename. 

Here we treat the resulting URL as a standard file path and use `dirname` paired with `basename` to get the name of the parent directory of the file. The parent directory holds the actual name of the emoji, while the file itself is only a random hash. We use [Bash’s parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) feature to construct our filename.

Finally, we download the remote file to the current directory:

```bash
echo "${result}"  | jq -r '.results[].value' | while read -r url; do 
name=$(basename $(dirname "${url}"))
curl -s -o "${name}.${url##*.}" "${url}"
done 
```

We need to check if there are more results to page through, so let’s look for the `marker_next` field. If we can’t find one, then mission accomplishedsy. Not only is it great for parsing and filtering JSON in Bash, it also makes building and manipulating objects simple:

```bash
payload=$(
  jq -nc \
    --arg     token "${SLACK_TOKEN}" \
    --argjson count "100" \
    '{
      token: $token, 
      count: $count
    }'
)
```

Next, is the run loop where we make our API requests. This passes through the payload object we just defined whilhis to authenticate with the Slack API itself.

## Testing Your Findings

We now understand the structure of our payload. We also have the endpoint to hit as well as our tokens and session cookie to authenticate. Piecing it all together, you can now use cURL to hit the API directly from your terminal:

```bash
$ curl --silent https://edgeapi.slack.com/cache/<team>/emojis/list?fp=97
  -H 'cookie: d=<cookie>;' \
  --data-raw '{"token":"<token>","count":10}'
```

Replace the following:

- `<team>` is your workspace, or team, id.
- `<cookie>` is your session cookie value.
- `<token>` is your request token.

If everything worked out, you should have successful API response like the one above. If the response has root field named `marker_next`, make note of the asor the same request, you’ll see something similar to:

```json
{
	"token": "xoxc-xxxx-xxxx-xxxx",
	"count": 100,
	"marker": "some-other-emoji"
}
```

- `token` is the API request token the Slack client uses to make the emoji list request on your behalf.
- `count` is the amount of emojis to return as a page.
- `marker` tells the API where in the emoji list to start paging.

The final piece of the puzzle is getting the value of your session cookie. You can grab this by clicking the “Request Headers” section under the “Headers” tab. You should see a header labeled `cookie`. 

There’s going to be a fairly large block of text to parse through, but you’re looking for the cookie named `d`. Save everything between the `d=` and the closing `;`. You’re going to need tInvestigative Work

There just has to be a straightforward way we can *mostly* automate this. So, I did some cursory digging around the Chrome Developer Tools console and found this endpoint in the “Network” tab:

```
https://edgeapi.slack.com/cache/T0XXXX/emojis/list?fp=97
```

The `T0XXXX` will be your workspace, or team, id. Make note of it, you’ll need it later.

If you intercept one of these requests and take a peak at the “Response” tab in the “Network” panel, you’ll see a JSON response with a structure similar to:

```json
{
	"ok": true,
	"next_marker": "a-custom-emoji",
	"results": [
		{
			"name": "another-custom-emoji",
			"value": "https://emoji.slack-edge.com/T0XXXX/another-custom-emoji/xxxxxxx.png"
		}
		... more emojis ...
	]
}
```

- `ok` tells you whether the request was successful or not. If it returns `false` there will be an additional field named `error` that should clue you into what went wrong.
- `next_marker` tells you where in the list of custom emoji the *next* page of results should start. We use this as the value of `marker` in subsequent request payloads ( see below ). This is effectively how you page through large lists of emoji.
- `results` should be obvious, but it contains an array of objects with `name` and `value` fields.
    - `name` is the alias of the emoji.
    - `value` is the direct CDN URL to the emoji.

You may see other fields, but `next_marker` and `value` are the only fields we really care about.

Next, If you take a look at the “Payload” tab in the “Network” panel for the same request, you’ll see something similar to:

```json
{
	"token": "xoxc-xxxx-xxxx-xxxx",
	"count": 100,
	"marker": "some-other-emoji"
}
```

- `token` is the API request token the Slack client uses to make the emoji list request on your behalf.
- `count` is the amount of emojis to return as a page.
- `marker` tells the API where in the emoji list to start paging.

The final piece of the puzzle is getting the value of your session cookie. You can grab this by clicking the “Request Headers” section under the “Headers” tab. You should see a header labeled `cookie`. 

There’s going to be a fairly large block of text to parse through, but you’re looking for the cookie named `d`. Save everything between the `d=` and the closing `;`. You’re going to need this to authenticate with the Slack API itself.

## Testing Your Findings

We now understand the structure of our payload. We also have the endpoint to hit as well as our tokens and session cookie to authenticate. Piecing it all together, you can now use cURL to hit the API directly from your terminal:

```bash
$ curl --silent https://edgeapi.slack.com/cache/<team>/emojis/list?fp=97
  -H 'cookie: d=<cookie>;' \
  --data-raw '{"token":"<token>","count":10}'
```

Replace the following:

- `<team>` is your workspace, or team, id.
- `<cookie>` is your session cookie value.
- `<token>` is your request token.

If everything worked out, you should have successful API response like the one above. If the response has root field named `marker_next`, make note of the associated value to help page through subsequent results. Keep doing this in a loop until your response no longer returns a `marker_next` field. 

Once that happens, you’re at the end of the list.

With a little bit of help from `jq` to parse and filter the JSON responses, we can grab a simple list of URLs. 

```bash
$ <previous_curl_command> | jq -r '.results[].value'
https://emoji.slack-edge.com/T0XXXX/no/060fca9aa2581a93.png
https://emoji.slack-edge.com/T0XXXX/nods/c7fe54342ab5b8b6.gif
https://emoji.slack-edge.com/T0XXXX/nods-back/fbd1b5384cdd0905.gif
https://emoji.slack-edge.com/T0XXXX/nomnomnom/612cfc74c785010d.gif
https://emoji.slack-edge.com/T0XXXX/octocat/627964d7c9.png
https://emoji.slack-edge.com/T0XXXX/ohyou/6a352df984d9c076.gif
https://emoji.slack-edge.com/T0XXXX/one-sec-cooking/e749627cb088859d.png
https://emoji.slack-edge.com/T0XXXX/oof/db94710445cbb206.png
https://emoji.slack-edge.com/T0XXXX/petrol/35ed3db238f795fc.png
https://emoji.slack-edge.com/T0XXXX/piggy/b7762ee8cd.png
```

We now understand how to collect everything we need, so let’s automate this a bit more.

## The Implementation

We’re going to write a little script that’ll download all the custom emojis from the target Slack workspace. It’s going to perform the following steps:

1. Define a starting JSON payload. 
2. Create a run loop. 
3. With each loop we make a request using the API endpoint. 
4. Do some error checking.
5. Iterate through the results and save them to disk. 
6. If the results contain a `next_marker` update the JSON payload with a `marker` field and continue the run loop.
7. Keep going until the last request no longer provides a `next_marker`.

First, we want to define some environmental variables so we can easily configure the script:

```bash
: ${SLACK_WORKSPACE_ID:=}
: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}
```

Now we define our JSON payload object. We use `jq` here to keep things easy. Not only is it great for parsing and filtering JSON in Bash, it also makes building and manipulating objects simple:

```bash
payload=$(
  jq -nc \
    --arg     token "${SLACK_TOKEN}" \
    --argjson count "100" \
    '{
      token: $token, 
      count: $count
    }'
)
```

Next, is the run loop where we make our API requests. This passes through the payload object we just defined while also targeting our workspace:

```bash
while true; do
  result=$(
    curl -s --compressed "https://edgeapi.slack.com/cache/${SLACK_WORKSPACE_ID}/emojis/list?fp=97" \
      -H "cookie: d=${SLACK_COOKIE};" \
      --data-raw "${payload}" 
  )
done
```

We obviously want to do some simple error checking so we know what we did wrong if the requests fail. Grab the error, spit it out and terminate the script.

```bash
if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
  echo "${result}" | jq -r ".error"
  exit 1
fi
```

We now start iterating through any of the results we got from the initial request. We really only care about the `value` field as the URL gives us all the pieces we need to give our emojis a human-readable filename. 

Here we treat the resulting URL as a standard file path and use `dirname` paired with `basename` to get the name of the parent directory of the file. The parent directory holds the actual name of the emoji, while the file itself is only a random hash. We use [Bash’s parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) feature to construct our filename.

Finally, we download the remote file to the current directory:

```bash
echo "${result}"  | jq -r '.results[].value' | while read -r url; do 
name=$(basename $(dirname "${url}"))
curl -s -o "${name}.${url##*.}" "${url}"
done 
```

We need to check if there are more results to page through, so let’s look for the `marker_next` field. If we can’t find one, then mission accomplished; all done. However, if we do get a value, we take the previous payload we constructed and *add* the `marker` field. 

The next loop will pick this change up and pass it on through to the API request telling Slack to give us the next page of precious emojis.

```bash
marker=$(echo "${result}" | jq -r ".next_marker")
[[ "${marker}" == "null" ]] && exit 0

payload=$(echo "${payload}" | jq --arg marker "${marker}" '. + { marker: $marker }')
```

## The Finished Product

```bash
#!/usr/bin/env bash

set -eo pipefail

: ${SLACK_WORKSPACE_ID:=}
: ${SLACK_COOKIE:=}
: ${SLACK_TOKEN:=}

payload=$(
  jq -nc \
    --arg     token "${SLACK_TOKEN}" \
    --argjson count "100" \
    '{
      token: $token, 
      count: $count
    }'
)

while true; do
  result=$(
    curl -s --compressed "https://edgeapi.slack.com/cache/${SLACK_WORKSPACE_ID}/emojis/list?fp=97" \
      -H "cookie: d=${SLACK_COOKIE};" \
      --data-raw "${payload}" 
  )

  if [[ $(echo "${result}" | jq -r ".ok") == false ]]; then
    echo "${result}" | jq -r ".error"
    exit 1
  fi

  echo "${result}"  | jq -r '.results[].value' | while read -r url; do 
    name=$(basename $(dirname "${url}"))
    curl -s -o "${name}.${url##*.}" "${url}"
  done 

  marker=$(echo "${result}" | jq -r ".next_marker")
  [[ "${marker}" == "null" ]] && exit 0

  payload=$(echo "${payload}" | jq --arg marker "${marker}" '. + { marker: $marker }')
done
```

This is pretty much it. A barebones script that downloads all findings to its present working directory. To test it out yourself, make the script executable, define the environmental variables and fire it off like so:

```bash
$ SLACK_WORKSPACE_ID=*** SLACK_COOKIE=*** SLACK_TOKEN=*** ./fetch.sh
```

## An Even Better Version!

I know I just made you read through all this, but you also could’ve just downloaded the tool from here. It’s got heaps more bells and whistles ( if you’re into that sort of thing):

%[https://github.com/wilhelm-murdoch/slack-emoji-toolkit]

## The Bitter Irony

In typical bored engineer fashion, I’ve spent more time writing this article, documenting and publishing the code than I ever would have personally just “handraulically” doing this from time to time.

Hopefully, you’ve learned something new! 🤞

## Bonus Relevant XKCD Image

![Untitled.png](https://cdn.hashnode.com/res/hashnode/image/upload/v1663601487957/aTOrHhP9G.png)
