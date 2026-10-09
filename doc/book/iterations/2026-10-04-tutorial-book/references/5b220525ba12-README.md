# A place to begin

This is a small Ada working room for **Godot 4.6 Standard**. It includes **Godot XR Tools 4.5.1**, taken from Ada's bundled copy, and its OpenXR action map. You do not need the museum project to open the download.

Extract the ZIP, import `project.godot`, and let the first import finish. Open `main.tscn` and run the project. **The computer version starts on desktop by default.** This avoids a blocking OpenXR alert when no headset is connected. The headset route below enables XR during Day Zero; the study and room stay the same.

The room contains a running counter and a pink pickup cube. Edit `studies/hello_world.gd`, save, and run again. Change `count += 1` to `count += 2`. The counter should now take steps of two. Its value counts frames, not seconds.

## What is yours

`main.tscn` inherits the prepared room in `base.tscn`. Its child **Study** has the counter script attached. That script creates its own display. It is the same script used in the separate Point Zero desktop study, with no `$` references or scene lookups.

Keep `prepared/` and `addons/` together as the supplied environment. You can inspect them without needing to explain or rebuild them yet. The test cube checks the player's pickup system; making that system is not Point Zero's lesson.

For another study, duplicate `main.tscn` and attach its script to Study. Keep the prepared room and player once. If a lesson needs a supplied interaction component, it will name that dependency. Later, place selected studies together to make a room of your own.

## Continue with Point One

Open `point_one.tscn` and use **Run Current Scene** (F6). **Run Project** (F5) still opens the Day Zero counter. Point One uses the same room, lighting and player, with the setup-check cube and display removed from this lesson's arrangement.

Read `studies/point_one/TUTORIAL.md`. The three station scripts are `position.gd`, `visible.gd` and `solid.gd`, in the same folder. The lesson creates each sphere and collider in code; the scene supplies their labelled stations. Walk towards each station from the front. The player can cross the first two, while the third stops movement. Desktop collision was tested; physical XR remains to be checked. Virtual collision limits locomotion, not the physical movement of a headset or hand.

The scripts also work on a bare Node3D in another prepared scene. They require no scene lookups, player reference or add-on. The collision comparison does require a moving physics body; here the supplied player performs that role.

## Continue with Point Lines

Point Lines continues in `point_lines.tscn`, also opened with **Run Current Scene** (F6). Read `studies/point_lines/TUTORIAL.md` and edit `line.gd` beside it. Both endpoints are created in code. Approach, aim and press E to hold one on desktop; press E again to release. XR uses the supplied near grip. The handles remain where released. Restart the scene to restore their initial positions. The handles and the segment remain children of the same `Study` node, whose scale should stay at one for the metre readings.

`prepared/point_handle.gd` supplies XR Tools pickup around Point One's mesh/collider construction. `prepared/segment.gd` supplies the cylinder's placement and orientation. These two scripts are explicit dependencies of the lesson. The dark backdrop is only a visual aid and has no collision. Physical headset testing remains pending.

## Continue with Point Trace

Open `point_trace.tscn` with **Run Current Scene** (F6). Read `studies/point_trace/TUTORIAL.md` and edit `trace.gd` beside it. The lesson creates one PointHandle, a drawing and a readout in code. It retains positions in an `Array[Vector3]`, uses a distance threshold to admit another, and joins adjacent entries with a `for` loop. Change `spacing` from `0.08` to `0.25`, or `capacity` from `128` to `32`, then restart and compare.

The supplied `prepared/trace_drawing.gd` provides `clear()` and `join(a, b)` using Lines' segment renderer. It marks the retained endpoints with small pink dots and reuses its drawing nodes. All positions use Study's frame; keep its scale at one. This is a continuous record of the handle centre. Release holds the point still; taking it again continues the same record, including the move into the desktop hold. Release saves a copy for Grid, with a confirmation in the room. Restart the scene for a fresh drawing. The museum pens' nib, snapping grid and stroke separation are additional behaviors, outside this reduced study.

## Bring your trace into Point Grid

In `point_trace.tscn`, hold the point and draw with the desktop mouse or tracked VR controller. Release it and look for **Saved for Point Grid**. The supplied `TraceMemory` saves a snapshot of the current retained list on this device. A new release replaces that record; restarting Trace without making a usable drawing does not erase it.

Stop Trace, open `point_grid.tscn`, and use **Run Current Scene** (F6). Pink shows the saved trace; white shows the same positions rounded to the chosen grid. If no usable trace exists, the room asks you to draw and release one first. Nothing generated is presented as your drawing.

Read `studies/point_grid/TUTORIAL.md` and edit `grid.gd`. It loads `source_points`, maps each position into a new `grid_points` list, and displays both. Change `grid_size` from `0.25` to `0.5` and rerun Grid without redrawing. The source stays intact. Equal rounded neighbours remain separate entries, though their zero-length segment is hidden. A loop through samples and a grid address identify different things.

`prepared/trace_memory.gd` supplies release detection and local-file transport in `user://ada_point_trace_v1.json`. The file carries Study-local coordinates in metres and survives separate scene runs on the same device. It is not cloud sync. `prepared/trace_comparison.gd` supplies the two views, using the same source-based centre and scale for both. Their horizontal separation and the XY ruling are display aids. The visible rule in the learner's code operates on the original values before that display transform.

## Continue with Triangle

Open `point_triangle.tscn` with **Run Current Scene** (F6). Read `studies/point_triangle/TUTORIAL.md` and edit `triangle.gd`. It reads the same saved Trace snapshot used by Grid and selects three positions by list index. The source is not rounded, flattened, fitted or overwritten. If fewer than three positions are available, the room asks you to make and release a trace first. It never invents a replacement drawing.

Three pink PointHandles let you edit copies of the selected positions. Their connecting segments close a boundary. Set `show_face` to `true` and run again to add the face. The learner script creates an ImmediateMesh, submits the three current corner positions each frame and displays it in a MeshInstance3D. The supplied off-white material shows both sides without light variation; the boundary material is off-black. Neither the rendered face nor its edge strokes adds collision. The handle colliders still allow pickup.

Move a corner with desktop aim/E or XR near grip. Separate collinear or coincident corners to recover a face. Restarting reloads the original selections; edits to these handles are not saved over the trace. Keep Study scale one and its local frame shared with Trace. Selection is by sample index, not equal distance or corner detection; this is one triangle, not a fill of the entire drawing. General polygon triangulation, normals and indexed meshes remain later work.

## Continue with Polyhedra

Open `point_polyhedra.tscn` with **Run Current Scene** (F6). Read `studies/point_polyhedra/TUTORIAL.md` and edit `polyhedra.gd`. It loads the same three original Trace selections as Triangle; temporary handle edits in Triangle are not saved. A fourth position is their centre plus `(0, 0, -0.7)`. Four labelled PointHandles let you change the positions. This explicit depth offset is not a computed normal to your triangle: move the handles if your drawing leaves the points collinear or coplanar.

The learner keeps vertex positions separately from the face list. Three rows initially draw the open corner. Add `[1, 3, 2],` before the face array's closing bracket and run again to close its rim with a fourth triangular face. A nested loop submits each row's three positions. Moving a numbered handle updates every face that refers to it; changing the rows changes the connections without moving the positions. The six visible edges reuse Segment. The same face and edge materials used in Triangle are supplied.

With four non-coplanar points, the closed surface bounds a tetrahedron. Rendering does not create solid interior material or a collider. The small handles retain their pickup colliders. The study never overwrites the Trace record. Restart restores the original selected positions and the current authored face list. The museum's convex-hull collision, ramps and barriers are separate return investigations.

## Continue with Cube

Open `point_cube.tscn` with **Run Current Scene** (F6). Read `studies/point_cube/TUTORIAL.md` and edit `cube.gd`. The lesson reuses the position/face-list construction with eight explicit cube coordinates. It needs no saved trace and never reads or writes the Trace record. Twelve boundary segments and twelve triangle patches are created in code.

Follow the front pair `[4, 5, 7]`, `[5, 6, 7]`. The first patch is off-white and the second pink; an amber segment marks their shared edge `[5, 7]`. Move corner 6 with desktop aim/E or XR grip. Only the second front triangle tilts; neighbouring top/right triangles also update. The labels remain readable through surfaces as annotations. All patch materials show both sides without lighting variation.

For repeatable comparison set `corner_shift` to `0.35` and run again; it adds that Z displacement to corner 6 at startup. For another triangulation replace the first pair with `[4, 5, 6]`, `[4, 6, 7]`, and set `diagonal_pair` to `[4, 6]`. The two choices cover the same original flat square but give different surfaces after corner 6 moves out of plane. Restore the original pair, `[5, 7]` and zero shift when finished. `show_diagonal` hides the guide independently; `show_faces` leaves the wire structure and handles. Restart restores authored values; handle edits are temporary.

The nested loop begins and ends a separate mesh surface for each triangle so the second patch can use a distinct supplied material. This is a presentation choice; `faces` remains the list of triangle connections. Neither the mesh nor its drawn edges adds collision. The museum's replay animation, folding net and prefab shelf are separate return encounters.

## Continue with Primitives Ignorance

Open `primitive_rules.tscn` with **Run Current Scene** (F6). Read `studies/primitive_rules/TUTORIAL.md`. The two lesson scripts create their geometry in code. The scene places the octahedron to the left and SphereMesh to the right; neither script needs scene lookups.

In `octahedron.gd`, `octahedron_positions(radius: float) -> Array[Vector3]` returns six opposite-axis positions for a positive radius. Change the argument in `_ready()` from `0.55` to `0.75` and run again. The eight triangular faces and twelve edge pairs are supplied separately. Move a numbered handle with aim/E or XR near grip to edit the generated result. The function is not called each frame; restarting restores its result. This study does not read or write the saved Trace.

In `sphere.gd`, change radial segments from 8 to 16, then restore 8 before changing rings from 4 to 8. Radius 0.55 and full height 1.1 stay fixed. `prepared/mesh_edges.gd` supplies a wire guide from the actual non-degenerate triangle edges, without changing the source geometry. Both studies reuse the unshaded, two-sided face material. Only the numbered handles have pickup colliders; the surfaces have no collision.

## Make one column from a profile

Open `primitive_column.tscn` with **Run Current Scene** (F6). Read `studies/primitive_column/TUTORIAL.md` and edit `column.gd`. This companion follows Ignorance's position function. Seven radii define seven equally spaced rings over a full height of 2.2 metres. A supplied circle sampler supplies the angular positions; the learner's nested loop scales and places each ring. ColumnSurface joins the rings and adds two caps, with flat lighting normals. The complete builder source is beside the lesson.

Change the middle radius from 0.22 to 0.55, restore it, change height to 1.6, restore it, then compare 4, 6, 8, 12 and 16 sides. Height does not change widths; side count does not change the stored radii or ring heights. These are straight profile intervals, unlike the curved sections of the companion gallery. Adding a profile entry redistributes the equally spaced heights; it is not an independent smoothness control. The surface has no collider. The script needs no scene-child lookups, no saved Trace and no new input system.

## Continue with Portals

Open `primitive_portals.tscn` with **Run Current Scene** (F6). Read `studies/primitive_portals/TUTORIAL.md` and edit `perimeter.gd`. The supplied circle sampler returns ordered positions; your function measures their closed polygon, including the last-to-first edge. Change `divisions` from 6 to 12, 24 and 48. Keep `radius = 1.0`. The sampler accepts 3 to 256 divisions and a positive radius.

The comparison uses `TAU * radius` for circle circumference and tests whether the perimeter shortfall is at most the chosen tolerance, in metres. At 48 sides, changing `tolerance` from 0.01 to 0.001 changes the decision without changing the polygon. This is a total-length difference, not a maximum spatial gap or a torus accuracy measure. The grey drawing is fixed at 256 segments and is not the numerical reference.

The script creates the supplied PolygonDisplay directly; it needs no authored child nodes. No new input controls, physics boundary or saved gesture are involved. The museum's ring ladder and halving track remain separate encounters. Trigonometric derivation and automatic refinement are later work.

## Compose in Melencolia

Open `primitive_composition.tscn` with **Run Current Scene** (F6). Read `studies/primitive_composition/TUTORIAL.md` and edit `arrangement.gd`. The loop builds three identical pyramids in code and places each at a listed Vector3. All five local vertices and six render triangles remain the same when a whole body is placed elsewhere. Change the middle Z from -0.8 to 0.8; then bring the outer X values from ±1.15 to ±0.55. Walk around the arrangement and inspect the overlaps.

Pyramid's inspectable builder reuses a position list and face list; its material and lighting normals are supplied. This reduced study draws on the museum's geometric court, not a reconstruction of Dürer's engraving. These are visible surfaces without collision. Save authored placements in the script and restart to rebuild them. The historical and critical reading remains separate; the archived museum notes are included as a source companion.

## Enter Rings of Ash — the resolution colonnade

Open `resolution_colonnade.tscn` with **Run Current Scene** (F6). This optional gallery uses the same desktop and XR player infrastructure in a larger room. Click to look, use WASD to walk, and press R to return to the entrance. The configured headset route uses the usual movement and turn sticks; B/Y returns to the entrance.

Twenty-five columns use five outline families (Vessel, Reed, Bell, Spindle and Cairn) and staggered heights from 2.87 to 6.17 metres including the plinth. Across the hall, radial segments are 4, 6, 8, 12 and 16. Along its depth, the curved-profile subdivisions use the same five counts. Base labels name the outline, mesh height, sides and profile divisions. To compare resolution with height and outline held fixed, disable `varied_forms` on the standalone gallery scene under `studies/resolution_colonnade/`; all columns return to the original Vessel profile at 4.67 metres above their plinths. The root walking scene creates its gallery in `walk.gd`, where the same property can be set before adding it. Straight collars retain one height interval because subdividing their straight profile would not change their silhouette.

The architecture is inspired by Pompeian red walls: pale stone, bronze rims, charcoal floor, open roof and a rose light at the far end. Desktop Forward+ adds volumetric haze. XR and Compatibility omit that effect and SSAO; physical headset comfort and performance are not yet verified.

`studies/resolution_colonnade/gallery.gd` makes the room, and `resolution_totem.gd` makes each body. These are source-identical copies of the registered Ada gallery assets. The standalone totem and gallery scenes are included beside them; the root scene adds the player. This is a spatial companion, not a new required programming lesson.

## Begin Transformation

Open `trans_pre.tscn` and read `studies/trans_pre/TUTORIAL.md`. Edit `motion.gd` beside it. Change `stage` from `0` to `1`, `2` and `3`, restarting after each edit: still, rise and fall, add a turn, add uniform scaling. The cube and its small readout are created in code. `marked_cube.gd` supplies its box and orientation mark; `motion_readout.gd` only displays the current values. The dark backdrop and plinth belong to the prepared scene.

The learner owns the clock, extent, duration, turning rate and scale factor. `tutorial-sine.md` gives a short optional comparison at stage 1, with the same endpoints and period. The production museum cubes use the linear version; their pickup, collection, rewards and sound are outside this reduced study. The animated cube and display props have no colliders. The prepared room still supplies the solid floor and player. Physical headset use remains untested.

## The prepared studio

The room now has a sky providing ambient and reflected light, a warm shadow-casting main light and a dim cool fill. Walls and plinths are matte off-white; the pink cube is smoother. The desktop preset uses ACES tone mapping, soft directional shadows, gentle ambient occlusion and anti-aliasing. It contains no downloaded HDR image, texture pack or baked lighting data.

Select **AdaRoom** in `main.tscn`. Its **Studio Light** group exposes **Studio Environment**, **Key Energy** (`0.65`), **Key Rotation Degrees** (`-48, -32, 0`) and **Fill Energy** (`0.18`). Save and run after changing a value. The environment is stored in `prepared/studio_environment.tres`, so its sky, ambient light and tone mapping are inspectable as an ordinary Godot resource.

Try Key Energy at `0`, then restore `0.65`. The cast shadow disappears; the sky and fill still light the cube. This is a check of the arrangement you are borrowing. The Point Zero script stays unchanged.

The default computer renderer is **Forward+**, with 4× MSAA, soft shadows and contact shading from SSAO. Temporal anti-aliasing is disabled so the changing counter stays legible. For an older computer, choose **Compatibility** in the editor's renderer selector and restart. The Android feature configuration also uses Compatibility, with 2× MSAA and smaller shadow maps. Compatibility uses half the direct-light energy to retain the pale surfaces, and sharper shadows. Images will differ between renderers.

The room disables its SSAO when XR is active, and removes the desktop soft-shadow setting. The active-headset rendering path still needs a device test. The camera follows a tracked head in XR; do not reposition that camera to imitate a desktop screenshot.

## Controls

| Desktop | Headset with controllers |
|---|---|
| Click the window to capture the mouse; move it to look. | Turn your head to look. |
| WASD or arrow keys to walk. | Left stick to move; right stick for 30° snap turns. |
| Aim the centre mark at the cube, come within 2.5 m, then E or click to pick up. Repeat to drop. | Bring a controller marker within 20 cm of the cube; hold grip to pick up and release grip to let go. |
| R returns the cube to its plinth. Esc releases the mouse. | B or Y returns the cube to its plinth. |

Desktop pickup moves the object to a position in front of the camera. It checks the object's pickup/release behavior, but it does not reproduce the reach, grip or release of a tracked hand. The headset version has simple pink controller markers; articulated hands are not included in the room.

## Headset setup belongs to Day Zero

For a connected PC headset, establish its OpenXR runtime before launching. In **Project Settings → XR → OpenXR**, turn **Enabled** on and restart the editor when prompted. Run the same `main.tscn`. For a single launch from a terminal, use `godot --path <project-folder> --xr-mode on`. Switch Enabled off for ordinary desktop work, or use `--xr-mode off` for one desktop launch. XR shaders and the action map are already configured.

For standalone Quest, the project has an Android override enabling OpenXR. Install the Godot 4.6 export templates and the Android tools, then create the Android OpenXR export preset. Device-specific SDK paths and signing credentials are deliberately not distributed in this download.

Use the versioned [XR setup guide](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html), [Android export guide](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html) and [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html). Godot 4.6 supports direct Android OpenXR export; its vendor plug-in is optional but recommended. This download uses core OpenXR and does not bundle a vendor plug-in or a built APK.

The desktop checks and simulated XR checks are recorded in `VERIFICATION.md`. **A real headset and standalone Quest deployment still need to be checked.** Before calling Day Zero complete on your device: look around, move and turn, grip and release the cube, reset it, and check that tracking and input resume after opening the headset menu.

## Provenance

Ada's starter code is covered by the included `LICENSE`. XR Tools retains its own `addons/godot-xr-tools/LICENSE`, hand-asset license and icon license. `DEPENDENCIES.json` records every bundled dependency's SHA-256 hash. The toolkit's Blender authoring sources are omitted; its runtime hand assets are retained. In the Ada repository, run `doc/book/iterations/2026-10-03-ada-xr-starter/build.py` to assemble the local add-on folder and download; the ZIP already includes it.
