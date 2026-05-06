# Shortcuts

Quick toggles, contexts, and recipes — things to find fast. Each entry has a
**title**, a **kind** (`toggle` / `command` / `note` / `context` / `recipe`), a
short description, optional **tags**, and either a runtime **flag** name or a
shell **command** the user can copy.

The encyclopedia surfaces this file at `/shortcuts` with search, tag filters,
and inline buttons that flip flags or copy commands.

Add new entries below in the same shape. Keep titles short and imperative
("Turn biome off for clean captures", not "Biome").

---

## Turn biome off for clean map captures

**Kind:** toggle
**Tags:** capture, biome, debug, screenshot
**Flag:** `biome_enabled`
**Default:** `true`

The biome ring renders vegetation, particles, and atmospheric layers around
every grid map. For debugging map architecture or running clean captures, the
biome obscures the grid. Flip this flag off to skip biome generation entirely.

When `biome_enabled = false`, `GridSystem._handle_biome_ring()` returns early
on map load and `BiomeAccrualManager` doesn't apply. Walls, floor, utilities,
interactables render normally. Vegetation, foliage, particle systems, the
ambient ring — all skipped.

Restore by flipping the flag back to `true`. The change takes effect on the
next map load (no restart needed).

---

## Run multi-angle capture for a single map

**Kind:** command
**Tags:** capture, godot, screenshot

```
godot_console --path . --xr-mode off --no-window \
  --script res://commons/testing/capture_multi_angle.gd \
  -- --mode=map --target=<MapName>
```

Output goes to `%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots/<MapName>/{front,left,right,above}.png`.

Click **Run capture** on `/maps?name=<MapName>` for the same effect via the
encyclopedia. Combine with `biome_enabled=false` (above) for clean,
architecture-only captures.

---

## Regenerate spine-coverage indexes

**Kind:** command
**Tags:** coverage, audit, indexes

```
python tools/artifact_doc_index.py
python tools/map_coverage.py
```

Updates `doc/reports/ARTIFACT_DOC_INDEX.json` and `doc/reports/MAP_COVERAGE.json`.
Reads on every `/coverage` page load via the encyclopedia API; refresh those
JSON files to pick up new artifact docs or placement edits.

---

## Re-import the spine into Auto-InDesign

**Kind:** command
**Tags:** book, auto-indesign, import

```
curl -X POST -H "Content-Type: application/json" \
  -d '{"adaResearchPath":"C:/Users/palle/Documents/GitHub/AdaResearch_46"}' \
  http://localhost:3000/api/import-spine-maps
```

Re-builds the 5,950-page spine book using the latest text + captures + walker
traces. Returns the new project id. Open in `/preview/<id>` or `/editor/<id>`.

---

## Walker census refresh

**Kind:** command
**Tags:** walker, coverage

```
curl http://localhost:3003/api/walker-census?refresh=1
```

Forces a fresh walker run across all 179 spine maps. Cached for 90 seconds
otherwise. Results show on `/coverage` walker track.

---

## Coverage gate locally

**Kind:** command
**Tags:** ci, coverage, gate

```
python tools/check_coverage.py            # regenerate + gate
python tools/check_coverage.py --skip-regen
python tools/check_coverage.py --write-budget
```

Asserts all map-coverage invariants against `doc/reports/COVERAGE_BUDGET.json`.
The pre-commit hook runs this when coverage-affecting files are staged.

---

## Install the versioned pre-commit hook

**Kind:** command
**Tags:** git, ci, setup

```
git config core.hooksPath githooks
```

One-time per clone. Wires `githooks/pre-commit` (OpenXR action map guard +
coverage gate). The hook is fast; only runs the coverage gate when files
that can move coverage numbers are staged.

---

## Generate template-gallery screenshots for a blog post

**Kind:** command
**Tags:** book, blog, screenshots

```
cd ../auto-indesign
node scripts/screenshot-templates.mjs
```

Writes 14 PNGs into the encyclopedia's `public/blog/` folder via Puppeteer
against the running Auto-InDesign on port 3000. Used as blog post images.

---

## Where the canonical files live

**Kind:** context
**Tags:** layout, paths

```
commons/maps/<MapName>/         the map's text + map_data.json
commons/artifacts/registry/     artifact catalogue per category
commons/maps/curriculum_spine.json     the 19 spine sequences
commons/maps/sequences/<id>.json       one sequence's map list
doc/reports/                    coverage / walker / artifact-doc indexes
doc/HOOKS.md                    132 seed sentences
doc/SHORTCUTS.md                this file
ada_run/runtime_flags.json      toggleable runtime state
ada_run/desktop_feedback.md     VR feedback bridge from Godot
```

---

## Capture all grid mutator patterns

**Kind:** command
**Tags:** mutators, capture, grid, debug, screenshot

```
godot_console --path . --xr-mode off --no-window \
  --script res://commons/testing/capture_mutator_cycle.gd \
  -- --grid_size=16 --outdir=user://mutator_shots
```

Builds a self-contained 16×16 MultiMesh, mounts `GridColorMutator` and
`GridVisibilityMutator`, captures one PNG per named pattern and a combined
color×visibility matrix. Output: `%APPDATA%/Godot/app_userdata/Ada Research
Zero One/mutator_shots/<channel>_<pattern>.png` plus `capture_report.json`.

Use this to verify any change to the mutator substrate (`commons/grid/mutators/`)
hasn't regressed visuals. Add a new expression file → re-run → visually diff
the new shots against the previous run.

---

## VR-mode quick reset

**Kind:** note
**Tags:** vr, debug

If maps load in editor preview but the grid generation skips silently,
check that `auto_load_map_on_ready = true` on the GridSystem node in the
scene. Some debug scenes flip this off and forget to flip it back.
