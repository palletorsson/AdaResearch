"""Write hall thirteen around the installed finite spatial sum."""
from pathlib import Path
import hashlib, json, shutil
ROOT = Path(__file__).resolve().parents[1]
MAP = 'Random_Space'
HERE = ROOT / 'doc/book/iterations/2026-10-09-randomness-revision' / MAP
STUDY = ROOT / 'doc/book/studies/randomness-lineage'

def main():
    HERE.mkdir(parents=True, exist_ok=True)
    protected = [f'commons/maps/{MAP}/{n}' for n in ['tutorial.md', 'final.md', 'map_data.json']]
    protected += ['commons/artifacts/noise_mixer/noise_mixer.gd', 'commons/artifacts/noise_mixer/noise_mixer.tscn',
                  'commons/context/walkgrids/RandomSpace.gd', 'commons/context/walkgrids/random_space.tscn',
                  'commons/artifacts/worley_noise/worley_noise.gd', 'commons/maps/sequences/randomness.json',
                  'doc/book/studies/randomness-lineage/point_body.gd']
    if not (HERE / 'before-manifest.json').exists():
        hashes = {}
        for p in protected:
            dest = HERE / 'before' / p
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / p, dest)
            hashes[p] = hashlib.sha256((ROOT / p).read_bytes()).hexdigest()
        (HERE / 'before-manifest.json').write_text(json.dumps(hashes, indent=2), encoding='utf8')
    text = '''# Fields add

**Learning elements**

- A finite sum of spatial contributions
- Layer count, frequency ratio and amplitude ratio
- Seeded offsets kept between edits
- Raw values and display normalization

In Synthesis, several weighted waves made one result. In Space Geometry, neighbouring addresses sampled one field. Here those operations meet: sample several fields at the same address and add their contributions. Unlike Pheromone, a visit changes nothing. The same address and settings give the same value regardless of the route you took through the room.

At the noise mixer, reduce OCT to one. Change LAC and PER separately: neither affects the first layer. Add a second layer and try again. LAC now changes the next frequency; PER changes its weight. SEED selects a new arrangement of offsets. The violet ground and blue cellular field remain comparisons; this lesson rebuilds the mixer.

## Keep the parts of the sum

Add a Node3D to your local copy of the prepared museum hall, at hall-local **(9.5, 0.232, 12), Y rotation -90 degrees**, with unit scale. This tested position sits on the existing violet surface; recheck its support if you change that surface. Put the two printed files together and attach `13_fields_add.gd`. The museum supplies the player, XR Tools, camera and light. This script creates its own table, screens and point. The table and screens are visual only. The front is local positive Z.

The familiar PointBody selects four actions by its local horizontal position. Hold it over a label and press the trigger. REPLAY recreates the same eight offsets from the current seed, keeping the other settings. OCT cycles through one to four layers. WEIGHT switches PER between 0.3 and 0.7. SEED increments the seed and rebuilds. Moving or releasing the point changes no values.

Each entry in `parts` is a list of weighted samples from one layer. `raw` keeps their sum at each address. The first screen shows the last included contribution. The middle screen shows the sum using the same fixed grey scale. The third shows that identical sum stretched between its own minimum and maximum. It is a different view, not another field.

## The complete study

Start with `replay()`, `wave()` and `sample_fields()`. `picture()` turns retained values into pixels. The remaining functions supply the familiar control and display.

<!-- student-code:13_fields_add.gd -->
```gdscript
__MAIN__
```

## The carried point

Use the unchanged `point_body.gd` from earlier rooms. It is printed here so the complete dependency is available together.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

## Read one address

The nested grid loops visit 32 × 32 sample addresses. Dividing by SIDE gives coordinates from 0 up to, but not including, 1. The inner layer loop begins with amplitude 1 and frequency 4. It samples the function after applying that frequency and the layer's saved offset. Then it adds the weighted value and prepares the next amplitude and frequency.

With LAC 2 and PER 0.5, four layers use frequencies **4, 8, 16, 32** and weights **1, 0.5, 0.25, 0.125**. OCT decides how far along that list to go. Removing a layer removes its contribution; it does not draw a replacement for what remains. Changing PER keeps the offsets but recomputes the weighted contributions. Changing LAC keeps them too, while changing where later layers sample.

The museum's base function is the five sine expressions in `wave()`. One layer already contains all five; it is not one simple sine and it is not the Perlin function from Space Geometry. The product `x * y` also makes this more than a sum of straight repeating stripes. We retain the actual function so that the reconstruction has a specific source. This is a finite construction, not a simulation of geological history or an infinite fractal.

Eight offsets are prepared once per replay even though this study uses at most four. That follows the installed mixer's offset list and keeps earlier entries available unchanged. `sample_fields()` makes no random draws. Parameter edits revisit a function; they do not accumulate marks as Pheromone did.

## A scale belongs to the picture

The first two screens map -3 to black, zero to grey and +3 to white. With up to four layers and PER at most 0.7, the absolute sum cannot exceed 1 + 0.7 + 0.49 + 0.343, because each base sample is an average of five sine values. Those settings fit inside the shared display bounds.

The last screen instead maps this sample set's lowest value to black and its highest to white. A small numerical range can therefore fill the whole contrast range. If the range is smaller than 0.0001, the code uses width 1 to avoid division by zero; a constant field becomes black. The arrays are not normalized in place. The centre readout and raw range remain available beside the pictures.

The installed mixer shows a 128 × 128 image through an earth-toned palette. Our study uses 32 × 32 samples, a grey scale, and exposes both scales. At shared sample coordinates the underlying sum agrees. The images need not match: resolution, range and palette affect what is visible. Adding layers does not add pixels, and a coarse image may miss or misrepresent fine variations.

## Make a change you can explain

1. Start with one layer and record the centre value. Change WEIGHT: it should stay the same. Add a layer; now changing WEIGHT can matter. Return to one layer and recover the earlier result. No new seed is needed.
2. Change `lacunarity` from 2.0 to 3.0 in the code. Predict frequencies 4, 12, 36, 108 for four layers. At one layer the field remains unchanged; later contributions change. The offset record should stay exactly the same.
3. Change SIDE from 32 to 64. You have added sample addresses, not layers. Every former address occurs at an even row and column in the new grid, with the same raw value. The stretched image's extrema may change because it now includes additional samples.

For one further comparison, keep four layers and temporarily put this loop immediately before `redraw()` in `sample_fields()`:

```gdscript
    for i in range(raw.size()):
        raw[i] *= 0.25
```

This scales the completed sum, leaving the stored parts unchanged. The fixed-scale middle screen becomes quieter. The stretched screen remains the same apart from numerical rounding, provided its range stays above the small-range guard. A quarter of the values can occupy the same contrast. Remove this intervention before continuing.

## What travels onward

Keep the distinction between a construction, its retained values and the view used to read them. This room used a seed to arrange offsets; the next room draws a wait and retains a deadline. There, revealing more about a decision should not secretly make a different decision.
'''
    text = text.replace('__MAIN__', (STUDY / '13_fields_add.gd').read_text(encoding='utf8').rstrip()).replace('__POINT__', (STUDY / 'point_body.gd').read_text(encoding='utf8').rstrip())
    (ROOT / f'commons/maps/{MAP}/tutorial.md').write_text(text, encoding='utf8')
    final = (HERE / f'before/commons/maps/{MAP}/final.md').read_text(encoding='utf8')
    final = final.replace('This display offers neither a neutral palette nor a fixed shared scale; either would expose another part of this construction and make a useful comparison for a future display.',
        'The small reconstruction gives that comparison a place. Two screens show the same sum: one keeps a shared grey scale; the other stretches its own range. Make the values smaller and the second picture can remain just as emphatic. The landscape has not grown back. The display has spread a narrower difference across the same distance from black to white.')
    (ROOT / f'commons/maps/{MAP}/final.md').write_text(final, encoding='utf8')

if __name__ == '__main__':
    main()
