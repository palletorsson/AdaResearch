Volume does not begin here as a container. It begins as a question about a corner: what must be added before three meeting faces enclose anything?

<!-- @grab_trihedron -->

Pick up the open corner and turn it. Find the shared apex. Follow each edge away from it, then look across the opening opposite that apex. Count the visible triangles before looking for a base.

Three triangles meet at one vertex. The corner is not any one of those faces; it is a relation between them. Three flat things have stopped lying flat together.

The rendered object has no base face. Its script builds exactly these three faces from four vertices:

```gdscript
[0, 1, 2]
[0, 2, 3]
[0, 3, 1]
```

The missing fourth triangle matters. An open corner can suggest an inside without closing a boundary around a volume.

<!-- @grab_tetrahedron -->

Turn the tetrahedron beside it. Find the face that closes the corresponding opening. Count its vertices, edges and faces, touching or pointing to each once: four vertices, six edges, four faces.

Adding a base to the first corner would close a tetrahedral boundary. The neighbouring tetrahedron is a regular example of that closed family: four congruent equilateral triangles. The open wedge and the regular solid have different proportions, so compare their connections and closure before comparing their angles.

A surface encloses a region without having to fill that region with rendered material. What looks like a solid in a game is often a boundary mesh. What can collide with it is another decision.

<!-- @ -->

## The opening that physics closes

Look again through the open corner. Predict what a small colliding object should do if brought through the missing base. What information would the physics system need to answer that question?

This artifact builds its collider as the **convex hull of all four vertices**. That hull includes the missing base. The visual opening and the collision enclosure therefore describe different boundaries.

The mismatch is useful only if we keep the two accounts distinct. A blocked physics object would establish something about the collider and its collision layers. It would not establish that an open geometric surface secretly has a base. Conversely, seeing through the opening does not establish a passage for every simulated body.

A possible extension is to place two visually identical corners with different colliders and let visitors choose which should admit an object. The question would become who gets to decide what counts as open, with the decision exposed in an interaction rather than hidden in an invisible wall.

<!-- @ -->

## A corner with a handle

<!-- @pyramid_edit -->

Find the apex handle and the four base handles. Leave the base alone and raise the apex a little. Predict which side faces will change before lowering it again. Then move one base corner and compare the effect.

This is a five-vertex pyramid editor. Its four triangular sides meet at the apex, and its base is drawn with triangles too. Moving a handle rebuilds the faces that depend on it. The tool's default arrangement is a square-based pyramid; free handles can take it outside that initial shape.

A corner can be measured by adding the face angles that meet there. Compare their sum with a full turn:

```text
angular defect = 360 degrees - sum of incident face angles
```

At a cube corner, three right angles total 270 degrees, leaving a defect of 90. At a regular tetrahedron corner, three 60-degree angles leave 180. The faces meet in space with less than a full planar turn between them.

Keep the pyramid's base flat and move its apex toward that plane. The side faces change as the corner opens out. At a collapsed or crossing configuration, stop applying the language of an ordinary enclosed solid without checking it: the editor follows points, and does not certify every result as a valid pyramid.

<!-- @cube_scene -->

Count the cube's eight vertices, twelve edges and six square faces. Compare with the tetrahedron:

```text
tetrahedron: 4 - 6 + 4 = 2
cube:       8 - 12 + 6 = 2
```

This is the Euler characteristic, `V - E + F`. It is two for these closed surfaces with sphere topology. It is not two for every closed surface: a torus later in the chapter gives zero. Likewise, the total angular defect of a convex polyhedral surface is 720 degrees; that number is not a volume or a guarantee that anything counted as a “solid” has the same topology.

The faces are where you look. Their connections give you another account of what you are holding.

<!-- @ -->

## The shape changes its use

<!-- @prism_block -->

Find a bare prism before approaching the striped enclosure. Follow one triangular end, then the edges that carry it to the other end. Which face could lie against the floor? Which could rise away from it?

A triangular prism carries two triangular ends joined by three quadrilateral sides: six vertices, nine edges, five geometric faces. A renderer can split those quadrilaterals into triangles without changing the boundary's Euler characteristic. The face count has to say which decomposition it is counting.

Now find the wedges leading toward the raised floor. Approach the low end of a slope; compare it with an upright face. One surface interrupts forward movement. Another lets forward movement become upward movement. Both can be made from flat faces. What changed was their relation to the floor, your approach and the body the game moves for you.

The museum places a walkable wedge with a collision surface as well as a visible mesh. Its builder scales the scene to the required rise and run:

```gdscript
w.scale = Vector3(1.0, maxf(0.05, rise), maxf(0.2, run_cells))
```

A triangle in a picture does not yet promise a walkable slope. The floor must meet it, and your movement system must accept its incline. Keep that distinction available as you walk: a route can look continuous before it works as one.

<!-- @concrete_barrier -->

The red and white stripes announce the enclosure before you reach it. Approach the concrete, then follow its outside edge. Where did your intended straight line go?

Look along a section's end. The wide foot narrows through sloping shoulders into a small crown. This is a more elaborate profile than the bare triangular prism, carried along a length by the same operation of extrusion:

```gdscript
var outline := MF.jersey_outline(base_width, top_width, barrier_height)
body.mesh = MF.extrude_profile(outline, barrier_length, barrier_height)
```

The stripes help you recognise an instruction. They do not stop the player. These placed barriers also request a physics body; its shape comes from the mesh:

```gdscript
shape.shape = body.mesh.create_convex_shape()
```

Here is the hull again. It keeps the outermost points and spans between them, potentially smoothing over details of the stepped profile. The rendered concrete and the surface your simulated body meets have separate accounts of the same boundary.

The wedge can offer passage; the barrier can redirect it. Neither use belongs to geometry alone. A barrier could protect a place to stand. A slope could lead somewhere you cannot return from. Follow what each arrangement permits before deciding what to call it.

<!-- @street_sign -->

STOP. Did you stop when you read it, or when you reached the concrete?

The sign has no collision body of its own. Its word addresses you. The barrier addresses the player's physics body. Two kinds of instruction stand close enough to look like one.

Find the blue arrows: ahead, left, right, both ways. Read one from the side. Then stand where its face is legible. An arrow needs an orientation and someone to orient; it cannot guarantee that the route it suggests is open. The two-headed sign makes a small fork in the sentence. You still have to look.

The arrows are meshes too: a rectangular shaft meets a triangular head. Rotating that little assembly changes its direction. The triangle from the previous hall has become a request about your next movement.

Try holding *smooth* and *striated* as questions here. Where does movement feel continuous? Where is it channelled, divided or interrupted? The slope still has triangles and collision calculations underneath its apparent ease. The repeated barriers can make a route easier to read. Neither word settles the value of the arrangement.

Choose one arrow you would turn, one barrier you would move, or one pause you would preserve. Describe whose movement would change. This is a proposal for another version of the room; these fixtures do not currently offer a grab-and-rearrange control. There is already enough to discover in the difference between what the sign asks and what the floor allows.

<!-- @ -->

## Other ways the solids gather

<!-- @diamonds -->

The stacked diamonds make another use of a repeated solid. Follow how their orientations change up the stack. The pattern belongs to a relation repeated between objects, not to a property contained in one stone.

<!-- @rock_spawner -->

The rocks offer irregular boundaries to compare with the regular ones. Look at the spaces they leave between them. Those spaces arise from shape, arrangement and physics; they are not outside computation merely because they look irregular.

<!-- @rock_scanner -->

Follow the scanning plane through the pile and compare successive sections. A section keeps one cut through a three-dimensional arrangement. Different heights can produce different outlines from the same pile. Predict a change before the plane reaches it.

<!-- @ -->

Before leaving, point to a visual boundary, a collision boundary and a connection pattern. Explain what each can tell you that the others cannot. Then choose a use for one of the forms that does not follow automatically from its name.

The next room takes the eight-cornered example apart. A cube will be built from the relations you can now count, and then handed over to you to change.
