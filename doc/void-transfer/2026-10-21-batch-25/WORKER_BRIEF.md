# Batch 25 worker brief (from the Claude coordinator)

Read first:
- `doc/void-transfer/2026-10-21-batch-25/CLAUDE_TASK.md` (the contract);
- `doc/void-transfer/GODOT_TESTING_FOR_AGENTS.md` (testing rules and known traps);
- `tools/probes/void_transfer_probe.gd` (shared probe and `input_*` helpers);
- the reference trial `commons/void/trials/randomness_03/` (`probe.gd`, `HANDOFF.md`,
  `REQUESTS.md`, the adapters);
- also `commons/void/trials/wavefunctions_05/probe.gd`.

## What you may and may not do

- **Write only your own trial folder(s).** Placement scripts, adapters and notes go
  inside them.
- **Never launch Godot.** That includes native, export, editor and headless parse
  checks. The coordinator runs every Godot job serially, one at a time.
- **Python checks are allowed:**
  - `python tools/audit_void_transfer.py <trial>`
  - `python tools/validate_void_rooms.py --trial=<trial> --editor`
  - a jsonschema check against `commons/void/rooms.schema.json`.
- **Do not edit shared code:**
  - `commons/void/*.gd`, `floor_content.gd`, catalog, `playable.json`, schema;
  - `tools/`, `tools/probes/`;
  - source artifacts, maps, `final.md` / texts;
  - other trials.
- **No git operations:** no commit, stash, reset or checkout.
- **No broad scans:** never walk `ada_run/` or search recursively from the repo root.
  Use explicit paths, or `grep` limited to named folders.
- **No curation, no text rewrites.** Keep the 42 x 32 m floor, 6 m storeys, the
  pillars and both shafts. Add no walls or ceilings. Never shrink an exhibit.
- **Shared fixes go in your trial's `REQUESTS.md`,** each with:
  - the evidence, labelled static or measured;
  - the exact hook code;
  - the adapter path in your folder.

  Codex owns the shared side; do not make the fix yourself.

## Placement contract

- **The floor dict:** `{id, artifact, station, position:[x,z], facing, height, scale, config}`.
  - Config values are strings; a bare `#key` becomes `"true"`.
  - `station` is S if z ≥ 0 else N, then E if x ≥ 0 else W.
- **The rigid 180° turn:** `x = cx - col`, `z = cz - row`, chosen so the source spawn
  (`s`/`sp`) lands on the arrival (0, 12). Facing = (yaw + 180) mod 360.
  - Keep the token height and scale. Check what the height is relative to. Random_Remove's
    3 was measured from a basin floor; the museum reports in
    `../ada_encyclopedia/captures/` and `commons/maps/<Map>/` notes can tell you.
- **Fixed obstacles:**
  - shafts at x = ±10, z = 0, each opening 5 x 6 m (x ±7.5..12.5, z −3..3), full storey
    height;
  - water risers at (±6.5, −4.2) and electrical risers at (6.92 / −6.08, −4.2);
  - columns 0.9 m at x ∈ {±5, ±14, ±20}, z = ±14;
  - the default floor sign at (3.5, −7.8), 3.7 x 1.65 m from 0.525 m up;
  - the arrival around (0, 12);
  - shaft A's landing pads, x −9.07..−7.53:
    - odd floors: z 0.8..3.0;
    - even floors: z −3..−0.8.
- **Move a placement only for honest fit or access,** and record the rigid position, the
  new one and the reason. Report external extent, protrusion into another floor, missing
  support (the source's `structure` plinths and basins) and source-empty dependencies.
- **Read each artifact's script, not only the token:**
  - Which config keys are actually read, and when? A reader that only acts in
    `apply_grid_config()` without rebuilding needs `configure_before_ready` (a shared
    request).
  - Look for world-space assumptions (`global_position = <local value>`), standalone
    UI/CanvasLayers, `_unhandled_input` keys (R, Space, C, B, T, M collide with the Void),
    Camera3D/WorldEnvironment, GridSystem dependencies, and Area3D groups such as
    `player` vs the Void's `player_body`.
- **If the live museum plan differs from `map_data.json`, report it.** It is in
  `commons/data/museum/em_plan.json`, rows with `map == <Map>`. Follow the inventory and
  do not substitute.

## Probe (`<trial>/probe.gd`)

- **Inheritance and structure.**
  - `extends "res://tools/probes/void_transfer_probe.gd"`.
  - Override `focused_checks(tag)` per floor and `capture_floor()`. Use inside-tower,
    eye-height views where access matters.
  - `expected_empty_source(node)` covers measured-empty sources only.
- **Debug cases.**
  - `debug_cases()` must include `bounds-1` … `bounds-N`, one per floor. Each runs
    `inspect_floor`, fit checks and printed per-entry bounds, as in randomness_03.
  - Add one case per risky interaction.
  - The coordinator runs the bounds cases first and sends you the measured bounds.
- **Fit check.** Copy randomness_03's `fit_checks()`: whole shaft openings, arrival,
  floor sign, and any basin box from a neighbour floor, with the `shrink_mm` contact
  tolerance.
- **Real input.** Use the shared helpers:
  - `input_aim_camera`, `input_grab_preflight`, `input_grab`, `input_tip_to`;
  - the `press()` and `pointer_drag()` variants from randomness_03.

  Label API, geometry and measurement checks in their names.
- **Measured traps:**
  - **XR Tools type names.** Never write `is XRToolsPickable`, or any XR Tools class, as
    a type in the probe; it breaks the XR Tools compile. Use
    `has_method("is_picked_up")`.
  - **Desktop pointer layers.** The pointer sees only layers 19/21/23. A lever is dragged
    by its layer-19 `InteractableHandle`, not its layer-1 bar.
  - **Grab layers.** The desktop grab mask is 393220 (layers 3/18/19), and the XR grab
    area uses the hand's `grab_collision_mask`. A pickable on layer 1 is ungrabbable:
    report it, with `input_grab_preflight` evidence.
  - **Empty sources.** A source that builds nothing exports no GLB and breaks the editor
    test. Write a trial `prepare_editor_preview()` marker script (randomness_03's
    `*_preview.gd`) and request the hook.
  - **Negative AABBs.** Never call `AABB.grow(-x)`; zero-thickness meshes produce an
    engine ERROR. Use `shrink_mm`.
  - **Adapters.** A trial adapter that swaps a script must keep the scene's exported
    overrides; list them in the request. It must also stay correct after the placement
    moves or rotates and below world zero.

## Status file (`<trial>/STATUS.json`), updated at each transition

```json
{"trial":"<id>","worker":"<A|B|C|D>","stage":"reading|placing|probe|ready_for_native|blocked|fixing",
 "ready_for_native":false,"floors":{"1":"<Map>"},"placed":0,"moves":[],"requests":[],"open_questions":[],"notes":""}
```

Set `ready_for_native: true` only when all of these hold:
- every inventoried ID is placed once;
- `rooms.json` passes the schema and the editor validator;
- `audit_void_transfer.py` passes;
- `probe.gd` exists, with bounds and focused cases.

Then finish with a short reply: the state, what the coordinator should run first, and
any questions. The coordinator will send native results back to you for fixes. Write
`HANDOFF.md` and `transfer-status.json` drafts as well; the coordinator completes them
with native, export and editor evidence.
