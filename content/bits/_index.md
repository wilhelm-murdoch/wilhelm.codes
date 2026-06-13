---
title: Nibbles, Bits and Bytes
title_safe: Nibbles, Bits and Bytes
type: pages
layout: bits
# Bit entries are rendered inline on this page (see layouts/pages/bits.html),
# not as standalone pages. Skip rendering them individually so Hugo doesn't
# look for a per-page layout, while keeping them in .Site.RegularPages so the
# page above can list them.
cascade:
  - build:
      render: never
    target:
      kind: page
---
