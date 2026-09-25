# Grid Quantizes Movement

Look for your bend. It may have grown.

A drawing released in Trace can arrive here as a list of positions. Over the ruled field, a small movement has acquired another size. Keep it in view. We are going to give positions addresses, then ask what those addresses help us make.

## Find somewhere to return

<!-- @grab_sphere_point_snap -->

Pick up the snapping sphere. Move it slowly, watching its marker and the retained line. Try to move without adding a new place to the record. Then go far enough for another place to appear.

Trace already made choices about which positions to keep. Here the table shows the last ten kept positions, naming each in metres and in whole-number steps from the origin. With five centimetres between grid positions, `0.15` metres along X has index `3`: three steps from world zero. The same place has two names.

The calculation, reduced to one axis, is:

```gdscript
var index = roundi(pos.x / grid_size)
var placed_x = index * grid_size
```

Divide by the spacing. Round to the nearest integer. Multiply back to get metres. At this spacing, `0.12` becomes `0.10`; `0.13` becomes `0.15`. One centimetre of movement can carry the record across a five-centimetre interval. Elsewhere, a larger movement can leave its address unchanged.

Let go. The tool brings its marker onto the lattice. Pick it up, move away, then try to return to that address. Several nearby positions can round to the same result. Your hand has room to vary while the point finds its place again. This can help us make two pieces meet without placing them exactly by eye.[^point-grid-bowker-star]

Move the marker a little while watching where the recorded line ends. Can you keep that end still? Both columns in the table name retained positions. The difference to look for is between the moving marker and the position the program keeps.

## Give the interval a rhythm

<!-- @player_trace -->

Now walk a small loop, then a wider diagonal. Look behind you. The walking recorder keeps a finer sampled reference and a path rounded to one-metre spacing in its own frame.

Find a place where you can move while the coarse address holds. Slowly cross into another. Cross back. There is a rhythm in the jump, and room to move within the interval. A rule for making positions agree has also given us something to dance with.[^point-grid-ahmed-return]

Lean with your feet planted. The recorder can respond: it follows your headset across the floor. It must choose a point before it can draw a path called yours.

The lines connect the positions it keeps. A diagonal can cut across ground you went around. Returning to an earlier address can add another turn to the record; the program keeps an order of visits, not just a collection of places visited once. The address marks a return; your reason for coming back has stayed with you.

## Let the drawing find another use

<!-- @grid_lines -->

Return to the ruled field. Find your bend in pink, then compare green. Is it still your bend at this size?[^point-grid-carry]

This display subtracts the centre of the received drawing's bounds and applies a scale:

```gdscript
mesh.surface_add_vertex((p - center) * final_scale)
```

Pink shows the drawing centred and scaled. Small drawings grow fivefold; larger ones receive a smaller multiplier to fit within five metres. Green rounds the displayed positions again, with six intervals per metre along each axis. The source positions listed in the panel stay unchanged. Use PREVIOUS and NEXT to hold a page of those positions while you compare it with the line. AUTO lets the pages cycle; either arrow takes back the page.

A turn made by your wrist might now suggest a route for your whole body. Is there a part you would want to follow? A record can become a score, but it needs another decision about what following means.

## Give the address a floor

<!-- @plan_vitrine -->

Step onto the small plan in its glass enclosure. Count one row, then a column. Five by five: twenty-five one-metre cells. The printed indices run from zero to four.

Entering gives each hand a pen. Draw a small circle with the cyan left hand, then try it with the amber right. Cyan follows the sampled movement. Amber places its horizontal positions above the nearest cell centres; your hand can rise and fall between them. Try holding one height as you move across a cell. How much of your movement can disappear before the line takes another step?

The floor has entered the drawing. Its addresses reach up into the air, but they have not taken over every direction. Lift the amber hand without moving it sideways: height still has room to vary. Stepping out returns the pens; the traces linger briefly, then clear.

Find a cell using both numbers. Leave it and find it again. You can now describe where a cube might stand without pointing. Two indices can become an instruction for placing it.[^point-grid-scott]

Cross a row, then cut diagonally. The drawn divisions do not stop you. A continuous collision surface supports the plan. Over the other basin, the museum supplies walkable glass; the replayed lines provide no floor of their own.

An address can tell a program where to put something. What lets a body reach it needs further work.[^point-grid-lefebvre]

<!-- @ -->

A shared address can help us repeat a placement, coordinate a meeting, begin a level. Which of those uses would you want to take further?

The grid gives us a way to name a place and return to it together.

Next, three points can close a boundary. What must we add before there is a face inside it?

[^point-grid-bowker-star]: Geoffrey C. Bowker and Susan Leigh Star, [*Sorting Things Out: Classification and Its Consequences*](https://mitpress.mit.edu/9780262024617/sorting-things-out/) (MIT Press, 1999), study classifications and standards as information infrastructure, including whose differences become visible or disappear within them. The operational comparison here is treating different inputs as equivalent: it can support coordination while leaving distinctions out. Its consequences depend on what we build with that equivalence.

[^point-grid-ahmed-return]: Return to Ahmed, [*Queer Phenomenology*](https://www.dukeupress.edu/queer-phenomenology), introduction: bodily orientation involves relations of alignment and reach. Dancing with the interval is Ada’s proposed use of this rule, not a result already established by her argument.

[^point-grid-scott]: James C. Scott, [*Seeing Like a State: How Certain Schemes to Improve the Human Condition Have Failed*](https://yalebooks.yale.edu/book/9780300252989/seeing-like-a-state/) (Yale University Press, 1998), chapter 1, examines practices of administrative legibility, including cadastral mapping. The connection here is narrow: a plan can make a placement describable to someone not standing beside it. This does not make every grid coercive or establish that a legible plan is sufficient for inhabiting the place.

[^point-grid-lefebvre]: Henri Lefebvre, [*The Production of Space*](https://www.wiley-vch.de/de?isbn=9780631181774&option=com_eshop&title=The+Production+of+Space&view=product), translated by Donald Nicholson-Smith (Blackwell, 1991; French original 1974), chapter 1, distinguishes spatial practice, representations of space and representational spaces. His account keeps planning, practical activity and lived meanings in relation. The vitrine enters that problem without reproducing the whole theory: addresses and a plan do not by themselves establish access, habits, belonging or a place’s meaning to its inhabitants.

[^point-grid-carry]: If the field is empty, return to Trace, draw with a dot or stick until it retains at least two points, and release it. That release sends the record onward. The whiteboard and walking recorder keep separate records.
