# Capacity tree: evidence behind status

19 October 2026, second pass on `/capacity-tree` (encyclopedia). The page had
started inferring that an object stands in the Void from its museum hall, from
a scene path under `commons/void/`, from the word "Void" in a note, from a carry
record, or from membership of `Trans_Pre`. This patch replaces that with records.

## What changed

- `src/lib/capacity-evidence.ts` (new): a pure resolver over rooms files. A
  placement exists only when a record names the token, a record names another
  token with the same scene file, a configured assembly's exported member is a
  declared and file-verified mapping, that member's factory built it, or a placed
  piece instances the original scene. Copies carry `editor_source`; `only_parts`
  frees every other child, as `lines_area.gd` does. 38 members are declared;
  each is checked, on load, against the script that preloads the scene and
  against the export manifest. A failed check is reported and not counted.
- `src/lib/capacity-artifacts.ts`: location, editorial role and verification are
  separate fields. `stage` is the strongest configured location, or `proposed`
  when nothing exists. Trial reviews are carried with their date, caveat, the
  evidence paths they cite (existence and file time), and whether the trial's
  rooms file changed after the review. The source fingerprint is not reproduced
  here; the page says it is compared on the trial board.
- `src/app/capacity-tree/artifacts.tsx`: the strip separates "where configured"
  from "editorial", with definitions; the detail panel lists every record with
  its basis and files, then museum halls, then a verification table (source,
  native test, physical VR). Sequence cards show the review stage with date and
  caveat, and seven measures with hover definitions.
- `scripts/test-capacity-evidence.cjs` (new): sixteen checks, negative first.

## Before / after

`before-after.json`: seven authored objects change headline. Six over-claims
drop (grid-and-hall inferences; `void_beam` is source-only because no record
configures the descent assembly). One under-claim is recovered through a chain:
`construction_cube` is instanced by the cube walkway on floor 7 and in the
Transformation trial. `wp` loses floor 13 (map grid only) and gains the walkway.

| object | before | after |
|---|---|---|
| draw_dot | In Void (hall) | tower floor 4 · `record` / Bead10mm, Bead40mm, Bead80mm · assembly member · trace_area.gd |
| tetra_blocker | carried fl 6 (carry flag) | tower floor 6 + carried · `obstruction` / TetrahedronBlocker + 3 copies via 6/obstruction |
| wp | carried fl 6, 13, trial | tower floor 6, 7 + trial · instanced inside wedge blockers and the walkway |
| void_beam | In Void (note) | source only · no record |
| transformation_bay | proposed | none + proposed |

## Results

- `verification.json`: 16/16 checks; 228 records resolved for 133 objects;
  authored: 28 tower, 1 trial, 76 museum, 1 source, 1 proposed; 38/38 members
  verified; no evidence notes.
- `checker.json`: the existing `check-capacity-artifacts.cjs` still passes.
- Project typecheck: no diagnostics in the capacity files (the repo has
  pre-existing errors elsewhere). Dev server renders the three views; the first
  attempt broke the client bundle by value-importing the loader (`fs`), fixed by
  moving shared constants into the evidence module.

## Not tested, still uncertain

- No Godot run: nothing here says a placed object loads or works.
- Assembly members without a declared mapping (set dressing, captions, the
  Void's own line bodies) resolve to no record; the panel says unknown.
- The trial fingerprint is not compared here. The "rooms changed after review"
  signal is file time only.
- Nothing is committed in either repository.
