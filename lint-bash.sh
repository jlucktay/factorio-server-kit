#!/usr/bin/env bash
set -euo pipefail
shopt -s globstar nullglob

### NOTES
# Linters called by this script are (where possible) configured to follow Google's shell style guide:
# https://google.github.io/styleguide/shell.xml

readonly FACTORIO_ROOT="$(git rev-parse --show-toplevel)"

# https://github.com/mvdan/sh
find -x "$FACTORIO_ROOT" -type f -iname "*sh" \
  -not -path "*/.git/*" \
  -print0 \
  | xargs -0 -n 1 shfmt -w -s -ln=bash -i=2 -bn -ci -sr

# https://github.com/anordal/shellharden
find -x "$FACTORIO_ROOT" -type f -iname "*sh" \
  -not -path "*/.git/*" \
  -print0 \
  | xargs -0 -n 1 shellharden --check --replace --

# https://github.com/koalaman/shellcheck
find -x "$FACTORIO_ROOT" -type f -iname "*sh" \
  -not -path "*/.git/*" \
  -print0 \
  | xargs -0 -n 1 shellcheck --enable=all --exclude=SC2250 --severity=style --shell=bash --external-sources --

# Exclude: https://www.shellcheck.net/wiki/SC2250
# Prefer putting braces around variable references even when not strictly required.
