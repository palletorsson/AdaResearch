# The Endless Museum — lesson workbench

Ada is a VR project. Walk through the existing Endless Museum, encounter its artifacts, and build selected operations from the tutorials. Some artifacts belong to the reflective writing; others belong to the wider field. They do not all become programming exercises.

This download supplies a small working room for running the **same printed programs** when the full museum project is not installed. It is a workbench for the museum course, not a second curriculum. The museum remains the intended setting. Each `lessons/<hall>/TUTORIAL.md` and its executable files come from the current museum `tutorial.md`. `LESSONS.json` records their source and hashes. The build checks that every complete printed GDScript file equals the file you run.

## Day Zero: the supplied environment

Use **Godot 4.6 Standard**. The download includes Ada's pinned **Godot XR Tools 4.5.1** and OpenXR action map. Extract the ZIP, import `project.godot`, and let import finish. Run `main.tscn` to check the room, counter and pickup cube. Headset setup and controls appear below. Once this works, running a scene is assumed throughout the tutorials.

`base.tscn` supplies light, camera/player, floor and hands. Each lesson scene adds a unit-scale `PointStudy` with the complete learner script attached. The script builds its own objects; it has no hidden scene-child references. Keep `prepared/` and `addons/` as supplied infrastructure. In the full museum, put the same files beside your study in the corresponding hall.

The default launch is desktop so the project can open without an OpenXR runtime. Desktop is a checking aid: aim and press E to hold/release; a held object follows the camera, so looking or walking while holding moves it. Release before stepping away to inspect a drawing. Selection preserves the initial offset rather than pulling the point into the camera. Closing a scene does not save a held drawing. These accommodations belong here; lessons describe the VR encounter. Enter provides the optional `ui_accept` reset in the Godot primitives study; restarting the study also resets it.

## The route

Open the listed scene with **Run Current Scene** (F6). Read its tutorial and edit the named main file; inherited helpers are printed and included beside it. **Run Project** (F5) opens Day Zero. Each scene is prepared to run the current lesson, so the three-stage Point One corridor remains a museum encounter while the workbench builds the one point specified by the current tutorial.

| Hall | Scene | Tutorial / main file |
|---|---|---|
| Point Zero | `point_zero.tscn` | [Read](lessons/Point_Zero/TUTORIAL.md) · [counter.gd](lessons/Point_Zero/counter.gd) |
| Point_One | `point_one.tscn` | [Read](lessons/Point_One/TUTORIAL.md) · [point.gd](lessons/Point_One/point.gd) |
| Point_Coordinates | `point_coordinates.tscn` | [Read](lessons/Point_Coordinates/TUTORIAL.md) · [point.gd](lessons/Point_Coordinates/point.gd) |
| Point_Lines | `point_lines.tscn` | [Read](lessons/Point_Lines/TUTORIAL.md) · [line.gd](lessons/Point_Lines/line.gd) |
| Point_Trace | `point_trace.tscn` | [Read](lessons/Point_Trace/TUTORIAL.md) · [trace.gd](lessons/Point_Trace/trace.gd) |
| Point_Line_Grid | `point_grid.tscn` | [Read](lessons/Point_Line_Grid/TUTORIAL.md) · [grid.gd](lessons/Point_Line_Grid/grid.gd) |
| Point_Triangle_Context | `point_triangle.tscn` | [Read](lessons/Point_Triangle_Context/TUTORIAL.md) · [lesson.gd](lessons/Point_Triangle_Context/lesson.gd) |
| Primitives_Polythedra | `point_polyhedra.tscn` | [Read](lessons/Primitives_Polythedra/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Polythedra/lesson.gd) |
| Point_Animatedcube | `point_cube.tscn` | [Read](lessons/Point_Animatedcube/TUTORIAL.md) · [lesson.gd](lessons/Point_Animatedcube/lesson.gd) |
| Primitives_Ignorance | `primitive_rules.tscn` | [Read](lessons/Primitives_Ignorance/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Ignorance/lesson.gd) |
| Primitives_Godot | `primitive_godot.tscn` | [Read](lessons/Primitives_Godot/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Godot/lesson.gd) |
| Primitives_Columns | `primitive_column.tscn` | [Read](lessons/Primitives_Columns/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Columns/lesson.gd) |
| Primitives_Profiles | `primitive_profiles.tscn` | [Read](lessons/Primitives_Profiles/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Profiles/lesson.gd) |
| Primitives_Portals | `primitive_portals.tscn` | [Read](lessons/Primitives_Portals/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Portals/lesson.gd) |
| Primitives_Melencolia | `primitive_composition.tscn` | [Read](lessons/Primitives_Melencolia/TUTORIAL.md) · [lesson.gd](lessons/Primitives_Melencolia/lesson.gd) |

## What travels between halls

Point One's sphere and boundary acquire pickup in Coordinates. Lines moves that construction into PointBody; Trace reuses the class and LineSkin. Draw a short shape, release it to save, then open Grid in this same project. Grid loads the original segment sculpture and alters an independent copy. It neither draws a substitute gesture nor writes over the original.

The supplied archive is `user://ada_student_trace.scn`. It keeps Study-local positions in metres and the actual segment geometry; no timestamps or cloud transfer are implied. Triangle and Polyhedra read that same record. Choose the same three valid sample indices in each; the default indices need not be the corners you want. An absent or degenerate record receives an explanatory message rather than invented geometry.

The former starter used a JSON position record and different examples. It is not silently interpreted as the new sculpture archive: draw and intentionally release a new trace. The old repository studies remain historical source, but are excluded from this download. No saved learner drawing is shipped as if it were yours.

The current FaceBody supplies lit normals and a front side. The Triangle tutorial explains winding; Polyhedra and Cube reuse that renderer. Inspect faces from more than one position. Lights, viewpoint and edge strokes are supplied presentation, while positions and connections belong to the lesson.

## Later and optional studies

`trans_pre.tscn` retains the published introductory motion study in `studies/trans_pre/`. The seven-hall Transformation review draft is not automatically accepted by rebuilding this package. `resolution_colonnade.tscn` is an optional gallery companion. Its stand labels identify outline, height, sides and profile divisions; `varied_forms = false` holds outline and height fixed for comparison.

## Evidence and limits

The 6 October repair report is [starter-one-course](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-starter-one-course/index.html). Source equality, native code checks and a multi-process Trace → Grid handoff are separate from visual review. Synthetic XR input tests the supplied pickup interface; it cannot establish physical headset comfort, tracking or Quest performance. Those need a device session.

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

Desktop pickup retains the object’s initial offset from the camera-mounted holder. It does not reproduce the reach or independent movement of a tracked hand. The headset version has simple pink controller markers; articulated hands are not included in the room.

## Headset setup belongs to Day Zero

For a connected PC headset, establish its OpenXR runtime before launching. In **Project Settings → XR → OpenXR**, turn **Enabled** on and restart the editor when prompted. Run the same `main.tscn`. For a single launch from a terminal, use `godot --path <project-folder> --xr-mode on`. Switch Enabled off for ordinary desktop work, or use `--xr-mode off` for one desktop launch. XR shaders and the action map are already configured.

For standalone Quest, the project has an Android override enabling OpenXR. Install the Godot 4.6 export templates and the Android tools, then create the Android OpenXR export preset. Device-specific SDK paths and signing credentials are deliberately not distributed in this download.

Use the versioned [XR setup guide](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html), [Android export guide](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html) and [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html). Godot 4.6 supports direct Android OpenXR export; its vendor plug-in is optional but recommended. This download uses core OpenXR and does not bundle a vendor plug-in or a built APK.

The desktop checks and simulated XR checks are recorded in `VERIFICATION.md`. **A real headset and standalone Quest deployment still need to be checked.** Before calling Day Zero complete on your device: look around, move and turn, grip and release the cube, reset it, and check that tracking and input resume after opening the headset menu.

## Provenance

Ada's starter code is covered by the included `LICENSE`. XR Tools retains its own `addons/godot-xr-tools/LICENSE`, hand-asset license and icon license. `DEPENDENCIES.json` records every bundled dependency's SHA-256 hash. The toolkit's Blender authoring sources are omitted; its runtime hand assets are retained. In the Ada repository, run `doc/book/iterations/2026-10-03-ada-xr-starter/build.py` to assemble the local add-on folder and download; the ZIP already includes it.
