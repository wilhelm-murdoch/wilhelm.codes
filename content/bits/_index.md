---
title: Nibbles, Bits and Bytes
title_safe: Nibbles, Bits and Bytes
type: pages
layout: bits
# The bits section is still a work in progress: draft keeps it out of `hugo`
# (production) entirely, while `hugo server` still builds drafts for local
# preview.
draft: false
# Bit entries are shown inline on this page (see layouts/pages/bits.html), not
# as standalone pages. render: never keeps them off their own URLs; draft keeps
# them (and their tags/feeds) out of production while leaving them in
# .Site.RegularPages during local development so the page can list them.
cascade:
  - build:
      render: never
    draft: false
    target:
      kind: page
---
