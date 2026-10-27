# Matter and Logic — native port review

All 15 downloaded source pages have native Godot studies in the separate
`matter_logic_reference` trial: 36 study floors, 1007 independently editable parts,
983 referenced artifact GLBs and 24 label-only parts.
The earlier main-floor-12 pallet sketches are preserved. Standard floors remain
42 × 18 metres with six-metre storeys. This is a source-comparison collection,
not acceptance of final staging in the main spine.

The ZIP SHA-256 is `3f27f1855f783beca8eb8c42a408172ecc8bd066c06f1bb057924260c0a78daa`. Every original archive file still matches
the local source copy byte for byte. Source canvas texture recipes and Three.js
mesh recipes were reconstructed as native assets; screenshots are from Godot.

| Source page | Trial floors | Focused receipt in ada_run/matter-reference |
| --- | --- | --- |
| Matter Gates | 1, 2, 3, 4, 5, 6 | `gate-checks.json` |
| Marble Gate Boards | 7, 8, 9, 10, 11, 12 | `marble-checks.json` |
| Tyre, plank and wedge | 13 | `chain-checks.json` |
| Stack and queue | 14 | `stack-queue-checks.json` |
| Call stack | 15 | `program-flow-checks.json` |
| If / else loop | 16 | `program-flow-checks.json` |
| List loop | 17 | `program-flow-checks.json` |
| Prefab loop | 18 | `program-flow-checks.json` |
| Material programs | 19, 20, 21, 22 | `material-program-checks.json` |
| Material pipelines | 23, 24, 25, 26 | `material-program-checks.json` |
| Almost and Just | 27, 28, 29, 30, 31, 32 | `threshold-checks.json` |
| Gravity Knitter | 33 | `knitter-checks.json` |
| Rule Knitter | 34 | `knitter-checks.json` |
| Collatz marble machine | 35 | `collatz-checks.json` |
| Collatz knitting | 36 | `collatz-checks.json` |

## Evidence and its limits

- Six full-size gates: all 22 input rows passed with outputs read from native
  bodies. Production pointer RELEASE/RESET and moved/rotated negative-floor
  AND/NAND checks passed separately.
- Marble boards: 18 gate rows plus eight counter increments passed. The tyre
  chain and stack/queue also passed moved/rotated baseline checks.
- Call/loop studies: source default programs reached the real exit with the
  expected outputs and no route errors. This is not arbitrary-program coverage.
- Material programs/pipelines: 19 checks include array indices 0–5, all loop counts
  1–5, IF/IFELSE input values and four physical cup pipelines. The source automatic
  pin timing is explicit auto_pull configuration in these baseline checks.
- All six threshold studies produced finite completed Jolt observations. These
  are physical observations, not assertions of identical Cannon thresholds.
- Gravity Knitter: all 16 pattern/output combinations passed without a computed
  fallback, using rules 0 and 255. Rule 90's direct output also matched its
  neighbourhood rule. A separate actual-floor receipt follows the marble through
  the registered floor rather than assuming an empty test world's clearance.
- Collatz: arbitrary-precision values beyond int64, the full 7 → 1 path with 16
  parity stitches, three separate knitting panels and all 17 base-six decoded
  states passed. Its source machine uses programmed paths, not Cannon gravity.
- The actual desktop player and synthetic XR trackers loaded all 36 study floors.
  This establishes startup/instantiation, not headset ergonomics or a walkthrough.
- Primary controls on all study floors also passed actual rendered desktop clicks
  and synthetic XR triggers. Separate hand checks cover real AND/OR pickup/drop,
  RELEASE/RESET while held, a 1000-frame hold without timing out, and physical
  results after releasing the mover by hand. The source program-flow checks now
  pause a moving machine, verify its physical poses/cursor stay put, resume it and
  check the original outputs. These are not physical-headset tests.
- All 1007 parts passed the real editor model's move/rotate paths. Copies on
  every floor passed the shared save validator using validateOnly; saved layouts
  were not replaced by the test. All referenced GLBs were parsed and contain mesh
  geometry; explicit text-only parts use exported Label3D data.
- The final export completed without runtime errors or resource-leak diagnostics.
  The broader player-load harness reports an ObjectDB shutdown warning; no startup
  or per-floor load check failed. Physical-headset testing remains unperformed.

## Explicit native adaptations

Cannon pair-contact materials become Godot per-body materials. Native planar
guides use joints instead of per-step pose overwrites. The NAND beam needs 50/s
angular damping; marble XOR/NOT/HALF use 1/s sphere drag. The tyre-chain stack
boxes use zero friction while the loose plank retains its supports. The material
array pointer uses .5 friction. These are Jolt calibrations, not source constants.

Almost retains its 44 visible/editable planks but uses a welded 264-segment arc
collision surface for the unedited run, avoiding repeated impacts on overlapping
plank ends. Editing any pipe plank restores the source's individual box colliders.
Its h=1.046 take returns at a native margin around .90; the h=1.12 diagnostic also
returned (about .93), so the source's dial does not guarantee crossing in Jolt.
Just's source dashpot is translated into damping; its baseline tipped with six
grains for a source threshold of 5.6. No Boolean result forces target movement.

Computing pages' large helper floor/table is supplied by the Void slab so it does
not close shafts. Small source pedestals remain. Original tall knitters span
storeys; the images hide neighbouring exhibits and show only one floor slab for
inspection. They do not prove clearance. The Collatz well is aligned to shaft A,
with its native console moved onto standing ground.

Actual-player input testing exposed a separate Gravity Knitter placement defect:
its source marble starts 6.65 metres above the slab and landed on Floor32 instead
of entering the machine. The old entry and collider trace are preserved in
`gravity-knitter-before-shaft-placement.json` and `knitter-placement-before-shaft.json`.
The trial feed now passes through shaft A at root position [-8.25, 0], retaining
its original scale and height. Its controls and spawn are on solid slab beside
the shaft. The corrected trace reaches the actual trough and completes a stitch
without a jam. This fixes the feed; it does not assert complete visual clearance
for every tall frame or a curated multi-floor walkthrough.

The Collatz editor fabric is explicitly a completed-preview sample; gameplay
starts empty and adds a stitch per reading. Knitter screenshot fabrics use the
explicit source COMPUTE mode. Gravity Knitter pauses after three jams instead of
silently using the original source's fallback answer. Native controls provide
selected source presets; a complete replica of every HTML editor widget, all
source programs or the 2D knitting page's stream/schematic modes is not claimed.

## Hands-on controls

- Gates and tyre chain: right-click or XR grip carries loose parts. Beams and
  hinges remain attached. Arrange supports first, then drop the mover or press
  RELEASE. RESET releases the actual hand before restoring the authored homes.
  Holding pauses the observation timer; it does not overwrite the other bodies'
  physical motion. Hand rearrangements can change or break the canonical result.
- Marble boards: DROP feeds the chosen hopper; queued drops retain the source's
  .8–1.3 second spacing. CLEAR removes the delivered marbles and resets rockers.
- Stack/queue: TYPE selects the prefab; PUSH/POP and ENQUEUE/DEQUEUE operate the
  source containers. CLEAR starts a fresh comparison.
- Call/list/loop machines: PRESET, LESS and MORE show the active parameter. RUN
  becomes PAUSE/RESUME. The generated bodies and logical cursor pause together;
  resume restores stored velocities rather than moving a marble to a new station.
  PRESET rebuilds preserve the source rack's edited position and rotation.
- Material programs: X changes condition, index or lap count. Pipelines now wait
  for the player's PULL PINS command after RELEASE; they no longer remove the pins
  automatically before the player can reach that control. RESET replaces them.
- Threshold studies: the setting button prints its actual parameter/value and
  cycles three source settings. Almost also offers source-equation millimetre
  release changes and a measured high-water mark. Just waits for a requested
  grain and a settled needle; automatic source feeding is explicitly selected.
  Each study keeps three measured takes across RESET/REPEAT/preset changes.
  Readable time, angle, energy-height and cooling readings replace raw JSON.
  All six are placed on the north side and east bay of floor 14 / Trans Introduction;
  the existing crossings, logic and user arrangements are retained.
- Knitters: eight switches address patterns 111 through 000, allowing any rule
  from 0–255. RULE selects a preset; SEED cycles single/random/blank; EDGE switches
  blank/wrap boundaries. A random seed stays the same across reset/rule changes.
  The source rule display and output-ball colours follow the selected bits.
  RUN pauses/resumes a live marble, STEP produces one stitch, COMPUTE is an
  explicit mathematical finish, and CLEAR resets. Completed fabric can restart.
- Collatz: START selects a source start value; RUN pauses/resumes; STEP completes
  one reading; FINISH completes the source arithmetic; CLEAR clears the step
  latch. RUN/STEP can restart a finished take. The dead PAGE button was removed
  from the machine; PAGE/METHOD remain on the knitting panels, preserving panel
  identities and authored poses as they are rebuilt.

Local console labels now have contrast against their dark backing. Passive loose
parts explicitly let desktop clicks reach controls while carried; soundscape's
action-signal observation no longer turns them into trigger-consuming tools.

## Reproduce

`python tools/run_reference_probe.py <probe_name>` runs one focused native receipt
under the shared OS mutex. `python tools/export_void_trial.py matter_logic_reference` exports the
built scenes. `node tools/check_matter_reference_editor.cjs` checks the actual
editor/save paths. `reference_player_load` covers actual desktop/synthetic XR
startup; `reference_collection_capture --capture --void-trial=matter_logic_reference` captures
the inspected views. The published gallery links each page to its editor floors
and the untouched browser original. No chapter texts were rewritten.
