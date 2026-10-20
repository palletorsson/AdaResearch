"""Write the tenth Randomness lesson, preserving the installed museum."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[1]
HERE=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Space_Geometry'
STUDY=ROOT/'doc/book/studies/randomness-lineage'

def main():
    HERE.mkdir(parents=True,exist_ok=True)
    paths=['commons/maps/Random_Space_Geometry/'+n for n in ['tutorial.md','final.md','map_data.json']]+['algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd','algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.tscn','commons/maps/sequences/randomness.json','doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE/'before-manifest.json').exists():
        for p in paths:
            target=HERE/'before'/p;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/p,target)
        (HERE/'before-manifest.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf8')
        dest=HERE/'museum-before';dest.mkdir(exist_ok=True)
        run=ROOT/'ada_run/encounter_pilot/Random_Space_Geometry'
        for name in ['hall-before.png','installed-comparison.png','report.json','engine.log','source_manifest.json']:
            shutil.copy2(run/name,dest/name)
    tutorial='''# What neighbours share

**Learning elements**

- Independent draws and position-based field samples
- Matched grid addresses
- Spatial frequency
- Differences between neighbouring values

In Random Mushrooms you kept each body's record and changed how one property was displayed. Keep that separation here. Build two small grids at matching addresses: independent heights on the left, samples of a Perlin field on the right. Change the field's frequency while keeping every independent height.

First visit the comparison bench already in the second room of Random Space Geometry. Move FREQUENCY without changing SEED. Follow three neighbouring columns on each side. The WHITE NOISE side stays; the PERLIN NOISE side changes. OCTAVES adds another comparison, with finer layers over the broad field. Leave that control at one for the first encounter. We will construct one layer and return to layered noise in the Noise sequence.

## A small study inside the museum

Use the prepared Endless Museum project and its working player, camera, lighting and XR Tools. In a local copy of this hall, add a Node3D at hall-local **(3, 0, 12), Y rotation 90 degrees**, with unit scale. Save the two files below together and attach `10_neighbours_share.gd` to this node. Its front is local positive Z. The script builds a table, labels and two 8 × 8 cube grids; there are no hidden mesh references. The table and columns are visual only. The museum floor supports the player.

The point is the same PointBody used in the earlier lessons. Hold it over a labelled third of the front edge and press its trigger. Left replays the current settings; middle switches frequency between 0.1 and 0.3; right adds one to the seed and rebuilds both grids. Moving or releasing the point does not sample. These actions use local X zones, without a distance check or snapping.

## The complete study

<!-- student-code:10_neighbours_share.gd -->
```gdscript
__MAIN__
```

## Drawing a value; asking for a value

`replay()` resets the independent generator and visits the grid in row order. Each dictionary retains an address, a `white` draw and a `field` sample. The inner loop advances X. The outer loop advances the second grid coordinate, which becomes Z in the room. The array is still one-dimensional: a row contains eight entries.

The independent generator advances once per cell. Its next value does not consult the preceding height or its distance from another cell. That is the procedure called white noise on the installed bench; the values here have a uniform distribution between zero and one.

The field works differently. `get_noise_2d(x, z)` asks a function for its value at a position. Asking twice at the same position returns the same value under the same settings. Asking another position in between does not consume or change the first answer. Nearby positions can have related values because of the field's construction.

`TYPE_PERLIN` selects a gradient-noise algorithm supplied by Godot's FastNoiseLite. `FRACTAL_NONE` explicitly keeps one layer. We use this interface now; constructing gradient noise is a later lesson. The installed bench starts with three layers of fractal Brownian motion and offers an OCTAVES slider. Our single layer deliberately isolates the spatial relation. [Godot: FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html)

The Perlin sample is signed. Adding one and multiplying by one half maps its nominal −1…1 interval into 0…1. This does not make its distribution uniform. Both sides can use the same height scale without having the same histogram. A shared seed number also does not mean the two algorithms use the same random choices internally.

## Frequency belongs to space here

`sample_field()` sets the seed and frequency, then replaces only the `field` member of each record. It does not call the independent generator. Frequency sets the scale at which the algorithm reads the coordinates. At 0.1, neighbouring grid addresses are separated by 0.1 in its noise domain; at 0.3 they are separated by 0.3. This is spatial frequency. No clock advances in this study.

Wavefunctions already used a function evaluated across space. Here the seed selects another gradient field rather than merely shifting the phase of a repeating sine. Keep the distinction between a field and its samples: the field can be queried between these addresses, but our visible grid contains only sixty-four samples. Raising frequency does not add columns or guarantee an ever more jagged result. A coarse grid can miss variation between its samples.

`cell_gap` belongs to the display instead. It sets the physical spacing of the cubes in metres. Field lookup uses the integer address, so spreading the display does not sample the field again. You can change a view without changing its record, as in Mushrooms and Gaussian.

## Read a relation, then count it

Both grids use dark grey columns and the same height rule. A value of one gives a 0.65-metre column. A value of zero gets a 0.01-metre marker so its position remains visible. Each centre sits half its height above the table. The records retain the original values, including those hidden by this minimum height. There is no separate stretching of each grid to fill its available height.

The board reports a mean neighbour gap. For each record, `neighbour_gap()` compares its value with the entry immediately right and the entry one row below, when they exist. `i + 1` moves right; `i + SIDE` moves down. The boundary checks prevent the end of a row being joined to the start of the next. Each edge is counted once: an 8 × 8 grid has 56 horizontal and 56 vertical pairs.

`absf()` keeps the size of a difference regardless of which value is higher. Dividing their total by 112 gives the mean absolute gap, in the record's value units. It is a description of these samples, not a correlation coefficient or a proof that one procedure always produces a smaller gap. Their different value distributions also affect the result. Inspect a row as well as the number.

Entropy counted categories without retaining their arrangement. This measurement uses arrangement. An alternating grid of zeros and ones has a gap of one across every neighbour edge. A grid with zeros in its left half and ones in its right half has only eight differing edges, giving a mean of 8/112, or 1/14. Both contain thirty-two zeros and thirty-two ones.

## The point you bring

The control converts the point's world position into the study's local frame. Turning the table therefore keeps its actions attached to its own left, middle and right. Pickup and trigger handling are inherited, not taught again here.

<details>
<summary>Complete unchanged PointBody dependency</summary>

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

</details>

## Predict, change, check

1. Change the initial `frequency` from `0.1` to `0.3`. Before running, predict which record fields will change. Compare at seed 42: addresses and every independent value should remain identical; the Perlin values change. Switching back must restore their earlier values. No independent draw is spent by that switch.
2. Change `cell_gap` from `0.16` to `0.20`. Both grids spread out, while all values and both reported gaps stay the same. The cubes still fit the table. Explain why moving the display is different from changing where the function is sampled.
3. Change the initial `sample_seed` from `42` to `43`. Both procedures receive another seed. Compare them, then return to 42. Replay repeats the result under the same code, parameters and engine behaviour; it does not promise that two different engines or algorithms agree.

For an independent check, replace both value fields of every record with `(record.at.x + record.at.y) % 2`, then call `rebuild()`. Both gaps should be one. Next use `0.0 if record.at.x < 4 else 1.0`. Both gaps should be 1/14 despite unchanged category counts. These fixtures are authored patterns, not noise. REPLAY restores the sampled grids. `neighbour_gap()` assumes the complete row-ordered 8 × 8 record; removing individual records requires a different neighbour lookup.

The installed bench's height colours invite a terrain reading. Our neutral display lets the relationship carry more of the comparison. Neither version simulates erosion or proves what a landscape ought to look like.

Carry this question to the dartboard: **which sampling rule is an estimate relying on?** Related samples and independent samples are useful for different purposes. A field that makes plausible neighbouring heights is not automatically the right source for uniformly sampling a square.
'''
    tutorial=tutorial.replace('__MAIN__',(STUDY/'10_neighbours_share.gd').read_text(encoding='utf8').rstrip()).replace('__POINT__',(STUDY/'point_body.gd').read_text(encoding='utf8').rstrip())
    (ROOT/'commons/maps/Random_Space_Geometry/tutorial.md').write_text(tutorial,encoding='utf8')
    final=(HERE/'before/commons/maps/Random_Space_Geometry/final.md').read_text(encoding='utf8')
    final=final.replace('Its heights are drawn from the seed alone, so every redraw returns the same values; frequency changes how neighbours relate, and those heights have no relation for it to change.', 'With the seed and draw order kept, every redraw returns the same independent values. The frequency control belongs to the other construction: it changes where the grid samples the field.')
    final=final.replace('One productive discipline is to keep withholding the landscape reading, despite the subtitle and the palette, and describe only local differences.', 'At the tutorial table, the columns keep one grey material. You retain the independent heights while changing the field. A number names the average gap between neighbours, but a row is still worth following with your eye. Two arrangements can contain the same numbers and ask you to cross very different surfaces.\n\nOne productive discipline is to keep withholding the landscape reading, despite the subtitle and the palette, and describe only local differences.')
    final=final.replace('Both grids already share one height scale and one colour ramp,', 'On the installed bench, both grids share one height scale and one colour ramp,')
    final=final[:final.index('[^perlin]:')]+'''[^perlin]: The bench uses Godot's FastNoiseLite Perlin mode with layered fractal noise. The tutorial uses the same mode with one layer. Perlin noise relates values through a lattice of gradients; this names a construction, not a claim that the present library reproduces the original implementation exactly. See [Godot: FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html). The mixer in Random Space is a sum of sines and is identified there as such.
'''
    (ROOT/'commons/maps/Random_Space_Geometry/final.md').write_text(final,encoding='utf8')

if __name__=='__main__':main()
