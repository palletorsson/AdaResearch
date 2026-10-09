# Point Grid — your trace returns

Find the bend you made in Trace. It is here again. Beside it, the same record has been placed on a grid. Change the spacing and compare what happens to that bend.

## 1. Bring the drawing with you

In the [Ada student starter](../../README.md), open `point_trace.tscn`. Hold the point, draw, then release it. On desktop, mouse movement directs the held point; in VR, your tracked hand moves it. Wait for **Saved for Point Grid**.

Stop the scene and run `point_grid.tscn`. It loads that saved trace. If no usable trace has been saved, it asks you to return and draw one. It does not substitute a demonstration for your gesture.

The supplied `TraceMemory` keeps the latest released record on this device. It carries positions between the two lessons, including across separate runs. Opening Grid does not change the saved record. Returning to Trace, drawing and releasing saves a new one.

## 2. Keep the source and the result separate

Open `studies/point_grid/grid.gd`. We have two lists:

```gdscript
var source_points: Array[Vector3] = []
var grid_points: Array[Vector3] = []
var grid_size := 0.25
```

Both hold positions in metres. `source_points` receives the saved trace:

```gdscript
    source_points = TraceMemory.read_trace()
```

`grid_points` begins empty. We will fill it with new values, leaving the source alone. A quarter of a metre is our chosen grid spacing. All calculations use the Study frame in which Trace recorded the points.

## 3. Give each saved position an address

Trace's drawing loop visited neighbouring entries by index. This loop takes each stored value in turn:

```gdscript
    for p in source_points:
        var address := Vector3i(
            roundi(p.x / grid_size),
            roundi(p.y / grid_size),
            roundi(p.z / grid_size)
        )
        var placed := Vector3(address) * grid_size
        grid_points.append(placed)
```

For every position `p`, divide each coordinate by the spacing to count grid intervals. `roundi()` gives the nearest integer. `Vector3i` holds these three whole-number counts: the grid address.

For example, X = `0.12` metres is `0.48` quarter-metre steps, which rounds to zero. X = `0.13` metres is `0.52` steps, which rounds to one. A small difference in the saved input can put two results a quarter of a metre apart.

`Vector3(address)` turns the integer components into floating-point components. Multiplying by `grid_size` gives metres again. `append()` adds that result to the new list. Negative coordinates use the same rule; exact halfway values round away from zero.

Each input produces one output. Nearby samples may acquire exactly the same position, but we keep their entries and their order. An array index names a sample in the record; a grid address names a place. Several samples can name that same place.

## 4. Change the reading, keep the gesture

The supplied display draws the two lists:

```gdscript
    comparison.show_traces(source_points, grid_points, grid_size)
```

Pink shows your saved trace. White shows the grid version. Both use the same centring and display scale, with a sideways offset so you can compare them. These display adjustments do not edit either list. The faint ruling is one XY section; the rounding still uses all three coordinates.

Change `grid_size` from `0.25` to `0.5` and run Grid again. You do not have to redraw. It rereads the original trace and calculates another result. Pink stays the same while the white drawing changes. Try `0.1` next. Use a positive spacing.

The display joins consecutive entries directly. Equal neighbours produce no segment; a jump can produce a diagonal. It does not invent samples between those you made. A finer grid can retain more of the saved shape, but it cannot recover movements that Trace never recorded.

We have reused a drawing as data. Its shape can now be read under another rule without losing the earlier record. In Triangle, we will choose corners and give their connections another job: closing a boundary, then making a face.
