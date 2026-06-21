---
title: Why I Built <span>Glazier</span>
title_safe: Why I Built Glazier
highlight: blue
pack: duotone
icon: terminal-window
draft: false
toc: true
date: 2026-06-20
category: Development
tags:
  - go
  - golang
  - tmux
  - hcl
  - projects
---
I live in [tmux](https://github.com/tmux/tmux/wiki). I typically have an editor here, a dev server there, logs tailing in the corner or a spare pane for poking at things. The trouble is that this little world is frustratingly ephemeral. Rebooting my machine ( thank you, compuslory MacOS updates ), kill the wrong session or just close the laptop lid for too long and it can all evaporates. Then I'm back to rebuilding the same layout by hand, one `split-window` at a time, like some kind of animal.

<!--more-->

So I built [`Glazier`](https://github.com/wilhelm-murdoch/glazier); a small command-line tool that lets me describe a tmux workspace once and recreate it on demand. Type `glaze up` and the sessions, windows and panes I described spring back into existence exactly how I left them.

This has been a slow-burning labour of love for the better part of two years and it's finally in a state where I feel comfortable letting other people look at it. So let's talk about why it exists, what else is out there and how this one is different.

## It's just a config file, right?

That was the idea, at least. I just wanted to stop rebuilding the same layouts over and over. But, as is tradition, I didn't want to make it *too* easy for myself.

There was a second, more selfish motivation. As a platform engineer, there isn't a day that goes by where I don't work with [Terraform](https://www.terraform.io/). I've always been quietly fascinated by how it parses and validates its configuration. That whole experience of getting a precise, friendly error pointing at the exact line you fat-fingered, rather than a stack trace and a 🖕. I wanted to understand how that machinery actually worked.

So, I'm a heavy tmux user *and* I wanted to learn HCL parsing from the inside. These two things lined up a little too perfectly. So Glazier's profiles aren't YAML; they're [HCL](https://github.com/hashicorp/hcl). The same configuration language Terraform uses and parsed with the same underlying library.

Here's a basic profile:

```hcl
session {
  name = "daemon-run"

  window {
    name   = "ice-breaker"
    layout = "main-vertical"

    pane {
      commands = ["nvim ./payloads"]
    }

    pane {
      commands = ["watch -n1 netwatch --target arasaka-mainframe"]
    }
  }
}
```

Drop that in a file called `.glaze`, run `glaze up` next to it and you're jacked in.

## I'm not the first to do this; not even the 3rd... or the 4th.

This is a thoroughly-solved problem and I'd be doing you a disservice if I pretended otherwise. There's a whole shelf of mature, battle-tested tools that do effectively the same thing:

* [tmuxinator](https://github.com/tmuxinator/tmuxinator) is the one most are familiar with. Written in Ruby with YAML profiles. Probably what most people reach for.
* [teamocil](https://github.com/remi/teamocil) is also written Ruby; also uses YAML.
* [smug](https://github.com/ivaaaan/smug) is written in Go and uses YAML and is the closest in spirit to Glazier if we're being honest.
* [tmuxp](https://github.com/tmux-python/tmuxp) is written in good'ole reliable Python and it'll happily eat YAML *or* JSON.

If you already use and trust one of these, I'll be straight with you: there isn't a compelling reason to switch. Keep using what works. I'm not here to convince anyone to rip out a tool they're happy with.

But if you're still reading, here's what *I* like about mine.

## So what's actually different?

### The profile validates itself!

This is the part I set out to build, so it's the part I'm fondest of. Because Glazier is built on HCL, it inherits Terraform-style diagnostics for free. Mistype a layout, point a starting directory at somewhere that doesn't exist or forget a required block and you don't get a vague "something went wrong fuck you". You get told exactly what and where you messed up:

```text
Error: Invalid layout specified

  on .glaze line 4, in session.window:
   4:     layout = "main-plumbus"

The layout value of "main-plumbus" is not a supported preset
(even-horizontal, even-vertical, main-horizontal, main-vertical,
tiled) nor a valid tmux layout string.
```

There's a `glaze format` command that rewrites your profile into a canonical style and, with `--validate`, reports any of these diagnostics without touching tmux at all. Both of these scratch exactly the itch that started the whole project.

### Variables, templates and string functions! Oh, my!

A static layout is useful. A *templated* one is better. Profiles can reference variables and you can feed those in from `--var` flags or `GLAZE_ENV_*` environment variables:

```hcl
session {
  name               = "ops-${region}"
  starting_directory = path.pwd

  window {
    name = upper(region)

    pane {
      commands = ["k9s --context ${region}"]
    }
  }
}
```

```console
$ glaze up --var region=ap-southeast-2
```

Look familiar? If you work with Terraform it does!

There's a handful of built-in string functions too. `upper`, `lower`, `replace`, `trimspace`, `join` and friends which act as thin wrappers over the same `go-cty` standard library Terraform uses. Plus, a couple of freebies like `path.pwd` and `path.base` so a profile can adapt to wherever it's run from.

### It doesn't lie to you about timing.

This is the bit of engineering I'm quietly proudest of, even though nobody will ever see it. When you fire a sequence of commands into a tmux pane, the naive approach is to blast them in with a `sleep` between each one and hope the previous command finished. That's flaky and it's how a few other tools handle it.

Glazier instead serialises commands through tmux's own [`wait-for`](https://man.openbsd.org/tmux#wait-for) signalling, so each command genuinely waits for the previous one to finish before the next is sent. There are no fixed sleeps and no races. The *one* exception is the final command in a list, which is sent fire-and-forget. If your last command is a long-running dev server or `tail -f`, waiting on it would hang `up` forever.

I learned that last part the hard way.

### It can *mostly* save a session!

Run `glaze save` inside a live session and it'll capture the structure back out into a profile: windows, panes, names, layouts, focus and starting directories. The "mostly" is doing some load-bearing work in that sentence and it's a deliberate choice, not a missing feature.

`save` will **not** export your pane commands, environment variables, hooks or tmux options. Why? Because each of those is a footgun:

-  **Commands** would re-execute on the next `up`. A forgotten `rm -rf` captured from some pane could ruin your whole day on replay.
- **Environment variables** can only be read as the *entire* session environment. This means inherited secrets, tokens and keys getting written into a file you might commit. That's a big fat no from me, dawg.
- **Options** read back as effective state, hopelessly tangling up with your `tmux.conf` and manual tweaks.

So, a saved profile is a scaffold. It gets the geometry right and you add back the commands and config you actually want by hand.

## A real profile.

Enough talk. Here's the profile I actually use when working this website:

```hcl
session {
  name = replace(path.base, ".", "-")

  envs = {
    HUGO_GITHUB_TOKEN        = "${github}"
    HUGO_ACTIVITY_GRAPH_DEMO = "${demo}"
  }

  window {
    name  = "editor"

    pane {
      commands = ["nvim"]
    }
  }

  window {
    name  = "terminal"
    focus = true

    pane {}
  }

  window {
    name = "server"

    pane {
      commands = ["hugo server --disableFastRender"]
    }
  }

  window {
    name = "git"

    pane {
      commands = ["lazygit"]
    }
  }
}
```

Running `glaze up --var github=*** --var demo=true` gives me the following windows:
- My editor of choice; NeoVim.
- A dedicated terminal session.
- The Hugo server along with some `HUGO_` specific environment variables; values sourced from the CLI.
- Finally, `lazygit` to manage and commit my changes.

One thing I should point out is where I define the session name with `replace(path.base, ".", "-")`. This is a workaround for a small known tmux quirk where it won't allow `.` or `:` within a session name. Since the repository is `wilhelm.codes`, tmux will automatically assign it as `wilhelm_codes`. And since Glazier refers to the session by the name we explicitly define, it'll lose context the moment the session is created with the following useful error:

```shell
could not create new session `wilhelm.codes`: session `wilhelm.codes` was created but could not be found afterwards
```

Definitely a small edge case I should address with the next patch.

Further, the `--var` arguments aren't really necessary as you could just `export GLAZE_var_name` as well and Glazier will pick it up automatically.

Anyways, because the session is just a named thing, the rest of the lifecycle is tidy too. List what's running with `glaze ls`:

```console
$ glaze ls
NAME      WINDOWS  PATH
glazier*  2        /home/wilhelm/Development/wilhelm.codes
scratch   1        /tmp
```

The asterisk marks the session I'm currently attached to. When I'm done, I tear it down by profile:

```console
$ glaze down
```

`down` is idempotent and that's on purpose. Bringing down a session that isn't running is a no-op, not an error, so it's safe to drop in scripts without defensive checks.

## Some over-engineered bits ...

To be frank a tool that shells out to tmux did not strictly *need* a fuzzed HCL parser, build provenance attestations on its release binaries or a CI pipeline that runs the test suite against multiple Go versions and operating systems.

But, that was never really the point. The point was learning how Terraform's parser ticks, working out how to drive tmux reliably without sleeps and over-engineering the ever-loving-shit out of an already-solved problem because it was *fun*. Every constraint I imposed upon myself taught me something new. This is ultimately the only metric I actually care about for a hobby project like this.

## Where to get it?

It's [up on GitHub](https://github.com/wilhelm-murdoch/glazier) with a shiny MIT license. If you've got Go installed:

```console
$ go install github.com/wilhelm-murdoch/glazier/cmd/glaze@latest
```

Or, grab a prebuilt binary from the [releases page](https://github.com/wilhelm-murdoch/glazier/releases). I currently build for Linux and macOS on both `amd64` and `arm64`. Each one ships with a checksum and a signed provenance attestation, because of course it does.

## In closing ...

I would confidently say Glazier has moved on from "experimental" to "stable". It works and I use it every single day. But, there are rough edges and there may be any number of unencountered failure modes. The `down` and `ls` commands only landed recently and I'm not sure if the latter should remain. I've also got a running list of ideas I haven't talked myself out of yet. Like, something similar to Terraform's `*.tfvars` files or defining typed variables.

If you're already happy with Tmuxinator or Smug, then stick with them. But if the idea of a declarative, self-validating, slightly-too-clever tmux profile appeals to you, or you just want to read some Go that wraps tmux in ways it was probably never meant to be wrapped, I'd love for you to take it for a spin.

I sincerely hope you find [Glazier](https://github.com/wilhelm-murdoch/glazier) as useful as I had fun building it.
