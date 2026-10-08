# Make a colour return

**Learning elements**

- Seeded generators
- Draw order
- Value assignments

In the room, a seed helped us recover a colour arrangement. Here we will make that return ourselves: give one cube a generated colour, repeat it, then change the result without changing the seed.

This builds on `_ready()` from Point Zero, arrays and loops from Array, and material colour from Colour. The new tool is a local `RandomNumberGenerator`. We borrow its internal algorithm, just as we borrow the renderer. What we will control is when it draws and what those draws become. Random Entropy will ask what remains when we count the values instead of keeping their arrangement.

Use the [standalone study](/book-review/doc/book/iterations/2026-09-30-random-definition-making/random-definition-study.zip), with Day Zero's editor and run workflow already in place. Work in `study.gd`; keep `study.tscn` as the main scene. `display.gd` supplies the cubes, one material per cube and a REPLAY button. It does not request random values. Each numbered file in `steps/` is a complete version you can copy into `study.gd` if you lose your place.

## 1. Give one cube three values

The project opens at this first step. Its complete script is:

```gdscript
extends Node3D

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	$Display.build(1, false)
	replay()

func replay() -> void:
	var cube: MeshInstance3D = $Display.left[0]
	var material: StandardMaterial3D = cube.material_override
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	material.albedo_color = Color(a, b, c)
```

`$Display.build(1, false)` asks the supplied display for one cube and no second grid. The cube is the first member, `[0]`, of its `left` array. `material` refers to that cube's own material. These are the things already prepared for us; the three calls to `rng.randf()` are our new work.

Each call returns one number between zero and one. `Color(a, b, c)` assigns them to red, green and blue, in that order. Press REPLAY or Space. The helper calls `replay()` again; the generator continues from where the previous calls left it. Repetition is possible, but we have given it no instruction to recover a chosen colour.

## 2. Give the return a beginning

Add this variable beside `rng`:

```gdscript
var seed_value := 42
```

Then make this the first line inside `replay()`:

```gdscript
rng.seed = seed_value
```

Press REPLAY several times. Nothing appears to happen, although the code has requested three values again. Setting the seed puts this generator back at the same beginning. Change `42` to `137` and run again. Keep a colour you like by keeping its seed and this procedure. The complete version is `steps/02-seed.gd`.

## 3. Let the array receive the sequence

Change the display request to `$Display.build(4, false)`. It now gives us a 4 × 4 grid. In `replay()`, keep the seed reset once at the start, then colour each cube:

```gdscript
rng.seed = seed_value
for cube in $Display.left:
	var a := rng.randf()
	var b := rng.randf()
	var c := rng.randf()
	var colour := Color(a, b, c)
	var material: StandardMaterial3D = cube.material_override
	material.albedo_color = colour
```

The loop reuses Array's ordered collection. Three draws per cube, sixteen cubes: forty-eight values receive a place. The supplied display orders cubes left to right, bottom row first, as the museum instrument does. REPLAY keeps the arrangement. The complete version is `steps/03-grid.gd`.

Try moving the seed reset inside the loop, just before `var a`. Every cube now starts at the same three values. Move the reset back outside. Its position changes the pattern without changing the seed.

## 4. Put two beginnings beside each other

Use `steps/04-pair.gd`. Its display request is `$Display.build(4, true)`. The same colouring loop is now a function called `colour_grid(cubes)`. `replay()` calls it once with the left array and once with the right:

```gdscript
colour_grid($Display.left)
colour_grid($Display.right)
```

The function resets the generator **before each grid**. Check the same cell on both sides. Press REPLAY and check another. If we reset only once before both grids, the right would continue after the left's forty-eight draws. Equal seeds are useful here because we also keep the requests and their assignment equal.

## 5. Spend one value without colouring anything

Use `steps/05-unused-draw.gd`. A `skip_first` argument tells `colour_grid` whether to make this extra request, after resetting the seed and before entering the cube loop:

```gdscript
if skip_first:
    rng.randf()
```

`replay()` passes `false` for the left grid and `true` for the right. The left uses forty-eight draws; the right consumes forty-nine but still gives forty-eight to its colours. REPLAY now recovers the difference too.

Follow the first cube: the left takes `(a, b, c)`; the right takes `(b, c, d)`. No value has changed its position in the generated stream. A different part of that stream is being assigned to each channel.

## 6. Keep the draws. Change their roles.

Return to the matched pair from step 4, removing the unused draw. This time keep both beginnings equal and swap the right grid's red and blue assignments. `steps/06-channel-roles.gd` is the complete version. Its loop first constructs:

```gdscript
var colour := Color(a, b, c)
```

Then, only for the right grid:

```gdscript
if swap_channels:
    colour = Color(c, b, a)
```

Find a cube with visibly different red and blue amounts. Its green stays the same. Both grids consumed the same forty-eight values. We changed what a value does, without requesting another one.

Choose which comparison you want to keep. Then replace the right-hand assignment with `Color(a, a, a)`: one requested value now supplies all three channels. The other two requests remain in the loop, so later cells still begin at the same place in the stream.

You now have a small construction you can alter: a generator, a repeatable beginning, an ordered array and a choice about what each value becomes. The colour grids are one use of those parts. Their arrangement no longer has to exhaust what the program can do.

## Beside this lesson

The museum has 8 × 8 grids and twenty-four-draw bar strips; this study uses 4 × 4 grids so individual cells stay easy to compare. Both use Godot's generator and the same reset → request → assign order. The bars show a short prefix, not evidence from which to infer the generator's period. Godot documents reproducible seeded sequences but treats the underlying algorithm as an implementation detail: keep the engine version with a study you need to reproduce.

[Technical companion](/book-review/commons/maps/Random_Definition/technical.md): current placement, controls, state restoration and implementation references. [Godot's generator reference](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html).
