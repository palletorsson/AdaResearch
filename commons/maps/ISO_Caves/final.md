# On the enclosing side

<!-- @mc_portal_landscape -->

The portal landscape is a promise made by a boundary. From the approach it looks like terrain with openings: stone rises, a ring declares a passage, and the field has been asked to join the two. Walk its edge first. Does the opening meet the floor, or does the name “portal” ask you to supply a route the mesh has not made?

The generator carries a count and a burial choice:

```gdscript
num_portals = 7
burial = "straddling"
```

Press PORTALS and watch the rings multiply. Press BURIAL to move the same family of portals from sunken to standing to floating. A change in count is a change in repetition. A change in burial is a change in the relation between a boundary and the floor. Neither word guarantees that a body can cross.

<!-- @mc_inside_cave -->

Now turn towards the enclosing cave. The same kind of sampled boundary is no longer a facade in front of you. It is above, beside and behind the eye. Press PLUMB once, then OCTAVES once. Notice which changes you can read from outside and which only become legible when the wall closes around your viewpoint.

```glsl
density = ridged_noise(p) - plumbScale * (p.y + 100.0) / 300.0;
```

`plumb` is a written vertical bias: bedded, overturned, weightless or steep. `octaves` decides how many scales of the ridged sum survive. The field is sampled at a level and extracted into triangles. It is not a cave because the label says so; it becomes an interior when the classified air has enough width, headroom and an entrance.

Press HOLD before changing the field. The earlier view stays behind the live specimen as a memory of the surface. A column can show several crossings, but a counter is not a body. Follow the wall, look back to the entrance, and test the route with your own clearance rather than with the most dramatic chamber in view.

<!-- @queer_marching_cave -->

The long cave in the rear aisle keeps a different vocabulary: bulge and resolution. It is a useful remainder, not a third answer to the same control panel. Its folds make the distinction felt: topology is not only whether a surface exists, but which bodies its passages permit.

<!-- @ -->

An isosurface gives inside and outside one calculation. The museum makes the choice visible by changing your side of the boundary. A portal can be a hole that does not connect; an enclosing cave can be a room with no adequate entrance. The field supplies possibilities. A route is authored through width, collision and a body that can arrive.
