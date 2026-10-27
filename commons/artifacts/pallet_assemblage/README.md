# Euro pallet / hand assemblage

The human supplies the relation between parts. A saved collection names an arrangement;
it does not create a weld, a joint, or a claim that the sculpture balances.

## Current floor12 study / temporary AND

The Melencolia workshop now uses `config.study = "pallet_and"`. Its twenty original
pallet pieces form a shallow sloping channel: two blocks are physical obstructions
that the player moves by hand. With either obstruction left in place, the ball stops;
clearing both lets it reach TRUE. A white inverted cone stands on its narrow tip at
the exit, on the horizontal timber sheet. The actual ball impact topples it. Its
convex collider has an 8 mm flat tip so it can balance under gravity; it is dynamic
during a run, with no joint, balance motor or scripted fall.

The sheet is **2.4 × 1.2 × 0.018 m**, resting loose on four hollow **0.4 × 0.2 × 0.2 m**
cinder blocks: exactly one course. Cross-feet, spacer stacks, track boards and rails
retain their original pallet dimensions. All are independently grabbable/editable.
The former tall control pillar is replaced by a small plywood control tag.

The current tower uses `track_height: 0.6`: four loose timber packing crates lift
the single cinder course so the board's top is exactly **0.6 m above the floor**.
The four buttons face upward in a shallow black/pink control strip along its near
edge, like a model-car track controller. Their centres are at approximately0.632m.
Spare timber rests at the far edge so the approach and controls stay clear. The
crates are four separate editable groups, and the saved reachable recipe has
32 groups in total. Earlier saved low-board recipes retain their0.218m profile.

The active study now also uses `board_count: 2`: **two 2.4 × 1.2 m sheets end to
end**, giving a4.8m base at the same0.6m height. Eight crates and eight cinder blocks
support both sheets. Four additional loose1.2m runway boards let all twenty original
pallet pieces remain at their original sizes, with continuous rails around the
longer channel. All45 groups, including the extra runway boards, remain separately
editable and the timber can be moved by hand.

The slope is halved. Stations are placed to leave more nearly equal periods of
gravity-driven motion: measured clear-run times are approximately1.92s to X,
4.08s to Y and6.62s to the cone (intervals1.92,2.17,2.53s). No velocity or passage
time is imposed on the ball. Earlier one-board saved recipes keep their own layout.

BALL releases the white sphere from above the track; it can also be picked up and
dropped by hand. RESET restores this arrangement. SAVE keeps the twenty timber
pieces plus sheet, four cinder blocks, ball/release group, controls and TRUE cone in
one reusable definition. The environment poses live in the same canonical term,
and its geometric build expression includes all groups. Workbench previews use
the native exported meshes, including the cinder blocks' open cells.

`tools/run_pallet_logic.py` checks all four AND cases through physical ball contacts,
tip balance while blocked, the actual impact, and a saved-copy reload. Receipts and
views are in `ada_run/pallet-logic/`; `tools/check_pallet_logic_editor.cjs` checks
the full editor/catalogue roundtrip and preservation of every other tower record.

## Plain pallet exercise

The workshop is on **floor 12 / Melencolia**, at `[-4, 4.8]`. Without the study option,
the plain 1.2 × 0.8 × 0.144 metre pallet sits on two 60 cm support cubes.
It has eleven timber boards and nine spacer blocks, each an independent XRTools
pickable with a box collider and the existing chamfered construction-timber finish.
The support cubes and control pillar are separately editable environment parts.

- Desktop: right click to pick/release. Scroll changes carry distance. While holding
  pallet timber, **X / Y / Z** turn it 15 degrees; **Shift** reverses the turn.
- XR: pick the same timber with the existing pickup hand and turn your wrist.
- **PLACE**: released pieces stay at their poses, including unsupported poses.
- **GRAVITY**: release the loose pieces to genuine Jolt gravity and collisions.
- **SAVE**: release your held piece, then capture all twenty parts as a new prefab.
  Saving creates a timestamped name and a stable recipe ID; it never overwrites an
  existing sculpture. New instances start in PLACE so the saved arrangement survives.
- **RESET**: restore this workshop's starting pallet; saved recipes remain.
- **RECOVER**: restore the last local SAVE draft, including after a restart or failed
  connection. SAVE retries the same draft key; editing it makes a new save attempt.

The web app must be running for the shared save. Desktop defaults to
`http://127.0.0.1:3003`; `VOID_EDITOR_URL` or the scene's `editor_url` can select
another address. A Quest using USB needs the existing local server forwarded with
`adb reverse tcp:3003 tcp:3003`, plus an APK containing this new artifact. No physical
headset test or APK deployment is claimed by the synthetic-hand checks.

## Reuse and identity

`commons/modular/terms.json` is the canonical recipe. `pallet_hand_kit` is a new
hand-ready recipe derived from `eu_pallet`, `plank` and `cube`; the original modular
`eu_pallet` sketch remains unchanged. The kit uses a non-overlapping physical stack
and real pallet dimensions. Each board/block retains its ID, dimensions, role,
source, full local position and YXZ rotation when saved. A bounded pickup/place
event history records the human operations, without inferring connections.

`/api/handmade-prefabs` validates the twenty known pieces and writes a new immutable
pose recipe into that catalogue. The server derives the capacity-tree nodes,
workbench definitions, player-inventory entries and live-editor library entries
from it. A saved asset is distinct from an actual placed world instance.

Open `/prefab-workbench` and choose Melencolia, or refresh its tree after SAVE.
Use **Stage in live editor** to place a copy on any floor. The editor's player
inventory also refreshes its available recipes. A newly opened library includes
them under Handmade assemblage. Individual parts stay movable, rotatable and
copyable; the editor saves their overrides in the existing shared `rooms.json`.

The native and Three.js modular builders preserve explicit assemblage part IDs.
The workbench and lab editor reuse the real exported timber GLBs from the floor12
workshop, with saved poses applied to them. Saving a new sculpture needs no new
Godot export. All authored floor data from before this addition is preserved.

## Evidence and maintenance

- `python tools/run_pallet_assemblage.py`: production desktop pickup, supplied XRTools
  hand placement, offline-save recovery, real HTTP save, recipe/kernel reload,
  native editor-pose roundtrip, and Jolt gravity.
- `python tools/run_pallet_assemblage.py --capture`: rendered native views, including
  the real Melencolia placement. The example sculpture is a demonstration, not a
  claim of structural stability.
- `node tools/check_pallet_editor.cjs`: actual GLBs, catalogue/tree identity,
  independent production editor transforms/copy, validation, source preservation,
  rejected incomplete saves and idempotent retries.
- `node tools/check_pallet_types.cjs`: changed shared catalogue/bridge modules.
- `python tools/export_void_floors.py 12 ada_run/pallet-assemblage`: refresh native
  geometry only when the kit/support/control meshes change; uses the native OS lock.

Receipts and screenshots are in `ada_run/pallet-assemblage/`. One hand-built example
is retained in the catalogue; superseded probe recipes were archived there.
The complete web repository has pre-existing unrelated TypeScript errors; the
changed catalogue modules type-check independently.


## Material support AND

The active floor-12 study uses `logic_grammar: supports`. X and Y are original
145 × 78 × 100 mm pallet spacer blocks placed across two 120 mm openings. Three
original 800 mm transverse bearers, turned along the route, carry the ball. The
route occupies 2.64 m of the 4.8 m stage; every original timber dimension stays
unchanged. Four loose standard boards form low side guides. Original bottom
boards make real catches below the openings; spare deck boards are stacked at
the far edge. Both inputs are present by default. Remove either support to test
failure; put it back by hand to restore the physical route. There is no snap,
input flag controlling a floor, scripted ball velocity or timed result.

The clear Jolt run reaches X around 1.88 s, Y around 3.03 s and TRUE around 3.98 s.
This is an observed rhythm, not an equal-interval target: a longer anticipation,
two distinct crossings, then a shorter impact approach. Missing X or Y produces
an actual fall onto the base sheet and a wooden catch. The cone receives no
success action; the ball must strike and topple it.

`logic_grammar` is retained in the shared handmade recipe and live-editor
placement. Older recipes default to `blockers`, preserving their previous
semantics and saved poses. All 45 groups remain independently editable. See
[logic-grammar.md](logic-grammar.md) for the material and staging rules.

Validation: `python tools/run_pallet_supports.py`, then the capture variant,
`python tools/export_void_floors.py 12 ada_run/pallet-supports`, and
`node tools/check_pallet_supports_editor.cjs`. Native jobs use the shared OS
mutex. Receipts and actual-render screenshots live in `ada_run/pallet-supports`.


## Parallel support OR

`study: pallet_or` uses the same `supports` grammar and temporary 0.6 m two-sheet
stage. A separate floor-12 station sits at (-9.75, 5), beside the existing AND.
Every previous floor record and the twenty original timber dimensions are kept.
Four original deck planks form two shallow converging lanes, one spacer block
bridges the gap in each, and the fifth deck plank receives either route before
the shared inverted cone. The four additional 1.2 m planks supply outer edges.
Cross-bearers and stacked spacer blocks visibly carry the route. Low timber
catches receive unsuccessful balls below the raised paths.

BALL releases two real white Jolt balls simultaneously, one on each route.
Slightly different starting places stagger their arrivals without a timer. The
balls can collide with one another. X and Y are physical pieces, not switches
that select or enable a hidden route. A cone contact gives TRUE; two actual falls
give zero. In the tested setup X alone reaches the cone at about 3.93 s and Y
alone at about 4.12 s. No support causes both balls to fall by about 2.53 s.

SAVE retains all 46 independent groups, including the second ball/release and
all environmental pieces, in the same canonical handmade catalogue used by the
tree, workbench, inventory and lab editor. OR previews use the OR station's own
native exports; AND previews continue to use the AND station. RESET restores the
assembly, and supports can be removed and replaced by desktop or XR pickup.

Validation: `python tools/run_pallet_or.py` checks 00/01/10/11, pickup and return,
cone impacts, moved/rotated saved OR with Y alone, and the existing AND's 10/11
behaviour after the shared ball-factory extraction. `tools/stage_pallet_or.py`
validates and appends the OR record only after those checks pass. The capture
variant renders actual geometry, then `tools/export_void_floors.py 12
ada_run/pallet-or` and `node tools/check_pallet_or_editor.cjs` verify editor
models, placement and save parity. Receipts and screenshots: `ada_run/pallet-or`.
