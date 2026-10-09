# Which points must stay?

<!-- @cloth_straps -->

Eight strips hang in a rank, each a hand's width across and taller than you. They overlap a little, so the rank reads as one surface until you move and the gaps open. Walk along the front of it. Walk behind it.

Find a fold and stay with it. It runs from somewhere near the top down to the hem, and it does not sit still: it drifts, shallows, crosses into its neighbour. Nothing is driving this. The strips were built hanging and have been settling ever since.

Look up to where the fold starts. The top edge does not move at all. Every fold in front of you begins at that stillness and loosens on the way down. The hem, a hand above the floor, is the part that has been given the most freedom and does the least with it.

So something up there is being held. Before naming it, find out what.

Press **SUPPORT**. The gantry the strips appeared to hang from vanishes, and they go on hanging. Press it again for a hoop, again for a mast. The frame becomes a ring, a spar, a wall; the cloth does not move. Not a little. Not at all.

The rule that holds the top edge never looks at the frame:

```gdscript
var top: bool = absf(verts[i].y - ymax) < 0.01
var keep: bool = top and (mode == 0 or (mode == 1 and absf(absf(verts[i].x) - xmax) < 0.01))
sb.set_point_pinned(i, keep)
```

`verts` is the strip's own rest geometry, in its own coordinates. `ymax` is the highest value in it. A point is held if its height matches that top to within a hundredth of a metre — eight points of the hundred and twelve in each strip. The frame is not consulted, because the frame is not a party to the arrangement. It was built for you.

A convincing support does not prove how a simulation is attached to it. You have just taken the support away and watched nothing happen.

Now change what is actually holding. **PINS** keeps only the two points where that top row reaches its outer edges: from eight to two. Watch the top edge while it happens. It stops being an edge. The strip gathers toward its corners, the fold you were following deepens and swings, and the whole surface begins to behave like something hung rather than something fixed.

Press **RELEASE** and the last two let go.

The material never changed. `linear_stiffness` sat at 0.34 throughout; the solver ran the same way on the same mesh. What changed is how many of its points were forbidden to move — eight, then two, then none. Boundary conditions are not a detail of the setup. Here they are most of what you have been looking at.

**STIFFNESS** offers the other route to a different silhouette, and it is worth trying now rather than earlier, because you already know what the first route looks like. Two ways to change how a thing falls: change the material's resistance, or change which of its points are allowed to participate.

When we call an object compliant, how much of that belongs to the object, and how much to the arrangement holding it?

<!-- @ -->

<!-- @softstopscene -->

Four bodies fall nearby. They are soft spheres kept from the earlier collection, not woven cloth, and the comparison they offer is a different one: not what holds a body up, but what it meets on the way down. **LANDING** exchanges the thing underneath them — a floor, a narrow pan, a rail, a cone.

Watch one sphere meet the rail. The contact is a line rather than a plane, and the body has to resolve a shape around it.

Each specimen also stops, at a scheduled moment, and holds the form it had. Worth knowing before you read too much into any one of them: the stop raises damping and stiffness rather than recording the vertex positions, so the held shape is partly the solver's and not a destination the material was travelling toward.

Two questions leave this room together. What makes a body deform, and what makes us stop looking?

Carry the fixed edge into the next hall. There, the support itself moves — and this time it will not be scenery.

<!-- @ -->
