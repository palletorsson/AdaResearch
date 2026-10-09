# Random_Remove: restore the candidate grid

The room now has one working removal encounter: a local board of 64 cubes, four visible candidate sets, REMOVE ONE and RESET. The chapter is written to those controls. This recovers the relationship between the remover and its grid at museum scale; it is not a literal reconstruction of the old walkable floor.

## Historical and current evidence

- `ba5c514e9:commons/maps/Random_Two/map_data.json` is the original map name. It places `remove_random` at column 3, row 1 and describes an 8×8 demonstration region. The later room was renamed Random_Remove.
- `ba5c514e9:algorithms/randomness/RemoveRandom.gd` declares the region x=2…9, z=4…11, target y=1. `setup_initial_state()` admits only coordinates for which the host grid has a cube; `execute_step()` chooses an active position, removes its cube and removes an exhausted position from the set. Those declarations establish the intended grid relationship, not proof that every original cell was reachable in that historical build.
- `38c62ea9c:commons/maps/Random_Remove/map_data.json` still embeds the remover in the old grid. Its contemporary script expects `../GridMultiMesh`, or another MultiMesh beneath its parent.
- Before this repair, the current scene contained only the remover script. The script searched ancestors and `current_scene` for a MultiMesh, then could fall back to deleting ordinary scene nodes. An empty range could silently expand to every instance. The museum no longer supplied the old generated grid beside the remover, so these searches were neither a visible candidate set nor a safe room boundary.

Exact historical files, the pre-edit live files and SHA-256 hashes are preserved in `ada_run/random_remove_restore/`. See `before_sources.json` and `after_sources.json`.

## Implemented encounter

`RemoveRandom.gd` now accepts an explicit descendant MultiMesh. Missing or external targets remain unbound. There is no recursive scene search, ordinary-node deletion or expansion of an empty set. The instance data is copied into a private MultiMesh before mutation, so even a resource shared with another scene cannot be altered indirectly.

`remove_random_fixture.gd` builds an owned 8×8 board when `local_grid:true` is supplied. Permanent slot plates and row/column numbers survive removal. Amber cubes are eligible; grey cubes are excluded; a chosen cube turns red before disappearing. RANGE selects columns 2–5 and rows 2–5 (16 cubes), ROW selects row 3 (8), COLUMN selects column 3 (8), and ALL selects 64. Each mode restores the board before selecting its candidates. REMOVE ONE draws without replacement. RESET restores all transforms and cancels any pending highlighted removal. It does not rewind or expose the entire random history.

Only the existing `remove_random:90` map entry at [6,7] gained `#local_grid:true`. Structure, utilities and all other interactable entries are unchanged. The map description now names the working encounter. The source scene registration is unchanged. The coordinating plan agent separately admitted Random_Remove into the existing Soane museum layout and carried the explicit local-grid configuration; this worker did not edit shared plan, registry, roles or progress JSON.

A later placement audit found a stale saved necklace hand with `stamp:true`. The first museum probe had therefore used its old bench positions. The coordinating agent retired only this hall's stamp flag, preserving its saved beads and history. The final rerun uses authored cell [6,7], map-space position (6.5, 0, 7.5), rotation 90° and scale 1; the dark sphere follows its own authored cell [5,8]. All twelve checks pass at that current placement. The final screenshot pair is captured with the desktop camera's view-only reclaim timer stopped, so both images show the same board.

The 486-word `final.md` starts with the board and a countable prediction, then asks the visitor to remove, compare row and column, exhaust a range and reset. Explanation follows observation. Its limit is specific: two orders can empty the same region, while the display remembers only the latest removal. The optional misuse is to stop the random subtraction when a letter appears. The handoff remains 10 PRINT, the actual next room.

## Runtime proof

Godot 4.6 stable ran with the hidden Compatibility renderer. A headless attempt was rejected as evidence because its dummy MultiMesh backend did not retain readable transforms; the completed tests use actual rendering and real MultiMesh instance data.

Run the isolated encounter check:

```powershell
python ada_run/random_remove_restore/run_probe.py
```

`runtime_report.json`: **14 checks passed**. These include all four known candidate counts, sixteen distinct removals of the exact central set, an exhausted set doing nothing, an out-of-bounds empty selection remaining empty even when given the old expand flag, RESET during a highlight, a neighbouring 64-cube encounter staying intact, an unrelated mesh surviving, and a separate node sharing the original MultiMesh resource remaining unchanged. Actions pass through the real `InteractableAreaButton.button_pressed` signal and its button-to-remover connection.

Prepare the private museum snapshot, then check the actual placed encounter:

```powershell
python tools/run_encounter_probe.py Random_Remove --sequence randomness --render
python ada_run/random_remove_restore/run_museum_probe.py
```

`museum_runtime_report.json`: **12 checks passed**. The live museum loaded the explicit local-grid configuration and started at 64 visible cubes / 16 candidates. Physics rays reached all six button detectors without an obstruction. Exhaustion removed precisely sixteen distinct candidates; another press changed nothing. RESET restored 64. All 28 other recorded museum nodes survived, and the approach-floor ray hit the same collider at the same height before and after. The built-in pedestal sits at floor y=0; the button detector centres are y=0.81–1.00m.

The deterministic test seed 20260908 removed indices `[36,26,19,37,34,45,18,28,44,20,43,29,27,21,42,35]`, exactly the sixteen candidates, without duplicates. These are observed runtime results, not a promised sequence for visitor resets.

The fresh screenshots `random-before.png` and `random-after-range.png` beside this note were inspected: the amber central region becomes an empty square with visible slot plates, the grey border remains, and the neighbouring dark sphere remains present behind the board. `python tools/wall_voice.py --map Random_Remove --check` returned zero failures and zero notes.

Durable copies beside this note are `random-museum.json`, `random-sources.json`, `random-before.png` and `random-after-range.png`. The isolated fourteen-check report `random-runtime.json` is unchanged. The final run started at 2026-09-08T08:39:00.450465+00:00. Its manifest records the exact input hashes before execution and separately reports any mutable bake output changes; no non-output source changed during the run.

The engine logs include existing DebugLogger and shader-cache write errors; no errors name either changed removal script. These results cover mechanism, binding, visible geometry and detector access. A headset reach/readability check and an independent learner walkthrough remain open.

## Reusable lesson

Recover the missing relationship from history, then give it explicit ownership. A model that once manipulated its host floor needs either that floor restored locally or a clearly bounded replacement it owns. Make the eligible set visible before the action, preserve addresses after removal, provide a real reset, and test an empty set beside unrelated objects. Apply this pattern only to other rooms with evidence of the same lost dependency; do not generalise by enabling a scene-wide search.

## Files changed by this worker

- `algorithms/randomness/RemoveRandom.gd`
- `algorithms/randomness/remove_random_fixture.gd` (new)
- `commons/maps/Random_Remove/map_data.json`
- `commons/maps/Random_Remove/final.md`
- `ada_run/random_remove_restore/` (source snapshots, two probes, runners, reports, images and hashes)
- This iteration note.

No commits, resets or shared JSON edits were made by this worker.
