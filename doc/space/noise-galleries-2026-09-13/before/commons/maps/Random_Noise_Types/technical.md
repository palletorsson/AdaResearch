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

## Secondary exhibits and limits

`WhiteNoiseGallery` draws independently sampled bar heights on a grid. `NoiseColors3D` draws prescribed spectral-power curves multiplied by random factors in [0.7, 1.3], with height clamps. Neither display is an FFT measurement of the bench's centres or its own audio output. They retain their current placements and secondary status. Their sound buttons, scaled controls and spectral fidelity require their own review.

The enum name BLUE_NOISE is retained for compatibility with existing scenes. This pass verifies a minimum-distance sampler, not a spectral quality guarantee. The legacy `mode:pink` alias selects Gaussian for compatibility; the room's controls and book call it clustered/Gaussian. No entropy estimate, comparative randomness ranking or numeric QFEP lambda is measured here.
