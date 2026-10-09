# Current edition — 6 October 2026

The current starter extracts complete programs from all 15 canonical Primitives tutorials, including Point Zero and Coordinates. `LESSONS.json` records the exact sources. Read the [current repair and verification report](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html).

Verification uses a newly unpacked download, separate native Godot processes for the Trace → Grid handoff, deliberate fault injection and native rendered comparisons. Physical headset testing remains pending. Historical counts below describe their dated editions; they are not test results for the current lesson code.

---

## Historical verification record (superseded lesson programs)

# Starter verification — 3 October 2026

Godot 4.6 stable, Windows, NVIDIA RTX 3070. The updated studio uses Forward+ on desktop; Compatibility was also rendered separately.

The ZIP was extracted into a new temporary folder outside AdaResearch and imported without the museum project, its autoloads or its cached resources. Cold import and the subsequent native integration run completed with empty error logs.

**30 checks passed.** They cover the counter's construction and progression; the active desktop camera; floor and wall collision; movement; pickup, carrying, release and reset; blocked pickup through architecture; both XR controller bindings; XR Tools locomotion-provider discovery; near grip and tracked carrying with both synthetic hands; movement, snap turns, focus gating and the reset input.

XR tests registered synthetic XRControllerTrackers and sent grip, pose, stick and button inputs through the actual controller nodes and XR Tools components. They did not emulate a head-mounted display. Head tracking, stereo output, device performance, reach and comfort, reconnecting a physical controller, and the standalone Quest export remain untested.

The screenshot is rendered by Godot from the running desktop room. It is not an image of the museum or an XR view.

After the lighting revision, a newly packaged ZIP was extracted into another empty temporary folder. Its cold import and all 30 integration checks passed again, now with Forward+. The error logs were empty. Actual Forward+ and Compatibility captures were inspected at the entrance, beside the cube and with the main light removed. The sky, fill and off-white materials keep the object readable; Forward+ also supplies softer shadows and contact shading. The Compatibility image has sharper shadows and different brightness.

The studio environment is bundled as a local resource. A rendered integration check exposed temporal anti-aliasing ghosting on the counter; temporal AA is now disabled, while MSAA still smooths geometry edges. SSAO and angular soft shadows are disabled by the room when an initialized OpenXR interface is present; this active-headset rendering branch has not been tested on a device. The Android renderer and shadow/anti-aliasing overrides are configured, not performance-certified.

The reproducible image capture and lighting comparison are under `doc/book/iterations/2026-10-03-day-zero-light-and-material/` in Ada. Its comparison counter is frozen by the capture harness only; the integration screenshot and downloadable lesson use the running counter.

## Point One extension

`point_one.tscn` now uses the same prepared room with its setup-check props omitted. The three lesson scripts create their position, visible mesh and collision body independently. A fresh ZIP import was clean. The original 30 Day Zero checks passed again after this shared-room change.

**23 further checks passed for Point One**, including compiling the exact learner edits, walking through the empty and visible-only stations with the supplied desktop player, stopping at the solid station, changing the invisible radius independently, changing both radii through one variable, and retaining collision when the light is removed. The scripts also ran on bare Node3D instances. The screenshot is the actual shared room, captured before those test edits. The matching printed code and class/property names were checked against the local Godot 4.6 API reference.

The Point One evidence and reproducible checks are under `doc/book/iterations/2026-10-03-point-one-a-body/`. This is an author review pilot, not a completed beginner reading or physical XR trial.

## Point Lines extension

`point_lines.tscn` adds two grabbable handles, a finite segment and two readouts, all created by its lesson script and named supplied helpers. The original room/player scripts and Point Zero/Point One learner scripts are unchanged by this extension. A fresh archive was imported without errors; the updated lesson was then tested in that extracted project.

Point Lines has **32 native checks**, covering subtraction and length, horizontal/vertical/downward and depth configurations, coincidence and recovery, desktop aim/pickup/release, synthetic XR near-grip movement and frozen release, same-parent coordinates, and the reversed-subtraction edit on a bare Node3D. The harness checks after the rendered frame, when node `_process()` callbacks have run. Measurement text is displayed to two decimal places to avoid making floating-point representation the subject of this lesson.

Actual desktop renders and results are in `doc/book/iterations/2026-10-03-point-lines-two-ends/`. Synthetic XR input does not certify headset tracking, reach, comfort or rendering performance. Coordinates retains its place between Point One and Lines in the curriculum; its new starter-based tutorial revision is still pending.

## Point Trace extension

`point_trace.tscn` adds a continuous recording study in the same room. The learner script creates its PointHandle, TraceDrawing and readout. An ordered Vector3 array, distance threshold, adjacent-pair loop and capacity limit are visible in the learner code. TraceDrawing reuses Segment and pools its own drawing nodes; it does not choose what enters the array.

**34 native checks passed** in a freshly extracted project after a clean Godot 4.6 import. They cover typed positions and value copies, threshold admission, exact consecutive pairs, the same route at two spacings (47 and 17 retained positions), oldest-first deletion, bounded drawing nodes, no deletion during a pause, desktop pickup/movement/release, synthetic XR grip/movement/release, and construction without scene-authored lesson objects. Screenshots are native desktop renders of a scripted route. All five printed code excerpts match the tested script. The existing room, player, Point One and Lines code is unchanged.

Evidence and the reproducible harness are under `doc/book/iterations/2026-10-03-point-trace-positions-kept/`. Physical headset and beginner reading trials remain pending. The museum pens' nib tracking, snapping, separate strokes and export are deliberately outside this reduced study. Whole-array copying is not taught here.

## Earlier Point Grid extension (superseded)

The initial Grid pilot added a free input point and a separate marker placed by a rounded integer address. It has been replaced by the saved-trace return below. The following evidence describes that earlier version, preserved in its review folder.

**39 native checks passed** after a clean import of a freshly extracted ZIP in Godot 4.6. The checks cover positive and negative boundaries, halfway cases, independent rounding on three axes, unchanged input, ordered returns to earlier addresses, no invented intervening visits, direct diagonal connections, two spacings, finite capacity, desktop pickup/release, synthetic XR grip, and local coordinates when the study is translated. The four printed code excerpts match the executable lesson. Actual desktop screenshots show scripted positions for controlled comparisons; the route returns to its exact initial position for a clean readout.

The evidence and reproducible harness are under `doc/book/iterations/2026-10-03-point-grid-an-address/`. Headset and beginner trials remain pending. The larger hall's marker-offset correction on release, walking recorder, transformed replay and floor-plan construction are outside this reduced lesson.

## Trace returns in Grid — current handoff

Trace now saves the actual retained list when the desktop or XR pickup releases. Grid loads that snapshot and maps each entry into a separate list. The file preserves exact coordinate values, including very small values, and survives separate engine runs. Grid never writes to it. Missing or invalid data produces an empty-state instruction, not a demonstration gesture.

**36 native checks and 4 separate-process checks passed.** Desktop mouse events passed through the actual player handler; synthetic controller poses and grip passed through the XR Tools pickup. The checks cover save-on-release, independent snapshots, valid replacement, rejected short/invalid records, round trips with tiny coordinates, unchanged source bytes, repeated mappings at different spacings, equal rounded neighbours, and recovery of the record in a second engine process. The synthetic XR fixture supplies an eye height so its body remains on the floor; it is not a tracked-head or headset test.

Both comparisons use one source-based display fit. The wider backdrop and final images were checked again against the same saved record. All printed code excerpts match the current learner scripts. Evidence: `doc/book/iterations/2026-10-03-trace-return-to-grid/`. The package contains the supplied transport and display, not a saved example passed off as the student's drawing. Physical headset and beginner trials remain pending.

## Triangle extension

`point_triangle.tscn` reads the original Trace snapshot and selects three original Vector3 values by list index. It creates three handles, three segments and an ImmediateMesh face in the learner script. Moving a handle changes its independent position; it never saves over the trace. The default starts with edges; `show_face = true` adds a two-sided unshaded face. Collinear positions retain three submitted vertices with zero area. No face collision is created.

**27 native checks passed** in a freshly extracted starter after a clean Godot 4.6 import. They cover exact selection from the prior 41-position synthetic XR release record, boundary/face separation, unchanged source, mouse-driven and synthetic-XR corner editing, release, collinearity/coincidence/recovery, no accumulated surfaces, no collision at the interior, empty/short record handling, restart and construction on a bare Node3D. Four printed excerpts match the tested script. A first harness run called an unavailable inspection method; correcting the harness produced the passing run without changing lesson code. Final native stderr is empty.

Images and harness: `doc/book/iterations/2026-10-03-triangle-three-corners/`. These are student-room desktop renders. Physical headset and beginner trials remain pending. General triangulation, normals and indexed meshes are not taught by this pilot. The saved demonstration trace is test evidence only and is not included in the starter download.

## Polyhedra extension

`point_polyhedra.tscn` separates a four-position array from face-index rows. It uses the same three original Trace selections as Triangle, adds a fourth position with an explicit negative-Z offset, and creates four numbered handles, six segments and an ImmediateMesh. The learner adds one face row to close the open corner. Labels face the viewer and remain readable through faces as annotations. This is an ordinary face list interpreted by the script, not a GPU index buffer. No mesh collider is created.

**28 native checks passed** in a freshly extracted starter. They cover the saved source, selected values and fourth-point offset, exact emitted triangles, the open rim and closed connectivity, the actual printed one-row script edit, shared-vertex changes, unchanged opposite face, coplanarity and recovery, bounded drawing nodes, no collision at the added face, actual mouse pickup and synthetic XR grip/movement/release, unchanged source bytes, restart and empty/short states. An initial harness read the newly added face before the next drawing frame; waiting for that frame corrected the test without a lesson change. The numbered labels were subsequently improved and the native checks rerun. Final native stderr is empty.

The four printed excerpts match the default or the tested edited script. Native screenshots and the reproducible harness are in `doc/book/iterations/2026-10-03-polyhedra-a-face-list/`. The synthetic release record is not bundled in the student ZIP. The study starts from the actual learner's saved data and reports missing data honestly. Physical headset and beginner trials remain pending.

## Cube extension

`point_cube.tscn` continues the position/connection construction with eight explicitly authored cube coordinates. It creates eight handles, twelve boundary segments, twelve triangular patches and one independent diagonal guide. It requires no saved trace and contains no TraceMemory access. The front pair follows the museum builder's numbering: `[4,5,7]` and `[5,6,7]`.

**29 native checks passed** in a freshly extracted Godot 4.6 starter. Checks cover the one-metre edges, closed triangle connectivity, coplanar start, isolated movement of the second front patch when 6 moves, all other incident faces, unchanged connections, alternate diagonal with identical corner positions, visibility controls, actual printed code edits on a bare Node3D, repeatable startup displacement, restoration, no mesh collision, mouse-driven and synthetic XR pickup/movement/release, and bounded drawing nodes. Final native stderr is empty.

The prepared materials mark the second front patch pink and the shared diagonal amber. Face construction uses one ImmediateMesh surface per triangle so the materials can differ. It is not a GPU index-buffer lesson. Five printed excerpts match the default or tested edited script. The neutral room caption applies to either diagonal. Evidence and matched-camera native images are in `doc/book/iterations/2026-10-03-cube-a-shared-diagonal/`.

The diagrams use an elevated desktop camera. Physical headset reach, rendering and beginner comprehension remain untested. Assembly timing, nets and prefabs are preserved in the larger museum companion rather than built into this first cube exercise.

## Primitives Ignorance extension

**33 native checks passed** from a freshly extracted starter in Godot 4.6. The checks cover six signed-axis coordinates, independent function results with no rendering side effects, the literal radius edit on a bare Node3D, closed equilateral faces, handle deformation that persists between frames, the actual two SphereMesh edits with fixed dimensions, source/guide agreement, guide rebuild without accumulated strokes, no face collider, desktop mouse movement, synthetic XR grip and release, and restoration in a fresh instance. The image files show the real student room, including both resolution comparisons. Cold-import and native error logs are empty.

Evidence: `doc/book/iterations/2026-10-03-primitives-a-rule-for-positions/` in Ada. Three printed excerpts match the learner scripts. Full helper source is included. No physical headset, Quest performance or novice reading test is claimed.

## Portals extension

**35 native checks passed** after cold import of a freshly extracted starter. They include the printed 6/12/24/48-side settings, fixed radius, comparison with the independent chord-length formula, closed-loop accounting using a 3–4–5 triangle, non-mutating function results, translation and scale, a stricter tolerance with unchanged geometry, drawing/source agreement, bounded redraw and a bare-Node3D run. The final import and native error logs are empty. Three printed excerpts match the learner script.

Evidence: `doc/book/iterations/2026-10-03-portals-a-useful-limit/` in Ada. Screenshots come from the actual student room. No new pickup system was introduced; physical headset use, frame-time benchmarking and beginner comprehension remain untested.

## Rings of Ash gallery

**45 native checks passed** for the optional resolution colonnade. The 25 parameter pairs generate finite geometry at their prescribed varied heights. Five profiles remain distinct with height and sampling held fixed. All columns sit on their plinths, stay within their footprints and clear the beams. The optional uniform arrangement restores one profile at equal height. Either subdivision count increases the triangle count. Actual collision supports the floor, blocks the columns, and leaves the central aisle open. The supplied desktop player walked from the entrance to the far end; return and fall recovery also passed. Final native logs are clean. Five inside-room images were visually inspected.

Evidence: `doc/book/iterations/2026-10-03-resolution-colonnade/` in Ada. All 25 totems together have 27,140 triangles, excluding plinths and architecture. Desktop Forward+ renders volumetric haze; XR and Compatibility disable volumetric haze and SSAO. Physical headset comfort, device performance and Quest deployment remain untested.

Computer startup defaults to desktop. An additional trial with automatic XR startup found that the installed Oculus runtime opens a blocking engine alert when no HMD is present. The starter therefore makes PC XR an explicit Day Zero setting; the Android feature override enables OpenXR. It does not hide a failed headset setup as a successful device test.

The dependency manifest hashes the included Ada copy of XR Tools 4.5.1 and the action map. Blender authoring sources are omitted; the toolkit's runtime assets and their licenses are retained, so the starter does not require Blender. Movement is configured relative to the view, with no hand-direction mixing.

In the Ada repository the reproducible package builder and native checks are under `doc/book/iterations/2026-10-03-ada-xr-starter/`. The unchanged student counter is also checked against `doc/book/studies/point-zero/hello_world.gd`. No teaching script looks up a prepared scene node.
