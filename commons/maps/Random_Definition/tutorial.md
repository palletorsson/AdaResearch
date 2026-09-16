# One stream, different beginnings

In Synthesis Lab we kept five amounts and a phase to repeat a shape at a chosen instant. Here we keep a seed and a procedure. The primary is `seed_replay_demo:180#comparison:replicas#stand:table`, at (5,6), in the middle of Random_Definition. Its controls face −Z, toward the entrance. All excerpts below come from `algorithms/randomness/seed_replay/seed_replay_demo.gd`.

## Look, remember, return

Find a patch in one grid and check the same place in the other. Press REPLAY. Choose a seed with the slider or RANDOM, find another patch, and replay it. The comparison supplies the same integer to both grids:

```gdscript
func _column_seeds() -> Array:
    match comparison:
        "replicas", "offset":
            return [_current_seed, _current_seed]
```

This is the beginning of a longer function with other comparison modes. The placed room uses `replicas`.

Before colouring each grid, `_regenerate` restores the local generator:

```gdscript
_rng.seed = s
```

Each `_rng.randf()` call requests one value between zero and one and advances the generator. The returned value has no colour-channel role until the program assigns it one. The code visits the cubes in their construction order, row by row, requesting three values per cell:

```gdscript
for mi in cubes:
    var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override
    mat.albedo_color = Color(
        _rng.randf(),
        _rng.randf(),
        _rng.randf()
    )
```

Eight rows of eight cubes consume 192 draws. These are material colour values; the room's lighting also affects the colour that reaches the eye. Wait before pressing REPLAY. Elapsed room time does not consume this colour generator's stream: regeneration is requested by controls and configuration changes.

## Change the procedure before changing the seed

Press +1 DRAW. Look at the seed captions and cube positions before comparing their colours. Between restoring the seed and colouring the last grid, the program performs this operation:

```gdscript
if _extra_on and i == _columns.size() - 1:
    for k in range(extra_draws):
        _rng.randf()
```

This room uses `extra_draws = 1`. The right grid consumes 193 draws in total, but still assigns only 192 values to its colours. If the stream begins a, b, c, d, e, f, g, the left begins (a,b,c), (d,e,f); the right begins (b,c,d), (e,f,g). No cube changes its position. Grouping the stream by threes creates the channel boundaries that one extra draw disrupts.

Press REPLAY with the extra draw still on. The difference returns too. The button does not restore the original procedure. +1 DRAW switches the choice on or off:

```gdscript
_extra_on = not _extra_on
_regenerate()
```

Press +1 DRAW again to restore the match. Repeated presses toggle one discarded draw; they do not accumulate two, three or four discarded values.

## A continuous gesture chooses an integer

Move the slider slowly enough to see its number change. The actual handle supplies a normalized position; the receiver rounds that position to an integer:

```gdscript
var norm: float = clampf(slider.get_normalized_value(), 0.0, 1.0)
_current_seed = roundi(norm * 999.0)
```

The current panel offers 1,000 seed values, 0 through 999. Neighbouring handle positions can choose the same integer. A neighbouring integer need not produce a visually neighbouring palette. This range counts available seeds, not a proof that every resulting palette is distinct.

RANDOM uses a second generator belonging to this artifact:

```gdscript
_current_seed = _pick.randi() % 1000
_regenerate()
```

It can choose an earlier seed, including the current one. It does not guarantee a new picture. This separate picker is randomized once on arrival; the colour generator is reset for each grid. These controls do not advance Godot's shared global random generator.

The slider now reads `Panel/Param_0`, matching the actual panel node. Its earlier receiver used an obsolete node path: a moving handle could leave the seed unchanged. Programmatic seed changes synchronize the handle under a guard, so an update is not misread as a new gesture. The number on the slider and the captions now agree after arrival, RANDOM and rebuilding.

## What must be kept?

Record the integer and whether the extra draw is on. To reproduce the picture, also keep the generator implementation, draw order and assignment to RGB. The in-hall REPLAY button reconstructs that current procedure. There is no save-seed control here; rebuilding the hall starts again from its configured seed, 42, and its configured comparison. Cross-version or cross-generator identity has not been established by this encounter.

Try using the offset palette as something you want to retain. The next room, Random_Entropy, changes the question: what can a histogram and one number retain when the order of a sequence changes?


## Spatial staging — 16 September 2026

The map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.

### DNA comparison

Three frozen ten_print_textile instances share seed 41, with diagonals, orthogonals and blocks. NEXT SEED advances all by three; RESET restores 41. Each cell consumes a choice and a tint draw. Controls share the compact console.
