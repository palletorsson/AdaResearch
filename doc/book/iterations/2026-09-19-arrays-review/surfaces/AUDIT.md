# Arrays surface studies — 19 September 2026

Two map-local presentation repairs were made. Both manuscripts remain byte-identical to their frozen 18 September review sources.

## Decision

Keep the six floor comparisons and their return as six walls. The texts already earn the distinction between a stored unit and a perceived figure, and between a picture and its physical backing. The review correctly identified interference from the environment. Strengthen that encounter before revising its language.

The progression remains: address → arrangement rule → perceived figure → surface orientation → time in the following disco hall. No artifacts were removed, no prose was cut, and no sequence order changed.

## What was wrong, and what changed

**Floor overlap.** `tiling_principles.gd` intentionally places its six floor images 0.025 m above its own origin. Grid auto-grounding then finds that image as the bottom of the artifact and lowers the whole artifact by 0.025 m. Fresh actual-museum ray measurements found all six images at world y=0, coincident with the floor: the striped render was z-fighting, not a new tiling rule. The map token now reads `tiling_principles:0:0#mode:floor`. Its explicit zero Y offset invokes the existing authored-placement contract and skips auto-grounding. All six images now sit 0.025 m above the unchanged collision floor. No shader, artifact implementation or collision was altered.

**Competing magenta edges.** Both maps inherited `cube_scene.tscn`'s magenta wireframe and pink emission. `show_grid=false` does not disable this mesh material. Each map now uses the existing `settings.color_overrides` mechanism: neutral `0.69, 0.69, 0.69, 1.0` base/edge colours, zero emission, edge width 0.1. The actual runtime uniforms were measured. No shared material behavior changed.

The local colour parser requires comma-separated RGBA, not hexadecimal. An initial hex attempt fell back to white and was corrected before acceptance. Its captures/logs remain under `intermediate-hex-fallback/`. Likewise, `wireframe_opacity` is listed by the override mapper but absent from this shader; this repair does not rely on it.

## Text diff

There is **no manuscript diff** for either hall. Current/frozen source hashes are in `verification.json`. These lines can now be read against a clearer image:

- Floor: “The unit that you notice need not be the unit stored by the program.”
- Floor: “Their dark triangles are not holes, and the apparent ridges do not lift your feet.”
- Walls: “The backing, with its separate collision, is what stops your body.”

Map-only diffs: `Tutorial_Tiling_Floor-map.diff` and `Tutorial_Tiling_Walls-map.diff`. Snapshots were taken before editing.

## Paired actual-museum captures

The probe creates the live endless museum, with isolated control/override/hand paths. Before and after share camera positions, 1400×900 viewport, 74° FOV, Vulkan/mobile renderer, X-R off and audio dummy. Neither pair is AI-generated. The pictures capture the same six-field configuration with exception off and motif phase zero.

| Hall | Before | After |
|---|---|---|
| Floor, inside | `before/Tutorial_Tiling_Floor-inside.png` | `after/Tutorial_Tiling_Floor-inside.png` |
| Floor, entrance | `before/Tutorial_Tiling_Floor-entrance.png` | `after/Tutorial_Tiling_Floor-entrance.png` |
| Walls, inside | `before/Tutorial_Tiling_Walls-inside.png` | `after/Tutorial_Tiling_Walls-inside.png` |
| Walls, entrance | `before/Tutorial_Tiling_Walls-entrance.png` | `after/Tutorial_Tiling_Walls-entrance.png` |

**Capture limitation:** existing `ada_run/runtime_flags.json` has `_capture_active=true`. Grid generation therefore applies per-height instance colours, which take precedence over the neutral base material. The blue/grey horizontal wall bands in these actual-state captures are that debugging tint; the global file was left untouched. These images establish removal of bright magenta/emission and repair of the floor overlap. They do not depict a fully monochrome environment. No capture-only resetting of colours was used.

## Verification and remaining questions

Fresh after runs: **Floor 15/15, Walls 15/15**, plus **20 evidence assertions** in `verification.json`. These verify actual map loading and unchanged structure, six fields, floor/wall modes, isolated exception mutation, motif mutation, monochrome image values, live material uniforms, manuscript hashes, paired images and floor clearance. Both after runs exited zero with no script errors. Engine startup still reports the known UID/certificate diagnostics; these were not represented as lesson failures.

The source remains the current working project, not the frozen review bundle. Source and before/after map SHA-256 hashes, measured coordinates, commands, process IDs, timings and logs are retained. The first copied-probe launch had an indentation parse error; the failed log is preserved under `before/parse-failure-*`, and the corrected script ran all captures. All owned processes ended.

Headset control reach, human recognition of ONE EXCEPTION at a distance, and the rhythm of walking through all six fields remain embodied checks. The exterior sky, pink exit utility and incidental figures still introduce colour outside the study; this bounded fix does not redesign them. The lesson images are monochrome, and the local repaired architecture no longer emits magenta edges.

## Wall-pair state check

Both runs execute the same probe reset at `capture_surfaces.gd:97`: `phase=0; exception=false; refresh()` before capture. The wall artifact token and generator are unchanged; the wall-map diff contains only material settings. A direct black/white segmentation of 30,000 corresponding pixels inside the QUARTER TURN panel gives 100.0000% agreement (`wall-pair-pattern-check.json`). This supports the same visible motif state. Runtime texture byte hashes were not recorded, so this is not presented as an independent texture-byte comparison.
