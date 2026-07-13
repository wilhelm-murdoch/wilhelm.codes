---
title: I Added <span>Variable Block</span> Support To <span>Glazier</span>
title_safe: I Added Variable Block Support To Glazier
highlight: blue
pack: duotone
icon: sliders-horizontal
draft: false
toc: true
date: 2026-07-01
category: Projects
tags:
  - go
  - hcl
  - tmux
  - glazier
---
I knew the moment I thought about potentially adding variable definition blocks as a first-class feature Glazier it was going to bother me until I went about implementing it. So, as expected, a week later, here we are. I am happy to report that I've maintained my spotless record of _not_ talking myself out of something tricky.

So, over the course of the past few days Glazier learned a new trick. Profiles can now declare the variables they accept, give them primitive types, mark them as required and read them back through a proper `var.` namespace. 

## Out with the old.

Technically speaking, Glazier has had variable support since day one. You could pass `--var region=watson` and reference `${region}` anywhere in your profile and that was that. Anything you passed got dumped into a flat namespace and any name you *referenced*, but forgot to set, quietly resolved to an empty string.

That's fine right up until you fat-finger `${reigon}` and spend ten minutes wondering why your session name has a hole in it. The whole reason I built this thing was to get Terraform's "here is exactly what you did wrong and where" experience.

Letting variables fail silently just felt a bit like an own-goal.

## Profiles can now declare what they accept.

Because this whole thing is kind of a love letter to Terraform's parser, the idea behind variable definitions is functionally the same. You declare a `variable` block, it sits at the top level next to your session and that's the input you're allowed to pass:

```hcl
variable "district" {
  description = "the district the gig is themed after"
  type        = string
  default     = "watson"
}

variable "fixer" {
  type = string
}

session {
  name = "gig-${var.district}"

  window {
    name = "${var.fixer}-ops"

    pane {
      commands = ["echo ${var.fixer} has the next job"]
    }
  }
}
```

First, you reach a variable through `var.` and *only* `var.` now, so it reads exactly like it would in a `.tf` file. Second, `district` has a default and `fixer` doesn't, which turns out to matter quite a lot in a second.

```console
$ glaze up --var fixer=wakako # district falls back to "watson"
$ glaze up --var district=arasaka --var fixer=wakako
```

So, here you are using the same templated profile to define two seperate sessions decided entirely by flags.

## Pass it something it doesn't know and it says so.

If you pass a `--var` for a variable the profile never declared, you no longer get a silent shrug. You get a proper error:

```text
Error: Undefined variable

A value for "ghost" was passed with --var, but the profile declares no
variable "ghost". Add a variable "ghost" {} block, or remove the flag.
```

I went back and forth on this one. Being strict about undeclared flags is the sort of thing that feels pedantic until the day it catches a typo you'd have otherwise chased for half an hour. In this case strict won.

A `--var` you can't explain is almost always a mistake, so Glazier now treats it like one.

## No default means you have to mean it.

A variable *without* a default is required. Leave it unset and `up` refuses to do anything until you supply it:

```text
Error: Missing required variable

  on .glaze line 6, in variable "fixer":
   6: variable "fixer" {

The variable "fixer" has no default, so a value must be supplied with
--var fixer=<value>.
```

This is the bit that makes a profile a genuine contract rather than a suggestion. If a layout is useless without a fixer, declare `fixer` with no default and the tool will make absolutely sure you provided one before it touches tmux. 

## Proper type-checking.

Every variable declares a `type`. Use one of the bare keywords `string`, `number` or `bool`. The value you hand over on the command line is coerced into that type and rejected if it doesn't fit:

```hcl
variable "base_index" {
  type    = number
  default = 1
}
```

```text
$ glaze up --var base_index=two

Error: Invalid variable value

  on .glaze line 1, in variable "base_index":
   1: variable "base_index" {

The value passed for variable "base_index" with --var cannot be used as
number: a number is required.
```

`two` is not a number, so you find out *before* anything launches rather than after tmux has already swallowed a garbage option and started behaving oddly. Booleans get the same treatment: `true` and `false` are fine, anything else is shown the door. Unfortunately, I decided not to go with truthy or falsey value coercion.

I kept it to the three primitives on purpose. The moment you add `list(string)` and friends you're also signing up for coercing comma-soup off the command line into nested types. That's a much bigger can of worms than a tmux helper needs to open today.

Though, obviously, if you disagree you're more than welcome to leave a comment below!

## A namespace for everything.

I'll be honest about the consequence here. This is a breaking change and pretending otherwise would be rude. The old flat `${region}` style is gone. If a value comes from a declared variable, you read it as `var.region`.

Which raised a genuinely interesting design question I sat with for a while. If variables are only ever used *inside* a session, why not declare them inside the session block too? It feels more intuitive at first though, but it's also wrong. 

However you nest the declaration, the *reference* is still flat and global; you write `var.fixer`, never `session.var.fixer`. Declaring something file-global but reading it block-scoped is incoherent and a variable is really an input to the *invocation*, sitting conceptually above the session and not a property of it. So they live at the top level, exactly where Terraform puts them. I borrowed both the syntax and the reasoning.

## Where did the environment variables go?

They also got their own namespace. Previously `GLAZE_ENV_token` showed up as a bare `${token}`, sharing the same flat namespace as everything else. Now it lives under an `env.` namespace, which makes the three sources nicely symmetric:

- `var.*` for variables you declared and passed with `--var`
- `env.*` for `GLAZE_ENV_*` environment variables
- `path.pwd` & `path.base` the unchanged built-ins

```hcl
session {
  name = "host-${env.box}"

  window {
    pane {}
  }
}
```

```console
$ GLAZE_ENV_box=nightcity glaze up
```

```text
session = host-nightcity
```

There's no declaration needed for `env.*`; the environment is the environment. Only the things you pass with `--var` have to be declared, because those are the inputs *you* are claiming the profile accepts.

## Tearing down a session.

If a required variable now blocks `up`, doesn't that wreck `glaze down`? I recently taught the `down` command to evaluate *only* the session name so it doesn't need every variable buried deep in the profile just to kill a session. Surely required variables undo that?

They don't and this was the fiddly bit to get right. `down` resolves variables leniently. A variable used solely in some pane command, far away from the session name, is neither required nor evaluated when you're tearing things down:

```hcl
variable "beep" {
  type = string
}

session {
  name = "daemon-run"

  window {
    pane {
      commands = ["echo ${var.beep}"]
    }
  }
}
```

```console
$ glaze down
INF nothing to do; session is not running session=daemon-run
```

If `beep` isn't provided, the command just accepts it and moves on, because `down` never needed it. `up` enforces the full contract; `down` only asks for what the name actually depends on. Obviously, the exception here is if a variable is used to construct the actual session name. Other than that, this is an idempotent no-op.

## Validation has been updated too.

`glaze format --validate` decodes a profile and reports diagnostics without ever touching tmux and it now enforces the *entire* variable contract. Miss a required variable and validation fails right there:

```console
$ glaze format --validate
Error: Missing required variable
  ...

$ glaze format --validate --var region=us-east-1
# clean. nothing to report.
```

So, you can lint a parameterised profile in CI, or just before committing it and know it holds together before you ever try to bring it up.

## This literally broke all my current profiles.

And I regret nothing. The flat-namespace migration touched pretty much everything; sample profiles, the docs, a pile of tests and all the profiles I actually use day to day. Normally this is the part of a post where I'd sketch out a careful migration path and apologise profusely.

But, the entire userbase of this tool is almost, as far as I can tell, me. So the migration path is "I'll fix all my profiles tomorrow morning over coffee." 

{{< blockquote "There is a real freedom in shipping a breaking change to an audience you can fit in a mirror." "it me." >}}

To migrate is easy enough, just define your variables and prefix all references with `var.`. This _is_ still currently in beta after all.

## In closing...

Under the hood this turned into a more interesting refactor than I expected. `hcldec` wants to decode a whole file body against one spec and it flatly refuses to tolerate a `variable` block sitting next to the session it doesn't know about. The trick was to stop handing it the whole file, pull the session block out myself and decode *just its body*, which leaves the variable blocks to be gathered and resolved in their own quiet little pass beforehand. There's a tidy `PartialContent` implementation in there that was heaps of fun to figure out.

None of which a tmux wrapper strictly needed, of course. But "strictly needed" stopped being the bar around the time I added a fuzzer. The point was to feel out how Terraform turns a typo into a friendly, located error and now Glazier does a respectable impression of it for variables too. 

I'm still ironing out all the kinks and ensuring I still have an 80% baseline in testing and code coverage, but I'm planning to release this and a few bug fixes and dependency bumps this weekend. Tomorrow-me gets to read this back with fresh eyes and decide how much of it past-me oversold. Very nice.

Until I merge it in, you can play with the latest release [here](https://github.com/wilhelm-murdoch/glazier).

And now I'm thinking about adding `*.tfvars`-like functionality. Surely, I won't fall for this again?
