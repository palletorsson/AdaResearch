# Bernini — a turn through height

## Learning elements

- Sampling an oval profile in rings.
- Giving each ring an angle according to its height.
- Connecting neighbouring rings with triangle faces.
- Separating stored geometry from whole-object rotation.

Walk between the museum's columns. Follow one ridge upward. Then keep your gaze at one height while the shaft turns past it. You are following two changes: one through height, the other through time.

Effect Sound put one sine inside another's phase. Here we return to Unit Circle's coordinates and Primitives' connected faces. A rising sequence of angles becomes a shape. We will build a small shaft beside the existing installation, using an oval profile so its orientation is easy to see.

## Carry the point as a control

Keep `point_body.gd` and `line_skin.gd` unchanged. The same black sphere now selects the amount of twist. Its trigger starts or stops rotation of the finished shaft. The pink line follows the same numbered corner up through the rings.

In your prepared museum working copy, attach `07_twisted_shaft.gd` to an empty, unit-scale `Node3D` at hall-local `(5, 0, 10)`, yaw 180 degrees, in the entrance study bay. Keep the three files together. The museum supplies floor, camera, light, player and XR input routing. The script creates the shaft, its low base, control and label. The shaft and base are visual studies without collision; the carried sphere retains its pickup collider.

Start with the shaft still. Lower the sphere to local height 0.8 metres: the profiles line up. Raise it to 1.2 metres: they make half a turn over the shaft's height. At 1.6 metres they make one turn. Movement beyond those heights is clamped. Press the trigger while holding the sphere. Watch the whole shaft rotate, then press again. The twist remains when rotation stops.

## Complete program

Only the main script is new. The two carried files are printed below it and included in the download.

{CODE}

## Read the shape

In `ring_position`, `corner` goes around one profile; `row` moves up the shaft. Dividing the row by `spans` gives `u`, from zero at the bottom to one at the top. The height is `0.25 + height * u`: the first quarter metre belongs to the base.

Cosine supplies X and sine supplies Z, as in Unit Circle, now on a horizontal plane. The unequal radii, 0.40 and 0.20 metres, make an oval. We rotate that profile around Y by `TAU * turns * u`. At half height, the angle is half the total turn. This multiplication has no clock in it. With the default half-turn, corner zero begins at `(0.40, 0.25, 0)`, passes through `(0, 1.45, -0.40)` and ends at `(-0.40, 2.65, 0)`.

A perfectly circular cross-section has no preferred orientation. Merely rotating such a section about its centre cannot give its ideal outline a visible twist. Our oval makes the operation legible. The larger museum columns also move their ring centres and vary their radius. This small study isolates one part of their construction; it does not reproduce every feature or an historical building.

## Connect the rings

Eight corners on each of seventeen rings give 136 positions. Sixteen *spans* are the spaces between those rings. The list still has one dimension: `row * sides + corner` gives an address, just as Grid used a row and column to find an entry.

For each span, `a` and `b` are neighbouring corners on its lower ring; `c` and `d` are the corresponding corners above. The triples `(a, b, c)` and `(b, d, c)` make two triangles. `% sides` wraps the last corner back to zero on the same ring. Without that wrap, the seam would connect the wrong entries. Two centre positions and triangle fans close the bottom and top. We end with 138 positions and 272 faces.

The renderer reads each face's three addresses, adds those positions and generates normals for lighting. The smoothing group of `-1` keeps each triangle flat, so the finite facets and cap edges remain visible. This is the face-list approach used in Polyhedra and Sine Space. The pink line is an added guide through corner zero, not an edge that the surface needs in order to exist.

## Stop the clock without losing the form

Lifting the sphere changes `turns`, so `rebuild` calculates new positions. The face relationships remain the same. Small hand changes below the stated 0.002-turn threshold are ignored to avoid needless rebuilds.

The trigger only changes `running`. While it is true, `rotate_y` changes the parent shaft's orientation by radians per second times `delta`. The stored positions and mesh resource stay unchanged. Stopping preserves the current pose; it does not straighten the shaft. The witness line is a child of the same shaft, so it turns with the surface. The control remains outside that rotating parent.

## Make another shaft

Change `height` from `2.4` to `3.6` and run again. Predict what happens at half height and at the top. The same half-turn is spread over a longer distance; the top's orientation stays the same. Then change `sides` from eight to twelve. The profile has more samples, while height and total turn remain fixed. Explain which edit changed spacing along the shaft and which changed sampling around it.

Keep a form you want to return to. In John Cage, the next hall, the retained material will be a list of events and their times. A composition can have a record even when its next performance has not yet happened.

## Carried code

`point_body.gd` — the existing point and pickup behaviour.

{POINT_CODE}

`line_skin.gd` — the existing finite cylinder between two positions.

{LINE_CODE}

Implementation reference: [Godot SurfaceTool](https://docs.godotengine.org/en/stable/classes/class_surfacetool.html). The larger museum generator is `algorithms/wavefunctions/berninicolumns/BerniniColumns.gd`. It constructs a mesh on the CPU; this lesson does not require a vertex shader or noise.
