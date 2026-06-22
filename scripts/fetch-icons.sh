#!/usr/bin/env bash
#
# Fetch the site's icon set as inlined SVGs from the Iconify API.
#
# Icons used to come from FontAwesome Pro (non-distributable). They now come from
# freely distributable sets and are committed to the repo as static SVGs, so the
# site has no runtime icon dependency. This script documents their provenance and
# regenerates assets/icons/ if the mapping below changes.
#
# Sources & licenses (see THIRD-PARTY-LICENSES.md):
#   ph:*           Phosphor      - MIT          (UI + git, duotone style)
#   octicon:*      Octicons      - MIT (GitHub) (git icons Phosphor lacks)
#   simple-icons:* Simple Icons  - CC0          (brand logos)
#
# Files are named by their *original FontAwesome name* so templates can keep using
# the existing `pack` + `icon` params unchanged (pack "brands" -> brands/, else ui/).
#
# Usage: ./scripts/fetch-icons.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UI_DIR="${ROOT}/assets/icons/ui"
BRANDS_DIR="${ROOT}/assets/icons/brands"
API="https://api.iconify.design"

mkdir -p "${UI_DIR}" "${BRANDS_DIR}"

# fetch <fa-name> <iconify-id> <dest-dir>
fetch() {
  local name="$1" id="$2" dir="$3"
  local url="${API}/${id/://}.svg"
  echo "  ${name}.svg  <-  ${id}"
  curl -fsSL "${url}" -o "${dir}/${name}.svg"
}

# --- UI icons: Phosphor duotone (Octicons fill the one git gap) ---
echo "UI icons -> ${UI_DIR}"

# General UI (Phosphor duotone)
fetch broom                      ph:broom-duotone                       "${UI_DIR}"
fetch bucket                     ph:trash-duotone                       "${UI_DIR}"
fetch calendar-week              ph:calendar-dots-duotone               "${UI_DIR}"
fetch clock-rotate-left          ph:clock-counter-clockwise-duotone     "${UI_DIR}"
fetch code                       ph:code-duotone                        "${UI_DIR}"
fetch face-awesome               ph:smiley-duotone                      "${UI_DIR}"
fetch fire                       ph:fire-duotone                        "${UI_DIR}"
fetch globe                      ph:globe-duotone                       "${UI_DIR}"
fetch id-card                    ph:identification-card-duotone         "${UI_DIR}"
fetch list-check                 ph:list-checks-duotone                 "${UI_DIR}"
fetch mushroom                   ph:game-controller-duotone             "${UI_DIR}"
fetch pencil                     ph:pencil-duotone                      "${UI_DIR}"
fetch sack-dollar                ph:money-duotone                       "${UI_DIR}"
fetch seedling                   ph:plant-duotone                       "${UI_DIR}"
fetch shapes                     ph:shapes-duotone                      "${UI_DIR}"
fetch timeline                   ph:list-bullets-duotone                "${UI_DIR}"
fetch circle-dot                 ph:record-duotone                      "${UI_DIR}"
fetch circle-check               ph:check-circle-duotone                "${UI_DIR}"
fetch cube                       ph:cube-duotone                        "${UI_DIR}"
fetch eye                        ph:eye-duotone                         "${UI_DIR}"
fetch comments                   ph:chats-duotone                       "${UI_DIR}"
fetch exclamation                ph:warning-circle-duotone              "${UI_DIR}"
fetch lock-open                  ph:lock-open-duotone                   "${UI_DIR}"
fetch book                       ph:book-duotone                        "${UI_DIR}"
fetch heart                      ph:heart-duotone                       "${UI_DIR}"
fetch quote-right                ph:quotes-duotone                      "${UI_DIR}"
fetch arrow-up-right-from-square ph:arrow-square-out-duotone            "${UI_DIR}"
fetch pen-nib                    ph:pen-nib-duotone                     "${UI_DIR}"
fetch circle-question            ph:question-duotone                    "${UI_DIR}"
fetch siren-on                   ph:siren-duotone                       "${UI_DIR}"
fetch skull-crossbones           ph:skull-duotone                       "${UI_DIR}"
fetch hand-point-right           ph:hand-pointing-duotone               "${UI_DIR}"
fetch bomb                       ph:bomb-duotone                        "${UI_DIR}"
fetch play                       ph:play-duotone                        "${UI_DIR}"
fetch arrow-up-right             ph:arrow-up-right-duotone              "${UI_DIR}"
fetch chevron-down               ph:caret-down-duotone                  "${UI_DIR}"
fetch terminal-window            ph:terminal-window-duotone             "${UI_DIR}"
fetch cell-tower                 ph:cell-tower-duotone                  "${UI_DIR}"
fetch broadcast                  ph:broadcast-duotone                   "${UI_DIR}"
fetch bell                       ph:bell-duotone                        "${UI_DIR}"

# Git / changelog activity (Phosphor duotone)
fetch code-commit                ph:git-commit-duotone                  "${UI_DIR}"
fetch code-pull-request          ph:git-pull-request-duotone            "${UI_DIR}"
fetch code-merge                 ph:git-merge-duotone                   "${UI_DIR}"
fetch code-fork                  ph:git-fork-duotone                    "${UI_DIR}"
fetch code-branch                ph:git-branch-duotone                  "${UI_DIR}"
# Phosphor has no "closed pull request" glyph; use the Octicon (MIT).
fetch code-pull-request-closed   octicon:git-pull-request-closed-16     "${UI_DIR}"

# --- Brand logos (Simple Icons) ---
echo "Brand icons -> ${BRANDS_DIR}"
fetch github     simple-icons:github     "${BRANDS_DIR}"
fetch bluesky    simple-icons:bluesky    "${BRANDS_DIR}"
fetch linkedin   simple-icons:linkedin   "${BRANDS_DIR}"
fetch docker     simple-icons:docker     "${BRANDS_DIR}"
fetch instagram  simple-icons:instagram  "${BRANDS_DIR}"
fetch markdown   simple-icons:markdown   "${BRANDS_DIR}"
fetch youtube    simple-icons:youtube    "${BRANDS_DIR}"

echo "Done. $(find "${UI_DIR}" "${BRANDS_DIR}" -name '*.svg' | wc -l | tr -d ' ') icons written."
