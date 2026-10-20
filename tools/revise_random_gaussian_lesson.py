"""Focus the eighth lesson on a retained sample and its changing partition."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Gaussian'
STUDY=ROOT/'doc/book/studies/randomness-lineage'

def main():
    tutorial='''# Keep the values, change the bins

## Learning elements

- Uniform and Gaussian sampling rules.
- Mean and standard deviation as parameters.
- Retaining a sample before displaying it.
- Clipping a value and assigning a bin.
- Recounting without drawing again.

Find the distribution cabinet. Press PAUSE, let the airborne beads land, then CLEAR. Press BATCH three times. You have three hundred values. Press BINS: the bars change, but the total does not. Return to the original number of bins. What returned with it?

Random Walk kept positions in their order of arrival. Here we keep a list of numbers and group them into intervals. Entropy supplied counts; Arrays supplied the list and loop. The familiar PointBody returns as the control you hold. The new work is the relation between **drawing, keeping and counting**.

## Rebuild a small comparison

Work in your copy of Endless Museum. Attach `08_values_and_bins.gd` to an empty `Node3D` under Random Gaussian; keep the unchanged `point_body.gd` beside it. Day Zero already supplies the player, camera, lighting and XR Tools. This script builds its own display and labels. Its boxes are display meshes, not colliders.

The tested temporary station sits at hall-local `(3, 0, 7)`, turned 90° about Y. Leave room on its local positive-Z side to approach. The installed distribution cabinet remains in the hall.

Use the point as in Random Rotate: hold it over a labelled position and press the trigger. Moving it alone changes nothing. From left to right:

- **REPLAY** regenerates the present number of values from the seed, under the same law and parameters. It keeps the current bins.
- **+100** adds up to one hundred values, stopping at the run's limit of three hundred.
- **BINS** switches between ten and twenty intervals using the stored values.
- **LAW** switches GAUSS / UNIFORM and clears the sample. Press +100 three times to compare at equal count.

The display starts empty. There is no falling animation or automatic timer in this reconstruction: all samples count immediately. Start by reading `sample_value()`, `batch()` and `rebin()`; the remaining code constructs the display and connects the inherited action.

<!-- student-code:08_values_and_bins.gd -->
```gdscript
__MAIN__
```

## Give a draw a law

UNIFORM returns one `randf()` value in the interval from zero to one. GAUSS transforms two such draws. It uses the same guarded Box–Muller recipe as the installed cabinet. The logarithm and square root set a radius; the cosine takes one component. We use that recipe here without deriving it or adding a second sampler implementation.

The intermediate `z` approximates a normal variable centred at zero with standard deviation one. `mean + deviation * z` moves its centre and changes its spread. With our defaults, the mean parameter is 0.5 and the standard-deviation parameter is 0.15. Those describe the generating rule; this particular finite sample need not have exactly that mean or deviation.

`log(0)` is outside the recipe's domain. `maxf(..., 0.0001)` supplies a lower guard without shifting every valid draw. Together with the finite generator it makes an approximation, not a source of arbitrarily distant tails. The computed `z` cannot exceed about 4.29 in magnitude. More UNIFORM draws do not turn their law into GAUSS.

The two laws also spend the seeded stream differently: one draw per uniform sample, two per Gaussian sample. Equal seeds do not mean the two lists contain paired observations of the same value.

## Keep first, count second

`batch()` appends each raw result to `values`. The loop stops at the remaining capacity. Its job is sampling. `rebin()` makes a fresh list of zero counts, then reads the saved values. Its job is grouping. There is no random call inside it.

For ten bins, 0.23 belongs to index 2: multiply by ten, then take the integer part. Internal boundaries belong to the bin on their right. One needs special treatment: multiplying 1.0 by ten gives ten, but the last valid index is nine. `mini()` keeps that endpoint in the final bin.

Values outside zero to one are counted at the nearest display edge. This is clipping, not the reflection from Random Walk. The `clipped` counter records how many raw values crossed those edges. The first and last bins also contain values already inside the interval, so their total is not the clipped count.

Our `values` list keeps the **raw** number. Only the temporary `value` used for indexing is clamped. That makes the lost distance beyond an edge available to inspect. The installed cabinet keeps the already-clamped landed values and a separate clipped counter. This small reconstruction deliberately keeps more of the sample; the difference is part of the lesson.

After BINS, every raw value, its order, the clipped total and the generator state remain. The counts change because the partition changes. Returning to ten bins restores their earlier counts. No new observation was needed.

## Read the height carefully

The bars are made from the cube mesh you already know, changing only size and position. Zero counts have no bar. Each positive count is divided by the highest count, making the tallest bar one metre high. The label names that changing top count.

A single observation can therefore make a full-height bar. N tells you how much evidence is present; height alone does not. Unlike the cabinet, this study has no theoretical curve or expected-count bars. It shows the sample's counts, not a guarantee about what the next sample should look like.

## The point you already have

The point's pickup, release and trigger signal come from the same class. Converting its global position into the station's local frame keeps the four action zones attached to the station if it turns. Release does not make a new draw.

<details>
<summary>Complete unchanged PointBody dependency</summary>

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

</details>

## Make a change you can explain

1. Keep GAUSS and the seed. Change `deviation` from `0.15` to `0.30`, then restart the scene and collect the same number of values. Each raw distance from 0.5 doubles. The displayed histogram need not double its width: the screen still clips at zero and one. Check both the raw record and the clipped count.
2. Change `sample_limit` from `300` to `150`. The first +100 adds one hundred; the next adds fifty; further presses draw nothing. The first hundred values remain the prefix of the same seeded run. A taller-looking picture is not necessarily a larger sample.
3. In `cycle_bins()`, change twenty to forty. Keep the saved values and compare ten with forty bins. The number of bins changes, not the generator or the number of observations.

For an independent check, set `values` to `[-0.2, 0.0, 0.05, 0.49, 0.5, 0.99, 1.0, 1.3]`, then call `rebin(2)`. Predict both counts and the clipped total before running it. Two bins should each contain four values; only two values were outside the screen. Rebin to ten and explain each occupied interval. This uses deliberately supplied data, not another random run.

To repeat a sampled run, preserve the seed, law, parameters, amount and draw order in the same engine version. REPLAY regenerates that many values; BINS simply rereads the existing ones. They are different kinds of return.

## Return to the cabinet

The installed BINS cycles 30 → 60 → 10 → 30. PAUSE stops issuing new samples, while existing beads can still land. BATCH counts immediately, reserving capacity for those in flight. CLEAR empties both and resets the named generator while preserving paused/running state. WIDTH changes the Gaussian deviation and clears the sample; it is not a way to stretch the same stored values.

Blue and pale model bars share a count scale there. The orange line has a separate shape scale. Leave Poisson, exponential and their additional mathematics as comparisons for now. At the paint-splatter plate, a central region rejects some drawn positions altogether: another rule intervenes between sampling and what you see.

In Random Mushrooms the retained number becomes a parameter of a body. Keep this distinction with you: choose a value, decide what it may change, then construct the form.
'''
    for tag,name in [('MAIN','08_values_and_bins.gd'),('POINT','point_body.gd')]:
        tutorial=tutorial.replace('__'+tag+'__',(STUDY/name).read_text(encoding='utf8').rstrip())
    (ROOT/'commons/maps/Random_Gaussian/tutorial.md').write_text(tutorial,encoding='utf8')
    final=(HERE/'before/commons/maps/Random_Gaussian/final.md').read_text(encoding='utf8')
    final=re.sub(r'\n```gdscript\n.*?\n```\n','\n',final,flags=re.S)
    final=final.replace('UNIFORM has used each number directly:', 'UNIFORM has used each number directly.')
    final=final.replace('GAUSS has given two numbers another job:', 'GAUSS has given two numbers another job.')
    final=final.replace('There is the logarithm, the square root, the turning cosine again.', 'A logarithm, a square root and the turning cosine give those draws their new relation.')
    final=final.replace('Read the small guard on `u1`.', 'The sampling recipe guards its first input.')
    final=final.replace('so the same two-in-three can be watched staying inside a narrower or a wider band', "so the model's central band becomes narrower or wider; the actual proportion remains something to count")
    final=final.replace('two draws in three land within 0.15 of the middle, nineteen in twenty within 0.30, and the rare ones make the tails.', 'under the ideal model, roughly two draws in three lie within 0.15 of the middle and nineteen in twenty within 0.30. A finite sample can differ; the model does not appoint which beads must arrive.')
    final=final.replace('There is another boundary at the screen itself:', 'There is another boundary at the screen itself.')
    final=final.replace('The stored values are assigned to new intervals:', 'The stored values are assigned to new intervals.')
    final=final.replace('a disc one deviation across holds fewer', 'a disc with a radius of one deviation holds fewer')
    final=final.replace('the same guarded transform you read above', 'the same guarded sampling recipe')
    final=final.replace('We have met a centre, but have not discovered a command to belong to it.', 'In the tutorial, your point calls for another batch or another partition. One action adds evidence; the other changes its account. You can make the bars look different without asking chance for anything new.\n\nWe have met a centre, but have not discovered a command to belong to it.')
    final=re.sub(r'\n{3,}','\n\n',final)
    (ROOT/'commons/maps/Random_Gaussian/final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
