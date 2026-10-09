# Two ways to make

The same point returns as an inspector. Move it along the row, read what the neighbours will produce, and trigger one update. Its saved history spreads across the floor. Beside it, the pyramid repeats a placement recipe. Similar shapes give us a reason to compare what their procedures actually do.

## What changed

- **Tutorial:** replace the obsolete Wireworld lesson with the room's actual Rule 90 and recursive-copy comparison. Print all three required files. Teach Boolean inequality, separate old and next rows, a history's space/time axes, and the difference between a state update and a supplied placement recipe. Recursion's derivation waits for Fractals.
- **Reflection:** retain the encounter with resemblance, gaps and bodily support. Add the returning point's changed role and a current image. The same object now inspects a position and advances time; it no longer plants a seed as in the previous room.
- **Interaction:** mount the existing carried-point adapter beside the explorer. Move to inspect; trigger to STEP; release to park. Existing rule, seed, replay and clock controls remain.
- **Room:** preserve all three authored artifact placements and the level floor. Clear incidental sculpture from circulation, remove the extra generic gate and put entry and exit at the thresholds. The desk → recorded floor → fixed pyramid arrangement already works.
- **Wall text:** correct this hall's inherited five-copy caption to six placements, align the explorer caption with the seed comparison, and replace the obsolete Wireworld blurb. The book and shipped catalogue now describe the installed works.
- **Plan:** update this hall's paragraph, learning contract, transfer and evidence. Its review decision remains draft. No sequence reorder.

## What repeats, and what does it read?

Rule 90 reads the old left and right cells. The next cell is occupied when those values differ. The centre does not affect this rule's answer. A new row is written before replacing the present, and earlier snapshots stay intact.

The pyramid reads a position, spacing and remaining depth. Its installed configuration makes six recursive calls: four lower corners and two upper positions, including an extra crown. Spacing halves; the final cube size does not. Some instances overlap. Depth three gives the learner 216 leaf entries; the installed depth four gives 1,296. The supplied recipe matches the source, including its overlaps.

Changing the seed alters the cellular record while every pyramid transform stays fixed. This provides an executable distinction between similar-looking constructions. It makes no claim that this finite image proves an ideal fractal's dimension or computational universality.

## A small independent edit

Change `seed_sites` from `[16]` to `[14,16,18]`. Before running, predict the next occupied addresses. Shared neighbours cancel: the first new row contains only **13 and 19**. The cube construction retains the same 216 positions.

R replays the student's edited beginning. C returns to the built-in single/pair comparison. The exact edited file is executed by the test, rather than testing only an equivalent helper call.

There is also a useful boundary: from the single seed on a 32-cell ring, generation 15 has sixteen occupied cells. Generation 16 is empty. The two directions meet through the periodic boundary and XOR cancels the paired contributions. The apparent growing triangle belongs to a finite system.

## Full code in the existing museum

`procedures.gd` contains the row update and supplied copying function. `comparison.gd` creates the history table, fixed miniature, support, materials, labels and input. `point_body.gd` is byte-identical to the previous hall. These files run on the existing Day Zero `PointStudy`, with its supplied player, camera, lighting and XR Tools. There are no missing prepared study children.

The compact reconstruction fixes Rule 90 and holds at 24 recorded rows. Enter or the held trigger steps; R replays; C switches seeds. The museum supplies its wider VR controls and scrolls its last 24 rows across the floor. The small cubes are visual instances on a solid plinth; they do not recreate each large prefab collider. These differences are stated in the tutorial.

## Evidence

**29 learner checks and 38 museum checks pass in native Godot 4.6.** The tutorial's three code blocks are extracted, byte-compared with the maintained files and executed.

All eight Rule 90 cases and 240 mixed-start updates agree with the installed general evaluator. Recursive positions, in order, agree with the actual pyramid procedure at depths 0 through 4. Tests cover independent snapshots, periodic wrap, the empty generation, instance transforms, table support, seed/replay controls, the 24-row limit and supplied XRTools pickup/action/release in a translated and rotated study. The three-seed transfer passes. Two deliberately wrong procedures—OR instead of XOR, and writing into the row being read—fail the expected results and are detected.

Museum checks exercise the real point and desk controls, exact chronological floor record, all 768 available floor transforms, colour, scrolling and replay. All 1,296 cube transforms remain fixed after the seed and point actions. A supplied CharacterBody walks across the drawn dark cells on the solid floor without modifying the record. Four routes contain **158 layer-1 capsule and level-floor samples**. Both portal approaches are supported. Camera assertions are included in the museum total.

The first learner run caught a real typed-array assignment error; the printed code now uses `assign`. The first colour assertion was too strict for native MultiMesh storage. Its final measured maximum RGB channel difference is **0.00009766**, below one 8-bit channel step. State and transform checks remain independent of that tolerance. Both first-pass diagnostics are preserved.

The explorer algorithm, floor receiver and pyramid source remain byte-identical to this pass's baseline. Final logs contain no SCRIPT ERROR or Parse Error; existing unrelated engine warnings remain. The learner miniature is mounted temporarily only for its photograph.

## Still to review

These are native engine captures and supplied-pose interaction tests, not a physical headset session. Quest performance, full portal transfers, independent student acceptance and the secondary film's complete interaction are untested.

Existing blank frames remain visible. The image review caught a caption saying “five copies” although this configuration makes six calls. That caption and the explorer's inherited Rule 110 slogan are now replaced with the actual six-placement and changed-seed comparisons. Native checks confirm both captions appear in the hall. Other halls' captions are outside this review.

## Read and inspect

- [Tutorial left · reflection right](parallel.html)
- [Full tutorial](tutorial.html) · [Full reflection](final.html)
- [Tutorial Markdown](tutorial.md) · [Reflection Markdown](final.md)
- [procedures.gd](printed/procedures.gd) · [comparison.gd](printed/comparison.gd) · [point_body.gd](printed/point_body.gd)
- [Learner checks](checks.json) · [Museum checks and routes](museum/report.json)
- [Learner log](engine.log) · [Museum log](museum/engine.log)
- [First learner diagnostics](diagnostics/first-pass/learner-engine.log) · [First museum diagnostics](diagnostics/first-pass/museum-report.json)
- [Scoped changes](changes.diff) · [Review ZIP](ca-comparison-review.zip)

Next: **CA_EdgeOfChaos**. Keep the procedure fixed and follow one changed starting value through two nearly matching volumes.
