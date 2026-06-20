---
# There is no /blog/ list page — posts are surfaced on the home and archive
# pages. Skip rendering the section page so Hugo doesn't warn about a missing
# list layout. Individual posts (and their inclusion in .Site.RegularPages)
# are unaffected.
build:
  render: never
  list: never
---
