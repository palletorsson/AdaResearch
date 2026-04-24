# Git hooks (versioned)

Install once per clone:

```sh
git config core.hooksPath githooks
```

## What runs

**`pre-commit`** — two checks, in order:

1. Blocks accidental commits of `openxr_action_map.tres` (local VR input tweaks that must never ship).
2. Runs the coverage gate (`tools/check_coverage.py --skip-regen`) when the commit touches files that can move coverage numbers: map data, artifacts, registries, or spine text files.

The coverage gate is fast (< 1 s with `--skip-regen`, ~5 s with regeneration) and only triggers on coverage-affecting changes.

## If the coverage gate fails

Regenerate the reports:

```sh
python tools/map_coverage.py
```

If the new state is intentional and you want to accept the new numbers as the baseline:

```sh
python tools/check_coverage.py --write-budget
git add doc/reports/COVERAGE_BUDGET.json
```

The budget file (`doc/reports/COVERAGE_BUDGET.json`) is the durable baseline. Raising a budget is a deliberate act and shows up in the diff.

## Running the gate manually

```sh
python tools/check_coverage.py              # regenerate + gate
python tools/check_coverage.py --skip-regen # gate only
python tools/check_coverage.py --verbose    # show the current state
```
