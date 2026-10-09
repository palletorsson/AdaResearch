# Point Lines — keep two ends in relation

Take one endpoint. The other stays where it is. Between them, a pale segment turns and changes length. Two readings follow: a displacement and its length.

Point One gave a position a body. Point Coordinates adds a working hold and a frame in which to read its position. Here we use two positions in that same frame. The prepared handles supply the hold; the new work is the relation between them.

Open `point_lines.tscn` in the [Ada student starter](../../README.md). Use **Run Current Scene** (F6). Open `studies/point_lines/line.gd`. On desktop, approach a point, aim at it and press E to hold it. Move, then press E to release. It stays where you leave it. The XR route uses the supplied near-grip interaction.

## 1. Keep two positions

Inside `_ready()`, the script places two handles:

```gdscript
    a.position = Vector3(-0.75, 1.12, 0.0)
    b.position = Vector3(0.75, 1.12, 0.0)
```

`a` and `b` are references to the handles. Each `.position` is a `Vector3`. Both handles belong to `Study`, so their positions use the same reference frame. Keep Study's scale at one. In this room, one unit represents one metre.

The middle and last numbers agree. The first numbers place the handles 1.5 metres apart.

## 2. Subtract, then measure

Inside `_process()`, we read the relation again:

```gdscript
    var displacement := b.position - a.position
    var distance := displacement.length()
```

Subtract the start from the end. `displacement` is the change needed to get from A to B: initially `(1.5, 0.0, 0.0)`. It has a direction and a length.

`.length()` measures that vector and returns one number: `1.5`. The displacement is a `Vector3`; the distance is a `float`. A distance alone does not say which way to go.

Change B's first number from `0.75` to `0.25` in `_ready()`. Run again. The segment is now one metre long. You changed one endpoint; the relation supplied the new length. Restore `0.75`.

## 3. Turn without lengthening

Replace B's starting position with `Vector3(-0.75, 2.62, 0.0)`.

The segment stands upright. Its length is still 1.5 metres. The displacement is now `(0.0, 1.5, 0.0)`. A different direction can have the same length.

Restore B's original position. Change the subtraction to `a.position - b.position`. The displacement reverses. The distance stays the same, and the segment still joins the same two ends. Restore `b.position - a.position`.

## 4. Read it while it changes

This is the whole repeated part of `line.gd`:

```gdscript
func _process(_delta):
    var displacement := b.position - a.position
    var distance := displacement.length()
    segment.show_between(a.position, b.position)
    displacement_readout.text = str(displacement)
    distance_readout.text = "%.2f m" % distance
```

We reuse Point Zero's `_process()`. Each frame reads the current positions, draws between them and updates the text. `str()` makes text from a value. In the last line, `%` puts the distance into the `%.2f` slot: a number shown with two decimal places, followed by “m”. This rounds the display, not the stored positions. A small movement can leave the displayed number unchanged.

`show_between()` is a function in our supplied `Segment` script. We pass it the two positions. It places a thin cylinder between them and adjusts its length and orientation. The cylinder has a thickness chosen so we can see it. Its drawing code is included, but turning a mesh is not today's new operation.

Take one endpoint and move it. The handle supplies a new position; the relation responds. Release it. The script keeps reading even when nothing moves.

## What we borrowed

At the top of the file, `preload()` loads the two supplied scripts. `const` gives each a fixed name:

```gdscript
const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
```

`PointHandle.new()` creates a point with the supplied pickup behaviour. `Segment.new()` creates the cylinder. The lesson also creates its two `Label3D` readouts. Each node is added in `_ready()`; no teaching mesh or display is fetched from a scene file.

These are named dependencies. We can inspect or replace them while keeping the calculation between two positions.

## Two ends cannot keep a journey

Give B the same starting position as A. The distance becomes zero. The renderer hides a segment too short to draw; at coincidence there is no direction from one end to the other. Separate them again and it reappears.

Carry an endpoint around a detour, then return it to the same place. The calculation returns to the same result. It has kept no route.

The museum's walking line makes that absence visible beside a recorded trail. In Trace, we will keep the positions in between.
