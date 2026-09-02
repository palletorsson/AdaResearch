You took the grid.

The other door led to the trace, the line made once, by a body, and never again. This one leads here, where the line is made again and again until the making stops mattering, and where your movement is handed back to you as the nearest positions you were allowed to have had.

The last room ended on a question it could not answer for you: two losses, and which one you can live with. This room has decided. It lives with losing everything below a cell, and in exchange it keeps the address forever.

<!-- @player_trace -->

The recorder is at the door, the same instrument as before, a centimetre between points and a thousand and twenty-four of them before the oldest goes. But it is standing in a different room, and here it writes two lines from one walk.

The faint one is where you were, every frame, unquantised. The bright one is the cell the grid gave each of those positions, one metre to a side, and it comes out as a staircase. The gap between the two lines is not an error in either. It is what was thrown away, made visible for once, and the room keeps both so you can see the discard beside the thing it was discarded from.

`player_trace` writes your position into the cell it falls inside, not where it actually was.

Read that twice. It is the whole of the argument, and everything below is the mechanism.

<!-- @ -->

## Divide, round, multiply

```gdscript
const CELL_SIZE := 0.5

func world_to_cell(pos: Vector3) -> Vector3i:
    return Vector3i(
        int(round(pos.x / CELL_SIZE)),
        int(round(pos.y / CELL_SIZE)),
        int(round(pos.z / CELL_SIZE))
    )
```

Three operations, and the middle one is the room. Divide by the cell, round, multiply back. That is quantisation entire, the same three steps that make pixels out of a photograph and samples out of a sound, and the only thing that changes from one medium to the next is the number you divide by.

Notice where the loss happens. The trace lost at the sampling, and then its lines invented what lay between. Here the loss is at the *write*, and the write is idempotent: run it twice on the same position and nothing more is lost, because nothing is left to lose. Everything within a quarter of a metre of a node has become the node. And `round()` settles the tie the way the engine settles it, away from zero, so a body standing exactly halfway is pushed outward, away from the origin, by a rule nobody in the room wrote.

The origin is still here. Cell `(0, 0, 0)` is its cell, and every other address is counted from it in whole steps. What the first room excavated, this room has made a lattice of.

<!-- @grid_lines -->

Five cells a side, one metre each, and the frame was here before you were. It does not even turn.

Look at the middle of the room, where the floor is missing, and notice that the lines cross the hole anyway. Nothing is there, and it is addressed. That is the grid's confession, and it makes it out loud: a cell does not need an occupant to have a name. Once laid down, the lattice forgets it was laid down and presents itself as how space simply is, the way a surveyed section line comes to look like nature. The word for that register is *cadastral*, and it was invented for collecting tax.

<!-- @ -->

## It never forgets, and it never updates

```gdscript
var visited_cells: Dictionary = {}  # Vector3i -> timestamp

func _process(_delta: float) -> void:
    var cell := world_to_cell(learner.global_position)
    if not cell in visited_cells:
        visited_cells[cell] = Time.get_ticks_msec()
        highlight_cell(cell)
```

Read the `if`. The trace dropped its oldest point for every new one and forgot from the far end, two hundred frames at a time. This forgets nothing, and it also learns nothing after first contact. Pace one cell for an hour and the record holds a single entry, stamped with the first millisecond you crossed into it. Re-entry does not overwrite.

So the grid counts places and not time, and that is the loss it lives with: duration, entirely. The trace kept how long and lost what happened. The grid keeps *where*, once, forever, and cannot tell you whether you passed through or stayed.

<!-- @grab_sphere_point_snap -->

Reach for it. While you hold it, it follows your hand. When you let go it jumps, to the nearest whole metre, and the jump is a small discontinuity you feel in the arm before you see it. That tug is the lesson in your muscles: your intention landed between two addresses, and the grid decided which.

The table beside it shows the transaction in two columns: where you measurably were, and the name that will stand for it. `(2.37, 0.0, -1.83)` becomes `(2, 0, -2)`. The decimals are not rounded off. They are erased, because that is what addressing requires.

It snaps at a metre where the tutorial's cell is half that, and the coarseness is the point. Half a metre you might not notice. A metre you feel.

<!-- @ -->

## Comparable

```gdscript
func path_length_cells(path: Array) -> int:
    return path.size() - 1  # edges between consecutive cells
```

How far becomes how many. Two different bodies take two different walks through the same cells, and the function returns the same integer for both, and now they can be laid side by side, replayed, diffed, learned from. This is the promise the last room made on this one's behalf, that a grid is how two movements are made comparable, and here it is delivered with the price in plain sight. The same number for different walks is the point. It is also exactly what was thrown away.

```gdscript
func quantised_step(from: Vector3, to: Vector3) -> Array:
    var current := world_to_cell(from)
    var steps: Array = [current]
    while current != world_to_cell(to):
        var diff := world_to_cell(to) - current
        if abs(diff.x) >= abs(diff.y) and abs(diff.x) >= abs(diff.z):
            current.x += sign(diff.x)
        elif abs(diff.y) >= abs(diff.z):
            current.y += sign(diff.y)
        else:
            current.z += sign(diff.z)
        steps.append(current)
    return steps
```

A diagonal cannot exist here. Each step moves one axis, the one with the most left to go, so your straight line comes back as a staircase. The staircase is not a rendering artefact. It is what the grid believes your path was. The word is *aliasing*: the grid is a sampling frequency, and you moved faster than it samples. Shrink the cells and the staircase leans toward your line. It never becomes it.

<!-- @floating_sphere_field -->

The field drifts through the addresses without taking any. Five by three by eight metres, bounded again, and the spheres in it have positions the grid never asks for.

<!-- @3t -->

**THE GRID / THE TRACE.** The plaque carries both names with a slash between them, because this room is one half of an answer and it knows it. Both are made of the same thing, two points and a decision about what to keep, and the slash is the decision.

<!-- @room_grammar -->

On the floor, a plan being dealt by a rule: a rectangle split, and split again, into rooms, with doors cut where the grammar allows. It is not this room's plan. But it is the same hand, the grid's logic turned on walls, a decision about which differences count taken about where you may stand at all.

<!-- @ -->

## Whose grid

The room says the word out loud: quantisation is never neutral. A grid is a decision about which differences count and which fall below resolution, and once the decision is made, everything finer than a cell does not exist to the system. Not as a small value. As a fact. Foucault's disciplinary diagram is not a metaphor the room reaches for; it is the mechanism the room implements. The census, the timetable, the cell block, the pixel: each is a body made legible by being snapped to a frame it did not author. *Whose grid, and whose resolution* is the political question, and the room hands it to you as a tug in the arm rather than a slogan.

And then it refuses to let you off with the critique. The snap that erases your sub-cell body is the same snap that lets two bodies' paths be laid side by side. The discipline is the condition of the comparison. Surveillance and science are one operation, and the room asks you to hold both in one gesture: the loss of the continuous self, and the birth of the shareable record.

That doubled feeling, fit and misfit at once, is the thing to keep.

The next room adds a third point, and three points do something two cannot. They close.
