# Closing a boundary, adding a face

Three edges meet. You can still see the room between them.

Everything you have seen so far was drawn in triangles. The sphere in the first room. The hammer. The plinths, the walls, the floor you are standing on. Not the lines, which are their own thing, but every *surface*: each one is a closed outline filled with triangles, because that is the only shape the machine knows how to fill. This room is where you meet the unit.

<!-- @triangle_line_puzzle -->

Bring the loose lines to the three waiting corners. Fit the last edge and look through the triangle. Closing it has not covered anything.

Press **SHOW / HIDE FILL**. A translucent patch appears between the same corners. Press again. The edges stay; the patch goes.

A boundary and a face have arrived through different actions. Connecting these three points closes a loop. Asking the renderer to make a triangle gives it a surface to show. We have chosen that these corners belong together, in this order. Their positions did not make that commitment for us.

Why triangles, and not squares, or anything else? Because three points always share a plane. There is no fourth point to disagree, so a triangle is flat by necessity, and a flat face is something the renderer can light with one direction.

<!-- @triangle_construction_plate -->

The wall plate holds the distinction still: three points, three connected edges, a face.

![The same three corners shown as points, a connected boundary and a filled triangle.](/book-review/doc/book/figures/Point_Triangle_Context/triangle-construction.png)

We built this plate while writing the chapter. The book needed an image; the room gained another object to approach. This illustration is a Godot view of that same construction. A sentence can ask for something to try, and making it can change the sentence.

<!-- @draw_triangle_faces -->

At the small drawing station, a triangle waits with black corners and an off-white face. If you released a drawing in Trace, your own bend waits here instead, still open. Its journey has changed it: six positions kept, its span reduced to arm's reach, its height flattened. The machine has prepared your drawing for a method that expects a plane. What did that preparation leave behind?[^point-triangle-carry]

Move the drawing point near the first corner to close that carried loop. For the simpler comparison, **RESTORE TRIANGLE** replaces the current drawing with three editable corners.

<!-- @triangle_live_twin -->

Look up. The small drawing has a twin in the middle of the hall. Move a corner and watch the same change arrive more than three times larger. Your hand can reach the small figure; your body can walk around the other.

Leave the corners where they are. Walk towards the side of the large face. Its breadth narrows until the black edges almost meet in your view. Step back and the surface opens again. You have changed where you look from, without moving a single corner.[^point-triangle-winding]

Now return to the small drawing. Bring its upper corner down onto the line between the other two and release it. The large figure flattens too. This time walking around cannot recover the missing area. Three positions remain, but they lie along one line. Lift the corner away and a face opens between them again.

From one view, these two events can look alike. In one, the face waits for another viewpoint. In the other, we must change what we made.

<!-- @draw_triangle_faces -->

Press **SHOW / HIDE FILL** while the triangle is open in your view. Both copies lose their faces together; the corners and edges remain. Hiding a surface has left its geometry available for a return. The large fill also lets you walk through it while it is visible. What covers your view need not stop your body.

<!-- @pink_triangle -->

A triangle on a stick, pink from here. Walk round it. Blue.

A face has a front, and the front is decided by nothing more than the order its three corners are listed in. Swap two and the same three points face the other way. The renderer, by default, draws only the front and throws the back away unseen, so most of the triangles you have ever looked at were visible from one side and did not exist from the other. This parasol was built to show both, which is a decision somebody had to make, and the two colours are that decision made visible.

We have been calling all of these a triangle. A boundary, a rendered face, a figure seen edge-on, three corners with no area: keeping their differences lets us do more with the name. It is the unit because it is the only shape that cannot lie: always flat, always one shape for its lengths, always facing one way. Everything larger is made by agreeing triangles together, and every fold, crease and seam you will ever see in here is a place where the agreement ends.

The tool will accept longer outlines too. Draw a six-corner L, close it, then release the handles and press **SHIFT START**. The corners stay where they were. The fill can reach across the notch you left open.[^point-triangle-construction]

Every triangle in this method shares the first corner. Choosing another beginning changes the fan. Its rule has kept working while failing to keep your intended interior. The counter still reports four triangles; counting them does not tell us whether they belong there.

We can choose a suitable start, ask for a different filling method, or keep the unexpected wing as the beginning of another work.[^point-triangle-triangulation] The mistake needs an explanation, but its explanation need not decide what we want from it.

<!-- @quad_line_puzzle -->

At the far end, four edges offer another empty boundary. Three points pass by construction. A fourth may not, and when it sits off the plane there is no face to draw, so the machine does the only thing it can: it splits the quad into two triangles, and the line it splits along is a fold.

<!-- @quad -->

Nearby, the quad adds two triangular faces along a diagonal. Lift a corner away from that diagonal: one face follows while the other stays. Move an end of the shared edge and both change. A shape that looked like one square has given us two surfaces that can tilt apart. Four rods with hinges lean; three rods with hinges hold, and that is why every truss, every bicycle frame and every roof that has stayed up is triangles under the skin.

<!-- @folded_strip -->

Twenty-four faces in a strip, pleated like paper, and every fold is where two triangles meet at an angle. Fold it further. Nothing tears, because nothing here was ever one surface. It was always this many, and the folds were only hidden while they were flat.

Next, faces meet at a corner. What must we add to enclose a volume?

[^point-triangle-winding]: For the rendering convention, see [Godot 4.6’s SurfaceTool documentation](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html): triangle front faces use clockwise winding. Vertex order, shading normals and the material’s culling setting have different jobs. The puzzle deliberately displays both sides. That choice changes visibility; it does not give the face thickness or a collider.
[^point-triangle-triangulation]: One available development route is Godot’s [`Geometry2D.triangulate_polygon`](https://docs.godotengine.org/en/4.6/classes/class_geometry2d.html#class-geometry2d-method-triangulate-polygon), which returns triangle indices for a 2D polygon and an empty result if triangulation fails. A planar 3D drawing would first need coordinates in its plane, followed by mapping the returned indices back to its vertices and handling winding. This room still uses its first-vertex fan; no alternate triangulator is installed by this note.
[^point-triangle-carry]: The trace travels on the same `TraceData` autoload that brings your drawing to the ruled field in Grid: releasing one of the three coloured drawing pens in Trace appends a snapshot of its retained positions, and this tool reads the most recent one. Grid and Triangle each read that saved drawing; Triangle does not receive Grid's enlarged or snapped display. If nothing was released there, or you have come to this room first, the tool opens with one editable triangle, also shown by the large twin. NEW OUTLINE begins another drawing while keeping that triangle. A carried trace is left open; the twin does not close it for you. The reduction to six corners, the rescaling and the flattening happen on arrival, not in Trace; the stored positions are unchanged, and the whiteboard's image travels by no route at all.
[^point-triangle-construction]: The [technical companion](/book?map=Point_Triangle_Context&section=technical) gives the six coordinates and the manual two-fill comparison. SHIFT START changes the last completed loop; release the pen and every corner, and leave no unfinished outline. The instrument reports START and whether the action is ready. Letters A–F name our route here; the tool displays numbered corners.
