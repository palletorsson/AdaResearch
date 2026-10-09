# Making form from points lines and light

*From borrowed outlines to free drawing in space · 4 October 2026*

A pale knot hangs above a plinth. Its colour seems to have softened into the air. Change one setting and the mist becomes hundreds of overlapping bubbles. Change it again and a thin chain of light follows the same turns. None of the stored positions has moved. Yet the body in front of us feels different each time.

This is the latest form study in Ada, the museum and book we are building together. We are looking for ways to make forms by taking the engine's ordinary materials seriously: points, lines, profiles, surfaces, transparency and time. Each gives us something to work with. Each also makes decisions that can be difficult to see until we put another version beside it.

![A soft band of pink, cyan and amber describes a knot in space.](space-brush.png)

*The free-space brush shown as soft colour. Overlapping marks suggest a continuous band. Native Godot capture.*

We arrived here through columns and letters. Repeating an outline at different heights gave a column its body. Changing the width of those outlines gave it a waist or a flared mouth. A font offered more elaborate starting shapes: O already contained an opening; B contained two. We borrowed those outlines and carried them along paths. The proportions of a letter became the dimensions of a possible space.

The [earlier study](../2026-10-04-glyph-form-atlas/blog.html) followed that borrowing. This one asks how much of a boundary we need to construct before we begin to see a body.

We started with a sphere so that the comparison would be easy to follow. One version has a continuous visible surface. Another places small luminous points at locations on the same spherical boundary. The gaps are substantial, but we can still read the roundness. Moving closer makes the individual marks more insistent. The object holds together at one distance and loosens at another.

![Small luminous points describe a spherical boundary, leaving dark gaps between them.](points.png)

*The points share a spherical arrangement. There is no filled surface connecting them.*

Lines offer a different kind of connection. Latitude and longitude give the sphere ribs. We can follow a curve around the body and see other curves through it. The places where they cross help us read its organisation. In our implementation, these lines are made from short, thin cylinders. Even this apparently spare drawing needs little bodies in order to become visible.

A line can do much more than outline an object. Repeated lines can make a screen or a canopy. Straight segments stretched between two guiding curves can describe a curved envelope. A line given a wider section can become a ribbon, a rail or a tube. Leave it open, close it, branch it, repeat it: each decision changes what the arrangement permits us to see through it. The woven and branching forms remain experiments to build; the luminous rings already give us somewhere to begin.

![Luminous circles intersect around a sphere whose interior remains open to view.](lines.png)

*The lines describe a boundary. Screen glow gives them a halo; it does not close the gaps.*

Here it matters to distinguish what we perceive from what we have constructed. Seeing a surface between ribs does not mean there are triangles filling those intervals. A visible crossing does not automatically join two parts. A glowing boundary does not automatically stop a player. Geometry, appearance and collision can support one another, but the connection has to be made. The museum can let us discover the difference with a body, rather than leaving it as an implementation detail.

The transparent spheres make another possibility visible. Their edges overlap and brighten. Several marks can occupy the same region without hiding one another completely. In the knot study, we keep a position, a colour and a size for each mark. Switching the display changes how those records become visible: soft stamps, spherical shells or small light points. The drawing can survive a change in what it appears to be made of.

![The same knot appears as a dense chain of overlapping luminous spherical shells.](brush-bubbles.png)

*The same 540 stored positions as the soft knot above, displayed as shells. Their overlaps accumulate light.*

That accumulation has its own conditions. These shells use additive colour: overlaps become brighter. They do not mix like paint, and they do not simulate glass bending the view through it. The soft version uses flat marks that turn toward the camera, each fading at its edge. Its apparent mist comes from their overlap. Understanding this gives us more precise choices about the work. We can keep the luminous excess, reduce it, or choose another way for one mark to meet another.

There is also a nearly invisible sphere that receives paint. Drawing across it reveals the surface through the marks it permits. The strokes remain on that curved boundary when we change viewpoint. Beside it, the free-space brush lets a stroke occupy different depths. One encounter discovers a surface already specified; the other lets us place marks without that spherical constraint.

![Pink and pale blue strokes wrap around a faint spherical surface.](painted-sphere.png)

*At this station the surface determines where the paint can land. The free-space brush beside it has a different permission.*

The sphere was useful for comparing these methods. The marks themselves can be arranged into a face, a landscape, an unreadable scribble or a room. A point has a position; nothing in that position requires it to belong to a sphere. A sequence of positions can come from a formula, a drawing gesture or samples taken from an image. The source of the arrangement becomes another artistic decision.

Imagine reconstructing the Mona Lisa this way. This is a proposed next study. With points, we could distribute colour across a field of separate marks, changing their size and density. With transparent spheres, we could build layers and watch their overlap alter the image. With lines, we could follow contours, gather strokes into hatching or let a continuous path search through the portrait. These would be different drawings of the same source, each asking us to notice something else.

An image supplies positions across its width and height, along with colour. It does not directly supply the depth we would need for a spatial portrait. We would compose that depth. We might place every mark so that the familiar face aligns from one chosen viewpoint, then spread those marks through a room. Moving sideways would reveal the intervals that the frontal view concealed. Recognition would become something we could approach and leave.

That chosen viewpoint deserves attention. If the face resolves from one position, we have made a place from which the arrangement is supposed to make sense. Other positions expose its construction. We can treat those views as parts of the work too: a cheek becoming a corridor of marks, a shadow separating into dark threads. The invitation to move makes room for readings that the frontal image cannot contain.

This is where free drawing matters. A visitor should be able to carry a stroke away from the supplied arrangement, add something between its layers, or let a line continue beyond the frame. The borrowed image gives us a place to begin. It need not determine where every subsequent mark belongs. There is a queer possibility in allowing a recognisable form to remain present while its parts find other affiliations.

For Ada, these experiments connect the point, the line and the trace to a larger practice of making. A position becomes a mark. Keeping positions makes a trace. Giving the trace thickness, repetition or duration changes the body we can perceive. The code provides operations the student can reuse; the encounter gives us reasons to choose among them.

The next portrait could begin with a face that holds together from the doorway. Then we enter. Between the marks, there is room for another drawing.

---

*Illustrations are native captures from the working Painting space desktop study. It supports drawing, changing the display of stored marks, undo and local saving. The Mona Lisa reconstruction, woven structures and branching networks are proposals. Tracked-hand use and Quest performance remain untested.*

[Explore the eight studies](index.html) · [See the freehand drawing test](../2026-10-04-freehand-drawing/index.html) · [Download the Godot project](painting-space.zip) · [Read the construction notes](../../studies/painting-space/README.md) · [The room inside a letter](../2026-10-04-glyph-form-atlas/blog.html)
