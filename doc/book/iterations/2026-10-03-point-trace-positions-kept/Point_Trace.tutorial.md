# Point Trace — keep the way through

Move the point in a loop. Let go. The point stops, but the loop remains: a line through positions the point has left behind.

In Point Lines, two positions were enough to draw a segment. Each frame replaced the previous reading. Here we keep readings in order, so the route can outlast the movement.

Open `point_trace.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). The lesson script is `studies/point_trace/trace.gd`. Hold the point as you did in Lines. This study makes one continuous record; releasing holds the point still, and taking it again continues that record. Restart the scene for a fresh drawing.

## 1. Give positions somewhere to stay

```gdscript
var points: Array[Vector3] = []
var spacing := 0.08
var capacity := 128
```

`points` is an **Array**: an ordered list. `Array[Vector3]` says what it can hold. Each entry is one position, with three coordinates. The list itself has one index: first entry, second entry, third entry. It is a one-dimensional list of three-dimensional positions.

`[]` starts it empty. Inside `_ready()`, after placing the point, we keep its first position:

```gdscript
    points.append(point.position)
```

`append()` adds a value at the end. It stores the position at that moment. Moving the point later does not move that saved position.

## 2. Decide when to keep another

These lines run inside `_process()`:

```gdscript
    var displacement := point.position - points[-1]
    if displacement.length() >= spacing:
        points.append(point.position)
```

`points[-1]` reads the last entry. We reuse Lines' subtraction and length to measure from that saved position to the point now.

`if` introduces a condition. `>=` means “greater than or equal to”. The indented line runs only when the distance reaches `spacing`: here, 0.08 metres, or eight centimetres. Smaller movements accumulate as a separation from the last saved position; they do not each become entries.

Move slowly, then stop. The count stops increasing. Point Zero's frames still pass, but this list records positions rather than elapsed time. A long pause leaves no extra entry to show how long you waited.

## 3. Join neighbours in the list

After adding a position, the script redraws the retained route:

```gdscript
        drawing.clear()
        for i in range(1, points.size()):
            drawing.join(points[i - 1], points[i])
```

`size()` gives the number of entries. Their indexes start at zero. With four positions, the indexes are `0, 1, 2, 3`.

The **for loop** repeats its indented line. `range(1, points.size())` supplies indexes from 1 up to, but excluding, the size. With four entries, `i` becomes 1, then 2, then 3. The pairs are therefore `0–1`, `1–2`, `2–3`: three segments through four positions.

This loop finishes a traversal of the saved list. `_process()` returns each frame to inspect movement. One repeats through entries; the other repeats over time.

`TraceDrawing` is the supplied display. `clear()` clears the drawing; it leaves `points` alone. Each `join(a, b)` reuses Lines' segment renderer and marks its endpoints with small pink dots. Drawing thickness and mesh construction stay in that helper. The loop deciding which positions to join is yours.

## 4. Change what the route can retain

Change `spacing` to `0.25`. Run again and make a similar loop. Fewer positions are kept; the straight connections cut across more of the curve. Restore `0.08` and compare.

Spacing is a minimum separation, not a guarantee that every eight centimetres is recorded. We inspect once per frame. A fast move can leave a larger gap, and the drawing joins its ends without knowing what happened between them.

The record also has a limit:

```gdscript
        if points.size() > capacity:
            points.pop_front()
```

`pop_front()` removes the oldest entry. The remaining entries keep their order. Change `capacity` to `32` and continue drawing. Once the count reaches 32, a new position replaces the oldest; the far end of the route begins to disappear. Waiting alone removes nothing. Restore `128` when you want a longer record.

The museum's pens combine a movement threshold with a grid that shapes each saved position. This smaller study follows the handle's centre without snapping it to a grid. All positions use Study's reference frame. Grid is the next distinction: keeping a position and assigning it to a cell are different decisions.
