#!/usr/bin/env bash
if test "$BASH" = "" || "$BASH" -uc 'a=();true "${a[@]}"' 2> /dev/null; then
  # Bash 4.4, Zsh
  set -euo pipefail
else
  # Bash 4.3 and older chokes on empty arrays with set -u.
  set -eo pipefail
fi
shopt -s nullglob globstar

mkdir -pv gs/jlucktay-factorio-asia/

gsutil -m rsync -r -u \
  -x "saves/_autosave.\.zip$|saves/_autosave.\.tmp\.zip$|saves-.*/.*\.zip$" \
  gs://jlucktay-factorio-asia/ \
  ./gs/jlucktay-factorio-asia/
