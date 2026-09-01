A point had no parts. Two of them have a distance.

That is the whole gift of this room, and everything difficult in it follows from that one addition. Not a new object — a *relation*, which is worse, because a relation can be written down.

<!-- @street_talker -->

The board at the door says four words: *two points, a distance, a segment, a direction.*

They are not four names for the same thing, and the room is the demonstration. A distance is a single number. An infinite line has no length at all. A segment has one because somebody chose two ends. A direction is what is left when you throw the length away. Each is the one before it with something added — and the something is always a body.

<!-- @ -->

## Two points, and what is between them

```gdscript
const GRID_SIZE := Vector2i(8, 8)
const SPACING := 1.0
```

Two points determine a line. To keep only what lies between them is already a decision.

<!-- @two_points_line -->

Here are the two ends, and here is what was kept. Move either one and the between re-computes without being asked — which is the first sign that the segment is not a thing you drew but a *rule you agreed to*. You are holding one end of a promise, and the rest of the line, the infinite part, is still out there in both directions, unkept.

<!-- @klee_walking_point -->

A line is a dot that went for a walk. Klee said it and it stayed said, because it puts the time back in: the line is not a shape, it is the record of something having moved. Nothing here shows the walking. You get the trace and are asked to believe in the walk.

<!-- @ -->

## Length is length

Distance is a relation between two points. Length is a property of the segment — of the part you decided to keep — and that difference is where everything starts, because a property can be written on a label.

<!-- @scale_lines -->

Rungs, ascending. Once you can say *how much*, you have a unit, and a unit came from somewhere — a foot, a forearm, a platinum bar in a vault outside Paris, and since 1983 the distance light travels in 1/299792458 of a second. The metric system is not a discovery about space. It is a decision about which line to trust.

<!-- @modulor_man_demo -->

Le Corbusier took one imaginary man — 1.83 m, six feet, the handsome policeman of an English detective novel — and made his body the measure of doorways, ceilings and chairs for a generation. Nobody was measured. The earlier version of the system used 1.75 m and was revised upward because six feet is a rounder number in the system he was arguing against. Stand next to him. The scale is either yours or it is not, and if it is not, the building will keep telling you so in small ways for as long as you are inside it.

<!-- @two_point_ruler -->

Stop adjusting the segment and it becomes a ruler. That is the whole of metrology in one gesture: not a special object, just a distance somebody decided to keep.

Read the pale block. It measures 0.50 m, and it goes on measuring 0.50 m however many times you ask, because reading a thing does not change it.

The blue block, which you did not measure, is smaller than it was.

Nothing here is lying to you. The number is right, the subject is untouched, and the readout has no way of mentioning that what it described and what it altered were two different objects. You cannot catch it while you are doing it — watching the other block means taking the rule off this one. The only way to see it is to stop measuring and look somewhere you had no reason to look.

<!-- @walk_this_line_marking -->

Paint on the floor, and you follow it, and nobody asked you to. A measure only has to be *drawn* to start being obeyed.

<!-- @ -->

## Crossing

```gdscript
func connect_horizontal() -> void:
    for y in GRID_SIZE.y:
        for x in range(GRID_SIZE.x - 1):
            draw_line(points[y][x].position, points[y][x + 1].position)
```

On a plane, two lines have exactly two options.

Keep hold of that qualifier. You are standing in three dimensions and the room is about to speak as though you were not.

<!-- @plus_line_puzzle -->

They meet once. Two lines that cross agree on precisely one point and disagree about every other point in the universe, and we call that agreement an intersection, as though it were a place. It is a coincidence with a name.

<!-- @parallel_line_puzzle -->

Or they agree never to. Parallel is the stronger claim: not *they have not met yet* but *they will not, ever, however far you follow them*. It is a promise about infinity made by two short segments in a small room, and everything built square is built on it.

<!-- @ -->

## And then it points

Give the segment an order — from here to there — and something new appears. It points.

```gdscript
var displacement := b - a
var distance := displacement.length()
var direction := displacement.normalized()
```

Three lines, three different objects, and the philosophical distinction and the computational one are the same distinction. `b - a` is a displacement: it has a size and a way round. `.length()` throws the way round away and keeps a number. `.normalized()` throws the number away and keeps the way round. Nothing is left of the segment in either result, and neither result can be turned back into it alone.

Pick the third one up, and it is something you aim.

<!-- @grabbable_line -->

You measure by pulling. That is the moment the body enters: the hand is now inside the instrument, and the reading depends on where you decided to stop. Every measurement in this room is a measurement of your reach as much as of the thing.

<!-- @laser_measure -->

The beam finds the distance to whatever it lands on. Nothing about the beam knows what that is.

<!-- @laser_exploding_sphere -->

The same object. The same straight line, aimed the same way, with something different at the far end. Pointing and destroying are not two techniques; they are one technique and two situations, and the line cannot tell them apart. Nothing in the vector records the difference.

<!-- @line_demo -->

Make one yourself. Two snap points and the segment between them, and you can pull the ends until the length is whatever you wanted. It is just a line. Nothing about it is doing anything.

<!-- @line_sledgehammer -->

Two seconds later it is a sledgehammer.

Not a metaphor and not a reward — the same object, still two points and everything between them, still a length and a direction, with a mass at one end and your hands at the other. Nothing was added but the body. That is the last rung of the escalation this room has been climbing since the first paragraph, and it took two seconds and no new geometry.

It has to be *swung*. Resting it against something does nothing, which is the difference between a hammer and a wand: the damage is not in the object, it is in what you did with it.

<!-- @do_not_cross_barrier -->

And a line drawn to keep you out is still just two points and a rule. It has no force. It stops you anyway.

Until you swing at it. Then it turns out to have had no force at all — it falls over, still legible, and the way is open. Both halves of that sentence had to be true for either to mean anything, and until there was something in the room that could break it, only the second half was.

You do not have to. It is a police line and a prohibition and somebody put it there, and walking round it costs nothing. But the room has now made the choice available, and *available* is a different thing from *forbidden*, which is what the barrier was pretending to be.

<!-- @ -->

## Vertical, horizontal, and the one that lies

```gdscript
func connect_vertical() -> void:
    for y in range(GRID_SIZE.y - 1):
        for x in GRID_SIZE.x:
            draw_line(points[y][x].position, points[y + 1][x].position)
```

Horizontal and vertical are the same function with the indices swapped. Space does not have a preferred axis; the code does, and only because someone wrote `y` first.

<!-- @perspective_lines -->

And here parallels meet after all — not because they stopped being parallel, but because you are standing somewhere. Perspective is the one honest confession the room makes: every reading so far has had a position in it, and this is the only place that says so out loud.

<!-- @fontana_puncture -->

One cut. Not a line drawn on the surface — a line that goes *through* it, which is the only way to prove the surface was ever there.

<!-- @ -->

## The fork

```gdscript
func graph_stats() -> Dictionary:
    var V: int = GRID_SIZE.x * GRID_SIZE.y
    var E: int = (GRID_SIZE.x - 1) * GRID_SIZE.y + (GRID_SIZE.y - 1) * GRID_SIZE.x
    return {"vertices": V, "edges": E}
```

Lines that repeat become countable. Lines that are countable become a structure.

<!-- @dgrid -->

The grid: the line made regular, repeatable, and completely indifferent to you. It is enormously useful and it does not care where you are standing, which are the same property described twice. What does not fit it is remainder — not wrong, just not counted, which in practice is the same thing.

<!-- @ -->

Two exits, and they are opposites.

The **grid** is the line made again and again until the making stops mattering. The **trace** is the line made once, by a body, and never recoverable. Both are made of exactly the same thing: two points, and a decision about what to keep.

The next rooms are those two. Not in order of difficulty — in order of what you are willing to give up.
