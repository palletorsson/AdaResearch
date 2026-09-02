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

Four control points you can take hold of, and a cable four metres long strung through them. Move one and the whole curve recomputes and re-skins in front of you. This is the room's honest object, so read it carefully: the cable is a spline sagged by a fixed fraction between its handles, not a chain solving its own equation. It is a very good drawing of a catenary, made by somebody who knew what one looks like. The difference between that and the real curve is small, and the chapter cares about it enormously, because everything else in this room got its shape without anybody knowing what the shape would be.

<!-- @laundry_line_cathedral -->

Three washing lines between poles, pegged with towels and shirts, and these are true `cosh` curves rather than good drawings. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. That is Gaudí's trick, and it is the reason this is the hero of the room. He hung chains from a ceiling, photographed them, and turned the photograph upside down, because a chain in pure tension inverted is an arch in pure compression, and the curve that costs least to hang is the curve that costs least to stand. He let gravity do the drawing and then read the drawing the other way up.

<!-- @ -->

## The film

<!-- @catenoid -->

The chain, spun. A soap film between two rings makes this surface and no other, because surface tension is a cost per unit area and this is the least area that will reach both rings. You can pick it up. It is the same `cosh` as the laundry line, rotated about the axis, with its waist set to half a metre at the scale on the plinth.

<!-- @helicoid -->

Beside it, the other one. A plane rotating as it rises, a spiral staircase with infinitely many steps, rising three tenths of a turn's height per turn and making two full turns on its stand. Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces there are, and here is the fact worth carrying out of the room: one bends continuously into the other without a single point of the surface ever stretching. They are the same film in two poses.

<!-- @science_screen -->

The screen redraws what stands near it as a flat diagram, once a second. It is the only thing in this room that draws a curve rather than being one, and next to a chain that computes itself, a picture of a chain looks like what it is: a record, made afterwards, by something that had to be told.

<!-- @ -->

## Matter as the solver

The chain does not iterate. It does not sample its neighbourhood, take a step, and check whether things improved. It is already in the shape that costs least, at every instant, and if you move an end it is in the new one immediately. That is what makes these two problems the oldest solved ones: they were solved before anybody could state them, by rope and by water, and the mathematics arrived centuries later to describe what the rope had been doing all along.

The calculus of variations is that description. The room is the thing it describes.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.
