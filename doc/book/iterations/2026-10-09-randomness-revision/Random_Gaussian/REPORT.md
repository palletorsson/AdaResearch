# Keep the values, change the bins

**Eighth of fourteen Randomness halls revised.** A retained list becomes a histogram. The required comparison stays with two laws, uniform and Gaussian; the point supplies the familiar hand control.

## The next capacity

Random Walk kept the order of accepted positions. Here the learner keeps sampled numbers, then counts how many belong to each interval. Arrays, counts, conditions and loops already have a purpose in the spine. The new distinction is between drawing a value, retaining it, and grouping it for display.

The code uses the installed cabinet's guarded Box–Muller recipe for Gaussian sampling. Mean and standard deviation become parameters the learner can change. The recipe is explained without making its mathematical derivation a prerequisite. Poisson, exponential, the Galton board and the paint-splatter refusal remain encounters in the hall; they are not four additional required implementations.

## One point, four actions

The unchanged PointBody from earlier lessons controls the comparison as it did in Random Rotate. Hold it over one of four labelled positions and press the trigger. Moving it alone draws nothing.

| Action | What changes | What stays |
|---|---|---|
| +100 | Appends up to one hundred samples | Earlier entries, current law and bins |
| BINS | Ten/twenty intervals and their counts | Raw values, order, clipped total and RNG state |
| REPLAY | Rebuilds the present sample from the seed | Amount, law, parameters and bins |
| LAW | Switches uniform/Gaussian and clears the sample | Seed and bins |

The full new script and unchanged PointBody are printed in the tutorial and extracted for testing. The prepared museum provides the camera, player, lighting and XR Tools. All display geometry is created by the script. It draws batches immediately; there is no falling animation or automatic timer to explain again.

The temporary reconstruction sits at hall-local (3, 0, 7), yaw 90°. The existing cabinet remains. The body-sized approach is clear and has floor. These are local placement checks, not a complete walking-route certification.

## Keep the difference between records visible

The learner retains raw values and clamps only a temporary value for choosing a display bin. The cabinet retains already-clamped landed values and a separate clipped counter. These are different records. The tutorial names the difference: the student's record can still reveal how far a value went beyond the screen.

For the deliberately supplied values −0.2, 0, 0.05, 0.49, 0.5, 0.99, 1 and 1.3, two bins contain four each; only two values were clipped. Edge-bin counts do not measure clipping, because they also include valid interior observations. One belongs to the final bin, despite multiplying it by the bin count producing an index just past the array.

Changing the bins uses no random draw. Returning to the original partition restores its earlier counts. Replay is different: it regenerates the same amount under the same seed, law and parameters in the same engine version. Switching laws changes draw consumption—one draw per uniform value, two per Gaussian value.

## Edits that test understanding

| Printed edit | Expected result |
|---|---|
| Deviation 0.15 → 0.30 | Each raw distance from 0.5 doubles; clipping prevents the displayed shape from simply doubling. |
| Limit 300 → 150 | +100 then +50; further presses consume no draws. |
| Twenty bins → forty | A finer partition of the same values, with no change in RNG state. |

The histogram scales by its largest count. TOP names that changing value; N names the total. A single observation can make a full-height bar. Empty bins have no cube. This display contains no theoretical curve: the learner must read a finite sample, rather than identify a familiar outline and stop looking.

In the captured default run, the same 300 Gaussian values have a highest count of 76 with ten bins and 40 with twenty. UNIFORM at N=300 and twenty bins has a highest count of 22. Those bar heights have different count scales; the labels keep the difference visible. Seed 42 was used without searching for a pleasing picture.

## How the two texts read together

The reflection keeps its existing question: **what changes when the values stay, but we count them differently?** It attends to the expectation suggested by the orange model, the distinction between issued and landed evidence, clipping, bin-centre estimates and the empty centre of the splatter plate.

Four code excerpts become prose. The approximate two-thirds and nineteen-in-twenty proportions are identified as properties of the ideal model, not promises about a finite batch. The splatter's refused disc is described by its radius, correcting the ambiguous phrase “one deviation across.” A brief passage links the student's point to the choice between adding evidence and changing its account.

The closing distinction remains: frequent under a chosen model does not mean preferable, healthy or correct. Random Mushrooms can now ask which features of a body a sampled number is allowed to change.

## Evidence

The exact printed program and three actual source edits each pass **30 Godot checks**. Four deliberate faults are rejected: drawing during rebinning, wrapping the value one to the first bin, failing to zero old counts, and losing raw values through premature clipping.

Checks cover initialization, seeded draw order, finite budgets, retained prefixes, replay, empty displays, boundary fixtures, bin limits, clipped counts, geometry, independent instances, supplied point actions under a rotated/translated root, and the fact that moving, releasing and waiting do not sample. The wider-deviation test compares raw offsets rather than expecting a particular statistical shape from a short run.

The native museum run passes **28 checks**, including six capture-camera checks. It compares the installed sampler with its actual source recipe, confirms rebinning without RNG changes, checks clear/replay and law changes, verifies the uniform model's expected count of ten per bin at N=300, and exercises capacity while four beads are in flight. It also checks the width cycle and the existing splatter refusal parameters.

The printed learner program is then reconstructed in the real isolated hall. Its four controls are exercised through the inherited point action at supplied poses. Three native images compare the saved Gaussian sample at ten and twenty bins with a uniform sample. All six final images were inspected directly.

## Scope

The map, installed sampler, splatter source and shared PointBody match their pre-edit hashes. This task updates the canonical tutorial and reflection, and supplies a temporary learner reconstruction; it does not replace or rearrange production exhibits.

This is an author-informed reconstruction, not a blind ghost-student reading or a physical-headset test. Supplied poses and action calls do not establish grab-driver behaviour or headset readability. The accepted museum log retains an existing unknown UID, renderer compatibility warnings and a fallback for a blocked authored entrance. It contains no script, parse or signal-callback error.

Local links, rendered-code parity and the ZIP are checked. Browser layout was not inspected because local file URLs were blocked earlier. The reflection's older cabinet image is preserved as an earlier figure and included in the packet; the report images are this run's captures.

[Facing pages](parallel.html) · [Tutorial](tutorial.html) · [Reflection](final.html) · [Before/after](changes.html)

[Predictions](predictions.md) · [Code results](tests.json) · [Museum receipt](museum/report.json) · [Editable sequence plan](../../../course/randomness-revision/PLAN.md) · [Review ZIP](random-gaussian-review.zip)
