# The room inside a letter

*Borrowing font outlines to build forms in Godot · 4 October 2026*

From the side, the pale green body looks like a wall caught in a slow turn. Look down from above and it becomes a B. Its two empty spaces have become wells. We can still read the letter, but now there is somewhere for our gaze to go inside it.

This began with a question about columns. In Ada, we had been making forms from rings: choose an outline, repeat it at different heights, connect the points. Changing the number of points made the cylinder visibly faceted. Changing the width of each ring gave the column a waist, a belly or a flared mouth. Then we looked at the engine’s text mesh. A font already contains carefully drawn outlines. Could those become the sections of other bodies?

![A pale green B rises and twists into a body with two open wells.](wells.png)

*The B is easiest to recognise from above. The small letter beside it shows the profile from which the body was made. Native Godot capture.*

Ada is a museum and a book being developed together. We build an encounter, inspect what it makes possible, and let that change the writing. Here the encounter begins with a familiar object whose construction we usually leave to software: a letter.

The shortcut is already substantial. Drawing the outline of B means deciding where the outside runs, where each hole begins, and which region is filled. A font carries those decisions. Godot’s [TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html) can turn a vector glyph into a triangulated face and give it depth. In our study, we ask for the flat face first. We keep its triangles and find its boundary edges. Our own code then carries the section through space and builds the walls between successive sections.

A straight path gives us an ordinary extrusion. Rotate each section a little and the body twists. Change its width as it rises and it narrows or opens. The early experiments included a distorted B, an asterisk column and a turning ampersand. The second study separates two decisions more clearly: the shape we carry, and the path along which we carry it.

O makes the difference easy to see. Standing upright and given depth, it becomes a large opening. Turn its section onto the ground, draw it upward, narrow it and then widen it, and the same letter begins to resemble a vessel. The opening has survived both operations. Its use seems to have changed.

![An upright O at bodily scale, with a small dark figure in front of its lower stroke.](passage.png)

*The dark capsule is a 1.7 metre reference. O offers an opening, but also a raised threshold.*

![The O profile becomes a hollow pink body with a narrow middle and a flared rim.](vessel.png)

*The same source profile, carried upward through changing widths. The lower opening remains in the mesh.*

Then the apparent uses begin to object. O’s lower stroke is now a sill. A simple collision test finds room for a 1.7 metre capsule when it is raised into the opening; at floor level, the capsule meets the rim. Enlarging a letter has brought us close to a doorway, but has also enlarged something that obstructs passage.

The vessel has another problem. Its hole continues through the bottom. Put it on a plinth and it looks complete, because the plinth supplies the surface beneath it. Lift it away and the opening remains. The mesh has no base with which to hold liquid. An image can quietly borrow a function from its surroundings.

These are useful discoveries for the museum. They give the next modelling decision a reason. We could cut through O’s lower stroke, or construct a base for the vessel. Each operation would answer a specific need revealed by the form. The familiar outline gets us somewhere quickly; using it makes us look again.

Other letters put pressure on the method differently. Carry C around an arc and its gap becomes an opening along a curved channel. It suggests a seat or a shelter, although we have tested neither use. Carry I around a complete circle and join the ends, and something more surprising happens. The original section has no hole. The finished ring has one. Its top and bottom strokes have become circular flanges, joined by a thinner wall.

![A lavender ring with broad upper and lower flanges, beside its source letter I.](loop.png)

*The hole comes from closing the path. It was never inside I.*

This lets us distinguish changes that photographs can make look similar. B brings two holes into the construction. I acquires one because of the route its section follows. Twisting B preserves its two channels in this study; it does not make them meet. To join them, we would have to make a new connection. Shape can change continuously while the number of openings stays the same.

The colon adds a quieter complication. Its two dots become two leaning bodies. They travel through the same sequence of transformations, belong to one character and sit in one mesh resource. They are still separate. The category used by the software does not settle how many connected bodies we have made.

What else could enter this system? A symbol font offers stars, arrows and other compound outlines. We successfully tested a star from a vector symbol font in the first study. A drawing or a recorded trace could also supply a profile once we had turned it into a properly triangulated region. There are limits: a trace may cross itself, a glyph may fail triangulation, and a font may contain bitmap images instead of usable outlines. Each source asks for a little close reading before it can be borrowed.

The ease of the method makes that borrowing worth noticing. Someone designed the thickness of these strokes and the proportions of these counters for reading. Those choices return as walls and openings. A different font would give us different bodies before we changed a single rule of the sweep. The alphabet is already a collection of made decisions.

There is a queer possibility here that interests us: allowing a familiar form to acquire a use beyond the one assigned to it, while its earlier life remains legible. B can keep returning as a letter inside a sculptural body. We can enjoy that recognition without requiring it to determine what the body must become. From one position we read; from another we inspect a space.

This is also a small example of how Ada’s research moves. A question about an engine feature produces a form. The form produces an unexpected obstruction. The obstruction gives the writing something precise to say and the next piece of code something to change. The illustration records a stage in an argument that is still being made.

For the next encounter, O’s lower stroke is enough. We can keep the original beside a version with a cut through its sill, then test passage with the museum’s actual player. The cut would make the letter less complete and the opening more usable. There is a good place to begin writing about a door.

---

*These are standalone Godot studies, with camera exploration and selected geometry and physics checks. The six-body study passed 37 checks. Walking in VR, physical fabrication and the proposed cuts remain to be tested.*

[Explore the six bodies](index.html) · [Download the Godot project](borrowed-outlines.zip) · [Read the method and limits](../../studies/glyph-form-atlas/README.md) · [See the first glyph study](../2026-10-04-glyphs-as-profiles/index.html)
