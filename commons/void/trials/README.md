# First maps as adaptation trials

Palle's direction, 19 October 2026: make the first map of every sequence to
learn what adaptation each kind of map needs and what capacities we have.

Read the current spine, then `briefs.json`, then `reviews.json`. The web board is
`http://localhost:3003/void-trials`. Its notes save here, separately from the floor
layout. `python tools/void_sequence_trials.py --check` checks the source inventory.

## Contract

The current spine has 25 sequences. The Void has 14 curated Primitives floors;
Grid shares Trace. Existing code is evidence of an implementation, not proof
that every imported artifact works. Do not mark a first map complete because
its scene loads or an editor GLB exists. Do not infer a whole sequence is ready
from its opening.

For each trial: encounter -> source artifact -> tower adaptation -> observable
test -> evidence -> reusable capacity -> later exception. Keep desktop and VR
as input adapters to one game. Preserve user placement, fixed frame and shafts.
Keep tutorial and reflective writing distinct. Check their spatial references
after placement; do not rewrite either automatically.

`briefs.json` contains provisional authored choices, not revised curriculum.
`void_sequence_trials.py` follows live curriculum/sequence order, inventories
original placements and scene paths, and flags changed openings or missing
sources. It does not choose the teaching focus or generate floor placements.
`reviews.json` stores human observations, next changes and evidence references.
The board records source fingerprints so a source change requests a fresh review.
Scene script dependencies and performance are not covered by that fingerprint;
rerun the relevant native probes after code changes.

## Test levels

1. Source check: original scene/configuration and texts exist.
2. Native check: load the actual scene; assert the selected operation; repeat,
   reset, leave/return and check bounded work. Record renderer and source revision.
3. Desktop observation: clear arrival, readable comparison, reachable controls,
   real interactions, editor save/reload and unobstructed descent.
4. Physical headset observation: same result with actual hands; eye readability,
   comfortable reach, stereo rendering and measured performance.

A review stage is an author's report, not an automated proof. Add an evidence
path or a concrete observation. A failure becomes a specific adaptation task,
not a reason to replace the artifact's principle.

## First next trial

Transformation / Trans_Pre: still collectible cube -> rise -> rise and turn ->
rise, turn and pulse -> short construction route to finished pickups. Retain
the original scenes, lerp motion curve and demo/collect distinction. Verify
player detection in the Void, local movement after relocation and repeat/reset.
Introduction now supplies the passenger/collision trial below this opening.

Palle chose separate selectable trials on 19 October. The curated Primitives
tower stays intact. `playable.json` registers built trials; unbuilt briefs remain
on the board without pretending to be playable.

## Play and arrange

Main menu -> Void trials -> Transformation. This uses the shared Void player,
health, atmosphere and frame. Pre occupies floor 1; Introduction is on floor 2,
with an empty structural floor above and a catch floor 3 below. R / B restores
the current encounter, including collected cubes and trial score. Retrying
from the catch floor returns to Introduction. M / left X returns to the menu.

`http://localhost:3003/lab-editor?mode=void&trial=transformation&floor=1`
uses `transformation/rooms.json`, with separate autosave, browser drafts,
revision checks, backups and Desktop/Ada Void/trials/transformation/rooms.json.
It cannot save over the curated `commons/void/rooms.json`. Real mesh previews
are exported separately under `/void-trials/transformation/`.

## Repeatable checks

- `node tools/test_introduction_editor.cjs`: 41 exported parts and seven route walls; copy, move and
  turn through production editor functions. Writes a real platform-copy fixture
  for the native test without changing the saved layout.
- `python tools/test_introduction_crossing.py`: Pre's B descent, walk up wp,
  board, ride both ways, step off, jump, fatal fall/retry, editor-copy passenger
  motion and streaming. Desktop plus synthetic tracked XR. Add `--capture`
  for native Mobile screenshots.
- `python tools/test_transformation_two_shafts.py`: complete Trans_Pre route,
  both real shaft drops, original cube behaviours and ordinary-tower pad regression.
  Add `--capture` for native Mobile screenshots.
- `node tools/test_transformation_two_shafts_editor.cjs`: real exported parts,
  copy/move/turn, save validation and Desktop mirror agreement.
- `python tools/test_void_trial.py --capture`: actual original scenes, desktop
  and synthetic tracked XR rig; saves isolated from the user's museum progress.
- `node tools/test_void_trial_layout.cjs`: trial save isolation and stale writes.
- `python tools/export_void_trial.py transformation`: original native geometry.
- `python tools/test_game_menu.py trial --out ada_run/void-trial-test/menu-renderer`:
  real mouse input -> picker -> staging -> trial -> return -> normal tower.

The authored Trans_Pre route is the regression fixture. If its placements or
teaching intention change, review the navigation checks too. Synthetic XR does
not certify headset comfort, stereo readability or performance.

First lessons from the trial: continuous ramp for both player capsules; local
score provider for original pickups; explicit Void health provider for recovery;
collected nodes may be gone when streaming callbacks run; retry must restore
content and clear cached floor residency together. Introduction now tests
passenger movement; rotation and scaling under a passenger remain later work.

## Trans_Pre / the two shafts

The trial now arrives through A and leaves through B. Their centres stay open;
two narrow marked boards cushion each landing. Per-floor `descent.pad_shafts`
selects A on the encounter floor and B on the catch floor. Other layouts keep
their existing default B. The trial still starts on floor 1 beside the arrival.
Left Y returns to its roof to try the first drop.

Read the original still -> rise -> turn -> scale comparison first. Walk around
the south bank of B, then climb the original wp onto a one-metre cube platform
in the east wing. Collect four finished cubes and leave through B. The route
turns around the permanent pillars at the north and south ends.

`transformation/pickup_walkway.json` composes 24 original unit blocks and six
original wp ramps. Their geometry/collision come from Primitives; the arrangement
is new. The shared factory accepts a recipe path, while Cube keeps its own recipe.
All 30 pieces and three captions are independently editable. The old 0.6 m timber
route and redundant second assembly are no longer placed in this trial.

Evidence: `doc/book/iterations/2026-10-19-transformation-two-shafts/`.
No chapter text or curated tower arrangement changed.

## Introduction / movement becomes support

Arrive through B from Pre. Enter the central bay, climb the same wp ramps onto
one-metre cubes around the lethal pit, wait for the travelling four-cube deck, ride to the far bank,
and walk down the opposite ramp. The ferry returns automatically and can carry
the visitor back. The A corner landing reaches the catch floor below.

`transformation/introduction_crossing.json` defines 28 fixed cubes, six wp ramps
and five captions. The scene adds the existing Void ferry as a fixed editor
anchor with a travelling child, plus a lethal surface: 41 independently editable parts in total.
The four-cube deck travels three metres between the banks of the five-metre
pit. The two tower shafts remain open for descent. Move/turn/copy the anchor to relocate its whole route. Its runtime
motion does not change the saved anchor. The two work lights and route marks
remain editable too. The editor's GLB is a static preview; ride it in Godot.

The original `tc` movement is reused through the existing Void rider adapter.
The test caught the original boarding timer cancelling an empty auto-return;
the adapter now preserves automatic cycling after a visitor steps off.
Death on Introduction returns to floor 2 rather than restarting Pre.

Evidence: `doc/book/iterations/2026-10-19-introduction-carried-crossing/`:
The original shaft crossing passed 95 desktop/synthetic-XR assertions and nine
editor checks. The newer central pit passes 121 desktop/synthetic-XR assertions
and eleven editor checks. The preceding Pre regression passed 112 checks. Physical headset
comfort/performance and the older full-menu shutdown caveat remain unverified.
The travelling crossing is built; Introduction's growing and rotating crossings
are not part of this pass. Tutorial and final texts remain unchanged.

Latest placement: `doc/book/iterations/2026-10-19-introduction-hazard-pit/`.
The raised pit adds `LethalPit`, one editable part containing the visible red
surface and its damage volume. Contact near the feet kills through shared Void
health; leaning above it and riding remain safe. It is one metre deep in the
block construction, not a new hole through the slab. Seven editable unfinished partitions now separate arrival and exit, blocking
the cube-rim and side bypasses. The original growing/turning crossings remain
later adaptations.
The test records a retained-resource shutdown error in one run and a successful
rerun; this older teardown issue is not claimed fixed.

## Noise / Random_Noise_Types (20 October)

Main menu -> Void trials -> Noise. Start on floor 1 beside the shaft B boards. The six
original artifacts keep their museum configuration; the sampling bench carries the
explicit seed 31415. The east wing holds the single point, the bench, the Uncertain
Surface and the two miniature galleries on one-metre concrete blocks; Related Weather's
three glazed walls partition the central bay, with its controls at the north end and
the gold line toward shaft A. Leave through A onto the catch floor; R / B rebuilds the
encounter floor (the seeded bench returns identical).

`http://localhost:3003/lab-editor?mode=void&trial=noise&floor=1` edits
`trials/noise/rooms.json` with its own autosave, backups and Desktop mirror.

- `python tools/test_noise_types_trial.py` (add `--capture` for Mobile screenshots,
  `--measure` for floor-local bounds): desktop and synthetic XR; bench accounting,
  determinism and bounded failure, fixed-glass collision, gallery audio across floor
  residency, both drops, retry and re-entry.
- `node tools/test_noise_types_trial_editor.cjs`: copy/move/turn/save/reload/restore
  through the production editor code and API, with isolation hashes.
- `python tools/export_void_trial.py noise`: real geometry for the editor.

Report: `doc/book/iterations/2026-10-20-void-noise-types-trial/index.html`.
