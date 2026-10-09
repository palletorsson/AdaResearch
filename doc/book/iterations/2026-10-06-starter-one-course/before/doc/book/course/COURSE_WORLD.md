# Endless Museum, portable studies

3 October 2026. Course agreement following Palle's distinction between a study that can run separately and a study that belongs to Ada.

Palle's clarification: the tutorial environment is the existing **Endless Museum**. Use its halls, player, lighting, artifacts and spine order. The student develops a growing collection of works within that environment. A small study can also run separately, but its construction and teaching progression should return to the actual museum encounter.

The museum already provides chapter and map selection through `start_chapter` and `start_map` on its museum node. The shipped menu route uses `commons/scenes/endless_museum_staged.tscn`; the desktop development scene is `commons/scenes/endless_museum.tscn`. This is a choice of the existing host, not a proposal to build another environment. Point Zero uses the existing museum counter, Point One its corridor points, and Coordinates its held point and WORLD/LOCAL cards. All three tutorials have their printed edits checked in their halls. Other pilots still run in the separate starter; adapt and check each in turn. Day Zero’s detailed setup text also still needs its host instructions aligned with this agreement.

## Current saved drawing — 6 October

The author's correction is explicit: save the hand movement in Trace and place its drawing as a sculpture in Grid. The current class-based lessons do this inside the existing museum. They carry the saved geometry as well as the position record. Grid introduces no replacement point or new drawing. [Actual museum images, complete lessons and assertions](../iterations/2026-10-06-trace-saved-to-grid/index.html).

The learner study is temporarily hosted at hall-local (8.5,0,8.5), unit scale, in each actual hall for the integration check. Rooms, artifacts, lighting and player belong to the museum. Native source tests and this separate-process hall check pass; physical headset use remains untested. The tutorial makes this available in the student's working copy; it does not permanently add another artifact to the shipped map. Earlier starter and existing-artifact pilots below are historical course versions.

## Day Zero establishes the environment

Day Zero establishes a working copy of the Ada project and the existing Endless Museum, including its player, lighting, OpenXR configuration and chosen XR Tools components. Explain what the supplied environment does; do not ask students to assemble a fresh collection of plug-ins or a new room for every lesson. The small starter remains useful for isolated testing and portable examples.

Day Zero covers importing the project, editing, saving, running and stopping. The headset route also covers device setup and export, followed by a real check of head tracking, movement and a supplied pickup object. A successful desktop run does not certify the headset route.

The desktop route supports students without a headset and quick iteration. Its input and camera can differ from XR. When that difference matters to a lesson, name it.

Day Zero also prepares the image: viewing, environment light, a main light, fill, material response and clear edges. The starter provides an editable studio preset. Its desktop Forward+ rendering and lighter Compatibility path are documented separately; neither a polished screenshot nor a desktop run certifies headset performance. Later lessons inherit these conditions and return to their construction when relevant.

The [lighting comparison](../iterations/2026-10-03-day-zero-light-and-material/index.html) shows the running room before and after, and what happens when its main light is removed.

## What each tutorial contributes

The reader's introduction at the start of [Point Zero](../../../commons/maps/Point_Zero/tutorial.md) explains the three overlapping sets: artifacts selected for the tutorial, artifacts encountered through reflective writing, and the wider museum field. The tutorial and reflective tracks can be read alongside each other, but neither must account for everything in a hall. An artifact may belong to both tracks, one, or neither. Presence outside the written tracks is not by itself grounds for removal or a demand for another lesson. Selection should serve the particular learning progression or inquiry.

| Part | Responsibility |
|---|---|
| Prepared world | Viewing, locomotion, device input and the supplied interaction components. |
| Student's study | The display, body, rule or system taught here, created in code with its state and direct references. |
| Hall | The scale, placement, neighbours and bodily situation that give this construction a question. |

Each lesson names its starting context and dependencies. Create the teaching object in code; do not fetch a secretly prepared object using `$`, `get_node()` or another path lookup. A supplied XR component is allowed when its role and public interface are stated. Self-contained does not mean rewriting the engine or an entire player in every example.

For Point Zero, use the frame counter already in the hall. Its script creates the console and keeps a direct reference to its label. The lesson changes only the update: read the engine total every frame, then read it once. It needs no second counter, greeting display or camera exercise. Begin other lessons by finding their material in the existing artifacts too.

When Coordinates introduces grabbing, the lesson must declare the provided pickup component and what it supplies. A desktop substitute can test position changes, but cannot stand in for testing reach, grip or release on the headset. Where useful, pass a position or event into the study through an explained interface, keeping device-specific input separate from the rule being investigated.

Save each work as a scene or script the student can reuse. Bring selected works together into their own room. The growing collection need not all run at once, and the learner need not reproduce every museum artifact.

## What is available now

**Current Primitives continuation, 6 October:** [Triangle through Melencolia](../iterations/2026-10-06-primitives-tutorial-lineage/index.html) now uses the existing Endless Museum as its host. Nine canonical tutorials print complete reduced programs and local support, carry original Trace data into Triangle/Polyhedra, and return the PointBody and CubeBody classes. All nine run natively and mount in their actual halls; 122 assertions pass and ten deliberately broken variants fail. Physical headset use remains untested. This supersedes the 3 October standalone pilots below as the current teaching route; retain those links as historical experiments. The [current facing pages](../iterations/2026-10-05-primitives-facing-pages/index.html#map=Point_Triangle_Context) place tutorial left and reflection right.

- The full Ada project enables OpenXR, bundles Godot XR Tools 4.5.1 and starts `commons/scenes/vr_staging.tscn`, as checked in the local project and add-on configuration.
- The small Day Zero and Point Zero downloads are desktop studies. They contain no tracked player or XR add-ons.
- [Point Zero — Already running](../iterations/2026-10-03-point-zero-in-the-museum/index.html#reading) now studies the existing frame counter in Endless Museum. The exact printed function edits passed native checks in the hall. No new artifact is placed, and the original source is unchanged. Physical headset use remains untested.
- The [student XR starter](../studies/ada-xr-starter/README.md) now packages one room, a desktop player, an XR Tools player, a supplied pickup cube and the unchanged Point Zero counter. The add-on and action map are included in its download. Desktop and simulated-controller checks are recorded with the package; a real headset run and standalone Quest export still need verification.
- [Point One — the existing points](../iterations/2026-10-03-point-one-existing-points/index.html#reading) now follows `point_condition.gd` in the museum corridor: position, surface and a separate collision boundary. Its printed edits and actual desktop walker contact are checked in the hall. The earlier three-script starter study remains an optional companion.
- [Coordinates — carry a position](../iterations/2026-10-03-coordinates-existing-point/index.html#reading) uses the museum's existing held point, frame and cards. The learner edits its starting height and report formatting; the lesson distinguishes WORLD, frame-local and parent-local positions. Printed edits and supplied pickup/release passed native checks with a synthetic holder. Physical headset use remains untested.
- The [Point Lines pilot](../iterations/2026-10-03-point-lines-two-ends/index.html#reading) runs in `point_lines.tscn` in the shared starter. Its named supplied scripts provide holding and segment drawing; the lesson computes displacement and distance. Its museum revision is next after the Coordinates lesson has been read.

- The [Point Trace pilot](../iterations/2026-10-03-point-trace-positions-kept/index.html#reading) runs in `point_trace.tscn`. It inherits the handle, retains positions in a typed array, and traverses adjacent entries with a loop. Its smaller continuous recorder deliberately omits the museum pens' snapping and separate strokes.

- [Your trace returns in Grid](../iterations/2026-10-03-trace-return-to-grid/index.html#reading). Release the point in Trace to save a snapshot, then run `point_grid.tscn`. The lesson maps that saved list into a separate rounded list and compares the two. The supplied local-file transport keeps the gesture across scene runs; Grid never substitutes another drawing.

- [Triangle — three corners, then a face](../iterations/2026-10-03-triangle-three-corners/index.html#reading) continues the same saved trace in `point_triangle.tscn`. Three selected positions become independent movable corners. Lines close the boundary; an explicit ImmediateMesh submission adds the face. The lesson does not triangulate the complete drawing or modify its saved source.

- [Polyhedra — a face list](../iterations/2026-10-03-polyhedra-a-face-list/index.html#reading) runs in `point_polyhedra.tscn`. It returns to the same original Trace selections and adds a fourth point. Face-index rows and a nested loop let the learner close an opening by adding one row, independently of moving the corners. Collision remains a separate museum return.

- [Cube — the shared diagonal](../iterations/2026-10-03-cube-a-shared-diagonal/index.html#reading) runs in `point_cube.tscn`. It reuses the face-list construction with eight authored positions. Moving one front corner and changing the diagonal compare position edits with connection edits. No saved trace is required or altered.

- [Primitives — a rule for positions](../iterations/2026-10-03-primitives-a-rule-for-positions/index.html#reading) runs in `primitive_rules.tscn`. A function generates six opposite-axis positions from a radius; the existing renderer connects and lets you edit them. A SphereMesh return separates dimensions from two directions of subdivision.

- [Portals — how close is useful?](../iterations/2026-10-03-portals-a-useful-limit/index.html#reading) runs in `primitive_portals.tscn`. A function adds successive distances and closes the loop. The learner varies the side count and an absolute perimeter tolerance; circle sampling and the finite grey guide remain supplied.

Keep writing and checking one tutorial at a time. Use the Endless Museum as the intended teaching context. For each reduced example, identify its existing artifact, the code the learner owns, and how that code is hosted in the hall. Keep direct references to code-created lesson objects; do not replace that requirement with hidden scene-path lookups. Record actual museum integration and headset results separately from the starter's checks. The prepared player is something to borrow; the existing artifact supplies the specific code the student reads and changes.
