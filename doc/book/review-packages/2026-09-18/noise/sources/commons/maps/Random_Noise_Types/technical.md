# Two kinds of constraint

This account follows `algorithms/randomness/randompoint/randompoint.gd` and `algorithms/randomness/randompoints/randompoints.gd`.

## The single point

The map's `randompoint` opts into `stand:bounds`, with half-extent 0.6 m, rotation 90°, and origin raised 1.25 m at cell (3,2), facing the open approach. Its square marks allowed centre coordinates; it is not a colliding sheet. Two global uniform draws choose the initial local x/y. Local z starts at zero. `_process` clips x/y and replaces z with zero, then updates the coordinate label. `_on_point_dropped` performs the same clipping, without resampling. This repeatedly maintained boundary differs from the bench's one-time admission test. The visual casing is opt-in; other placements retain their original bare presentation.

## The bench

`randompoints:180#stand:compare#count:24#size:0.9` builds two equal slabs, 0.90 × 0.90 × 0.12 m. Default spacing is derived once for the configured count and volume: 0.8 times the cube root of volume/count, snapped to 5 mm. This map gives 0.130 m. `radius` can explicitly configure that distance; `dist` is accepted by the script but is not a recognized numeric key in the grid token parser.

The left cloud uses independent uniform coordinate draws. The right either rejects uniform proposals that are too close to already accepted centres, or draws clamped Gaussians independently on each axis. The Gaussian standard deviation is half-extent times 0.25. Clamping puts tail draws on a boundary instead of redrawing them; it is not a truncated Gaussian or pink-noise generator.

One seeded RNG supplies the left cloud first, then continues for the right. REDRAW creates a fresh generator with the same seed. Equal settings and call order therefore repeat both clouds; the clouds do not share the same proposal prefix. Increasing the left count also advances where the right starts reading that stream.

The distance sampler proposes up to 100 candidates per requested slot. Each candidate checks all previously accepted centres. Failed slots do not relax the distance and do not stop later slots trying. This is simple finite dart throwing, without a spatial hash, active list, annulus search, or packing optimality certificate.

```gdscript
if min_dist >= blue_noise_min_dist:
	pts.append(candidate)
	placed = true
	break
```

The display keeps these accounts separate:

- Right candidates = accepted + refused. Gaussian candidates equal accepted; its refused count is zero.
- Requested slots = accepted + unfilled. Unfilled records the finite search shortfall.
- Ghost instances = min(220, refused). They retain the first refusals, not a representative random subsample.

Each accepted point carries a shell of radius distance/2. Admission uses exact centre distance. A 0.25-second observer counts current pairs below distance minus 1 mm and colours their shells; it counts each pair once. That observer uses coordinates in the common cloud frame. At the map's unit scale those units are metres. Arbitrary nonuniform scaling elsewhere would change world-distance interpretation.

The point bodies still use project pickable/physics behaviour. Absence of a spacing force does not mean absence of all physics. RESTORE freezes them, clears velocities and returns their saved local positions. It recomputes close pairs immediately, including naturally close Gaussian pairs. Release a held point before restoring; a pointer still carrying a body can continue to write its position.

## Local controls

REDRAW repeats the current seeded construction. NEW SEED chooses a five-digit seed different from the current one. RULE alternates spaced / clustered. RESTORE restores home coordinates without resampling. LOAD alternates the configured population and four times it, without deriving a new distance. The cased plate names all three dimensions, full candidate counts, ghost display limit and finite attempt budget.

## The galleries: two more primary encounters

The four works remain in place. `WhiteNoiseGallery` and `NoiseColors3D` now use `#stand:gallery#seed:31415`. The console helper counteracts each miniature's scale for the controls only; the existing model dimensions, sample counts, bar-generation code and audio filters are retained. The side consoles keep the central visual fields available to inspect. Existing button signals still select five noise modes and STOP. Switching modes stops the old stream before restarting, clearing queued samples, and resets filter state. With a nonzero seed each mode starts from the same white-innovation stream within that artifact; the two artifacts retain their distinct seed offsets (13579 and 24680).

`WhiteNoiseGallery` draws 10,000 bar heights at regular grid addresses. Each height is a uniform draw multiplied by max_height; colour samples a gradient with that same draw. Its sound is generated independently of those heights. None of its five sound buttons regenerates or reads the visual field.

`NoiseColors3D` retains 200 bins in each of five rows. The row values follow 1/f², 1/f, 1, f and f², using f = max((i+1)/200, 0.01). Each is multiplied by a random value in [0.7, 1.3], multiplied by max_height and clamped to [0.01, 2 × max_height]. These are perturbed, clipped illustrations, not measured spectra. With show_all_types=true in this map, selecting sound leaves all rows intact.

Both scripts contain the same sample-filter formulas. WHITE returns an independent uniform innovation. PINK combines several stateful recurrences. BROWN adds 0.02 times the innovation to a state bounded to [-1,1]. BLUE subtracts a running low-pass estimate from the innovation. VIOLET differences adjacent innovations. Gain and the final ±0.95 clamp follow. These implementation names are retained; this review does not certify exact spectral slopes for the approximate, bounded filters, particularly BLUE and BROWN.

The review exports two-second, 44.1 kHz mono PCM previews by calling the actual generators, with seed 12345 and reset filter state for each mode. These dry samples precede room attenuation. They do not record speakers, a headset, or the AudioStreamGenerator's output buffer. Pointer tests separately verify that the actual stream starts, switches and stops. Previews keep the existing gain; they are not loudness-normalized, so listening comparisons can reflect both level and temporal structure.

No artifact in this hall currently scans a spatial row into sound. That possibility belongs in the book as a named next experiment. Preserving this distinction makes the existing juxtaposition available for thought without inventing a hidden connection.

## Remaining implementation boundaries

The point sampler's enum name BLUE_NOISE and legacy `mode:pink` alias remain for compatibility; the latter selects the clamped Gaussian, while the bench UI names it clustered. The distance sampler has no spectral quality certificate. The galleries' model curves and audio filters are separate constructions. No entropy estimate or numerical QFEP lambda is assigned to them.

Headset comfort, direct hand presses, perceived timbre in the room and Quest performance remain unverified. The desktop interaction lane and generated audio records establish narrower facts, listed in the review receipt.
