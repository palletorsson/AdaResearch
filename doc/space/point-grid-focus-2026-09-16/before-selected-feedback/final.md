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

Let go. The tool brings its marker onto the lattice. Pick it up and try to return to that address. You have some room to be imprecise and still arrive at the same result. That can be useful: we may want two pieces to meet without having to place them by eye.

The table gives another name to the retained position. It does not show the unrounded position beside it. We still need your movement to notice what this record leaves out.

## Give the interval a rhythm

<!-- @player_trace -->

Now walk a small loop, then a wider diagonal. Look behind you. The walking recorder keeps a finer sampled reference and a path rounded to one-metre spacing in its own frame.

Find a place where you can move while the coarse address holds. Slowly cross into another. Cross back. There is a rhythm in the jump, and room to move within the interval. A rule for making positions agree has also given us something to dance with.

In VR, lean with your feet planted. The recorder can respond: it follows the headset horizontally, using the rig's origin for height. On desktop it follows the walking body. It must choose a point before it can draw a path called yours.

The lines connect the positions it keeps. A diagonal can cut across ground you went around. Returning to an earlier address can add another turn to the record; the program keeps an order of visits, not just a collection of places visited once. An address lets us recognise a return. It does not tell us why we came back.

## Let the drawing find another use

<!-- @grid_lines -->

Return to the ruled field. Find your bend in the pink line, then compare the green version. If there is no released trace yet, return to Trace, draw with a dot or stick until it retains at least two points, and let go. The whiteboard's ink and the walking recorder keep separate records.

This display subtracts the centre of the received drawing's bounds and applies a scale:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Small drawings grow fivefold; larger ones receive a smaller multiplier so their longest dimension fits within five metres. Pink shows this transformed drawing. Green rounds it again, with six intervals per displayed metre along each axis. The source positions stay unchanged.

A turn made by your wrist might now suggest a route for your whole body. Imagine following it with someone else. Where would you begin? How closely would you follow? A record can become a score, but it needs another decision about what following means.

The panel still lists source-world coordinates while the drawing stands here at another size. A number needs its frame. The gesture has crossed into another use without carrying all the circumstances that made it.

## Give the address a floor

<!-- @plan_vitrine -->

Step onto the small plan in its glass enclosure. Count one row, then a column. Five by five: twenty-five one-metre cells. The printed indices run from zero to four.

Find a cell using both numbers. Leave it and find it again. You can now describe where a cube might stand without pointing. A neighbouring address could hold another cube; a wedge could lead up to them. These are arrangements we can begin to specify with what we know.

Cross a row, then cut diagonally. The drawn divisions do not stop you. A continuous collision surface supports the plan. Over the other basin, the museum supplies walkable glass; the replayed lines provide no floor of their own.

An address can tell a program where to put something. What lets a body reach it needs further work.

<!-- @ -->

There are other movements and other plans here. We could keep following them. For now, carry this much: a shared address can help us repeat a placement, coordinate a meeting, begin a level. It cannot decide which of those things we should want.

Next, three points can close a boundary. What must we add before there is a face inside it?
