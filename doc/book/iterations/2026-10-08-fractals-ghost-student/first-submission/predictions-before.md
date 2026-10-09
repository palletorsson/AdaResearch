# Predictions recorded before execution

I have read the complete packet. No Godot run, teacher probe, outside solution, or runtime observation informs these predictions. These are hypotheses to compare with the frozen first submission. The numerical checks below are derived from the printed rules; several are also supplied by the tutorial and are therefore not independent discoveries.

## Required Synthesis variation

I will change only the initial `recipe` declaration in a separate copy of `recipe.gd`, from three steps to four. Seed `(0, 6)`, retained fraction `1.0 / 3.0`, drawing, helpers and all functions stay identical.

- At startup both LIVE and KEPT should contain 16 intervals because `_ready()` copies the initial recipe.
- Each interval should have length `6 / 81 = 2 / 27` metres, approximately 0.074074074. Their combined model length should be `16 * 2 / 27 = 32 / 27`, approximately 1.185185185 metres. The displayed caption should round that to 1.185 m.
- The first interval begins at 0, the last ends at 6, and each parent contributes two ordered, disjoint end intervals. The one common display scale remains 0.34. Six model metres still span 2.04 physical metres; that bounding span is not the sum of visible bar widths.
- Choosing quarters should leave 16 pieces, each `6 / 256`, totalling 0.375 m. KEPT should remain four-cut thirds unless KEEP is requested. RESTORE should copy the kept recipe; choosing another fraction afterwards must leave KEPT unchanged.
- One `advance()` should reach five cuts and 32 pieces. A further call should preserve the result.
- Because the instruction changes only the initial declaration, `reset_live()` still explicitly resets LIVE to three cuts, not four. KEPT should retain its last saved recipe. That is an expected asymmetry of this prescribed edit, not a reason to silently change a second line.

## My optional composition: a fork whose centre follows a wave

**Question:** Can I move a tree's endpoints while preserving its fork openings and even the final twigs' directions? I choose a periodic influence rather than a random field because I can state the relationships before seeing the silhouette. I want a shared bend by generation, not independently jittered branches or a moving tree.

**Earlier operation:** Waves' `amplitude * sin(TAU * frequency * coordinate + phase)`, and Noise Columns' instruction to name the scalar's receiver. I substitute a parent branch's integer depth for time. The result is static; there is no clock or repeated update of the generated angles.

**Input recipe:** `generations = 3`, `ratio = 0.7`, amplitude 12 degrees, frequency 0.25 cycles per parent-depth unit, phase `PI / 2`. Parent depth 0 is the trunk, depth 1 its children, and so on. Both siblings at each fork receive the same offset; branches at the same depth share a sample. The seed trunk remains length 0.7 at station position `(0, 0.60, 0)`.

**Receiver:** only the construction assignment to `child.rotation.z`: `TURN * sign_value + fork_bias(depth)`. `fork_bias` returns the wave sample in radians, with amplitude bounded to 0–15 degrees. The copied drawing and first-fork grip code remain. The original stays in `reconstructed/Fractal_RecursiveTrees/`.

**Predicted change:** the three sampled offsets are +12, 0 and -12 degrees. The first fork's child angles become -23 and +47 degrees instead of -35 and +35. The next generation uses -35 and +35; the last uses -47 and +23. The outline should lose its mirror symmetry about the original vertical axis. Endpoints should move, while the initial tree remains planar. Because the offsets sum to zero along every three-generation path, the terminal twig directions should return to the original directions before a grip is moved. Their start and end positions need not return: earlier turns have already displaced those attachment points. I have not observed whether this difference is visually legible.

**Expected invariants:** 15 segments; lengths 0.7, 0.49, 0.343 and 0.2401 metres in populations 1, 2, 4 and 8; two children per nonterminal branch; each child origin at its parent's tip; 70-degree angle between a fork's children at construction; finite transforms and unit scale. The existing clamp should still cap scripted generations at four, producing at most 31 segments, and ratio at 0.4–0.8. A rigid turn of the first fork should preserve its descendant lengths and attachments and leave the other first-fork subtree unchanged. The exact wave angle pattern is a construction property, not promised after manual editing.

**Controls for the comparison:** amplitude zero should reconstruct the original transforms, modulo floating-point tolerance. Two fresh instances with identical recipe values should have identical transforms before grips are touched. Changing phase should move the geometry without changing the structural invariants. Frequency is cycles per level, not hertz: treating this static sample as elapsed time would be a different composition.

**Planned observation and revision:** compare the original and variant from in front and from the side. From the side, both initially planar trees may largely collapse to the same thin profile; that would be evidence about the view, not proof of unchanged endpoints. I will choose any later phase/amplitude revision after results and visible evidence are returned. I will not invent an encounter or a reason for a revision now.

## Other hall predictions for the printed scripts

| Hall | Prediction before running |
| --- | --- |
| Recursion | Default sizes 1.8, 1.17, 0.7605; ratio 0.5 still gives three sizes 1.8, 0.9, 0.45. Depth zero produces none. A low ratio can reach the size cutoff before the depth allowance is exhausted. |
| Recursive Trees | Three generations after the trunk produce 15 segments, four produce 31. Ratio changes lengths, not count. A first-fork turn carries its descendants and leaves the sibling family. |
| Cantor | Two releases produce four intervals with total length 8/3; five produce 32 and total 64/81. HISTORY draws 63 bars at five without adding current intervals. A release below the threshold must not advance. |
| Koch / Sierpinski | The student builds Koch only: second step has 16 segments and 17 positions, total 64/9 and endpoint distance 4; fourth has 256 segments and 257 positions. Reversing side reflects this horizontal seed's Y coordinates, while preserving lengths. |
| Menger | Counts 1, 20, 400; edges 9, 3, 1; volumes 729, 540, 400. The selected label still addresses level one at cut two. Keeping only no-middle cells gives 8 then 64, with the same outer bounds. |
| Golden Spiral | The required study has `[1,1,2,3,5,8,13,21,34,55]`, with 10 bars per view; ninth extra request does not append. A held contact should append once until both grips are released. No spiral is built by this script. |

All counts and transformations remain unverified until execution. The optional native probe encodes selected expectations, not evidence that they passed.
