# Which points must stay?

<!-- @cloth_straps -->

Eight strips hang in a rank, each a forearm wide and twice your height. They overlap by a hand's breadth, so from straight on the rank reads as one surface. Walk along the front of it. Walk behind it.

Stay with one strip long enough to watch it. Nothing is driving this: the strips were built hanging and have been settling ever since, and a sheet this long is still stretching and swinging well after it was made. Whatever shape it has now, it has not finished arriving at.

Look up to where it meets the top. That edge does not move at all. Everything loosening below it begins at that stillness.

So something up there is being held. Before naming it, find out what.

Press **SUPPORT**. The gantry the strips appeared to hang from vanishes, and they go on hanging — the held edge in the same place, the rest carrying on exactly as it was. Press it again for a hoop, again for a mast. Three pieces of architecture, and not one of them changes where the cloth is held.

The rule that holds that edge never looks at the frame:

```gdscript
var top: bool = absf(verts[i].y - ymax) < 0.01
var keep: bool = top and (mode == 0 or (mode == 1 and absf(absf(verts[i].x) - xmax) < 0.01))
sb.set_point_pinned(i, keep)
```

`verts` is the strip's own rest geometry, in its own coordinates. `ymax` is the highest value in it. A point is held if its height matches that top to within a hundredth of a metre — eight points of the hundred and twelve in each strip. The frame is not consulted, because the frame is not a party to the arrangement. It was built for you.

A convincing support does not prove how a simulation is attached to it. You have just taken the support away and watched the attachment survive it.

Press **SUPPORT** once more and a wall arrives behind the rank. This is the one value you cannot walk through, and the only one that reaches into the space the cloth occupies. A frame that was scenery to the pin rule is not scenery to the body, yours or the cloth's.

Now change what is actually holding. **PINS** keeps only the two points where that top row reaches its outer edges: from eight to two. Watch the top edge while it happens. It stops being an edge. The strip gathers toward its corners and begins to behave like something hung rather than something fixed.

Before you let the last two go, try **STIFFNESS**. It is the other route to a different silhouette, and it is worth taking now rather than earlier, because you already know what the first route looks like. Two ways to change how a thing falls: change the material's resistance, or change which of its points are allowed to participate.

Then press **RELEASE**, and the last two let go.

The material never changed while the pins did. The solver ran the same way on the same mesh. What changed is how many of its points were forbidden to move — eight, then two, then none. Boundary conditions are not a detail of the setup. Here they are most of what you have been looking at.

The strips are on the floor now, and **REBUILD** is the only control that hangs them again.

When we call an object compliant, how much of that belongs to the object, and how much to the arrangement holding it?

<!-- @ -->

<!-- @softstopscene -->

Four bodies stand nearby, already stopped. They are soft spheres kept from the earlier collection, not woven cloth, and each froze at a scheduled moment of a fall you were not here for.

**LANDING** exchanges the thing underneath them and drops them again. Watch one meet the rail: the contact is a line rather than a plane, and the body has to resolve a shape around it.

Worth knowing before you read too much into any held shape: the stop raises damping and stiffness rather than recording the vertex positions, so what you are looking at is partly the solver's and not a destination the material was travelling toward.

Two questions leave this room together. What makes a body deform, and what makes us stop looking?

On the way out the floor runs empty for a long time, and then a few cells stand higher than the rest and one is missing altogether — the fixed points of the room this hall used to be, left where they were when everything around them was moved.

Carry the fixed edge into the next hall. There, the support itself moves, and this time the cloth will know.

<!-- @ -->
