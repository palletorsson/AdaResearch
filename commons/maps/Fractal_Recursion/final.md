A rule fed its own output is the whole engine, and only the base case stops it.

You arrive in mid-air and drop a metre and a bit onto the floor, because nobody marked a spawn here and the room worked one out from its own centroid. That is a fair introduction. This is the engine room of the chapter, and almost nothing in it is the size it was meant to be.

```gdscript
func draw_recursive(centre: Vector3, size: float, depth: int) -> void:
    if depth <= 0:
        return                      # the base case, and the only thing that stops it
    add_square(centre, size)
    draw_recursive(centre, size * size_reduction, depth - 1)
```

Output becomes input. The function calls itself with a smaller argument and the smaller call calls itself again, and the whole structure is that one line repeated until a counter runs out. Everything in this chapter is built by something shaped like this.

## One call, or many

<!-- @fractal_recursion_2 -->

Six squares inside each other, each half the last, hanging edge-on above head height. Read the code behind it and there is exactly one self-call, which makes this a tail call: one square per level, a straight line down. It is recursion in the strict sense and it is not branching, so nothing here multiplies. The corpus keeps a blunter description of it than the label on the wall does: a loop wearing recursion's clothes.

Keep it in mind for the next object, which is what happens when the call is made four times instead of once.

<!-- @example_8_3_recursion_circles_vr -->

Four metres of tori, eighty-five of them, each ring carrying four smaller rings at six tenths the radius. Four calls per level and four levels: eighty-five is what one, four, sixteen and sixty-four come to. The whole assembly turns for about seven seconds, freezes for ten, and turns again. That pause is worth the wait. A branching recursion is not more complicated than a tail call by a little; it is a different order of thing, and the difference between this and the flat squares beside it is one number in one line.

<!-- @cube_subdivision -->

The only thing in this room you cannot walk through. A cube splits into eight at a bit under half scale, then one of those eight is picked at random and split again, and again, for about ten seconds until the pile stops at eighty-five cubes. The pick is unseeded, so the pile is different every time the room loads, and it is the one object here that shows the engine choosing. Recursion in a program is exhaustive. Recursion in a world has to decide where to spend.

<!-- @ -->

## Built and buried

<!-- @recursive_table -->

<!-- @recursive_chair -->

A table and a chair, each assembled from a subdivided cube in five timed steps: split, keep the top layer and four corners, flatten the top, stretch the legs. Both are here and neither can be seen. Each was placed at a fifth of its size and dropped half a metre, which puts the whole of both inside the solid cube of the floor. The chair finishes building about two and a half seconds after the room loads, underneath you.

They are the chapter's best argument about what recursion is for, which is that a chair is not a special shape but a cube with the right cells kept, and you cannot look at either of them.

<!-- @cube_staircase -->

A staircase builds itself over two and a half seconds, six treads and a handrail, twenty-six boxes. It stands in one of the nine holes in this floor, and it has no collision, so it is a staircase you cannot climb standing in a gap you can fall through.

<!-- @fibonacci_pagoda -->

Eight tiers, each scaled down by the golden ratio to the power of a half, with a five-part finial on top: a hundred and nine pieces in all, and nine and a half metres of them in a room whose walls stop at two. It goes straight out through the roofline. This is the chapter's other recursion, the one that shrinks by an irrational number instead of a half, and you have to stand well back and look up through where the wall should be.

<!-- @ -->

## Watching and not watching

<!-- @science_screen -->

A screen, floating a metre and a half up with its stand's foot hanging in air, set to draw a bar chart. Twenty bars, and they come from a random number generator with a fixed seed inside the screen itself. No object in this room feeds it. It is a graph of nothing, drawn accurately, refreshed forever.

<!-- @dark_sphere -->

A dark sphere turning slowly over a disc of light, breathing on a sine. It carries a hit body that a catalyst could shoot, and in this room shooting it does nothing at all, because the response is chosen from the map's name and this map's name matches none of the rungs that respond.

<!-- @synthesis_stand -->

And beside it the same sphere again, on a low slab, as the one variant of its family the measurements ranked highest, with the values on a plaque. A family reduced to its best member is the opposite move from everything else here: recursion makes many from one, and this makes one from many.

<!-- @ -->

## The base case

Everything in this room is one line calling itself. The squares call once and make a ladder. The rings call four times and make a swarm. The cube calls once but chooses where, and the pagoda calls with an irrational ratio and climbs out of the building.

What stops any of them is the same thing: a counter, checked at the top, that eventually says no. Without it the engine does not make an infinitely detailed object; it makes nothing, because it never returns. The base case is not a safety rail bolted on afterwards. It is the half of the rule that makes the other half mean anything.

Next: what these rules make, measured — and the two moves that make all of it.
