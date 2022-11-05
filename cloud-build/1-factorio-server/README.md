# Factorio server VM image

- machine-type: used `c2d-standard-4` ✅
  - only one CPU was really seeing much use ✅
  - memory usage was low, ~13GB free ✅
  - go for 2x cpu, 8gb memory next time ✅
    - `c2d-standard-2` ✅

- add `-o "GSUtil:parallel_process_count=1"` to `gsutil` calls ✅
  - only for scripts executed locally, potentially from a Mac ✅

- syncing factorio/mods/* to server?
  - env var: `UPDATE_MODS_ON_START`
    - <https://github.com/factoriotools/factorio-docker/blob/master/docker/files/update-mods.sh>
  - propagate `mod-list.json` and `mod-settings.dat` to factorio/mods/ directory
