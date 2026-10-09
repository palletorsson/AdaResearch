# More pieces, less material

<!-- @cantor_set -->

One bar is waiting. Where could it go if we let it become two?

Press NEXT. The new pair appears beneath it. Their outside ends reach as far as the first bar, but the middle is missing. Press again. Look for the new gaps before counting the pieces. Each piece has lost its own middle; the first large gap has not been divided or repaired.

The trees sent another branch into space. Here another generation leaves less behind. At the fifth cut, thirty-two pieces share less than a metre of the six metres we began with. The desk counts the latest row. Above it, the old bars are still present. The whole display has become busier while the thing it is recording has become smaller in total length.

Turn HISTORY off. There is much less to look at. The kept length does not change. The earlier rows were a record we added so we could follow the operation. They were never extra members of the latest generation.

GHOST brings back pale marks where this generation cut its middles. They have no collision. The display can remember an absence without filling it with something that supports a body. Turn HISTORY on again and follow the larger absences upwards to the rows where they first appeared.

These two lines make the next pair in the bar's code:

```gdscript
var new_length = bar_length / 3.0
var offset = bar_length / 3.0
```

The new bars are placed at the old centre minus that offset and the old centre plus it. Their width is `new_length`. Two thirds remain, separated by the third for which we create no solid bar. Repeating the operation gives us:

```text
pieces      = 2^n
piece length = 6 / 3^n
kept length  = 6 * (2/3)^n
```

The count rises as the retained length falls. Neither number tells us how much work the renderer is doing. With history visible, it draws every earlier row as well. At five cuts that means sixty-three solid bars, before we count the ghosts, the desk or the rest of the room.

The screen stops at five. Its smallest pieces still have width, height and depth. The mathematical construction asks us to continue without a last cut. Its limiting set has zero total length and uncountably many points. We have not displayed that limit. We have made a finite instrument for approaching its rule.

From here the gaps can look generous. Carry that impression up the ramp.

<!-- @example_8_4_cantor_pagoda_vr -->

There is a broad opening under the pink beam. Walk through it. The same removal that interrupted a bar now offers a passage.

Return to the desk and press CUT twice. Smaller openings appear beside the first one. Choose one that looks wide enough, go up the ramp and try it. At this setting the gaps include three metres, one metre and a third of a metre. All are gaps. They do not all admit the same body.

The rule supplied intervals. The pagoda gave them height and depth, stacked their history above them, and made their surfaces collide with us. Here is the box shape used by its collision code:

```gdscript
shape.size = Vector3(width, block_height, block_thickness)
```

The interval's width is only one of those three decisions. Press DEPTH: the passage becomes longer or shorter while its opening stays the same width. LATEST removes the earlier levels overhead. The ground-level intervals remain; the roof was our way of arranging their past.

Try the narrow gap once more. The simulation does not collide with every fold of your clothes. It tests a proxy body. A passage can exclude that body even when the eye can travel through it. The obstruction belongs to a relation between the gap and the body we have implemented. To make a way through, we could widen the opening, change the body, or change which surfaces count as solid. Each choice makes a different world.

More cuts have made more openings, but many are too small for this visitor. Nothing in the operation promises that more detail will make more room for us. And still we want to look inside. That desire can lead us back to the rule, to ask which of its decisions might move.

<!-- @ -->

The smaller Cantor drawing, the three trees, the cloud and the dark sphere remain around the experiment. Their kinds of repetition do not have to resolve into one shape. Further on, Koch will put a detour into a line; Sierpinski will carry removal into a triangle. We have learned to lose length while multiplying pieces. What happens when the next rule makes the boundary grow instead?
