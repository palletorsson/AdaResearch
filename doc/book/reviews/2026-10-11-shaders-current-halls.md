# Shaders — text and current halls

11 October 2026. Six halls, in the existing order. This pass reconciles the current working museum with its saved plan and sharpens a few distinctions in the writing. It changes no printed learner code or artifact implementation.

## Reading decisions

| Hall | Decision |
| --- | --- |
| Shaping | Keep the current circle-on-receivers introduction. The earlier claim that everything is flat no longer describes the hall. |
| Patterns | Make the coordinate fold explicit in the reflection: repeating a mark does not require copying a body for every tile. |
| Materials | Keep the current distinction between a lighting response and geometric height. Preserve its handoff to Water. |
| Water / FBM | Hold the pool's phase before comparing viewpoints. Put the rack's exact frequency and amplitude defaults in the tutorial. Treat eight octaves as the slider limit, not a universal visibility threshold. |
| Pink | Describe the competing lighting and emission contributions in the reflection. Put the older sphere's emission coefficients and the frame-dependent bob explanation in the tutorial's optional return. These do not describe the new three-amount recipe. |
| State | Distinguish an appearance of growth, an unconnected request for previous state, and an actual completed field supplied to the next update. Close the sequence by naming what its surfaces answer to. |

The tutorial explains construction, inputs and operations. The final asks what those operations permit us to perceive, do and mistake. Existing code remains visible in the tutorial; none was added to the reflection.

## Saved plan

The six Shader rows now derive directly from each current `map_data.json`, using `tools/em_map_halls.py:derive_row`. Their authored dimensions and orientations are retained. Applying the older template-width normalization here would rotate the Materials hall and no longer describe its current setting.

| Hall | Authored footprint, cells | Placed artifacts |
| --- | --- | ---: |
| Shader_01_Shaping | 22 × 20 | 4 |
| Shader_05_Patterns | 37 × 62 | 9 |
| Shader_11_QueerRubber | 34 × 18 | 4 |
| Shader_09_FBM | 26 × 29 | 3 |
| Shader_12_PinkExtravaganza | 39 × 37 | 4 |
| Shader_10_ReactionDiffusion | 25 × 29 | 3 |

The plan includes the shaping wall, patterned passage, material parlour, composition stage and state chamber. The pool token now selects the 11 × 11 m water study; the basin is open around the separate glass bridge. Existing supporting artifacts remain. The legacy museum-key entry follows the first Shader hall. Other chapters' plan rows and baked records are unchanged from the start of this pass.

These are authored map footprints. The runtime adds its entrance and passage treatment; baked cells therefore need not have the same row number as map cells.

## Checks and limits

- Godot 4.6, headless, XR off: six-hall bake completed with exit code 0. All 27 artifacts placed verbatim; zero slid, zero left behind, zero artifact refusals.
- No script or shader errors in that run. The project reports an unresolved default audio-bus UID, `uid://rwex60pqapc`, at startup, and leaked objects at shutdown. This pass does not claim a clean project-wide runtime.
- Every printed code block in the six tutorials is unchanged from the start of the pass. This was a prose/placement check, not a new ghost-student execution or a headset trial.
- The map, registry and implementation fingerprints in `2026-10-11-shaders-current-halls.json` identify the working sources checked. The shared checkout contains other pending work; this is not a claim that a clean checkout of this text/plan commit includes all pending museum implementation changes.

Source receipts: `patterns_tile.gdshader` and the repeated-mask passage; `shader_09_fbm.gd` and `fbm_basic.gdshader`; `basin_water.gd`, `water_study.gd` and `layered_water.gdshader`; `shader_12_pinkextravaganza.gd` and `drag_extravaganza.gdshader`; the state chamber's `field.gd`, `field_step.gdshader` and `field_view.gdshader`; the older reaction-diffusion rack and its unbound sampler. The following sequence remains Cellular Automata, beginning with `CA_Introduction`.
