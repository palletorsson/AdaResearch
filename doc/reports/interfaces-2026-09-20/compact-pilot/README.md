# First interface pilot: Pattern Foundry

20 September 2026. This pass starts from the [Foundry encounter review](../../../book/iterations/2026-09-19-tiling-review/opening/DECISIONS.md) and preserves the source, receiver, hold, ownership and recipe experiments described in `commons/maps/Pattern_Foundry/final.md`.

## Applied

- `commons/ui/control_panel.gd`: opt-in columns, maximum row width and row gap. Wrapping measures visual and collision bounds in panel coordinates, preserving authored control sizes and rotations. Larger controls get a wider slot or their own row. Deferred construction receives one settling measurement. Default single-row callers keep their earlier layout.
- `commons/artifacts/pattern_machine_a/recipe_study.gd`: the same eight buttons use four columns. Outer centres move from 2.10 m apart to 0.90 m. The stand narrows from 2.60 m to 1.35 m. The panel and stand are lowered after the first render showed that the added row covered more of the specimens; printed labels use darker ink. Button ordering, callbacks, receiver membership, state and manuscript wording are unchanged.
- All generated panel text remains 2D on surfaces. Older labels elsewhere in the loom and on receiver tags still need migration; this is not a claim that the whole artifact is compliant.

## Evidence

`before-*` and `after-*` are fresh Godot captures of the actual museum, from the same two loom-relative camera poses and field of view. The first attempt crashed during startup while attempting a default user-log write; explicit workspace log paths resolved it. Final rendered runs exit 0. Existing UID, certificate and unrelated museum warnings remain in the logs; no script compilation failures were found in the successful runs.

- `layout-checks.json`: 70 checks on real buttons, pointer handlers, full-size geometry, backing, flat labels, retained readout state, repeated layout, rotated oversized controls and collision bounds. Direct pointer events test the handler chain; this does not test tracked hands.
- `recipe-regression.json`: existing Foundry regression, 101 checks, including saved source restoration, held receivers, relink/undo, equal metre sampling and selected collision approaches. Some actions use signals, others the pointer path; it is not a complete end-user input playthrough.
- `before-capture.json` and `after-capture.json`: actual control centres and 24 hall/capture setup checks each.
- `interim-tall-approach.png`: the first wrapped layout, retained as the reason for lowering the panel before the final captures.
- `changes.diff`: exact changes against the two saved inputs in `before/`, independent of the already-dirty Git checkout.

Headset comfort, seated reach, tracked-hand operation and Quest performance remain untested. Smaller spread is a measured layout improvement, not universal reach certification.

## Adoption and remaining queue

| Finding | Image / encounter | Component or boundary | Next action |
|---|---|---|---|
| Long source/receiver button row | Foundry, `before-approach.png` | `ControlPanel` → `pattern_machine_a/recipe_study.gd` | First placement changed and desktop checks passed; validate in headset before wider adoption |
| Full-size controls can be shrunk by their enclosure | Shared console source, `control_console.gd::_build_body` | `board_width / panel_width` applied to the whole panel | Introduce and verify an opt-in natural-size enclosure policy before wrapping console consumers |
| Older values and captions are still Label3D | Earlier all-controls capture; Foundry receiver tags | Slider/dial child labels and receiver-label builders | Preserve bindings and units while moving text onto 2D surfaces |
| Large panel intrudes into view | QFEP Sandbox, `sandbox-controls.png` in the existing review | Neighbouring display placement and mounting | Inspect source and player pose; reposition/resize while retaining offered/received distinction |
| Readout dominates specimen | QFEP Synthesis, `synthesis-controls.png` | Specimen readout / side controls | Compare a smaller, closer display without removing the pressure/physics distinction |

The QFEP items remain visual findings from the other review, not newly fixed defects. No QFEP files or shared review index were edited. A future rollout must identify the actual configured uses of each changed component; this pilot only adopts wrapping in Foundry.
