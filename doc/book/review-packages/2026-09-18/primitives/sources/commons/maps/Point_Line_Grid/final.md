Look for your bend. It may have grown.

A drawing released in Trace can arrive here as a list of positions. Over the ruled field, a small movement has acquired another size. Keep it in view. We are going to give positions addresses, then ask what those addresses help us make.

## Find somewhere to return

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it slowly, watching its marker and the retained line. Try to move without adding a new place to the record. Then go far enough for another place to appear.

Trace already made choices about which positions to keep. Here, look at the table's other way of naming them. Beside the coordinates in metres are integer indices. With this tool's five-centimetre spacing, `0.15` metres along X has index `3`: three spacings from world zero. The same place has two names.

The calculation, reduced to one axis, is:

```gdscript
var index = roundi(pos.x / grid_size)
var placed_x = index * grid_size
```

Divide by the spacing. Round to the nearest integer. Multiply back to get metres. At this spacing, `0.12` becomes `0.10`; `0.13` becomes `0.15`. One centimetre of movement can carry the record across a five-centimetre interval. Elsewhere, a larger movement can leave its address unchanged.

Let go. The tool brings its marker onto the lattice. Pick it up and try to return to that address. You have some room to be imprecise and still arrive at the same result. That can be useful: we may want two pieces to meet without having to place them by eye.[^point-grid-bowker-star]

The table gives another name to the retained position. It does not show the unrounded position beside it. We still need your movement to notice what this record leaves out.

## Give the interval a rhythm

<!-- @player_trace -->

Now walk a small loop, then a wider diagonal. Look behind you. The walking recorder keeps a finer sampled reference and a path rounded to one-metre spacing in its own frame.

Find a place where you can move while the coarse address holds. Slowly cross into another. Cross back. There is a rhythm in the jump, and room to move within the interval. A rule for making positions agree has also given us something to dance with.[^point-grid-ahmed-return]

In VR, lean with your feet planted. The recorder can respond: it follows the headset horizontally, using the rig's origin for height. On desktop it follows the walking body. It must choose a point before it can draw a path called yours.

The lines connect the positions it keeps. A diagonal can cut across ground you went around. Returning to an earlier address can add another turn to the record; the program keeps an order of visits, not just a collection of places visited once. An address lets us recognise a return. It does not tell us why we came back.

## Let the drawing find another use

<!-- @grid_lines -->

Return to the ruled field. Find your bend in pink, then compare green. Is it still your bend at this size? If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and let go. The whiteboard and walking recorder keep separate records.

This display subtracts the centre of the received drawing's bounds and applies a scale:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Pink shows the drawing centred and scaled. Small drawings grow fivefold; larger ones receive a smaller multiplier to fit within five metres. Green rounds the displayed positions again, with six intervals per metre along each axis. The source positions listed in the panel stay unchanged.

A turn made by your wrist might now suggest a route for your whole body. Is there a part you would want to follow? A record can become a score, but it needs another decision about what following means.

## Give the address a floor

<!-- @plan_vitrine -->

Step onto the small plan in its glass enclosure. Count one row, then a column. Five by five: twenty-five one-metre cells. The printed indices run from zero to four.

Find a cell using both numbers. Leave it and find it again. You can now describe where a cube might stand without pointing. Two indices can become an instruction for placing it.[^point-grid-scott]

Cross a row, then cut diagonally. The drawn divisions do not stop you. A continuous collision surface supports the plan. Over the other basin, the museum supplies walkable glass; the replayed lines provide no floor of their own.

An address can tell a program where to put something. What lets a body reach it needs further work.[^point-grid-lefebvre]

<!-- @ -->

There are other movements and other plans here. We could keep following them. For now, carry this much: a shared address can help us repeat a placement, coordinate a meeting, begin a level. It cannot decide which of those things we should want.

The grid gives us a way to name a place and return to it together.

Next, three points can close a boundary. What must we add before there is a face inside it?

[^point-grid-bowker-star]: Geoffrey C. Bowker and Susan Leigh Star, [*Sorting Things Out: Classification and Its Consequences*](https://mitpress.mit.edu/9780262024617/sorting-things-out/) (MIT Press, 1999), study classifications and standards as information infrastructure, including whose differences become visible or disappear within them. Rounding coordinates is not identical to classifying people. It supplies a small operational comparison: treating different inputs as equivalent can support coordination while leaving distinctions out. Its consequences depend on what we build with that equivalence.

[^point-grid-ahmed-return]: Return to Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), introduction: bodily orientation involves relations of alignment and reach. Dancing with the interval is Ada’s proposed use of this rule, not a result already established by her argument.

[^point-grid-scott]: James C. Scott, [*Seeing Like a State: How Certain Schemes to Improve the Human Condition Have Failed*](https://yalebooks.yale.edu/book/9780300252989/seeing-like-a-state/) (Yale University Press, 1998), chapter 1, examines practices of administrative legibility, including cadastral mapping. The connection here is narrow: a plan can make a placement describable to someone not standing beside it. This does not make every grid coercive or establish that a legible plan is sufficient for inhabiting the place.

[^point-grid-lefebvre]: Henri Lefebvre, [*The Production of Space*](https://www.wiley-vch.de/de?isbn=9780631181774&option=com_eshop&title=The+Production+of+Space&view=product), translated by Donald Nicholson-Smith (Blackwell, 1991; French original 1974), chapter 1, distinguishes spatial practice, representations of space and representational spaces. His account keeps planning, practical activity and lived meanings in relation. The vitrine enters that problem without reproducing the whole theory: addresses and a plan do not by themselves establish access, habits, belonging or a place’s meaning to its inhabitants.
