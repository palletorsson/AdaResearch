# Point Grid — a place to return to

Move the pink point slowly. A smaller white marker waits, then jumps. Your point can move while the marker keeps its place.

Trace kept positions after enough movement. Here we give each position a grid address and keep a new position when that address changes. The list and drawing loop are already ours; the new operation is rounding.

Open `point_grid.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). Edit `studies/point_grid/grid.gd`. The same supplied handle provides the hold. The script creates the white marker as Point One created its sphere. Three readouts show the input in metres, its grid address, and the resulting placement in metres.

## 1. Count steps from an origin

The grid has a chosen spacing:

```gdscript
var grid_size := 0.25
```

One step is a quarter of a metre. All positions use Study's frame. Keep its scale at one: one unit represents one metre.

Inside `_process()`, we read the point and calculate its address:

```gdscript
    var p := point.position
    var address := Vector3i(
        roundi(p.x / grid_size),
        roundi(p.y / grid_size),
        roundi(p.z / grid_size)
    )
```

For each coordinate, divide by the spacing to count steps. `roundi()` rounds that count to the nearest integer. `Vector3i` holds three integers, while `Vector3` holds three floating-point numbers. The address counts grid intervals; the position measures metres.

The starting X value is `0.12`. Dividing by `0.25` gives `0.48` steps. The nearest whole number is zero. Y is `1.25` metres, exactly five steps; Z is zero. The address is therefore `(0, 5, 0)`.

## 2. Give the address a position

```gdscript
    var placed := Vector3(address) * grid_size
    marker.position = placed
```

`Vector3(address)` converts the integer components into floating-point components. Multiplying by the spacing gives metres again. Address `(0, 5, 0)` becomes position `(0.0, 1.25, 0.0)`.

We move the marker to this result. The held point keeps its own position. Calculating an address does not force your hand onto it.

In `_ready()`, change the point's starting X from `0.12` to `0.13` and run again. The address becomes `(1, 5, 0)`. The input changed by one centimetre; the placed X changed by twenty-five centimetres. You crossed the halfway boundary between two grid positions.

Try `-0.12`, then `-0.13`. Negative addresses extend the same rule to the other side of zero. At an exact halfway value, Godot rounds away from zero.

## 3. Keep an order of visits

We reuse Trace's `Array[Vector3]`. The first frame seeds the empty list. After that, we add a position only when it differs from the last one:

```gdscript
    if points.is_empty():
        points.append(placed)
    if placed != points[-1]:
        points.append(placed)
```

`is_empty()` tests whether the list has no entries. `!=` means “not equal”. Moving within one address adds nothing. Moving away and returning adds another visit to that address. The record keeps an order, so a place can occur more than once.

An array index and a grid address do different jobs. `points[3]` reads the fourth visit; it does not mean the fourth column of the room.

The existing loop joins each retained position to the next. These segments can run diagonally. The code does not fill in skipped addresses or find a route along the ruled lines. Trace's capacity limit still keeps at most 128 positions.

## 4. Change the agreement

Restore X to `0.12`. Change `grid_size` to `0.5` and restart. Move, pause, and try to return to a place you left. The larger spacing gives a wider region of input positions the same address. Use a positive spacing; zero cannot divide a position into steps.

The supplied `GridRuling` redraws the reference lines at the chosen spacing. It shows only the XY section at Z = 0, with grid indices along its edges. Move the point towards you: the third address component changes too. The rounding works in three dimensions even though this section is flat.

This is a reduced version of the hall's snapping artifact. Its finer grid, release alignment and table add other ways to inspect the rule. Here the marker shows the result while the held point stays free.

A grid can help endpoints find the same place again. It supplies neither a face nor collision. Next we can arrange three points, close their boundary, and ask what it takes to put a surface inside.
