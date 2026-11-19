# Descent becomes part of the subject

Palle's reference is a broad stepped slide beside a staircase: a sequence of large
plates lets momentum, contact and the brief absence of support become an encounter.
The request also makes subtraction into a way through the Boolean floors, and wave
functions into different slides and extravagant stairs.

## Installed routes

- Forces: ten connections, from `Vectors_Act1_WhatAVectorIs` through
  `Vectors_Act5_ForceAsPlace` (floors 48–58 at initial publication). Four broad inclined plates
  have real 45 cm step-offs. A separate stair lane provides the other route.
- Wave Functions: eleven connections from `WaveFunctions_Intro` through
  `WaveFunctions_Synthesis_Lab` (65–76 at initial publication). S-shaped, eased, rippled and enclosed
  chutes alternate with three 1.5-turn fan staircases. The stairs have 12.5 cm
  risers, changing tread widths, inner/outer rails and repeated balusters.
- Boolean: two connections, `Boolean_Verbs` → `Boolean_Gallery` → `Boolean_Works`
  (161–163 at initial publication). A fitted deck in shaft B has a real two-metre square absence. The
  openings alternate between the north and south ends; the next floor retains
  a solid receiving pad. This is a one-floor drop, not an uninterrupted shaft.

The last floor of each sequence does not automatically acquire an exit to a
different subject. The existing routes remain available. Exterior connections
use a side without an existing large playground wing at either endpoint.

## One editable installation grammar

`commons/void/sequence_descent.gd` / `.tscn` provide the shared scene, registered
as `sequence_descent` in `commons/void/catalog.json`. Each placement in
`commons/void/rooms.json` has its own ID, position, facing and config:

```json
{
  "kind": "wave_s",
  "drop": 6,
  "source_map": "WaveFunctions_Intro",
  "destination_map": "WaveFunctions_Pendulum",
  "destination_floor": 66,
  "connects_next_floor": true,
  "tower_services": false
}
```

Kinds: `jump_terraces`, `wave_s`, `wave_eased`, `wave_ripple`, `wave_tube`,
`maximal_stairs`, `boolean_drop`. Boolean adds `hole_z: -1.5` or `1.5`.
The ordinary room editor can move/select/remove each installation. The drop and
destination must match the actual adjacent levels; a position edit must preserve
the floor overlap and the receiving pad. These are physical connections, so an
arbitrary move is not automatically a valid route.

`tools/install_sequence_descents.py` resolves sequence membership by map identity
and calculates level differences from the current layout. It is an initial
placement/update tool: rerunning it intentionally replaces these routes' authored
poses and configuration. It preserves all other artifact IDs and room contents.
After inserting floors, regenerate/review the destination indices and previews.

## Movement and performance

Wave chutes reuse `columns_pipe_slide.gd` and `pipe_slide_provider.gd`, including
desktop carry and the XR movement-provider priority contract. Motion goes through
the collision solver; there is no camera tween or teleport. Guided speed is capped
at 3 m/s. Forces, Boolean drops and stairs retain normal player movement/gravity.

`connects_next_floor` keeps the departure route live when floor streaming changes
focus. Exit colliders carry the destination floor identity. The exterior supports
join the existing `void_exterior_walk` contract. Repeated boxes share a MultiMesh
per material; rails and slide beds use bounded meshes. No dynamic lights are added.
Quest frame time and headset comfort still require measurement on the device.

## Research loop

Start with a single descent, then change one condition: step-off versus continuous
support, linear versus eased height, or open versus enclosed chute. Preserve the
configuration and ask what the body anticipated that the surface did not provide.
For Boolean, the consequence of subtraction is a route; what remains determines
where the fall can end. For Waves, the same six-metre difference is distributed
over different curves. Neither route style establishes a universal learning order.

Observe the departure, interruption of contact, landing and ability to return via
stairs. Record whether a route creates a question or simply becomes an obstacle.
Keep room and text claims tied to what is actually traversable.

## Verification and next iteration

`tools/test_sequence_descents.py KIND [--render] [--synthetic-xr] [--map=NAME]`
runs the actual tower with isolated saves. Evidence lives under
`ada_run/sequence-descents/`: install receipt, per-kind checks, native logs and
rendered views. It checks real descent, supported arrival, lower-floor activation,
route residency, bounded guided speed and release after relocation. The approach
bridge is tested by walking from the tower edge. The first run caught a bridge
rail across the mouth; the rail now stops before the turning apron.
The XR stair check also caught a flat entry plate overlapping the first two
treads. The entry now meets their radial edge, and the probe requires every
tread to be traversed in order rather than accepting a fall to the exit.

Desktop checks cover every route geometry, including the mirrored Forces route.
Synthetic XR checks cover the S chute, fan staircase and second Boolean opening;
the first Boolean opening is checked with the desktop walker. These exercise
actual collision and floor streaming, not only generated geometry.

`tools/publish_sequence_descents.py` publishes the 23 installed route previews
through the existing incremental exporter. Models remain in the canonical C:
store; other artifact previews are retained. Publication receipts are saved in
`ada_run/sequence-descents/publication/`.

Publishing floors 51–53 exposed an existing crate-template error in
`commons/artifacts/mesh_merge.gd`: the gravity-oval props build their template
outside the scene tree, where global transforms are unavailable. The merger now
composes local ancestor transforms for detached templates. A regression probe
(`tools/probes/mesh_merge_template.gd`) compares all 36 box vertices through a
rotated, scaled hierarchy against the same hierarchy in the live tree. Publication
still rejects native errors; no diagnostic was suppressed to pass this export.

Completed evidence: 11 traversal cases / 120 checks passed; room validation has
no errors. All 23 route GLBs return HTTP 200 from the local editor, match their
authored configuration and resolve to the C: model store. The final publication
retains all 2,294 artifact IDs from its preceding manifest. See `verification.json`
and `publication/verified.json` in the evidence directory. Quest deployment followed
this initial verification, as recorded below. Floor numbering has since changed;
use stable map names and `evidence/routes.json` for the checkpoint's route list.

## Requested Quest follow-up

Palle subsequently requested an updated standalone Quest build and entry into
the Color sequence. Version 20 (`2026.11.19-sequence-descents`) is built with
`tools/export_quest_game.py --freeze-source --out ada_run/sequence-descents/quest`.
Install through `tools/deploy_quest_game.py` with `-r` semantics, retaining saves.

The debug main menu accepts a one-time `user://void_launch.json` containing
`{"map":"Color_Context_Placed"}`. It resolves the stable map identity, waits
five seconds for the XR session, consumes the request and calls the ordinary
`_open_void_floor` staged path. With no request, menu behavior is unchanged.
`tools/verify_sequence_descent_apk.py` checks all 23 packaged routes and runs
`tools/probes/quest_color_launch.gd` against extracted APK bytecode with isolated
saves. Build, installation and device evidence are in the `quest/` directory;
do not infer installation completion from the build receipt alone.

The completed export had the known Windows teardown crash after `[ DONE ] export`;
ZIP integrity and the required runtime payload passed. Retention comparison against
the exact installed APK caught 337 absent cached `.scn` museum cartridges. They
were also absent from the frozen stage, although every one still existed in the
working source and was byte-identical to the installed APK. The cause of that
stage loss is not yet established.

`tools/repair_descent_apk_retention.py` restores only that exact, checked set,
preserves the original APK and `build-original.json`, aligns the repaired APK,
and signs with Godot's existing debug certificate. Certificate identity, ZIP CRCs
and alignment are checked. The active build receipt records the original hash,
the repair provenance and the new hash. No missing-resource check was relaxed.

Headset review: walk the approach, try both terraces and their stairs, release the
stick in each chute, stop on each Boolean landing, and descend the fan staircase.
Record comfort, perceived scale, route visibility and any collision with nearby
exhibits. Adjust one route before repeating that change across its family. The
native test is not a substitute for this embodied check or a Quest performance run.

Quest deployment completed on 2026-11-19: version 20 installed with its APK hash
verified on-device. All eight backed-up progress/construction files remained
byte-identical through installation. The packaged launch probe passed for Color
floor 28, all seven route types and all 23 connections; 35,194 prior resources
were retained. The first device launch failed creating the Vulkan window; a
second immersive launch succeeded. Fresh Quest 3 telemetry at y = -180 and the
device's completed TheVoid scene-load log confirm arrival at Color_Context_Placed.
Evidence: `ada_run/sequence-descents/quest/quest-status.json`, `device-color.log`,
`quest-launch.json` and `packaged-color.json`. Headset comfort and route performance
remain embodied checks, not conclusions from this launch verification.
