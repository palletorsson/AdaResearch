# Comparing two noise bases

This hall closes the current Noise route. Earlier rooms turn sampled values into points, columns, relief and occupied volume. Here the learner asks which differences belong to the generating rule, and which were introduced by the display. Cellular Automata follows: a stored neighbourhood updated in steps is a different mechanism from evaluating a fixed field at an address.

## The comparison as configured

The primary placements are `simplex_noise` at (3,7) and `perlin_noise` at (8,7). Both declare seed 20260910, size 8, frequency multiplier 10 (raised from 1 on 2026-09-10 after the first museum run: at 1 the four-metre field covered less than a fifth of one noise period and both fields stood as flat slabs; the FREQ slider now runs 1 to 20), amplitude 0.8, persistence 0.5, four octaves, the shared ramp and a front panel. The Perlin placement additionally declares `generator:perlin`. The map supplies these values before the artifacts enter the scene tree; the roots retain them through `_ready()` instead of letting the old 2D sliders replace them.

Each field contains 64 cubes with 0.5-metre spacing. Their local sample centres run from -2 to 1.5 on each horizontal axis. The roots stand at y=1.1. With amplitude 0.8 and cube half-height 0.25, a sample value of -1 puts the cube bottom 0.05 metres above the floor. Actual installation clearance still needs the museum runtime probe.

The two fields use the same colour ramp, metallic value 0.1 and roughness 0.8. Their room positions differ; lighting can still affect their appearance. Matching material parameters does not make every viewing condition identical.

## Basis, coordinates and values

The registry name is insufficient evidence of a generator. `NoiseVisualizer._noise_type_for()` selects the Perlin display's basis; its default remains `FastNoiseLite.TYPE_SIMPLEX` for compatibility with other placements. This hall explicitly selects `TYPE_PERLIN`. Both readouts obtain their basis names from the instantiated generators.

Godot 4.6's `TYPE_SIMPLEX` selects OpenSimplex2. It should not be described as a literal implementation of every detail of the original simplex algorithm. [Godot FastNoiseLite documentation](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html).

The simplex visualizer samples with this complete function:

```gdscript
func generate_noise_at(x: float, z: float) -> float:
	return noise_generator.get_noise_2d(x * frequency, z * frequency)
```

The generator also has its own frequency, 0.05, so the panel value multiplies that coordinate scale. Its fractal type is FBM with the declared octave count and gain. The Perlin visualizer adds an animation offset to the sampling coordinates; this offset remains zero in the museum comparison, whose panel does not start animation.

Every cube is updated using its own local x and z. Previously the update reconstructed those coordinates from a flattened index with a different row width than creation used. That changed the field under an unchanged display. Creation and update now ask for the value at the same spatial address.

The readouts show (-1, 0.5) and (1, -1), both inside the displayed patch and on sample centres. Relief maps a value to height using amplitude; the shared ramp separately maps it to colour. Neither mapping is intrinsic to a noise basis. Other placements can select `plate` or `column` to give the values different forms; this hall presents relief.

## A controlled return

Each front panel has FREQ and OCTAVES sliders plus REGEN and REPLAY. REGEN chooses and records another seed. REPLAY restores the declared seed, frequency and octave count, including the two handle positions. Move a slider on one side and the other field remains unchanged. Reset before attributing a difference to the basis.

The same seed makes each configured generator repeatable. It does not establish a correspondence between the two bases' ridges. Nor does a single small patch demonstrate isotropy or settle which algorithm is faster. Those claims need larger samples and appropriate measurements. The useful experiment here is narrower: can the visitor hold the sampling and display decisions steady, change one rule, and distinguish an observed difference from an expected one?

## Evidence and scope

`probe_wcn_noise_pair.gd` is prepared to inspect the actual museum installation, compare settings and cube samples, exercise panel signals, check clear routes and capture the pair. It has not yet run after the review corrections. Signal injection tests the connected software path; only a headset walk can establish how a tracked hand reaches and uses it.

The small `perlin_noise_terrain` remains a secondary example. The former 100-metre `noise_terrain` is archived and absent from this hall.

The optional portal remains and does not work. `configurable_portal#dest_map:Lab_Path` resolves its destination by asking the grid system for a `load_map` method and then a node in group `scene_manager` for `load_scene`; the grid system has neither and nothing in the repo joins that group, so every path reaches a `push_warning`. Measured at runtime on 2026-09-13 through `resolve_destination()`, which runs the same lookups and reports them without acting: `resolves: false, via: "nothing"`. The label says Lab Path; the code says nowhere.

The route to Cellular Automata is the spine's, not this sequence's. `curriculum_spine.json` puts cellularautomata directly after noise and the museum carries its own passage onward, but `commons/maps/sequences/noise.json` ends its maps array at Lab_Path and names `proceduralgeneration` and `morphogenesis` as unlocks — and morphogenesis was absorbed into softbodies, so one of the two names no longer points at a sequence on the spine. Making the sequence say what the spine says is a fold-level edit and is not made here.

## The witness (2026-09-13)

`generator_readback()` on both `SimplexNoise` and `PerlinNoise` returns the live FastNoiseLite's own `noise_type`, `seed`, `frequency`, `fractal_type`, `fractal_octaves`, `fractal_gain` and `fractal_lacunarity`, plus the visualizer's own `sample_scale` and `sample_offset` — the two terms applied to x and z before `get_noise_2d`. `witness_state()` pairs a display with the other display of ITS OWN hall (by group, scoped to the nearest ancestor carrying `em_map` or named `Seg…`) and returns which keys are equal, which differ, and the plate's lines.

`#witness:show` on a token builds the plate; the default is `none`, so the ten `simplex_noise` and twenty `perlin_noise` placements elsewhere are unchanged. The key is a word, not a number, because `#key:number` is read as a rotation unless the key is in `CONFIG_PARAM_NAMES`.

`resolve_destination()` on `configurable_portal` runs the same lookups `_load_destination_map()` runs and reports which branch would be taken, without taking it.

| measured 2026-09-13 | simplex | perlin |
|---|---|---|
| seed | 20260910 | 20260910 |
| generator frequency | 0.05 | 0.05 |
| fractal octaves | 4 | 4 |
| fractal gain | 0.5 | 0.5 |
| fractal lacunarity | 2.0 | 2.0 |
| fractal type | 1 | 1 |
| sample multiplier | 10.0 | 10.0 |
| sample offset | 0.0 | 0.0 |
| **noise_type** | **0** | **3** |
