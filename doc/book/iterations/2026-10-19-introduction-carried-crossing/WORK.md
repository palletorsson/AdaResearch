# Introduction / carried crossing — 19 October 2026

Request: same cubes and wedges, ride across a gap, editable, desktop/VR checks,
native screenshots. Wait with rewriting tutorial/final. Implemented in the
separate Transformation trial, floor 2 below Pre; curated tower untouched.

Source intention: original Trans_Introduction final.md's travelling cube changes
position while preserving size/facing, carrying a visitor. Only this first
crossing was adapted. Growing/turning crossings are later work. Original museum
map_data.json, final.md and tutorial.md for Pre/Introduction retain before hashes.

## Files and behavior

- `commons/void/trials/transformation/introduction_crossing.{json,gd,tscn}`:
  original wp + shared unit blocks; 18 fixed cubes, six ramps, five captions;
  existing portal ferry is the 30th part. Fixed editor anchor, moving child.
  Same part export/configuration path as Cube and Pre. Source metadata points
  to Primitives_Polythedra and Point_Animatedcube.
- Trial rooms: floor 0/1 preserved, Introduction floor 2, catch floor 3.
  Arrive via B, cross shaft A, descend A. Frame is unchanged except one added
  catch storey and A landing selection. No extra holes or bridge floor.
- `ride_platform.gd`: keep automatic departure running after detector exit.
  The original museum tc cancels the start timer; tests exposed empty ferry
  getting stuck when stepping off during the near-bank pause. Override only
  the Void adapter. Original transport controller and ferry factory unchanged.
- `game.gd` + trial playable definition: retry floor routing, 0/1 -> 1,
  2/3 -> 2. Death/retry on Introduction doesn't force replaying Pre.
- Trial catalog and native GLB exports refreshed. Lab editor floor 2 visibly
  lists 30 parts and saved status; 34 model snapshots loaded including lights.
  Copy/move/turn API fixtures validate without altering the saved user layout.
  Native test rides the actual editor-created copy loaded from editor-copy.json.
- Existing Pre/menu probe fixtures accept the added floor and count Pre's own
  artifacts rather than including newly streamed Introduction artifacts.

## Evidence

- `tests/checks.json`: 95 passing assertions, production desktop + synthetic XR.
- `images/checks.json`: 48 passing native Mobile assertions and five captures.
- `editor-checks.json`: 9 checks, including saved project/Desktop agreement.
- Previous Pre `tests/checks.json`: 112 checks pass with the extended trial.
- Both directions, camera/body carry, step off, jump, under-platform rejection,
  real shaft fall/recovery, reset, streaming, copy/rotation supported.
- Physical headset not tested. Existing Jolt solver-bias warning, headless
  refcount/ObjectDB shutdown warnings remain. Full-menu integration was not
  rerun; its older renderer/shutdown caveat remains separate.

## Play / next

Main menu -> Void trials -> Transformation. Start Pre floor 1 and use B's marked
landing for Introduction. Editor: /lab-editor?mode=void&trial=transformation&floor=2.
R / B retries the current encounter. Review in headset before stronger claims
about comfort or performance. Next teaching work can develop Translation or
the other Introduction crossings, subject to user direction. Do not rewrite
the two chapter texts without a new request. Preserve curated placements.
