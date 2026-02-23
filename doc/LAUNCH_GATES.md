# Launch Gates

This document defines the minimum machine-checked gates for launch readiness.

The goal is to stop guessing and give AI + humans one shared pass/fail scoreboard.

## Source of Truth

Use project JSON and automated audits, not hand-maintained counts in prose docs.

Primary tools:
- `python tools/spine_map_workbench.py sequence-contract --json <file>`
- `python tools/spine_map_workbench.py audit-artifacts --json <file>`
- `python scripts/validate_map.py --all --json`
- `python scripts/audit_lab_chain.py`

## Gate Set

### Gate A: Sequence Contract

Release-critical:
- `missing_declared_maps == 0`
- `duplicate_entries_within_sequence == 0`

Track as warnings:
- `undeclared_map_folders`
- `duplicates_across_sequences` (unless explicitly whitelisted)

Why: sequence flow must resolve cleanly at runtime.

### Gate B: Artifact Registry Integrity

Release-critical:
- `unresolved_scene_files == 0`
- `missing_scene_path == 0`
- `unsupported_scene_path == 0`

Track as warnings:
- missing curation fields (`include_in_map_data`, `map_ready`, `map_sequences`)
- `algorithm_without_curation`

Why: maps must not reference broken artifact scenes.

### Gate C: Map Validation (Global)

Release-critical:
- `grade F maps == 0`

Strongly recommended before launch (optional strict mode):
- `grade C maps == 0`

Why: ensures baseline map mechanics and registry references hold.

Runner default: grade-C is tracked but non-blocking. Use `--max-grade-c 0` to make C blocking.

### Gate D: Lab Progression Continuity

Release-critical:
- no `LOST` lines in `scripts/audit_lab_chain.py` output

Track as warnings:
- `CHANGED` lines (can be intentional but should be reviewed)

Why: Lab progression must not accidentally delete prior state.

## Execution

Run all gates:

```powershell
python tools/run_release_gates.py
```

Save JSON report:

```powershell
python tools/run_release_gates.py --json-out doc/reports/RELEASE_GATES.json
```

Save markdown report:

```powershell
python tools/run_release_gates.py --md-out doc/reports/RELEASE_GATES.md
```

Strict map mode (`C` also blocked):

```powershell
python tools/run_release_gates.py --max-grade-c 0
```

Use dashboard/tooling gate toggles:

```powershell
python tools/run_release_gates.py --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json
```

Ignore toggles (evaluate all gates):

```powershell
python tools/run_release_gates.py --ignore-gate-toggles
```

Strict enablement mode (fail if any gate is OFF):

```powershell
python tools/run_release_gates.py --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json --require-all-gates-enabled
```

## CI Policy

Workflow file:
- `.github/workflows/release-gates.yml`

Policy:
- `main` and `release/*`: strict mode enabled (`--require-all-gates-enabled`)
- pull requests targeting `main` or `release/*`: strict mode enabled
- `dev` and other branches: toggles are honored without strict enablement

Shared toggle file:
- `doc/reports/RELEASE_GATES_TOGGLES.json`
- Dashboard and CLI both read/write this file.

## Operational Rhythm

- Run on every major merge.
- Run before any release candidate build.
- Keep thresholds stable for one sprint at a time.
- If a threshold changes, commit that change explicitly with rationale.
