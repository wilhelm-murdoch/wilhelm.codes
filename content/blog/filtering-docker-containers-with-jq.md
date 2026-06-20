---
title: Filtering <span>Docker</span> <span>Containers</span> with jq
title_safe: Filtering Docker Containers with jq
highlight: blue
pack: brands
icon: docker
draft: false
date: 2022-09-29
category: Platform Engineering
tags:
  - docker
  - js
  - json
  - bash
---

As is the case with any seasoned DevOps engineer, I have a set of tools in my kit that I simply cannot live without. If I had to distill them into a top-5 list it would be the following.

<!--more-->

1. Bash for portability.
2. [jq](https://stedolan.github.io/jq/) to filter JSON objects from RESTful APIs.
3. AWS CLI as I cannot stand dealing with the web console.
4. `curl` ( with `wget` as a reasonable fallback ) to interact with various APIs.
5. [Terraform](https://www.terraform.io/) for *most* of my IaC needs.

It wouldn’t be an exaggeration to say I *literally* use these tools *every* day. Specifically, the first 3 items. Furthermore, to say that manually sorting through Docker containers is a practice in tedium would be a massive understatement. Because of this, not a day passes where I am not grateful to have found `jq`.  

In this case, my favourite duo *is* Docker and `jq`... which is what this article is about. Let’s learn some fun filtering patterns to make your life a bit easier if you’re stuck in a terminal all day like myself.
## Setting Up

First and foremost, you’re going to need to install `jq` in your test environment. If you’re on most common Linux distributions:

```bash
apt-get install jq
```

Or, on MacOS:

```bash
brew update && brew install jq
```

I’m assuming that if you’re reading this you already have Docker installed in your test environment. If not, head out to their website and read their [installation documentation](https://docs.docker.com/get-docker/). It tends to vary wildly depending on your OS.

Let’s spin up some containers we can play around with. I use `redis` for stuff like this:

```bash
for i in {1..5}; do docker run -it --rm -d redis; done
```

## Environmental Variables

### Sourceable Blocks

There may be times I wish to collate all environmental variables associated with a set of containers and stick them a `.env` file to source later. Here we create a block for all the `redis` containers we just spun up:

```bash
docker inspect $(docker ps -q) | jq -r '
    .[].Config.Env
  | flatten 
  | .[]
'
```

This one will generate a lot of duplicates as all our test containers are effectively clones. What if we want a distinct set of instead? We can use the `unique` filter:

```bash
docker inspect $(docker ps -q) | jq -r '
	[
	  .[].Config.Env
	] 
  | flatten 
  | unique 
  | .[]
'
```

What if I want a set from specific containers? 

```bash
docker inspect $(docker ps -q) | jq -r '
    [
	    .[] 
      | select([.Id] | inside([
	      "747c2c92855f88a8e9aa9709dcdf3a01f1677e70bf4c0bf0e520eb38ac502876",
	      "2cf70261ef62bc36d19aba02f8ef7b8d7aabfcb1e9f4593a919baa17f80aca5b"
	    ]))
      | .Config.Env
	] 
  | flatten 
  | unique 
  | .[]
'
```

How about filtering by a specific ip address for the default `bridge` network? Using a different network? Just replace `bridge` with the alternate network name.

```bash
docker inspect $(docker ps -q) | jq -r '
    .[] 
  | select(.NetworkSettings.Networks.bridge.IPAddress == "172.17.0.2") 
  | .Config.Env 
  | .[]
'
```

Multiple ip addresses?

```bash
docker inspect $(docker ps -q) | jq -r '
    .[] 
  | select([.NetworkSettings.Networks.bridge.IPAddress] 
  | inside([
      "172.17.0.2",
      "172.17.0.3"
    ])) 
  | .Config.Env 
  | .[]
'
```

### As Flags Instead

Here’s a strange one I’ve had to do. What if we want to recreate a list of `--env` flags we could pass to other `docker run ...` commands? 

```bash
docker inspect $(docker ps -q) | jq -r '
    [
        [
          .[].Config.Env
        ] 
      | flatten 
      | unique 
      | "--env=\(.[])"
    ] 
  | join(" ")
'
```

You’ll get a string that looks similar to the following.

```text
--env=GOSU_VERSION=1.14 --env=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin --env=REDIS_DOWNLOAD_SHA=f0e65fda74c44a3dd4fa9d512d4d4d833dd0939c934e946a5c622a630d057f2f --env=REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-7.0.4.tar.gz --env=REDIS_VERSION=7.0.4
```

## Filtering By Relative Time

I’ve had to use these several times for things like garbage collecting and cleaning up long-running containers. This uses a bit of Bash to help generate the relative timestamps. We use the `date` command for this, but if you’re on a `darwin`-based OS you’ll need to install `gdate` first via Homebrew with:

```bash
brew install coreutils
```

Substitute the following calls to `date` with `gdate` below if on MacOS.

### Newer Than …

Filtering out recent containers with relative time is fairly straight-forward. The following gives us all containers created in the last hour as JSON output from `docker inspect ...`:

```bash
threshold=$(date -d "1 hour ago" +%s)
docker inspect $(docker ps -q) | jq --argjson threshold "${threshold}" -r '
    .[] 
  | select((.State.StartedAt | split(".")[0] | "\(.)Z" | fromdate) > $threshold)
'
```

Perhaps you just want the names of the containers instead:

```bash
threshold=$(date -d "1 hour ago" +%s)
docker inspect $(docker ps -q) | jq --argjson threshold "${threshold}" -r '
    .[] 
  | select((.State.StartedAt | split(".")[0] | "\(.)Z" | fromdate) > $threshold)
  | .Name[1:]
'
```

Docker likes to put a `/` at the beginning of each generated container pet name, so we use `.Name[1:]` to snip it off.

What about just returning the associated ids?

```bash
threshold=$(date -d "1 hour ago" +%s)
docker inspect $(docker ps -q) | jq --argjson threshold "${threshold}" -r '
    .[] 
  | select((.State.StartedAt | split(".")[0] | "\(.)Z" | fromdate) > $threshold)
  | .Id
'
```

Or, ip addresses:

```bash
threshold=$(date -d "1 hour ago" +%s)
docker inspect $(docker ps -q) | jq --argjson threshold "${threshold}" -r '
    .[] 
  | select((.State.StartedAt | split(".")[0] | "\(.)Z" | fromdate) > $threshold)
  | .NetworkSettings.Networks.bridge.IPAddress
'
```

### Older Than???

The same filters apply, but you’re just flipping the compare operator from `>` to `<`:

```bash
threshold=$(date -d "1 hour ago" +%s)
docker inspect $(docker ps -q) | jq --argjson threshold "${threshold}" -r '
    .[] 
  | select((.State.StartedAt | split(".")[0] | "\(.)Z" | fromdate) < $threshold)
'
```

## Other Common Patterns

There have been times where I need a block of container ip addresses so I can dynamically update some Nginx upstreams somewhere. With `jq` it’s as easy as:

```bash
docker inspect $(docker ps -q) | jq -r '
  .[].NetworkSettings.Networks.bridge.IPAddress
'
```

The output would look something like this:

```bash
172.17.0.6
172.17.0.5
172.17.0.4
172.17.0.3
172.17.0.2
```

Perhaps, I want to find a specific container id by it’s ip address:

```bash
docker inspect $(docker ps -q) | jq -r '
	.[]
  | select(.NetworkSettings.Networks.bridge.IPAddress == "172.17.0.3")
  | .Id
'
```

Or, just give me the names of all running containers:

```bash
docker inspect $(docker ps -q) | jq -r '
  .[].Name[1:]
'
```

Which would give you something like:

```bash
zealous_hertz
fervent_dijkstra
focused_galileo
zealous_poincare
naughty_wescoff
```

## Cleaning Up …

We’re considerate people, so let’s clean up after ourselves by killing all containers created using the `redis` image:

```bash
docker kill $(docker inspect $(docker ps -q) | jq -r '
	.[] 
  | select(.Config.Image == "redis") 
  | .Id
')
```

Keep in mind this will kill *all* `redis` containers.

## In Closing …

Having a toolbox filled with utilities you can mix and match together is great if you spend most of your day working in a terminal on a glowing rectangle. Hopefully, I’ve made a strong enough case to for Docker and `jq` as a great combo.

## But, Wait! There’s More!

Why copy and paste these commands in your terminal, when you could just [download and install](https://github.com/wilhelm-murdoch/dq) a handy little Bash script to do it all for you? `dq` has all the above built-in as well as heaps more bells and whistles.

Here are a few command examples if you’re interested:

```bash
dq older-than 4 months --only-return ips --network pebkac
dq newer-than 2 fortnights --only-return ids
dq filter '.[].Name[1:]'
dq find-by-ip-address 172.17.0.2 --only-return names --network foo
```