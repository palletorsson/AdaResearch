The least-cost curve is computed by its boundary, not drawn by a hand.

Two of the oldest solved minimisations in the world stand in this room. A hanging chain finds the catenary, the exact curve of least potential energy for a rope between two points. A soap film finds the minimal surface, the least area that can span a wire frame. Nobody drew either. They are computed, continuously, by matter obeying one instruction: spend the least. The last hall had a solver stepping toward an answer and trembling short of it. Here there is no solver at all, and the answer is exact.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

One function does both. `cosh` is the hanging chain, and a hanging chain spun about its axis is the soap film. The waist of the surface is where the chain is slackest, and the number that sets it, `c`, is the only parameter either shape has.

## The chain

<!-- @cable_builder -->

Four cyan beads at ankle height, and a four-metre cable glowing magenta into blue slung through them with its belly grazing the floor. The beads are the only thing in this room you can actually take hold of. Move one and the whole curve recomputes and re-skins in your hands, every frame.

Read it carefully, because it is the room's honest object. The cable is not a chain solving its own equation. It is a spline whose sag is two Bezier handles per span, each pulled down by a fixed fraction of that span's length, so the depth is drafted rather than found. It is a very good drawing of a catenary made by somebody who knew what one looks like, and the difference matters enormously here, because everything else in this room got its shape without anybody knowing in advance what the shape would be.

<!-- @laundry_line_cathedral -->

Three washing lines pegged with towels and shirts, and these are true `cosh` curves rather than good drawings. Only one of the three has a pole under either end; the other two simply begin and end in the air, which nothing in the room admits. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. That is Gaudí's trick, and it is the reason this is the hero of the room. He hung chains from a ceiling, photographed them, and turned the photograph upside down, because a chain in pure tension inverted is an arch in pure compression, and the curve that costs least to hang is the curve that costs least to stand. He let gravity do the drawing and then read the drawing the other way up.

<!-- @ -->

## The film

<!-- @catenoid -->

The chain, spun. A soap film between two rings makes this surface and no other, because surface tension is a cost per unit area and this is the least area that will reach both rings. It lies low and wide on the floor, a cyan wireframe hourglass about a metre and a fifth across and only a third of a metre tall, and it is the same `cosh` as the laundry line, revolved.

It looks as though you could pick it up, and you cannot. It is built as a physics body on the layer the world's static geometry uses, which is the one layer a hand is told to ignore, so it carries a collider that no grab will ever find. Three separate documents in this project say you can lift it.

<!-- @helicoid -->

In a slot between two pillars, the other one, and you will step over it before you notice it: a green wireframe corkscrew twenty centimetres across and a third of a metre high, six thousand triangles in a thing the size of a mug. A plane rotating as it rises, two full turns, three tenths of a turn's height gained per turn.

Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces there are, and one bends continuously into the other without a single point of either ever stretching. They are the same film in two poses. Nothing in this room performs that bend. Both surfaces are computed once when the hall loads and then never touched again, so the deformation is a fact you are told and not a thing you can watch.

<!-- @science_screen -->

The screen looks for something within eight metres whose name it recognises, and finds the laundry line, whose name contains the word it is hunting for. It misses. The washing lines stand eight and two thirds metres away, sixty-six centimetres outside its reach, so the screen settles for its fallback and prints a position of zero. It is the only thing in this room that would draw a curve rather than be one, and it is standing just too far off to draw anything at all.

<!-- @ -->

## Matter as the solver

The chain does not iterate. It does not sample its neighbourhood, take a step, and check whether things improved. It is already in the shape that costs least, at every instant, and if you move an end it is in the new one immediately. That is what makes these two problems the oldest solved ones: they were solved before anybody could state them, by rope and by water, and the mathematics arrived centuries later to describe what the rope had been doing all along.

The calculus of variations is that description. The room is the thing it describes.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.
