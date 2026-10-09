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


## Related weather — 24 September 2026

`related_weather` at (6,18) adds three fixed glazed walls to the extended 13×28 hall. Their eight slits each show the newest eight accepted targets; the oldest visible slot is seven samples behind the newest. Opaque panels move but the glass collision stays fixed. Side and end aisles allow the body to move around the walls. Existing four artifacts, their configurations and all prior structure rows remain. Eighteen rows are inserted before former row 9; the teleporter moves from (6,7) to the final doorway (6,27).

`weather_signals.gd` supplies a seeded uniform innovation u in [-1,1] to all three channels. White returns u. The walk adds 0.10u to its unbounded sum. Pink uses the third-order IIR coefficients in [Julius O. Smith, Example: Synthesis of 1/F Noise](https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html). It receives 4096 preparation samples; the visible walk starts at zero afterward. Uniform rather than Gaussian innovations change the marginal distribution, not the filter transfer function. Neither the raw walk nor the raw pink output is clamped in the model.

The display uses fixed gains [1,1,11.6], then y = 1.70 + 0.75 * clamp(value,-1,1), with a 0.64 m sight slit. Orange slot markers identify target clipping. The gain is fixed for every seed, not recalculated to fit each run. Values on the console are before this clamp, with the pink display gain applied. No claim that these three marginal distributions are equal. Raw values, bounds and visible motor motion are distinct layers.

All channels share a one-second cubic smoothstep movement and a one-second dwell. RUN starts or resumes, HOLD pauses both pending travel and clock. NEXT starts one sample or finishes the currently paused stroke without drawing again. REPLAY cancels pending motion, clears the record and repeats filter preparation and visible targets from the same seed. NEW SEED clears with a different seed, which does not guarantee a different-looking short run. The record stops explicitly at 128 samples; the display retains eight and does not silently loop. Glass collision does not move during these controls.

The spectral check exports actual production-model samples, before gain, clipping or motor motion. It uses a stated Welch estimate and frequency band; the report accompanies this review. No spectral claim is made about eight visible targets, eased shutter trajectories or the older unmeasured audio filters. The new record is an architectural time-series display, not an acoustic measurement or a new proof of blue-noise spacing.


Measured signal receipt: production seed 4321, 65,536 accepted samples after 4,096 filter-preparation samples. Welch estimate: Hann window, 8192-sample segments, 4096 overlap, linear detrending; fit over 0.01–0.20 cycles per sample. Fitted power slopes: fresh +0.006, accumulated −1.947, filtered −0.992. The unbounded walk is nonstationary; its finite-record fit is descriptive. The filter's power×frequency response varies by 0.471 dB across that band. An independent SciPy recurrence agrees within 3.2e-11 after its transient. These checks support the raw pink approximation over the stated band, not an exact all-frequency process or a spectrum for the eased apertures. In the first 128 targets of this seed, clipping counts are [0,0,4]. See `doc/book/iterations/2026-09-24-related-weather/signal-checks.json` and `signal-study.png`.
