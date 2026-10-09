# Which points must stay?

<!-- @cloth_straps -->

Eight strips hang in a rank, each a forearm wide and twice your height. Their edges overlap, so from straight on the rank reads as one surface. Walk along the front of it. Walk behind it. Unlike the cube, this surface does not close around an inside. There is no enclosed volume for pressure to inflate.

Stay with one strip long enough to watch it. There is no motor here. The strips were built hanging and have been settling under gravity ever since; a sheet this long can keep stretching and swinging well after it was made. Whatever shape it has now, it has not finished arriving at.

Look up to where it meets the top. That edge does not move at all. Everything loosening below it begins at that stillness.

So something up there is being held. Before naming it, find out what.

Press **SUPPORT**. The gantry the strips appeared to hang from vanishes, and they go on hanging — the held edge in the same place, the rest still free to move. Press it again for a hoop, again for a mast. Three pieces of architecture, and not one of them changes where the cloth is held.

The rule that holds that edge never looks at the frame:

```gdscript
var top: bool = absf(verts[i].y - ymax) < 0.01
var keep: bool = top and (mode == 0 or (mode == 1 and absf(absf(verts[i].x) - xmax) < 0.01))
sb.set_point_pinned(i, keep)
```

`verts` is the strip's own rest geometry, in its own coordinates. `ymax` is the highest value in it. A point is held if its height matches that top to within a hundredth of a metre — eight points of the hundred and twelve in each strip. The strip is a mesh of triangles; its points are linked, and the pin rule chooses which must stay. That rule does not consult the frame. The apparent reason for the cloth to hang was built for you to see.

A convincing support does not prove how a simulation is attached to it. You have just taken the support away and watched the attachment survive it.

Press **SUPPORT** once more and a wall arrives behind the rank. The opening behind the cloth is now occupied by a solid surface. The pins stay where they were, but the passage changes. The pin rule can ignore a wall that a body must go around.

Now change what is actually holding. **PINS** keeps only the two points where that top row reaches its outer edges: from eight to two. Watch the top edge while it happens. Six points that were held can now sag between the two corners. The edge remains, but its straightness was being maintained.

Then press **RELEASE**, and the last two let go.

The material never changed while the pins did. The solver ran the same way on the same mesh. What changed is how many of its points were forbidden to move — eight, then two, then none. Boundary conditions are not a detail of the setup. Here they are most of what you have been looking at.

The strips are on the floor now. **REBUILD** makes a fresh hanging rank. Keep its top row held and try **STIFFNESS**. We can now compare two ways of changing the silhouette: change how strongly the surface resists deformation, or change which of its points may move.

When we call an object compliant, how much of that belongs to the object, and how much to the arrangement holding it?

<!-- @ -->

<!-- @softstopscene -->

Four bodies stand nearby. They began falling when the room loaded, and by the time you reach them their timers may already have stopped them. These are soft spheres kept from the earlier collection, not woven cloth. You can arrive after the event and still meet its shape.

A narrow rail crosses each landing. Look for where a body has come to rest: on the bar, against a post, or on the floor below. Then press **LANDING**. It exchanges the support and starts a new fall; the pan that arrives offers a floor between two walls. Stay for the fall this time.

Worth knowing before you read too much into any held shape: the stop raises damping and stiffness rather than recording the vertex positions, so what you are looking at is partly the solver's and not a destination the material was travelling toward.

Two questions leave this room together. What makes a body deform, and what makes us stop looking?

On the way out the floor runs empty for a long time, and then a few cells stand higher than the rest and one is missing altogether — the fixed points of the room this hall used to be, left where they were when everything around them was moved.

<!-- @ -->

<!-- study-spine:tension_membrane -->

<!-- @tension_membrane -->

Four slender posts hold a dark, narrow-waisted surface. Between them it has sunk towards the floor. The pink bead at its edge waits within reach. Pull it towards you. A crease travels back towards an attachment that does not move.

Let go. The bead moves without your hand, passes through a lower position, and comes back more quietly. Stay for the small movements after the large one.

Add a load. A dark weight gathers beneath the middle. Pull again and release. The same four points are held, but the surface now has something more to carry. It settles lower. Removing the load allows another return.

Nengudi's stretched hosiery brings a used material, close to skin, into this question of how far something can give. Our surface has no wearer and no remembered damage. Each return is calculated from lengths that the code has kept intact. To recover here is to approach an arrangement the program still remembers.

The anchors have asked nothing of themselves. We have asked the middle to accommodate another weight.

<!-- @ -->

Carry the fixed edge into the next hall. There, the support itself moves, and the bodies hanging from it will know.

<!-- @ -->
