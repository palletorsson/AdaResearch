# A Godot making path through Ada Research

Status, 30 September 2026. This is a plan, revised once after review. It describes the WORKING TREE of branch `palm-scanner-door-entry` unless a line says HEAD; section 1.5 lists what differs at HEAD. No tutorial, study kit, map or `curriculum.json` was changed, and nothing was run in Godot.

Tags used throughout:

- **[M]** measured in the survey (`survey_bundle.json`) or in the repo on 2026-09-30. It describes the WORKING TREE unless it says HEAD.
- **[P]** proposed in this plan.
- **[I]** inference, not run.
- **[D]** Godot 4.6 documentation as read in the survey.
- **[K]** general Godot knowledge, not checked this session.

Machine-readable twin: `godot_path.json`, built with this file by `build_plan_v2.py` from `plan_stops_v2.py`. The build refuses to write a plan that breaks any of these rules:

- halls follow the working-tree walking order;
- every capability has exactly one first stop, and nothing returns before it;
- every prerequisite from the survey's graph comes at or before the first stop, or has a stated reason (A.1, two cases);
- a meeting at depth "change" needs an earlier meeting at "understand";
- no main stop uses a capability first met only on an optional stop;
- the two XR capabilities are met only on stops that carry XR steps, and no desktop stop depends on them;
- all 33 capabilities of the survey's minimum complete game are first met by CP3.

Size of the path [P]: 115 stops. That is 89 hall stops (11 of them optional studios, 8 of those at halls `curriculum.json` marks "reflect"), 19 workshops including Day Zero (1 of them a branch), and 7 checkpoints. The other 115 of the 204 halls stay encounters; two of them (`Trans_Scale`, `VFM_09_Legs`) host a workshop. 90 capabilities are placed: 79 main, 8 branch, 3 outside.

### What can be taught today [M, checked 2026-09-30]

Every stop carries a lesson status: **runnable** (a runnable study covers the stop's core make), **fragment-rewrite**, **prose-rewrite**, or **new-page** (workshops, checkpoints, halls with no `tutorial.md`).

- All stops: fragment-rewrite 40, prose-rewrite 39, new-page 30, runnable 6.
- Hall stops only: fragment-rewrite 40, prose-rewrite 39, runnable 5, new-page 5.
- Stops with a runnable page today, in the working tree: 0 `day_zero`, 1 `Point_Zero`, 2 `Point_One`, 3 `Point_Coordinates`, 4 `Point_Lines`, 62 `Random_Definition`. The first five are the opening. `Random_Definition` runs on desktop as a worked example, but its step in the learner's project is new writing.
- Everything else has to be written or rewritten before it can be taught. For 26 hall stops, none of the capabilities this plan first meets there appears in what the survey found the current tutorial teaching.
- Not startable at HEAD: 0 `day_zero`, 2 `Point_One`, 3 `Point_Coordinates`, 5 `Point_Trace`, 62 `Random_Definition`, 73 `Shader_10_ReactionDiffusion`. `Point_Trace` and `Shader_10_ReactionDiffusion` are not startable anywhere until their supplied parts are built.
- At halls that exist only in the working tree: 1 `Point_Zero`, 3 `Point_Coordinates`, 32 `Tutorial_Tiling_Floor`, 35 `Color_Flashlight`, 38 `Color_Rainbow`, 39 `W12_particles`, 40 `Color_Grid_Pallet`, 41 `W13_settings`, 42 `Color_Paint`, 43 `W14_game_in_headset`, 53 `Change_Choreography`.

Do not present the path to anyone outside until the opening kits are tracked or shipped as release zips. That decision is Palle's, on the forum (thread 260929-ia2d6 is the related open one).

---

## 1. What exists

### 1.1 Halls and state [M]

- The working-tree spine (`commons/maps/curriculum_spine.json`) has 25 sequences and 204 halls. HEAD's has 196. The difference is not only the opening: section 1.5 gives it per sequence.
  - 192 halls have a `tutorial.md`.
  - 12 do not: `Array`, `Ribbon_Patterns_01`/`02`/`03`, the six `Shader_*` halls, `LSystems_Shape_Grammars` and `ISO_RhizomeBody`.
- The working-tree `primitives.json` opens `Point_Zero`, `Point_One`, `Point_Coordinates` (12 halls). The committed HEAD version opens at `Point_One` (10 halls).
- `Day_Zero` is front matter in `doc/book/day-zero.md` and is not a hall.

### 1.2 What form the tutorials take, per sequence [M, working tree]

"Writes" means the survey found learner-written or learner-configured Godot in the tutorial's own steps. In the fragment sequences (swarm, ML, graph theory, foundations, QFEP) that code does not run as written: it calls undefined helpers or scenes that do not exist.

| sequence | halls | runnable study | script fragments | prose only | missing | writes |
|---|---|---|---|---|---|---|
| Day Zero (preface) | 1 | 1 | 0 | 0 | 0 | 1 |
| primitives | 12 | 4 | 8 | 0 | 0 | 5 |
| transformation | 7 | 0 | 7 | 0 | 0 | 2 |
| array_tutorial | 5 | 0 | 1 | 3 | 1 | 1 |
| color | 8 | 0 | 2 | 6 | 0 | 0 |
| tiling | 8 | 0 | 0 | 5 | 3 | 0 |
| change | 2 | 0 | 1 | 1 | 0 | 0 |
| forces | 13 | 0 | 2 | 11 | 0 | 0 |
| formfinding | 6 | 0 | 5 | 1 | 0 | 5 |
| wavefunctions | 12 | 0 | 10 | 2 | 0 | 10 |
| randomness | 14 | 1 | 11 | 2 | 0 | 11 |
| noise | 9 | 0 | 4 | 5 | 0 | 1 |
| shaders | 6 | 0 | 0 | 0 | 6 | 0 |
| cellularautomata | 8 | 0 | 1 | 7 | 0 | 1 |
| fractals | 7 (+3 HEAD-only) | 0 | 1 | 6 | 0 | 1 |
| lsystems | 8 | 0 | 0 | 7 | 1 | 0 |
| proceduralgeneration | 7 | 0 | 0 | 7 | 0 | 0 |
| softbodies | 9 | 0 | 0 | 9 | 0 | 0 |
| isosurfaces | 13 | 0 | 4 | 8 | 1 | 4 |
| boolean_surfaces | 3 | 0 | 0 | 3 | 0 | 0 |
| swarmintelligence | 7 | 0 | 7 | 0 | 0 | 7 |
| machinelearning | 8 | 0 | 8 | 0 | 0 | 8 |
| graphtheory | 8 | 0 | 8 | 0 | 0 | 8 |
| foundationscrisis | 8 | 0 | 8 | 0 | 0 | 8 |
| qfeplaboratory | 8 | 0 | 6 | 2 | 0 | 6 |
| postfoundationscrisis | 8 | 0 | 0 | 8 | 0 | 0 |
| **total** | **204 + Day Zero** | **6** | **94** | **93** | **12** | **79** |

The six runnable studies are Day Zero, `Point_Zero`, `Point_One`, `Point_Coordinates`, `Point_Lines` and `Random_Definition`.

- Only `Point_Lines` is recorded as desktop-tested: its `verification.json` shows 22/22 and its curriculum status is `desktop-tested`.
- No study has been tried by a learner or on a headset.

Most of the "prose only" count comes from uncommitted working-tree rewrites made on 2026-09-28. Their HEAD versions were April or July script fragments, and those often did not describe the installed work.

### 1.3 Where each Godot capability is first taught today [M]

This table follows the working-tree walking order and the survey's reading: a capability counts where the learner writes or configures it in the tutorial's own code. Two rows are marked **illustrative**: their pages describe things that are not installed, so what they show is not taught.

| sequence | first taught here |
|---|---|
| Day Zero | `editor.project`, `editor.scene_tree`, `editor.run_debug` |
| primitives | `gd.variables`, `gd.functions`, `gd.lifecycle`, `gd.strings`, `gd.typing`, `scene.groups_paths` (Point_Zero); `scene.nodes_resources`, `mesh.primitive`, `phys.bodies`, `phys.shapes_layers` (Point_One); `space.vector3`, `space.transform`, and `xr.interaction` in the course project (Point_Coordinates, tutorial.md l.11); `gd.loops`, `gd.dictionaries` (Primitives_Portals) |
| transformation | `anim.tween`, `phys.forces` (Trans_Translation) |
| array_tutorial | **illustrative:** `gd.arrays`, `phys.areas`, `gd.signals_own`, `gd.export`, `mat.standard`, `scene.instancing` and, by the same reading, `gd.conditions` (4 `if` lines), all in `Tutorial_Disco`, a stale page that calls undefined helpers and describes a floor that is not installed |
| formfinding | `gd.packed_arrays` (Catenary); `gd.const_enum`, `mesh.procedural` and, by the same reading, `gd.conditions` (4 `if` lines) (Relaxation); `gd.recursion` (Equilibrium); `data.rng` (Annealing, where the survey placed `gd.conditions`); `space.interpolation` (Forge) |
| wavefunctions | `perf.budget` (Pendulum); `ui.world_space` (Unit_Circle); `audio.generate`, `design.loop` (Effect_Sound); `audio.playback` (AirMusic) |
| randomness | `mesh.multimesh`, `gd.async` (Remove); `space.rotation` (Rotate_Random_XYZ); `mat.textures` (Pheromone) |
| noise | **illustrative:** `light.env`, `scene.change`, `scene.autoload`, all in `Lab_Path`, whose tutorial describes classes and resources that do not exist |
| isosurfaces | `data.noise` (PortalLandscape); `gd.classes` (CaveGeneration) |
| swarmintelligence | `input.player` (ABM) |
| foundationscrisis | `cam.camera3d` (Escher_Impossible); `res.custom` (Brouwer_Intuitionism) |
| qfeplaboratory | `scene.lifetime` (QFEP_Edge_Of_Chaos) |

The `if` counts are gdscript-block lines counted on 2026-09-30 [M]. `Point_Trace` also shows two `if` lines, inside an excerpt to inspect, which the survey does not count as taught. Under this one standard, read the table by its late arrivals:

- The first page that teaches a condition and describes installed work is `FormFinding_Relaxation`, spine 8. The only earlier `if` in a taught block is on the stale `Tutorial_Disco` page.
- No page that describes installed work lights a scene; the only one that does is the fictional `Lab_Path` template in spine 11.
- No learner builds a player until spine 20.
- No learner handles a camera until spine 23.
- No learner frees an object deliberately until spine 24.

**Never taught today [M]:**

`editor.viewport3d`, `editor.version_control`, `gd.errors`, `scene.new_scene`, `res.shared_unique`, `mesh.csg`, `mesh.gridmap`, `input.actions`, `input.events`, `ui.controls`, `ui.layout`, `phys.queries`, `phys.softbody`, `anim.player`, `anim.tree_skeletal`, `shader.spatial`, `shader.other`, `shader.viewport_feedback`, `fx.particles`, `nav.navigation`, `data.save`, `data.undo`, `perf.profiling`, `perf.threads`, `tool.editor`, `test.checks`, `xr.setup`, `export.build`, `assets.import`, `twod.basics`, `net.multiplayer`, `access.a11y`.

That is 32 of the 83 shared ids. Five of them belong to the survey's 33-item minimum for a complete small game, so those five are missing from the whole spine: `editor.viewport3d`, `scene.new_scene`, `input.actions`, `ui.controls` and `export.build`.

### 1.4 The worst hidden-prerequisite chains [M]

1. **The opening at HEAD is broken.**
   - `Point_Lines/tutorial.md` (committed 2026-09-30) opens "Coordinates gave us two positions".
   - `Point_Coordinates` is neither in HEAD `primitives.json` nor tracked, and HEAD's `Point_One/tutorial.md` is the older 109-line fragment page.
   - In the working tree the chain holds, but the `Point_Coordinates` in-project exercise needs `point_held.tscn` (untracked) and XR Tools (gitignored).
2. **From Trace to Triangle, everything is first seen in excerpts.**
   - `Point_Trace` is the first appearance of arrays, `if` and early return, and autoloads. `Point_Line_Grid` is the first appearance of nested loops, the ternary operator, `%` formatting, `roundi`/`roundf` and `to_local`. `Point_Triangle_Context` is the first appearance of `surface_begin`/`surface_end`, typed loop variables and winding.
   - All of these sit in excerpts of installed sources of 1037 and 1240 lines, and nothing is taught.
3. **The body is assumed everywhere and built nowhere.**
   - Every Transformation crossing tests a supplied player (`transport_cube` rider carry, `rotation_rider_deck`).
   - So do `Vectors_Act4a` and `Act5`, `LSystems_Architecture` and `CA_ExpandingSpace`.
   - `input.actions` and `input.events` are never taught, and `input.player` is first taught at spine 20.
4. **Light, material and scene come before any lesson on them.**
   - No working-tree tutorial creates a `StandardMaterial3D` or a `Light3D` before the colour halls use them (survey grep: 0).
   - Every study kit inherits one supplied `base.tscn`, so the learner never meets an empty scene, and never sees that the editor's preview sun is not in the running game.
5. **Signals, autoloads and lifetime are named before they are taught.**
   - `Color_Nails` asks the learner to "trace the GameManager signal".
   - `Primitives_Melencolia` names a signal handler.
   - `Trans_Body` names the `LeakData` autoload.
   - `Random_Remove` presupposes a delayed coroutine.
6. **Sound arrives without a player.**
   - No spine tutorial mentions an `AudioStream` before `WaveFunctions_Effect_Sound`, and the step from float samples to `AudioStreamWAV` is shown nowhere.
   - The working-tree rewrite removed the only `AudioStreamGenerator` lesson in the sequence.
7. **Shading language is read four sequences before its lessons, and the shader sequence has none.**
   - `Tutorial_Pattern`, `Array_Patterns`, `Pattern_Disco`, `Noise_One` and `Noise_6_Wall` read shader code.
   - 0 of the 6 `Shader_*` halls has a `tutorial.md`.
8. **Late fragments call helpers and scenes that do not exist.**
   - Graph theory: `neighbours()`, `bfs_distances()`, `PriorityQueue`.
   - Machine learning: `CREATURE_SCENE`, `set_weights`, uninitialised weights.
   - Foundations crisis: `text_plinth.tscn`, `crisis_wing.tscn`, `proof_block.tscn`, and stray `<<</MAP>>>` tokens.
   - QFEP: four scenes under `res://commons/artifacts/qfep/`.
   - The April wave and randomness halls: `res://commons/artifacts/wavefunctions/` and `.../randomness/`, directories that do not exist.

### 1.5 Committed versus working tree [M]

**The walk differs in 11 sequences, not only in primitives.** 24 of the 25 spine sequence files carry uncommitted changes (`git status`), plus `curriculum_spine.json`. Their hall lists differ as follows:

| sequence | halls WT / HEAD | working-tree only | HEAD only | order differs |
|---|---|---|---|---|
| primitives | 12 / 10 | Point_Zero, Point_Coordinates | - | - |
| transformation | 7 / 9 | - | Trans_AxisDecomposition, Trans_RotationSpectacle | - |
| array_tutorial | 5 / 2 | Tutorial_3D, Tutorial_Tiling_Floor, Tutorial_Tiling_Walls | - | - |
| color | 8 / 4 | Color_Flashlight, Color_Rainbow, Color_Grid_Pallet, Color_Paint | - | - |
| tiling | 8 / 4 | Pattern_Disco, Ribbon_Patterns_01, Ribbon_Patterns_02, Ribbon_Patterns_03 | - | - |
| change | 2 / 4 | - | Accumulation_Riemann, Change_Reconciliation | - |
| forces | 13 / 12 | Change_Choreography | - | - |
| fractals | 7 / 10 | - | Fractal_JuliaSet, Fractal_MandelbrotSet, Fractal_CrossSequence | - |
| lsystems | 8 / 7 | LSystems_Shape_Grammars | - | - |
| proceduralgeneration | 7 / 7 | - | - | yes |
| softbodies | 9 / 9 | - | - | yes |

In total 15 halls exist only in the working tree and 7 only at HEAD. 11 stops of this path sit at working-tree-only halls; each is tagged "WT only" in its header and in A.2. A reader at HEAD would also walk `Trans_AxisDecomposition`, `Trans_RotationSpectacle`, `Accumulation_Riemann`, `Change_Reconciliation`, `Fractal_JuliaSet`, `Fractal_MandelbrotSet` and `Fractal_CrossSequence`, which this plan never mentions, and would meet `PG_Percolation_Network` before `PG_Branching_Growth` and `SoftBodies_Carusell` before `SoftBodies_Cloth_Physics`.

**Untracked, and so absent at HEAD:**

- the opening apparatus: `doc/book/day-zero.md`, `STUDENT_TOOLBOX.md`, `TUTORIAL_LINEAGE.md`, `PRIMITIVES_LINEAGE.md`, `BOOK_FRAME.md`;
- the curriculum tooling: `doc/book/tutorial-lineage/curriculum.json`, `tools/build_tutorial_lineage.py`, and the encyclopedia `/tutorial-lineage` and `/book-review` routes;
- the study kits `day-zero` (0 of 5 files tracked), `point-one` (0 of 15), `point-coordinates` (0 of 7) and `random-definition` (0 of 21). `point-zero` (7 of 7) and `point-lines` (9 of 10) are tracked;
- the whole `commons/maps/Point_Coordinates/` folder, and the tutorials of `Tutorial_Tiling_Floor`, `Boolean_Verbs` and `Boolean_Works`;
- parts this plan borrows or reads: `commons/primitives/point/point_held.tscn`, `doc/book/studies/point-one/contact_probe.gd`, `commons/primitives/point/point_sun_switch.gd`, `commons/artifacts/regularity/disco_controls.gd`, `commons/testing/probe_motion_chamber.gd`, `probe_field_receivers.gd`, `probe_gravity_relations.gd` and `probe_rainbow_celebration.gd`, and `boolean_burrow`. Each is tagged UNTRACKED where a stop uses it. (`rainbow.gd`, `rainbow_celebration.gd` and `rainbow_spark_burst.gd` are tracked.)

**Consequences.**

- At HEAD the opening cannot be walked from Day Zero: 0 `day_zero`, 2 `Point_One`, 3 `Point_Coordinates`, 5 `Point_Trace`, 62 `Random_Definition`, 73 `Shader_10_ReactionDiffusion` have no starting material. `my_room` itself can be started at HEAD, because W02 creates it from an empty project.
- **`curriculum.json` fails coverage against HEAD.** It validates against the working-tree spine (204 halls): 15 of its halls are absent from HEAD, and 7 HEAD halls have no node.
- **A clone does not run.** `.gitignore` ignores `/addons/*`, so XR Tools 4.5.1 is untracked while 200 tracked files reference it. A clone or worktree of the course project does not run.
- **Renderer mismatch.** The study kits set `gl_compatibility` for desktop and mobile. The course project sets no renderer, so it runs Forward+ on the desktop and Mobile on the Quest [K]. It sets `foveation_level=3` with no `vrs_mode` anywhere; [D] says `foveation_level` acts only under Compatibility.
- **Physics engine mismatch.** The course project sets `GodotPhysics3D`. [D] New 4.6 projects default to Jolt. The kits set no physics engine [I: which engine they run is unchecked].
- **XR changes the physics rate.** `start_xr.gd` sets `physics_ticks_per_second` from the headset refresh rate, so desktop and Quest physics differ (60 vs 72/90 Hz).

---

## 2. The learner and the teacher

### 2.1 Two working places, and the learner's own project [P]

- **The course project.** This repository, with XR Tools 4.5.1 on disk. The learner uses it for held and walked encounters on the xr route: Day Zero's Quest route and `Point_Coordinates`' pickup. It is not startable from a clone (XR Tools is gitignored, `point_held.tscn` is untracked).
- **The opening kits (stops 0-7).** The learner works in their own copy of each opening study kit. A kit is the starting material for its hall and the resume point for a learner who falls behind in the opening. The draft's proposal stays: each kit's starting scene should be the previous kit's finished state, as `TUTORIAL_LINEAGE.md` l.11 rules ("Each starting scene must visibly inherit the relevant parts of the preceding result"). Kits are not merged into anything, and no stop asks for the same work twice.
- **my_room (from W02, right after CP1).** The learner creates an empty project and carries their own point, segment variant and recorder into it. From then on all making happens in `my_room`; later kits (`random-definition`) are read as worked examples. Folders `rooms/` and `shared/` start at W02; at W15 the project becomes one scene per exhibit with a hub, so that profiling measures one exhibit at a time.
- **Resuming after CP1.** A reference room per checkpoint, kept as a tagged commit in a teaching repository [P, not built]. A learner who falls behind clones that tag beside their own project and copies in the scenes they lack. Their own exhibits are separate scenes, so nothing of theirs is overwritten.
- **Worked example and the learner's own work.** Each stop's "Make" is a worked example. "In the learner's own work" is a transfer prompt: the capability plus a choice the learner makes. This follows "The student chooses the arrangement and what it makes another body encounter" (`STUDENT_TOOLBOX.md` l.43), "Copying the correct demonstration is a beginning, not the only acceptable destination" (l.53) and "Give one variation that works beyond the original demonstration" (`PRIMITIVES_LINEAGE.md` l.60). The plan fixes capabilities; what the room holds is the learner's.
- **Two routes: desktop and xr.** The project is VR-primary, and the path keeps a headset route for the learner's own work. Every stop carries a route:
  - xr only: 26 `W08_headset_day`, 27 `W09_room_in_headset`, 43 `W14_game_in_headset`;
  - desktop steps plus xr steps: 0 `day_zero`, 3 `Point_Coordinates`, 59 `WaveFunctions_Intro`, 91 `ISO_Sculpting`, 105 `Escher_Impossible`, 113 `W18_release`;
  - every other stop is desktop.

  **Desktop-only exception.** A desktop-only cohort skips the xr route: the headset part of Day Zero, the pickup steps of `Point_Coordinates`, W08, W09, W14 and the xr steps of later stops. The build checks that no desktop stop depends on them. Such a cohort does not meet the project's primary medium, and its teacher should say so.
- **Input.** Named actions from `Point_Trace` on (through a supplied mover). W07 writes the room's input rules into its README: one named action per verb, grouped by system; Esc toggles mouse capture; before `Color_Paint`, 3D "buttons" are keys bound through the InputMap. From `Color_Paint` on, world interaction uses a centre-screen ray and UI uses the released mouse. Every mechanic is written against "a CharacterBody3D in group player", so the XR body can take the desktop body's place at W14.

### 2.2 Borrowing at three depths [P]

The depths are **use** (can operate it), **understand** (has opened it and can explain it) and **change** (can change or replace it independently). Every borrowed part in section 3 carries one of these. Some parts stay borrowed on purpose, and the plan names them as boundaries rather than promising to remove them.

| borrowed part | use | understand | change | or boundary |
|---|---|---|---|---|
| `base.tscn` camera, light, floor, environment | Day Zero | W02 (floor and light rebuilt, camera copied) | Primitives_Melencolia (own camera and sky) | |
| course project XR staging, controllers, `XRToolsFunctionPickup` | Day Zero, Point_Coordinates | W08 (own rig) | W14 (own XR body, pointer, comfort) | XR Tools internals and the OpenXR runtime |
| the pickable scene `point_held.tscn` | | Point_Coordinates | Point_Coordinates (a second point) | pickup release physics |
| `segment.gd` `show_between(a, b)` | | Point_Lines | Point_Lines (the learner's own variant), reused at Triangle and GT_Foundations | |
| `contact_probe.gd` raw-key handler | Point_One | Point_Trace (compared with named actions) | | |
| `mover.gd` [to be built] | | Point_Trace | | |
| Trace line-strip helper [to be built] | Point_Trace | Point_Triangle_Context | | |
| museum player (XR Tools PlayerBody) | throughout the course project | W07 (same operations on the desktop body) | W14 (in group player) | |
| `machine_stage.gd` (26 lines) | forces halls | Change_Choreography | Change_Choreography | |
| marching-cubes tables (`TRI_TABLE`) | ISO_ShapesGallery | | | the table is not re-derived |
| `utils/lsystem.gd`, `utils/turtle_3d.gd` | | LSystems_Grammar_Lab | | |
| `AStar3D`, `NavigationServer` | | GT_Pathfinding, PG_Caves_Mazes | | engine implementation |
| the Noise_One relief shader | | Noise_One | | |
| ping-pong pair [to be built] | Shader_10_ReactionDiffusion (branch) | | | |
| renderer, physics solver | W03 (read and recorded) | W06, W08, VFM_03_Motion | | engine; the choice between them is taught |

### 2.3 What a teacher needs per lesson [P]

The compact contract, printed for every stop in section 3:

- **header:** kind, route, and whether the stop is at a working-tree-only hall or not startable at HEAD;
- **lesson:** status, curriculum kind, the git state of `tutorial.md`, and what the stop starts from;
- **new:** capability ids first met here, with the depth;
- **returns:** capability ids met again, with the depth where one is set;
- **make:** the worked example;
- **in the learner's own work:** the transfer prompt;
- **borrows:** each borrowed part at a stated depth;
- **check:** an observation the learner predicts, plus one contrasting case;
- **carries forward:** the concrete thing the next lessons use.

This contract is editorial preparation and stays outside the literary flow, as `STUDENT_TOOLBOX.md` l.19 rules: the distinctions "do not require a repeated checklist or warning around every paragraph in the book." Each stop also has a `session_estimate` field in the JSON, left empty until the trial in section 7 measures it.

### 2.4 Standing rulings this plan keeps

- "Each starting scene must visibly inherit the relevant parts of the preceding result." (`TUTORIAL_LINEAGE.md` l.11)
- Day Zero should "establish the XR route before a lesson requires it" (l.17). `day-zero.md` l.48: "Putting the work on a headset is another setup task for Day Zero." l.56: "Resolve setup problems here before asking the first hall to explain them." l.58 marks the route unverified in this edition.
- `day-zero.md` l.42 says of the supplied player, movement and pickup: "Their construction is not an entrance examination for the point." It is about building those systems, not about using XR. (The draft misquoted it as a statement about XR.)
- "The student should learn to make their own point grabbable here." Then "let the student give the same capability to a second point." Also: "Do not invent a single grab() call that supposedly installs the whole interaction." (l.37, l.39, l.41) "Point Coordinates owns pickup and references." (`PRIMITIVES_LINEAGE.md` l.82) So pickup stays in `Point_Coordinates`, first in its order.
- "Distance belongs to the line." Also: "Keep the distance arrow as a supplied coordinate aid in Point Coordinates" (l.47-49). `Point_Coordinates/intent.md` l.7 defers "Distance, arrow construction, label formatting and target state". So the first event exercise (W05) comes after `Point_Trace`.
- "Grids, nested loops, neighbour search and graph counts are not prerequisites for making that first line" (l.55). Grid is "an optional placement aid, not a prerequisite for the first face" (`PRIMITIVES_LINEAGE.md` l.68).
- "For Trace, introduce the list before using append, and the condition before using a distance threshold." (l.71) The condition now arrives one hall earlier, at `Point_Lines`. `curriculum.json` `trace.borrow`: "Input receiver and line-strip rendering."
- Triangle: close three edges, then add the face (l.24-25; curriculum issue `triangle-route`: "Keep both conceptual steps").
- "No unexplained helper should be required to make the promised example work." (`STUDENT_TOOLBOX.md` l.11) This is the source of the three roles: excerpt to inspect, step to build, part to borrow.
- "Do not force an equal code quota across the spine." (`STUDENT_TOOLBOX.md` l.25) `tutorial-lineage/README.md`: "reflect = return critically without compulsory new code." So the 8 late reflect halls carry optional studios only (table under sequence 25 in section 3), and `Primitives_Melencolia` has no new code.
- Melencolia gives "A reason to transform a relation, without a compulsory new coding mechanism" (l.31).
- "A step that compiles is not yet proof of learning." Then: follow, vary, transfer. "If that last step needs a fresh unexplained helper, the handover is incomplete." (l.69)
- "Code execution and learner understanding are different checks" and "No headset acceptance claim follows from a desktop test." (`STUDENT_TOOLBOX.md` l.55, l.69)
- "Encounter order comes from the active spine, never from old sequence notes." (`tutorial-lineage/README.md` l.3) Also: "Do not add or reorder maps merely to draw this tree" (curriculum issue `triangle-route`). This plan moves no hall. Workshops sit at existing halls.

---

## 3. The path, from Day Zero [P]

How to read each sequence below:

- It names the halls that carry the making thread. The other halls stay encounters and are listed at the end of each sequence.
- Workshops sit where no hall naturally carries a Godot skill, and each says why it sits where it does. Where the reason is prerequisites rather than the hall, it says so.
- Checkpoints come where the survey supports one. Each has criteria, one open task and evidence.
- "Read" points at the installed works that inspired each lesson (the survey's `teachable_hook`).
- The stop index is in A.2.

### Preface

**00 · day_zero** (workshop, desktop + xr steps, not startable at HEAD): Day Zero: a place to run, and the headset route
- Lesson: runnable. Starts from: doc/book/studies/day-zero (UNTRACKED); course project with addons/godot-xr-tools on disk (gitignored) (at HEAD: absent). Desktop part runnable from the kit; the Quest route is prose, unverified.
- Why here: Front matter by ruling: 'Day Zero is front matter, not a museum map; Point Zero remains the first hall.' TUTORIAL_LINEAGE l.17 asks Day Zero to 'establish the XR route before a lesson requires it'. Godot 4.6 Standard with GDScript; C#/.NET named as outside.
- New: `editor.project`, `editor.scene_tree`, `editor.run_debug`. Returns: none. Names as outside: `other:csharp_dotnet`.
- Make (worked example): Desktop: import the day-zero kit in the Project Manager, change Welcome.text in the Inspector, save, run (F5 vs F6), stop, keep a clean copy. Headset (xr route, as day-zero.md l.46-58 sets it): open the Ada course project on a Quest, look around, use the intended movement and pick up a supplied test object. The route is marked unverified in the text.
- In the learner's own work: None yet. The learner now has two working places: a copy of the day-zero kit, and the Ada course project for held and walked encounters. Their own project, my_room, begins at W02.
- Borrows: base.tscn: floor, camera, DirectionalLight3D, WorldEnvironment, Welcome Label3D (use); the Ada course project's XR staging (commons/scenes/vr_staging.tscn), XR Tools player and pickup, Quest export preset (use); Android toolchain: export templates, JDK, Android SDK, headset developer mode (use).
- Check: The changed greeting appears in the running scene and in the Output panel. Headset: the supplied player responds on the device (day-zero.md l.62). Contrast: With a second scene open, F6 runs that scene and F5 runs the main scene named in project.godot.
- Carries forward: A kit copy that runs, and (xr route) the course project running on a headset.
- Basis: [M] doc/book/day-zero.md and doc/book/studies/day-zero are both UNTRACKED. Kit renderer is gl_compatibility for desktop and mobile. day-zero.md l.48: 'Putting the work on a headset is another setup task for Day Zero.' l.56: 'Resolve setup problems here before asking the first hall to explain them.' l.58: the Quest route 'ha[s] not been verified as part of this edition.' [M] /addons/* is gitignored (.gitignore l.13), so a clone of the course project has no XR Tools.

### 1. primitives

- **Today [M]:**
  - Four runnable desktop studies (`Point_Zero`, `Point_One`, `Point_Coordinates`, `Point_Lines`) give editor habits, `_ready`/`_process`, members, node and resource separation, colliders, `Vector3`, local and global position, and `b - a`.
  - After that, 7 of the 8 tutorials read excerpts of installed sources. `Primitives_Portals` offers helpers with no harness to run them in.
- **Proposed [P]:**
  - All twelve halls keep a making job, because `PRIMITIVES_LINEAGE.md` already assigns one to each. `Point_Line_Grid` stays a comparison and `Primitives_Melencolia` stays reflective.
  - The kit chain runs to CP1. `Point_One` → `Point_Coordinates` → `Point_Lines` stay adjacent, as `TUTORIAL_LINEAGE.md` l.79 asks.
  - The first `if` and the first function with parameters and a return value come at `Point_Lines`; the list, the loop and named input actions at `Point_Trace`.
  - Six workshops: debugging and the class reference (W01), `my_room` from nothing (W02), version control (W03), import (W04), a signal and a door (W05), export (W06).
  - Heavy stops: `Point_Zero` (5), `Point_One` (4), `Point_Coordinates` (4), `Point_Trace` (4). The first two are what the verified studies already do, all at use depth. `Point_Coordinates`' four are the hall's own subject (reference frames) plus the ruled pickup. `Point_Trace`'s input actions come through a supplied mover.

**01 · Point_Zero** (hall, WT only): Begin once, continue
- Lesson: runnable; curriculum kind build (loop); tutorial.md tracked. Starts from: doc/book/studies/point-zero (tracked).
- New: `gd.variables`, `gd.functions`, `gd.lifecycle`, `gd.strings`, `scene.groups_paths`. Returns: `editor.run_debug`.
- Make (worked example): The existing study, in the learner's copy of the point-zero kit: the greeting set in _ready(), a member count kept between calls and advanced in _process(), then moved into _ready(), then the increment changed. 'extends Node3D' is a borrowed first line; class_name waits for Trans_Pit.
- In the learner's own work: Change one more property of a supplied display from _ready() and say when it happens.
- Borrows: Label3D displays already placed (the type is not named in the tutorial) (use); engine scheduling (use); 'extends Node3D' as a first line (use).
- Check: The count rises every frame and the greeting is set once. Contrast: Counting inside _ready() stops at one.
- Carries forward: A member variable that keeps its value between calls; setup in _ready() and repeated work in _process(); a child found with $Greeting.
- Basis: [M] tutorial.md 88 lines; runnable study doc/book/studies/point-zero is tracked (7 files) and its README says verified natively. The hall is absent from HEAD's primitives.json. gd.functions here is the use of engine callbacks and str(count); writing a function with parameters and a return value comes at Point_Lines.

**02 · Point_One** (hall, not startable at HEAD): A position with a surface and a boundary
- Lesson: runnable; curriculum kind build (point); tutorial.md modified. Starts from: doc/book/studies/point-one (UNTRACKED) (at HEAD: absent). Runnable in the working tree; HEAD has the older fragment page.
- New: `scene.nodes_resources`, `mesh.primitive`, `phys.bodies`, `phys.shapes_layers` (use). Returns: `editor.run_debug`, `gd.lifecycle`.
- Make (worked example): The working-tree study: SphereMesh.new() (a resource) on MeshInstance3D.new() (a node), StaticBody3D + CollisionShape3D + SphereShape3D, visual and collision radii set separately; Debug > Visible Collision Shapes. Collision shapes only: layers and masks wait for Trans_Translation.
- In the learner's own work: Arrange three points with one name and different boundaries (STUDENT_TOOLBOX l.43): which can be passed through, which must be walked around?
- Borrows: contact_probe.gd feelers: move_and_collide, raw Space/R keys via _unhandled_key_input (UNTRACKED) (use); point_sun_switch.gd removable sun (UNTRACKED) (use); study.tscn stations and labels (use).
- Check: With the collision radius smaller than the visual radius, a feeler sinks into the sphere. Contrast: Equal radii: the feeler stops at the surface.
- Carries forward: A point recipe in which the visible surface and the collider are two separate decisions.
- Basis: [M] WORKING TREE tutorial rewrite (+71/-67, uncommitted); kit doc/book/studies/point-one is UNTRACKED (0 of 15 files). HEAD's tutorial is the older 109-line fragment page. Hidden prerequisite: local vs member variable is explained only in CONSTRUCTION.md.

**03 · Point_Coordinates** (hall, desktop + xr steps, WT only, not startable at HEAD): Hold a point, name its reference
- Lesson: runnable; curriculum kind build (coordinates); tutorial.md untracked. Starts from: doc/book/studies/point-coordinates (UNTRACKED); course project XR scene + point_held.tscn (UNTRACKED) (at HEAD: absent). Desktop study runnable; the pickup step needs the course project (XR Tools on disk, gitignored) and point_held.tscn (untracked); a portable XR starter is still to be supplied.
- New: `xr.interaction`, `space.vector3`, `space.transform`, `editor.viewport3d`. Returns: `editor.scene_tree`, `editor.run_debug`, `phys.shapes_layers`.
- Make (worked example): In the tutorial's order. (1) xr route, in the course project: instance commons/primitives/point/point_held.tscn under the room root of a prepared Ada XR scene; say what the XRToolsPickable body adds and where it attaches; test hold, carry and release with the prepared player. (2) Give a second instance the same capability somewhere else. (3) Desktop study (coordinates.tscn, points.gd): change X, Y, Z one at a time; move the parent root with the move gizmo, in local and in global gizmo space; print position and global_position.
- In the learner's own work: Name two of your points A and B in one shared frame, ready to be joined (TUTORIAL_LINEAGE l.20).
- Borrows: the course project's XR staging, controllers and XRToolsFunctionPickup (use); point_held.tscn, the pickable point (UNTRACKED) (understand); distance arrow, RGB guides, WORLD/LOCAL cards (use).
- Check: The held point follows the hand and stays where it is released; the second instance can be held too. Moving the parent changes global_position and leaves position unchanged. Contrast: Moving the point itself changes both readings.
- Carries forward: Two named positions in a stated frame, and (xr route) a point the learner can hold and a second one they made holdable.
- Basis: [M] The whole hall folder, the kit and point_held.tscn are UNTRACKED; XR Tools is gitignored. tutorial.md l.7-11 opens with the hold ('In an already configured Ada XR scene, instance commons/primitives/point/point_held.tscn ... make a second instance'); l.13: the desktop study 'does not include an XR player'. intent.md l.7. Rulings: TUTORIAL_LINEAGE l.37-43; PRIMITIVES_LINEAGE l.82 'Point Coordinates owns pickup and references'. Distance and target state stay deferred (intent.md l.7).

**04 · Point_Lines** (hall): Connect and measure
- Lesson: runnable; curriculum kind build (line); tutorial.md tracked. Starts from: doc/book/studies/point-lines (tracked). Runnable and desktop-tested; the distance_between variation is a proposed addition that needs a native re-run.
- New: `gd.conditions`. Returns: `space.vector3` (use), `gd.functions` (understand), `gd.variables` (understand), `gd.lifecycle`, `gd.strings` (understand), `editor.run_debug`.
- Make (worked example): The existing study (line.gd, segment.gd): displacement = b - a, .length(), _process re-reads the endpoints, '%.2f m' % distance (a format specifier), the Remote scene tree as a temporary hand. The locals a, b, displacement and distance are made again every frame, unlike Point Zero's member count. Then a variation in the learner's copy [P, an addition to the tested tutorial]: write func distance_between(a: Vector3, b: Vector3) -> float, and a segment variant that begins with the zero-length guard 'if distance <= 0.0001:'.
- In the learner's own work: Connect two different objects with your segment variant and read their distance.
- Borrows: segment.gd show_between(a, b): midpoint, CylinderMesh height, orientation (its rotation code stays borrowed) (understand).
- Check: Reversing the subtraction reverses the direction and keeps the length. distance_between returns the number the readout shows. Contrast: A and B at the same position: the guard hides the segment instead of pointing it in an undefined direction.
- Carries forward: distance_between(a, b), the learner's first function with parameters and a return value, and the first if, both reused by Trace.
- Basis: [M] tutorial.md and study committed 2026-09-30 (5a74c6e30); the study is tracked (9 files); verification.json 22/22; curriculum node 'line' is the only desktop-tested node. segment.gd already hides at distance <= 0.0001; writing the guard moves 'the condition before using a distance threshold' (TUTORIAL_LINEAGE l.71) one hall early. The variation needs a native re-run before it is published.

**05 · Point_Trace** (hall, not startable until its supplied parts are built): Let positions remain
- Lesson: fragment-rewrite; curriculum kind build (trace); tutorial.md modified. Starts from: the learner's point-lines copy + mover.gd + line-strip helper (both to be built). The list-first rewrite is curriculum issue trace-list; mover.gd and the line-strip helper are to be built.
- New: `input.actions`, `gd.arrays`, `gd.loops`, `gd.typing`. Returns: `gd.functions`, `gd.conditions`, `space.vector3`, `gd.lifecycle`.
- Make (worked example): In the learner's copy of their finished Lines study. (a) A hand: the supplied mover.gd [to be built] moves the point on the floor plane with Input.get_vector over four named actions. Open it, find the actions in Project Settings > Input Map, and add a fifth, 'pause', bound to Space. Compare contact_probe.gd, which reads the physical Space key directly (l.56-60). (b) The list: var trace: Array[Vector3] = []; record when the list is empty or when distance_between(trace[-1], p) exceeds a gate; append. (c) A loop with a job: sum the lengths of consecutive pairs and compare the total with (trace[-1] - trace[0]).length(). (d) Capacity 32 with pop_front. The supplied line-strip helper [to be built] draws the list.
- In the learner's own work: Choose what your recorder keeps: a gate, a capacity, and one thing it deliberately loses.
- Borrows: mover.gd: Input.get_vector over named actions (to be built [P]) (understand); line-strip display helper, contract draw(list) (to be built [P]; opened at Point_Triangle_Context) (use).
- Check: Holding still adds nothing. The summed length is at least the straight distance, and equal only for a straight path. With capacity 32 the oldest samples leave as new ones arrive. Contrast: Gate 0 records one position per frame, so the list grows with the frame rate.
- Carries forward: An ordered, capped Array[Vector3], the learner's gate, a summed path length, and named input actions that later stops trigger (REPLAY, RESTORE, the door target). In the museum, TraceData carries the released pen list into Grid and Triangle.
- Basis: [M] tutorial.md is excerpt-first (draw_dot.gd, 1037 lines), modified in the working tree; the survey's 'teaches' is empty. Ruling: TUTORIAL_LINEAGE l.71. curriculum.json trace.borrow: 'Input receiver and line-strip rendering.' The loop answers Lines' closing question (Point_Lines/tutorial.md l.58-60: 'The same starting and ending positions give the same displacement, however you travel between them.'). TUTORIAL_LINEAGE l.75: 'A trace can preserve a route while losing its pauses.' The amber short-memory dot is described but not placed (PRIMITIVES_LINEAGE l.67). Planned as more than one session: (a)-(b), then (c)-(d).

**06 · W01_break_it_on_purpose** at `Point_Trace` (workshop): Break it on purpose, then look it up
- Lesson: new-page. Starts from: the learner's Trace copy.
- Why here: Trace is the first collection, so the first empty and out-of-bounds cases occur here. Proposal: 'Debugging should enter through actual small constructions, not wait for a final technical appendix.'
- New: `gd.errors`, `other:docs_lookup`. Returns: `editor.run_debug` (understand), `gd.arrays`, `gd.conditions`, `gd.typing` (understand), `gd.loops` (understand).
- Make (worked example): Four planted faults in the recorder: trace[-1] on an empty list; a mistyped $Segmnet path (null instance); an off-by-one index; a member 'var seg = $Segment' without @onready (null when the script initialises, before the node is in the tree; fixed with @onready, which is counted with gd.export at Primitives_Ignorance). Predict each message, run, click from the error to its line, fix. Also: assign a String to the Array[Vector3] and read the parse-time error. A breakpoint on append; trace.size() in the Remote tree; push_warning when capacity trims. Then open the class reference (F1, or Ctrl+click on a type) and find one method of Array the lesson did not use.
- In the learner's own work: Plant one fault of your own in your recorder, give it to someone, and time how long they take to find it.
- Check: Each predicted error appears where predicted. The typed-list error appears before the scene runs. Contrast: A fault with no error at all (a gate that is never true) is found only by watching a value.
- Carries forward: A debugging habit that starts from a prediction, and the class reference as the first place to look.
- Basis: [M] gd.errors is in the never-taught list. [M] The course project's common failures are silent (a refused typed set(), a SHADER ERROR at first draw, 'Error calling from signal'), so the loud cases come first. Critique item 7 asks for documentation lookup as a skill. [K] F1 opens the help search in the 4.6 editor.

**07 · CP1_opening** at `Point_Trace` (checkpoint): Opening studies (its own session)
- Create and run a small script; say when _ready() and _process() run.
- Explain one condition (Lines' zero-length guard) and one function with parameters and a return value (distance_between).
- Move the point with named input actions and name the file where the actions live.
- Find a node by path and by the Remote tree.
- Diagnose one planted error from its message, and find one method in the class reference (W01).
- xr route: hold the point in the course project and give a second point the same capability (Point_Coordinates).
- The three-step check from TUTORIAL_LINEAGE l.69: follow the Trace exercise, make an intentional variation, then record the trace of a different moving object (a Point One feeler) without a new helper.
- Open task: Change what happens when the recorder's capacity is reached, and say what your choice loses.
- Evidence: a dated copy of the learner's study folders (Day Zero's 'keep a clean copy'; git arrives at W03); one beginner session record: confusions, elapsed time, and each place the teacher had to fill a gap.
- Basis: Critique's 'opening studies' checkpoint; the rulings' three-stage check. Held as its own session. Of the opening's stops, day_zero, Point_Zero, Point_One, Point_Coordinates and Point_Lines have runnable studies; only Point_Lines is desktop-tested; none is learner-tested.

**08 · W02_scene_from_nothing** at `Point_Line_Grid` (workshop): my_room: a scene from nothing
- Lesson: new-page. Starts from: a new empty project + the learner's own opening scripts.
- Why here: The kit chain closes at CP1. From here the learner needs a project of their own, and building it by carrying the opening's own parts keeps the ruling that each start inherits the preceding result. Point_Line_Grid is the first hall after CP1 and snaps that carried trace.
- New: `scene.new_scene`, `scene.instancing`, `light.env` (use). Returns: `editor.viewport3d` (understand), `editor.scene_tree` (understand), `scene.nodes_resources`, `mesh.primitive`, `phys.bodies`, `phys.shapes_layers`, `editor.project`.
- Make (worked example): Project Manager > New Project: my_room, Compatibility renderer (as the kits). Folders res://rooms/ and res://shared/. rooms/room.tscn from an empty Node3D root: a floor (MeshInstance3D + StaticBody3D/CollisionShape3D) and one DirectionalLight3D. Copy the Camera3D node from a kit's base.tscn (a borrowed part; cameras are the subject at Melencolia). Rebuild the point as shared/point.tscn with its separately sized collider, without a kit; drag it into room.tscn twice; set room.tscn as the main scene. Carry the segment variant and the recorder over as scripts.
- In the learner's own work: Put your A, B, segment and recorder into room.tscn so that the opening's result is visible in a project you made (TUTORIAL_LINEAGE l.11).
- Borrows: Camera3D copied from base.tscn (use).
- Check: The run shows the floor lit by the learner's own light, and the carried recorder works as it did in the kit. Contrast: Before any WorldEnvironment exists, delete the DirectionalLight3D: the editor viewport still looks lit (its preview sun and environment), while the running floor goes unlit against the clear colour [K, not run: confirm at the first native run]. Toggle the editor preview off to see what the game sees.
- Carries forward: A project the learner made, a folder rule (rooms/ for scenes, shared/ for reused parts), a saved scene with instances, and one light the learner placed.
- Basis: [M] Every kit ships and inherits one identical base.tscn, so the preview-sun gap never shows. [D] The editor preview sun and sky are not in the running project. This is also the critique's 'rebuild in a fresh scene' exercise (item 7). Departs from the Point One rulings on supplied surroundings (STUDENT_TOOLBOX l.17, l.31, l.67); see section 6.

**09 · W03_known_revision** at `Point_Line_Grid` (workshop): A known working revision
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: The first thing worth protecting has just been made. No branches yet: they come before the first risky rewrite (Tutorial_Disco).
- New: `editor.version_control`. Returns: `editor.project`.
- Make (worked example): git init in my_room, a .gitignore for .godot/, a README.md naming the Godot version, the renderer (rendering_method and rendering_method.mobile) and the physics engine as read in Project Settings; first commit. Move the point, read the .tscn diff; delete the floor, save, restore it from the commit.
- In the learner's own work: Commit before and after one change you are unsure of.
- Borrows: a git client (use).
- Check: The deleted floor comes back from the commit. The README names the renderer and physics engine the room actually runs. Contrast: Deleting .godot/ loses nothing that matters: the editor regenerates it.
- Carries forward: A way back that is not a manual copy, and a README that later stops (W06, W09, VFM_03_Motion) check against.
- Basis: [M] Day Zero's advice is to keep a clean copy (manual recovery). [M] In the course project /addons/* is gitignored, so a clone loads maps with zero artifacts. [M] Kits set gl_compatibility and no physics engine; the course project sets GodotPhysics3D; [D] new 4.6 projects default to Jolt.

**10 · Point_Line_Grid** (hall): A snapped copy (compare)
- Lesson: fragment-rewrite; curriculum kind compare (grid); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.functions`, `gd.arrays` (understand), `gd.loops`.
- Make (worked example): A pure snap(p, size) -> Vector3 (roundf per component); a snapped COPY of the trace (duplicate()) drawn beside the original. Optional: the 5x5 checker of plan_vitrine with two materials by (x+z)%2.
- In the learner's own work: Choose a spacing for your snapped copy and say what the snap loses from your own trace.
- Borrows: grid_lines / plan_vitrine displays (use).
- Check: The original list is unchanged after snapping the copy. Contrast: Snapping in place loses the original.
- Carries forward: Copy versus mutate (duplicate()); a pure function that returns a value and changes nothing else.
- Basis: [M] tutorial is reading-only excerpts; hidden prerequisites are nested loops, ternary, % and int/float rounding. Ruling: grid is 'an optional placement aid, not a prerequisite for the first face' (PRIMITIVES_LINEAGE l.68).

**11 · Point_Triangle_Context** (hall): Three edges, then a face
- Lesson: fragment-rewrite; curriculum kind build (face); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `mesh.procedural`, `mat.standard`. Returns: `gd.arrays`, `space.vector3`, `light.env`, `gd.functions`.
- Make (worked example): First encounter: close three edges between three of the learner's points with their segment variant from Point_Lines; line the points up. Next encounter: face.gd submits the three points with SurfaceTool (PRIMITIVE_TRIANGLES) with a normal (set_normal from a cross product, or generate_normals), commits to a MeshInstance3D with the learner's first StandardMaterial3D, and a fill toggle. Open the Trace line-strip helper: it was an ImmediateMesh line strip.
- In the learner's own work: Make a face between three positions you chose and say from which side it can be seen.
- Check: Moving one point reshapes the edges and the face. The lit face changes brightness as it turns toward the learner's light. Contrast: Reversed vertex order: the face disappears from the front (Godot winds front faces clockwise), until the material's cull_mode is set to disabled. Without a normal, the face does not respond to the light as it turns [K, not run]. Three collinear points: no area.
- Carries forward: A first authored surface with a normal and a material, and the borrowed line helper opened.
- Basis: [M] tutorial is excerpts of triangle_line_puzzle / draw_triangle_faces (1240 lines); nobody introduces surface_begin/end. Rulings: TUTORIAL_LINEAGE l.24-25 (close the edges first, then the face); curriculum issue triangle-route 'Keep both conceptual steps'; tutorial.md 'Close, look, then fill'; PRIMITIVES_LINEAGE l.54 (reuse the segment helper) and l.68 (stop at a usable face).

**12 · Primitives_Polythedra** (hall): Faces enclose; a hull collides
- Lesson: fragment-rewrite; curriculum kind build (enclosure); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.packed_arrays`. Returns: `mesh.procedural`, `phys.shapes_layers` (understand), `scene.new_scene`, `scene.instancing`, `space.vector3`.
- Make (worked example): One vertex list and one face-index list build an open corner, with one normal per face from a cross product; a ConvexPolygonShape3D from the same PackedVector3Array closes the opening for collision. Save as shared/tetra.tscn; instance it twice.
- In the learner's own work: Give one of your enclosures an opening a body can use, and one it cannot.
- Check: A body cannot enter the visible opening: the convex hull is closed. Contrast: A ConcavePolygonShape3D keeps the opening (static bodies only).
- Carries forward: A reusable scene of the learner's own geometry, and the corner list plus index-triple representation Cube reuses.
- Basis: [M] hook grab_trihedron. PRIMITIVES_LINEAGE l.69: Polyhedra -> Cube 'should reuse one vertex/face representation in the student kit'.

**13 · Point_Animatedcube** (hall): Positions and connections; replay and restore
- Lesson: fragment-rewrite; curriculum kind build (mesh), build (instances); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.packed_arrays`, `mesh.procedural` (understand), `gd.arrays`, `gd.lifecycle`, `gd.functions`, `scene.instancing`, `input.actions`, `space.vector3` (understand).
- Make (worked example): The data stays Polythedra's representation: 8 corners and 12 index triples. The render mesh is rebuilt from it with one normal per triangle (36 vertices, flat). Move one corner in the data and rebuild: the triangles that name it follow. REPLAY (an InputMap action) reveals triangles paced by delta accumulated in _process; RESTORE (another action) resets the corners from a stored copy. The Cube shelf: instance the cube and arrange neighbours.
- In the learner's own work: Give your own mesh two different resets: one for what is shown, one for the data.
- Check: RESTORE mid-replay returns the original corners. The cube's faces are evenly lit, each face flat. Contrast: Build the same cube as 8 shared vertices with an index array and generate_normals(): the normals average across faces and the cube looks rounded [K, not run]. REPLAY after a corner move shows the moved cube: replay reads current data.
- Carries forward: An editable mesh whose data (8 corners) and render (36 flat vertices) are separate; delta used as seconds for the first time.
- Basis: [M] hook animatedcubebuilder (874 lines, await and signals unexplained). The survey's mesh.procedural caution: SurfaceTool's normal convention can leave a mesh 'inside out with nothing visibly wrong'. TUTORIAL_LINEAGE l.27: 'Move one vertex while keeping triangle indices'.

**14 · Primitives_Ignorance** (hall): Configure, then decide
- Lesson: fragment-rewrite; curriculum kind compare (primitive); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.export` (understand). Returns: `mesh.primitive`, `gd.arrays`, `scene.instancing`.
- Make (worked example): shared/point.tscn gets @export radius, rings and radial_segments with a setter that rebuilds; count triangles from surface_get_arrays; drag two differently configured points side by side (the sphere pairs). Inspector changes apply when the game runs; a preview in the editor waits for @tool at Fractal_RecursiveTrees. The tutorial's own check: choose a resolution for a stated feature and viewing distance.
- In the learner's own work: Choose one resolution for one use of your point: name the feature, the viewing distance and the triangle count.
- Check: Doubling rings roughly doubles the triangle count, as predicted. Contrast: A setter that touches a child without the is_node_ready() guard fails when the scene loads, because an exported setter runs before _ready [K, not run].
- Carries forward: A configurable scene with a guarded setter, and a resolution chosen for a stated use.
- Basis: [M] tutorial.md l.56: 'A count is not a frame-time measurement. Identify a desired feature, viewing distance and proposed use before treating a larger or smaller number as an improvement.' l.34: choose a facet to keep for a visual use. l.109: 'The existing counter has no resize control or frame-time meter.' Profiling waits for Tutorial_Disco.

**15 · W04_import_one_thing** at `Primitives_Ignorance` (workshop): Import one thing you did not build
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Ignorance compares generated meshes; an imported mesh is a mesh whose choices were made by someone else. Moved here from Melencolia so that the reflective hall carries fewer compulsory stops.
- New: `assets.import`, `mat.textures`. Returns: `mat.standard`, `scene.instancing`, `editor.version_control` (understand).
- Make (worked example): Import one image (as albedo_texture on a QuadMesh) and one small CC0 glTF model; fix scale and origin in the Import dock and reimport; record the licence in shared/CREDITS.md. Commit the .import and .uid sidecars with the files; note the binary size in the commit.
- In the learner's own work: Put one imported object next to one of your generated ones and say whose choices each carries.
- Borrows: an external CC0 asset (use).
- Check: The model sits at 1 m scale after reimport; a fresh clone of my_room opens with the model in place. Contrast: Scaling the node instead of the import leaves every future instance wrong.
- Carries forward: The import pipeline, a credits file, and sidecars in version control.
- Basis: [M] The course project is almost entirely procedural, /assets/ is gitignored and Blender import is disabled, so the workshop brings its own asset. PRIMITIVES_LINEAGE l.34: in Ignorance 'a supplied name carries choices'.

**16 · Primitives_Portals** (hall): Refinement and stopping
- Lesson: fragment-rewrite; curriculum kind compare (refinement); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.loops`, `gd.functions`.
- Make (worked example): Run the tutorial's pure helpers (polygon_perimeter, gap_to_circle, achilles) in a _ready harness the tutorial does not give; print gap_to_circle per n.
- In the learner's own work: Choose a tolerance for one of your own refinements and say what the last displayed step hides.
- Borrows: combine_portals rings and the hall's NEXT RING / REVERSE / NEXT STEP / PLAY controls (use).
- Check: Halving reaches exactly 1.0 at step 54, as the tutorial's arithmetic says. Contrast: A tolerance of 1e-3 stops long before: the last displayed example is not the limit.
- Carries forward: Pure, printable functions; a tolerance distinguished from a limit.
- Basis: [M] tutorial.md 64 lines; 'Run the code' has no harness; Vector2/TAU/Dictionary unexplained. final.md l.11-47 names the hall's controls.

**17 · W05_signal_and_door** at `Primitives_Portals` (workshop): A signal and a door
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Placed by prerequisites, not by the hall: it needs a condition (Point_Lines), a moving point (Point_Trace) and the learner's own project (W02). Portals itself has no door (final.md l.9: 'These are portals for looking through'). The field anchor is the DO NOT CROSS barrier at Point_Lines (tutorial.md l.54: 'The passage opens because an additional instruction connects those events.'). The rulings keep target state out of Point_Coordinates (intent.md l.7).
- New: `gd.signals_own` (understand). Returns: `gd.conditions` (understand), `gd.functions`, `phys.shapes_layers`, `scene.instancing`, `input.actions`, `light.env`.
- Make (worked example): arrival.gd on the learner's moving point (Trace's mover): inside = distance_between(point, target) < r; 'signal arrived' emitted only on the false-to-true edge. door.gd connects to arrived (once in the editor, once in code) and opens by hiding its mesh and disabling its CollisionShape3D; a Timer's timeout closes it. Then connect the same arrived to a lamp (an OmniLight3D that flashes) without editing arrival.gd.
- In the learner's own work: Use the edge-triggered signal on something of yours and say what it lets a body do.
- Borrows: drag_point_target.gd (edge-triggered _inside, point_arrived) and line_demo.gd l.243-256, read as excerpts (understand).
- Check: Staying inside emits once; leaving and returning emits again. The lamp responds without a change to arrival.gd. Contrast: Emitting on the condition instead of the edge fires every frame. line_demo.gd finds the nearest barrier and calls trigger_explosion() directly: the detector must know its responder, so a second responder means editing the detector.
- Carries forward: Detector, announcer and responder as three objects; shared/door.tscn, which Trans_Pit and W11 reuse.
- Basis: [M] drag_point_target.gd already has an edge-triggered _inside flag and emits point_arrived. line_demo.gd l.247-256 calls barrier.trigger_explosion() on the nearest do_not_cross_barrier; it defers the call because 'Snap callbacks may arrive during a physics flush' (l.243-244). gd.signals_own is first taught today only in the stale Tutorial_Disco.

**18 · Primitives_Melencolia** (hall): Compose, view and light the vocabulary
- Lesson: fragment-rewrite; curriculum kind reflect (geometry_return); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `cam.camera3d`. Returns: `scene.instancing`, `light.env` (understand), `mat.standard`, `editor.viewport3d`.
- Make (worked example): No new coding mechanism. Arrange the learner's point, line, trace, face, tetra, cube and door in room.tscn. Replace the borrowed camera with one the learner places: Camera3D made current, FOV, near and far. Add a WorldEnvironment with a sky. Optional: check_magic(NUMBERS) over rows, columns and diagonals.
- In the learner's own work: Change one relation in your arrangement while keeping a reference someone can recognise (curriculum geometry_return.transfer).
- Borrows: durer_scene, snap_pyramid_puzzle (use).
- Check: Another person can say what the arrangement lets a body do. Contrast: With the WorldEnvironment in place, delete the DirectionalLight3D: the room loses its shadows and turns flatly sky-lit, not dark [K, not run]. Compare W02's run without an environment.
- Carries forward: A small composed room with a view and a sky the learner chose.
- Basis: Ruling: Melencolia gives 'A reason to transform a relation, without a compulsory new coding mechanism' (TUTORIAL_LINEAGE l.31); curriculum geometry_return is kind reflect. Camera, floor and lighting return here 'when [each] becomes the subject of an encounter' (STUDENT_TOOLBOX l.17).

**19 · W06_export_it** at `Primitives_Melencolia` (workshop): Export it
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: A practice stop, placed while little is at stake. Both outside texts ask for an early export. It adds no code, so the reflective hall stays reflective.
- New: `export.build`, `other:renderer_choice`. Returns: `editor.project`, `editor.version_control`.
- Make (worked example): Install 4.6 export templates, add a desktop preset in my_room, export, run the build outside the editor, give it to one person. Check the README's renderer line against the preset (rendering_method and rendering_method.mobile). Tag the commit.
- In the learner's own work: Give your composition to one person and write down what they did first.
- Borrows: export templates (use).
- Check: The build shows the composition on another machine. Contrast: Exclude the textures folder in the preset filter: the build loads with a missing-resource error or a missing texture.
- Carries forward: A route from project to something another person can open, and a tagged commit.
- Basis: [M] The course project has only Android and Web presets, no Windows preset. [D] res:// is read-only in an export.

**20 · CP2_composition** at `Primitives_Melencolia` (checkpoint): A composition another person can open
- Reuse one of the learner's scenes (point.tscn, tetra.tscn) with changed @export parameters.
- Connect one event to a response (arrived -> door or lamp).
- Keep and modify a small collection (the trace), and snap a copy of it.
- Compose, view and light an arrangement by choice, including one imported object.
- Export a build another person opens; note what they did first.
- A tagged commit.
- Open task: Make the door respond only after the point has remained inside for 0.5 s.
- Evidence: the build; the commit tag; one note from the other person.
- Basis: Critique's Primitives checkpoint; proposal's Melencolia row.

### 2. transformation

- **Today [M]:** seven fragment tutorials and no player. `Trans_Scale` shrank to 16 lines of prose in the working tree. `Trans_Introduction` and `Trans_Translation` repeat one helper block. No transformation map has a hazard, and `Trans_Pit`'s tutorial says it has no enforced failure.
- **Proposed [P]:**
  - Five making halls; the body and camera (W07); a headset day and the scale comparison on the xr route (W08, W09); HUD, pause and retry (W10).
  - `class_name` is first taught at `Trans_Pit`, as a base the learner's own pusher and gate share.
  - CP3 ends the short course (stops 0-30), which first meets every capability of the survey's minimum complete game.
  - `Trans_Body` stays an encounter. Its `carve_grid` with `LeakData` is a reading for W11's question of what survives.
  - Walk-in objects are called "collectibles"; "pickup" is kept for grabbing.

**21 · Trans_Pre** (hall): A collectible from your own cube
- Lesson: fragment-rewrite; curriculum kind build (transform); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `space.interpolation`, `space.rotation`. Returns: `gd.lifecycle`, `gd.export`, `scene.instancing`.
- Make (worked example): The learner's cube scene becomes a collectible in four stages (still, slide by pingpong, turn by rotate_y(speed * delta), pulse by lerp around 1.0), with @export rates.
- In the learner's own work: Choose how your collectible announces itself and keep it independent of the frame rate.
- Borrows: pick_up_cube.gd (936 lines), read as excerpts (understand).
- Check: With Engine.max_fps = 30 the turn per second is unchanged. Contrast: Remove delta: the speed follows the frame rate.
- Carries forward: Delta-scaled motion; interpolation with t in 0..1.
- Basis: [M] tutorial is teacher-facing excerpts; 'Start with the cube learned in Primitives' has no Primitives lesson behind it today (Polythedra and Animatedcube above supply it). 'Collectible' is used for walk-in objects throughout; 'pickup' is kept for grabbing.

**22 · Trans_Introduction** (hall): Transforms compose; a platform moves
- Lesson: fragment-rewrite; curriculum kind build (transform); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `space.transform` (understand), `gd.functions`, `phys.bodies`.
- Make (worked example): The tutorial's typed helpers in a harness (Transform3D.IDENTITY, translated/rotated/scaled, a * b applies b first, affine_inverse, is_equal_approx), renamed so they do not collide with Node3D.rotate_y and scale. An AnimatableBody3D platform that move_toward's between two ends in _physics_process.
- In the learner's own work: Put a moving platform where your room needs a crossing.
- Borrows: transport_cube rider carry (518 lines), read (understand).
- Check: Composing in the other order moves the object somewhere else. Contrast: affine_inverse() of the composite returns the identity (is_equal_approx).
- Carries forward: Order of composition; a platform moved in the physics step.
- Basis: [M] tutorial helpers 'rotate_y()' and 'scale()' would collide with Node3D members if pasted into a Node3D script [I, not run]; two dated addenda repeat each other.

**23 · W07_body_and_camera** at `Trans_Introduction` (workshop): A body that walks, a camera that looks
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: transport_cube carries a player; the survey names this hall 'the natural home for the missing first player controller'.
- New: `input.events`, `input.player`. Returns: `input.actions` (understand), `phys.bodies`, `cam.camera3d` (understand), `space.transform`, `gd.lifecycle`, `phys.shapes_layers`.
- Make (worked example): shared/player.tscn: CharacterBody3D in group 'player', CapsuleShape3D, a pivot with Camera3D. InputMap actions move_forward/back/left/right and jump; Input.get_vector turned relative to the camera basis; gravity when not on floor; velocity + move_and_slide() in _physics_process. Mouse capture and mouse-look in _unhandled_input; Esc releases the mouse. Ride the Trans_Introduction platform. Write the room's input rules into the README: one named action per verb, grouped by system; Esc toggles capture; before Color_Paint, 3D 'buttons' are keys bound through InputMap. Write every later mechanic against 'a CharacterBody3D in group player', not against player.tscn, so the XR body (W14) can take its place.
- In the learner's own work: Change one movement parameter (speed, jump, floor_max_angle) for a reason your room gives.
- Check: The player stays on the moving platform. With Project Settings > Physics > Common > Physics Interpolation on, the camera stops stuttering on a high-refresh display [K, not run]. Contrast: Move the platform by setting position in _process: the player slides or jitters.
- Carries forward: The learner's own body and camera, the 'player' group, and written input rules.
- Basis: [M] input.events is never taught; input.player is first taught in SwarmIntelligence_ABM (spine 20); every Transformation crossing tests a supplied body. array_body_comparison.gd already drives CharacterBody3D with floor_snap. [D] Godot's first 3D game builds this by part 03. [M] addons/godot-xr-tools/player/player_body.gd l.3-4: class_name XRToolsPlayerBody, extends CharacterBody3D (gitignored), so the group rule lets the headset body stand in.

**24 · Trans_Translation** (hall): Collect: area, tween, free
- Lesson: fragment-rewrite; curriculum kind build (transform); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `phys.areas`, `anim.tween`, `scene.lifetime`, `other:path3d_curves`. Returns: `scene.groups_paths` (understand), `gd.signals_own`, `space.transform`, `phys.shapes_layers` (understand).
- Make (worked example): The Pre collectible gets an Area3D whose mask sees only the player's collision layer (the first layer and mask decision). On body_entered by a body that is_in_group('player'): create_tween() flies it to the player, tween_callback(queue_free) removes it, a counter rises. This is the first use of groups (add_to_group, is_in_group). Optional step: move a collectible along a Path3D.
- In the learner's own work: Decide what collecting one of your objects changes, besides a number.
- Check: Collecting every collectible sets the counter to the number placed. Contrast: queue_free() directly in body_entered: the collectible vanishes before its flight plays, because a tween made with the node's own create_tween() is bound to that node [K].
- Carries forward: Trigger, response and removal; a layer and mask chosen on purpose.
- Basis: [M] tutorial has tween_property, tween_method with a lambda, apply_central_impulse and Curve3D sample_baked as helpers; the is_identity/invert/combine/get_origin block is duplicated from Introduction mid-page. Sound waits for Trans_Rotation so this stop carries three new ideas, not five.

**25 · Trans_Rotation** (hall): A turning plank under a pivot, and a sound
- Lesson: fragment-rewrite; curriculum kind build (rotation); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `anim.player`, `audio.playback`. Returns: `space.rotation` (understand), `input.player`, `phys.bodies` (understand), `assets.import`.
- Make (worked example): A plank (AnimatableBody3D) under a pivot Node3D, keyframed in an AnimationPlayer rotation track with its process callback set to Physics. Ride it; tune floor_snap_length and floor_max_angle. An AudioStreamPlayer3D at the pivot plays an imported creak, started from a method track at each turn. Compare Basis(axis, angle), Quaternion and look_at for one turn; Y*X versus X*Y.
- In the learner's own work: Give one moving thing in your room a sound that is placed where it moves.
- Borrows: transform_composition_workbench, array_body_comparison, read (understand); one CC0 sound sample (use).
- Check: The pivot at the plank's end sweeps a different path from the pivot at its centre. The creak comes from the pivot's side as the player turns. Contrast: AnimationPlayer left on its Idle callback: the rider jitters on the plank [K, not run]. Animate the mesh child instead of the body: the collision stays still.
- Carries forward: Keyframed motion updated in the physics step; pivots; slope and snap settings on the learner's body; the first placed sound.
- Basis: [M] tutorial 29 lines, a 3-line excerpt; it reports that headset traversal needs human review. Proposal: 'Audio should not be silent until Wavefunctions.'

**26 · W08_headset_day** at `Trans_Scale` (workshop, xr route): Headset day: my_room on the device
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Scheduled once, whenever a device is available after W06; listed at Trans_Scale because W09 needs it there. A desktop-only cohort skips W08, W09 and W14 and says so (section 2.1); no later desktop stop depends on them.
- New: `xr.setup`. Returns: `export.build` (change), `cam.camera3d`, `space.transform`, `editor.run_debug`, `other:renderer_choice` (understand).
- Make (worked example): A checklist session, done once, reusing Day Zero's toolchain: enable OpenXR and XR shaders in my_room; XROrigin3D, XRCamera3D and two XRController3D plus a start script (use_xr, vsync off) in a copy of room.tscn; the Android build template if the preset uses a gradle build; the OpenXR vendors plugin for Meta; an Android/Quest preset with a debug keystore; developer mode and adb; run on the device; read the device log with adb logcat and attach the remote debugger. Keep Compatibility, the renderer the kits and the 4.6 docs recommend for standalone headsets.
- In the learner's own work: Open your room on the headset and write down one thing that reads differently at 1:1.
- Borrows: OpenXR runtime, Android SDK/JDK/templates, OpenXR vendors plugin (use).
- Check: The room is at 1:1 scale on the device, and a print() from the room appears in adb logcat. Contrast: Export with the Forward+ desktop setting on the mobile line: the renderer differs from the README's, and effects the room relies on drop out or the export complains [K, not run].
- Carries forward: A verified route from my_room to a headset, and a way to read its errors there.
- Basis: [M] The tracked export_presets.cfg sets gradle_build/use_gradle_build=true (l.29) and xr_features/enable_meta_plugin=true with meta_xr_features entries (l.228-238). [M] The course project sets no rendering_method (Forward+ desktop, Mobile on Quest [K]); [D] the renderers page calls Compatibility 'Recommended for standalone headsets'. [M] Day Zero's Quest route is unverified. One verified run must be recorded before this stop is published.

**27 · W09_room_in_headset** at `Trans_Scale` (workshop, xr route): Scale the world, or scale the room
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Trans_Scale's encounter is a room scaled around a body left outside it; the headset is where the other operation can be felt.
- New: none. Returns: `xr.setup` (understand), `space.transform`.
- Make (worked example): In the headset: set XROrigin3D.world_scale to 2, then back to 1 and scale a room node by 2 instead, as Trans_Scale does (room.scale = Vector3.ONE * FACTOR).
- In the learner's own work: Choose one of the two operations for something in your room and say where the body stands in it.
- Check: Both change what the eyes see; only world_scale changes how many world units the tracked body spans [K/I, not run]. Contrast: world_scale is the converse of the hall's operation: the hall scales the room and leaves the body outside (Trans_Scale/tutorial.md l.14: 'The museum, body, gravity and walking speed are outside that multiplication.'); world_scale puts the body inside the change.
- Carries forward: Two scale operations the learner can tell apart in the headset.
- Basis: [M] Trans_Scale/tutorial.md l.9-14 (room.scale = Vector3.ONE * FACTOR; FACTOR is four).

**28 · Trans_Pit** (hall): Timed obstacles, a shared base, a gate
- Lesson: fragment-rewrite; curriculum kind compare (threshold); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.classes` (understand), `gd.const_enum`, `design.loop`. Returns: `phys.bodies`, `space.interpolation`, `anim.tween`, `gd.signals_own` (understand), `gd.lifecycle`, `scene.groups_paths`, `gd.conditions` (change).
- Make (worked example): (a) A shared base: 'class_name TimedMover extends AnimatableBody3D' with enum State {MOVING, PAUSED} and a Timer child whose timeout switches state. Two subclasses: a pusher, and the W05 door rebuilt as the exit gate with states CLOSED, OPENING, OPEN, CLOSING (Tween). (b) The gate opens when every collectible has been collected. The learner decides whether failing a lane costs anything, and writes the decision down.
- In the learner's own work: Decide what failing costs in your room, and whether that cost is fair to a body that cannot hurry.
- Borrows: pusher_block, grower_block, read (understand).
- Check: A second arrival while OPENING does what the learner decided (ignored or restarted). Both subclasses appear as TimedMover in the Create Node dialog. Contrast: Disable the gate's CollisionShape3D directly inside the body_entered chain: Godot refuses to change it while flushing queries; set_deferred('disabled', true) works [K; line_demo.gd l.243-244 defers for the same reason]. A second script declaring class_name TimedMover: the 'hides a global script class' error (tools/check_global_classes.py exists for it). Two booleans instead of an enum allow 'opening and closing' at once.
- Carries forward: class_name used to share a base between two of the learner's own scripts; explicit states; set_deferred during physics callbacks; a written failure decision.
- Basis: [M] tutorial rewritten +41/-88 (working tree); _physics_process and AnimatableBody3D named, not taught. tutorial.md l.77: 'This is a ground-level study without an enforced failure consequence ... do not describe it as a lethal pit or a compulsory timing gate.' No transformation map_data.json contains an h: hazard (all 7 checked). The survey's gd.classes caution records 2,568 files declaring class_name. Planned as two sessions, (a) then (b).

**29 · W10_pause_and_retry** at `Trans_Pit` (workshop): HUD, pause, retry
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Pit's timed lanes are the first place the learner's room has a timing obstacle, and the learner has just decided what failure costs. Critique #5: 'The first player needs a coherent relation between moving, looking, interacting and stopping.' The settings panel is W13.
- New: `ui.controls`, `other:pause_process_mode`, `scene.change`. Returns: `input.events` (understand), `input.actions`, `gd.signals_own`, `design.loop`.
- Make (worked example): A CanvasLayer HUD (collected counter, one instruction line). A pause menu of three Buttons (Resume, Retry, Quit) in a VBoxContainer (containers are explained at W13). get_tree().paused = true with the menu's process_mode set to When Paused; the menu opens with the mouse released and closes by recapturing it. Retry = reload_current_scene() in the learner's own project. One playtest with another person: note what they tried first.
- In the learner's own work: Write your room's one instruction line so that someone who has never seen it can start.
- Check: Open the menu, close it and keep moving; Resume works while paused; Retry puts every collectible back. Contrast: Leave the menu at Inherit: its buttons are dead while paused.
- Carries forward: A way to stop, resume and retry, and one observed playtest.
- Basis: [M] ui.controls and input.events are never taught; scene.change is first taught today only in the fictional Lab_Path. [M memory] under the museum's XR staging reload_current_scene() returns to the menu, so this retry belongs to the learner's own project. [D] Godot's first 3D game ends with score and retry.

**30 · CP3_playable_room** at `Trans_Pit` (checkpoint): A playable room (end of the short course)
- Movement, looking and one interaction (collect).
- Pause with a working resume, a retry, and an exit (gate plus quit).
- A visible instruction, and input rules written in the README.
- Packaged for someone else (W06 route repeated).
- One observed playtest, and one change made because of it.
- xr route: the room opens at 1:1 on the headset (W08); it is not yet playable there (W14).
- A tagged commit.
- Open task: Add one new obstacle built from TimedMover without editing the base class.
- Evidence: the build; the playtest note; the commit tag.
- Course exit: short course (stops 0-30).
- Basis: Critique's Transformation checkpoint; proposal: 'The first complete playable work should exist by the end of Transformation.' All 33 capabilities of the survey's minimum complete game are first met by this checkpoint (checked by the build).

Encounters without a making lesson in this path: `Trans_Body`.

### 3. array_tutorial

- **Today [M]:** `Array` has no `tutorial.md`. `Tutorial_3D` and the two tiling halls are stubs of 5 to 9 lines. `Tutorial_Disco` is stale.
- **Proposed [P]:**
  - `Array` carries the lifetime lesson (critique #4) and the first code form of instancing.
  - `Tutorial_Tiling_Floor` gives the first computed texture.
  - `Tutorial_Disco` gives the first MultiMesh and the first profiling, measured against the node grid, and the first branch before a risky rewrite.
  - `Tutorial_3D` becomes a variation inside `Array`.

**31 · Array** (hall): Slots, values and lifetimes
- Lesson: new-page; curriculum kind build (array); tutorial.md none. Starts from: my_room (the learner's own project, from W02 on).
- New: `mesh.gridmap`. Returns: `gd.loops`, `gd.arrays`, `scene.instancing` (understand), `scene.lifetime` (understand), `audio.playback`, `gd.errors`.
- Make (worked example): Replace hand-placed collectibles with a 2D data array (1 = collectible) instanced in nested loops with 'var c := preload("res://shared/collectible.tscn")', instantiate() and add_child() (the first code form of instancing). On collect, write 0 and keep the slot; rebuild the room from data. Keep an Array of node references, free one, test is_instance_valid. Hide versus remove_child versus queue_free. The collect sound now plays from a player owned by the room. Variation: Tutorial_3D's values[y][z][x]. Branch: the same layout as a GridMap with a MeshLibrary.
- In the learner's own work: Lay out one of your own objects from data, remove one without moving the others, and rebuild.
- Borrows: row_3_x, grid_2d_4x4, read (understand).
- Check: Collect (1,2), rebuild: (1,2) stays empty and every other slot keeps its index. Contrast: remove_at() instead of writing 0: every later index shifts. An AudioStreamPlayer3D child of the collectible is freed with it and cuts its sound short [K].
- Carries forward: Data kept apart from nodes; three ways an object leaves; code instancing.
- Basis: [M] Array has NO tutorial.md; its loop explanation lives in final.md. Critique #4: 'remove a cube, keep its slot in data, rebuild from data vs delete the slot'. curriculum array.transfer: 'Remove an occupant without moving the other addresses'.

**32 · Tutorial_Tiling_Floor** (hall, WT only): A texture from a loop
- Lesson: prose-rewrite; curriculum kind build (tile); tutorial.md untracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `mat.textures` (understand), `gd.loops`, `gd.conditions`.
- Make (worked example): Image.create + set_pixel for a binary diagonal tile, ImageTexture.create_from_image, nearest filtering, laid on floor cells with rotation (cx + cy) % 4 and one exception cell.
- In the learner's own work: Compute a tile for one surface of yours and place one deliberate exception.
- Borrows: tiling_principles, read (understand).
- Check: The exception cell is the only one out of rhythm. Contrast: Linear filtering blurs the tile edges.
- Carries forward: An ImageTexture computed with set_pixel and shown with nearest filtering.
- Basis: [M] tutorial.md UNTRACKED, a 5-line stub pointing to final.md.

**33 · Tutorial_Disco** (hall): One draw for many tiles
- Lesson: fragment-rewrite; curriculum kind build (clock_pattern); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `mesh.multimesh`, `perf.profiling`. Returns: `gd.lifecycle`, `gd.loops`, `editor.version_control` (change).
- Make (worked example): Before rewriting: make a branch. Turn Array's node grid into a MultiMeshInstance3D floor with use_colors; step (x + z + phase) % 2 on a delta clock. Run only the floor scene with F6 and compare 17x17 nodes with one MultiMesh in the Monitors (draw calls, frame time). Merge the branch or revert it.
- In the learner's own work: Measure one of your own many-object arrangements both ways before choosing.
- Borrows: disco_controls.gd (UNTRACKED), standalone_disco, read (understand).
- Check: Draw calls drop to one for the floor. Contrast: The MultiMesh floor has no per-instance collision: the player needs a separate collider to stand on it. Reverting only the scene and not the script leaves a script that expects nodes the scene no longer has.
- Carries forward: Many instances as one resource; the Monitors as a measuring habit; a branch before a risky rewrite.
- Basis: [M] tutorial.md (2026-04-24) is STALE: it describes an Area3D-per-tile pentatonic recorder with undefined helpers, while the installed floor is a MultiMesh driven by disco_controls.gd, which is UNTRACKED. [M] headless draws no frames, so profiling is windowed.

Encounters without a making lesson in this path: `Tutorial_3D`, `Tutorial_Tiling_Walls`.

### 4. color

- **Today [M]:** six prose guides and two fragment pages. Only `Color_Grid_Pallet`'s code matches the installed work. Lights, materials, signals and autoloads are used and never taught. Five of the eight halls exist only in the working tree.
- **Proposed [P]:** six making halls and four workshops: two rooms and an owner (W11), particles compared with the hall's bounded MultiMesh (W12), a settings panel (W13), and the game in the headset (W14, xr route). `Color_Paint` sets the room's rule for which input reaches the world.

**34 · Color_Context_Placed** (hall): A colour rule in the Inspector
- Lesson: prose-rewrite; curriculum kind build (colour); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.dictionaries`, `res.shared_unique`. Returns: `gd.export`, `mat.standard`, `mesh.primitive`, `gd.loops`, `scene.nodes_resources` (understand).
- Make (worked example): An @export_enum rule (one, by_shape, by_height, by_neighbour) over a const Dictionary of palettes; _ready() colours primitive parts with StandardMaterial3D; i % palette.size() repeats a palette. First one shared material, then one per part.
- In the learner's own work: Give your room a colour rule and one reason to break it.
- Borrows: chroma_stack, read (understand).
- Check: Switching the rule in the Inspector recolours by that rule. Contrast: With one shared material, recolouring one part recolours all of them.
- Carries forward: Tables as data; shared versus unique resources.
- Basis: [M] 6 of 8 colour tutorials are prose in the working tree; no earlier working-tree tutorial creates a StandardMaterial3D (survey grep: 0 files). Hook: chroma_stack's @export_enum rule plus const Dictionary tables.

**35 · Color_Flashlight** (hall, WT only): A light you carry
- Lesson: prose-rewrite; curriculum kind compare (light); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `light.env`, `mat.standard` (understand), `input.actions`, `cam.camera3d`, `perf.profiling` (understand).
- Make (worked example): A SpotLight3D under the player's camera with @export light_color and a toggle action; a second room corner lit by OmniLight3Ds on a light_cull_mask layer; roughness and metallic compared under the moving light.
- In the learner's own work: Keep one surface of yours and change only the light that reaches it (curriculum light.transfer).
- Borrows: flashlight_demo, colour_light_rooms, read (understand).
- Check: A surface outside the cull mask stays dark under that light. Contrast: Shadows on and off: read the cost in the Monitors as frame time, not FPS.
- Carries forward: Lights as objects with ranges, masks and cost.
- Basis: [M] no earlier tutorial mentions a Light3D (grep 0); light.env is first taught today only in the fictional Lab_Path.

**36 · Color_Nails** (hall): A value on a signal
- Lesson: prose-rewrite; curriculum kind build (colour_space); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `res.shared_unique`, `gd.signals_own`, `mat.standard`, `ui.controls`.
- Make (worked example): A HUD HSlider's value_changed (or the hall's ValueMapper3D values_changed) drives a duplicate()d material, so the right hand changes and the left does not.
- In the learner's own work: Let a visitor choose a colour for one of your objects and keep the others as they are.
- Borrows: nail_color_controller, ValueMapper3D, read (understand).
- Check: Only the duplicated material changes. Contrast: Without duplicate(), both hands change.
- Carries forward: A chosen value with an owner.
- Basis: [M] nail_color_controller.gd calls material.duplicate() and stores the colour in the GameManager autoload.

**37 · W11_two_rooms** at `Color_Nails` (workshop): Two rooms and an owner
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Critique #4's order: lifetime (Array), then a record across a scene change, then saving across restarts (Pattern_Foundry). Proposal: 'add a persistent session owner when information genuinely crosses scene lifetimes'.
- New: `scene.autoload`. Returns: `scene.change` (understand), `scene.lifetime`, `gd.signals_own`, `gd.classes`, `editor.run_debug`.
- Make (worked example): rooms/room_b.tscn behind the W05 door (change_scene_to_file). The chosen colour lives in a small autoload the learner writes (Session.gd), not in the museum's GameManager; room_b reads it in _ready(). print() in _exit_tree() shows what the change frees; watch the Remote tree during the change.
- In the learner's own work: Decide which one value of yours must outlive a scene change, and keep everything else local.
- Check: The colour survives the scene change; the Remote tree shows room A's nodes gone and Session still there. Contrast: Kept on a node in room A, it is lost on the change.
- Carries forward: An explicit owner for shared state.
- Basis: [M] Color_Nails is the only hall where a chosen value crosses scenes (GameManager). [M] the course project has 27 autoloads in the working tree (26 at HEAD); the learner should own one small one instead.

**38 · Color_Rainbow** (hall, WT only): Bands from a rule
- Lesson: prose-rewrite; curriculum kind build (colour_space); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.loops`, `mesh.procedural`, `phys.areas`, `editor.run_debug`, `input.actions`, `gd.variables`.
- Make (worked example): A fixed-width arch split into N bands coloured Color.from_hsv(float(i) / N, ...); an action or a HUD Button cycles N.
- In the learner's own work: Address the colours of one of your objects by index and choose what N means for it.
- Borrows: rainbow.gd and control_panel buttons (use).
- Check: N = 1 gives one band of the start hue. Contrast: Write i / N with two ints: every band gets hue 0 and the editor shows an integer-division warning (a return to W01's habit of reading warnings). With float(i), looping to N inclusive gives two red bands, because hue 1.0 is hue 0.0.
- Carries forward: A colour as an index into a rule-generated list.
- Basis: [M] HEAD's Mario-cube fragment sets RigidBody3D.mesh and preloads a nonexistent scene. [K] GDScript int / int truncates.

**39 · W12_particles** at `Color_Rainbow` (workshop, WT only): Two ways to celebrate: particles or a bounded MultiMesh
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Critique #6: 'Particles are missing: one small emitter exercise.' This hall is where the project already replaced a particle node with a bounded MultiMesh, so the comparison is the hall's own decision.
- New: `fx.particles`. Returns: `phys.areas`, `gd.signals_own`, `mat.standard`, `mesh.multimesh`, `perf.profiling`, `other:renderer_choice`.
- Make (worked example): A one-shot GPUParticles3D burst with a ParticleProcessMaterial and an emissive draw-pass mesh, fired by the exit gate's opened signal; local versus world coordinates on a moving emitter; the visibility AABB. Then the hall's own choice: a bounded MultiMesh burst with a fixed instance count and lifetime. Compare both under the room's Compatibility renderer.
- In the learner's own work: Choose one of the two for your exit and say what the other would have cost.
- Borrows: rainbow.gd l.226 (AtmosphereParticles, a GPUParticles3D), rainbow_celebration.gd l.31 and rainbow_spark_burst.gd l.1-3, read (understand).
- Check: The burst plays once per opening; the MultiMesh burst stays within its instance count. Contrast: one_shot off: a fountain. local_coords on a moving emitter: the trail moves with it.
- Carries forward: Particles as a response, measured against the bounded alternative the hall chose.
- Basis: [M] The arch builds a GPUParticles3D named AtmosphereParticles (rainbow.gd l.226). The celebration frees it (rainbow_celebration.gd l.31: arch.get_node("AtmosphereParticles").queue_free()) and draws MultiMesh confetti (l.17) and sparks, 'Ballistic sparks ... in all renderers. One small MultiMesh per collection' (rainbow_spark_burst.gd l.2-3). All tracked. [D] GPU particle collision is unsupported under Compatibility.

**40 · Color_Grid_Pallet** (hall, WT only): Addresses, a rule pass and an exception
- Lesson: fragment-rewrite; curriculum kind build (colour_space); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `ui.world_space`. Returns: `mesh.multimesh` (understand), `gd.dictionaries`, `ui.controls`.
- Make (worked example): The Disco MultiMesh floor with a Dictionary from Vector2i to instance index; a single-cell set_instance_color and a rule pass (x + y) % palette.size(); a palette panel of HUD buttons, opened with the mouse released. A Label3D above each edited cell shows its address (pixel_size, billboard). Pair each colour with a mark so hue is not the only cue.
- In the learner's own work: Make one of your arrangements addressable and keep one exception the rule cannot overwrite.
- Borrows: address_lesson.gd, read (its code matches the installed work) (understand).
- Check: An edit followed by a rule pass is overwritten. Contrast: Store exceptions separately and re-apply them after the rule.
- Carries forward: The address-to-instance map; rule versus exception; a world-space label.
- Basis: [M] the only colour tutorial whose code matches the installed work (address_lesson.gd l.82, 90-92).

**41 · W13_settings** at `Color_Grid_Pallet` (workshop, WT only): A settings panel
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: The palette panel is the room's second panel, and Grid_Pallet already pairs hue with a mark for access. Split from the draft's single menu workshop.
- New: `ui.layout`, `access.a11y`. Returns: `ui.controls` (understand), `input.events`, `other:pause_process_mode`.
- Make (worked example): A settings panel reached from the pause menu: MarginContainer, VBoxContainer and HBoxContainer rows; a Theme with a font whose size is the text-size setting; a mouse-sensitivity HSlider the player script reads; anchors so the panel survives a window resize. Applied at once, not yet saved (saving comes at Pattern_Foundry and AirMusic).
- In the learner's own work: Choose one setting your room needs for someone other than you, and add it.
- Check: Change the text size and sensitivity, close the panel, keep moving: both hold. Resize the window: the panel stays readable. Contrast: Fixed offsets without containers: the panel breaks at another window size.
- Carries forward: Containers, a theme and two settings that apply.
- Basis: [M] ui.layout and access.a11y are never taught. [M] the survey's access.a11y use: 'volume and mute, and readable font sizes'.

**42 · Color_Paint** (hall, WT only): A ray that leaves a mark
- Lesson: fragment-rewrite; curriculum kind compare (inscription); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `phys.queries`. Returns: `mat.textures` (change), `space.vector3`, `phys.shapes_layers` (understand), `space.transform`, `input.events`.
- Make (worked example): From the centre of the screen, PhysicsRayQueryParameters3D + intersect_ray to a wall; to_local(hit) -> UV on a flat quad; stamp a disc into an Image whose radius grows with distance; ImageTexture.update(). From here on the room's rule is: world interaction uses the centre-screen ray, UI uses the released mouse; add it to the README.
- In the learner's own work: Let the visitor leave one kind of mark on one surface of yours and decide what cannot be marked.
- Borrows: spray_can.gd, paper_draw_surface.gd (SubViewport canvas), read (understand).
- Check: Farther away, larger marks. Clicking a menu button does not paint the wall behind it, because the GUI takes the click before _unhandled_input. Contrast: A wall outside the ray's collision mask receives nothing.
- Carries forward: Rays, masks and UVs; one written rule for which input reaches the world.
- Basis: [M] raycasts and UVs are never taught before; the installed canvas is a SubViewport feedback shader the tutorial never names. [K] Re-uploading a texture every frame is costly on Quest.

**43 · W14_game_in_headset** at `Color_Paint` (workshop, xr route, WT only): The game in the headset
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: The first stop after the room has a menu (W10), settings (W13) and a world-interaction ray (Color_Paint), which are the three things a headset player needs in a different form. Without it the headset route could show the room but not play it.
- New: none. Returns: `xr.interaction` (understand), `xr.setup`, `ui.world_space` (change), `access.a11y` (understand), `phys.queries`, `scene.groups_paths`.
- Make (worked example): In my_room's headset copy: install XR Tools 4.5.1 (the course project's version); XRToolsPlayerBody added to group 'player' and put on the player's collision layer, so the collectibles, gate and fields the learner wrote accept it; a direct movement provider and a turn provider; the pause and settings panels shown on a quad through a SubViewport and operated with XRToolsFunctionPointer; a comfort choice (snap or smooth turn, a vignette); the controller ray paints the Color_Paint wall.
- In the learner's own work: Choose the comfort default for your room and say who it is for.
- Borrows: XR Tools 4.5.1: PlayerBody, movement providers, FunctionPointer, Viewport2Din3D (use).
- Check: Every mechanic from W07 onward works with the headset body without edits; the pointer operates the pause menu; the chosen turn mode applies. Contrast: A CanvasLayer HUD does not appear in the headset view [K, not run]: the panels have to be in the world.
- Carries forward: The room as a headset game with a world-space menu and a comfort setting.
- Basis: [M] addons/godot-xr-tools/player/player_body.gd l.3-4: class_name XRToolsPlayerBody extends CharacterBody3D (gitignored, 4.5.1 per day-zero.md l.42). [M] The survey's ui.world_space change level: 'Builds an interactive 3D panel (XR Tools Viewport2Din3D or its own raycast)'.

Encounters without a making lesson in this path: `Color_Pillar`, `Color_Walls`.

### 5. tiling

- **Today [M]:** five prose companions. The three `Ribbon_Patterns` halls that end the sequence have no tutorial and are untracked.
- **Proposed [P]:**
  - Saving across restarts (`Pattern_Foundry`), the first shader edit (`Tutorial_Pattern`) and a bounded undo of snapshots (`Symmetry_Seventeen`), then CP4.
  - `Ribbon_Patterns_03` (a versioned recipe with validation, a shader with `discard`, a saved costume) is the natural later branch for `gd.errors` at change depth. It needs a tutorial written first.

**44 · Pattern_Foundry** (hall): A recipe that survives a restart
- Lesson: prose-rewrite; curriculum kind build (pattern); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `data.save`. Returns: `mat.textures`, `gd.dictionaries`, `gd.errors` (understand), `res.shared_unique`, `export.build`.
- Make (worked example): A 4x4 palette-index source rendered into an Image with a repeat rule; one texture on two materials; a HOLD flag that stops one receiver updating; SAVE and RESTORE the source as JSON in user:// (FileAccess, JSON.stringify / parse_string).
- In the learner's own work: Choose one thing of yours that should survive quitting, and one that should not.
- Borrows: recipe_study.gd (saves user://pattern_recipes/foundry.json), read (understand).
- Check: Quit, relaunch, RESTORE: the same pattern. Contrast: Write to res:// instead: it works in the editor and fails in the exported build. Corrupt the JSON: push_error and a fallback, not a crash.
- Carries forward: Persistence across restarts, the third kind of keeping after a copy and a scene change.
- Basis: [M] data.save is never taught; the tutorial is companion prose in both states.

**45 · Tutorial_Pattern** (hall): Change the data or change the address
- Lesson: prose-rewrite; curriculum kind build (pattern); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `shader.spatial`. Returns: `mat.textures`, `gd.arrays`, `gd.functions`.
- Make (worked example): A supplied ten-line spatial shader samples the 4x4 texture with floor(UV * n) and fract(UV * n) and flips x on odd columns; the learner changes a uniform and one expression. Beside it, a GDScript function reverses each source row.
- In the learner's own work: Mirror one of your patterns both ways and choose which operation your room keeps.
- Borrows: the ten-line shader (understand).
- Check: Both mirrors give the same picture. Contrast: The shader mirror leaves the saved JSON unchanged; the data mirror changes it.
- Carries forward: Address operation versus data operation; the first shader edit.
- Basis: [M] Noise_One, Noise_6_Wall, Array_Patterns and Pattern_Disco read shading language before any shader lesson, and the Shaders sequence has no tutorials; the survey calls this 'a gentle first shader lesson before sequence 12'.

**46 · Symmetry_Seventeen** (hall): Three rules, a held copy, a bounded undo
- Lesson: prose-rewrite; curriculum kind compare (symmetry); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `data.undo`. Returns: `gd.functions`, `gd.arrays`, `mat.textures`, `res.shared_unique`.
- Make (worked example): get_color(x, y) under p1 (wrap), pm (odd-block mirror) and pg (glide) over one 4x4 Array; bake into a 32x32 Image; HOLD duplicates the image; undo as an Array of snapshots capped at 32.
- In the learner's own work: Give one of your editing tools an undo, and decide how far back it reaches.
- Borrows: vr_tile_editor, WallpaperGroups, read (understand).
- Check: Undo after RESET brings back the pre-reset source. Contrast: HOLD without duplicating: the held picture follows the live one.
- Carries forward: Snapshots and a bounded history; UndoRedo's commands come at QFEP_Sandbox.
- Basis: [M] tutorial companion prose in both states; its last line sends the learner to Ribbon_Patterns_01, which has no tutorial.

**47 · CP4_two_rooms_that_remember** at `Symmetry_Seventeen` (checkpoint): Two rooms that remember
- Two connected scenes.
- An explicit owner for shared state (the learner's autoload).
- A usable interface: pause menu, palette panel and a settings panel.
- One personal change that survives a restart (the saved pattern recipe).
- xr route: the room is playable on the headset with a world-space menu and a comfort choice (W14).
- A tagged commit.
- Open task: Rebuild the palette panel in a fresh scene without opening the old one, then compare the two.
- Evidence: the build; a restart demonstrated by someone else; the commit tag.
- Course exit: A: foundations and composition.
- Basis: Critique's Arrays/Color/Patterns checkpoint; proposal's first course exit. The rebuild task is critique item 7's 'rebuild exercise in a fresh scene'.

Encounters without a making lesson in this path: `Pattern_Disco`, `Array_Patterns`, `Ribbon_Patterns_01`, `Ribbon_Patterns_02`, `Ribbon_Patterns_03`.

### 6. change

- **Today [M]:** `Change_Intro` is the most code-bearing tutorial in its slice, and its code matches the workbench. It measures the rate in x, not in time.
- **Proposed [P]:** keep the plot, and add a rate in time with a fixed step and a local pause. Then W15 reorganises `my_room` into one scene per exhibit with a hub, before the heavy systems arrive. `Flow_Field` stays an encounter.

**48 · Change_Intro** (hall): A rate you can state
- Lesson: fragment-rewrite; curriculum kind build (rate); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.lifecycle` (understand), `mesh.procedural`, `gd.export`, `gd.functions`, `gd.const_enum`, `other:pause_process_mode`.
- Make (worked example): Plot f(x) as an ImmediateMesh line strip; a secant from an @export h; a Riemann loop. Then a mover whose speed is per second, stepped by a fixed-step accumulator (STEP = 1/60, capped catch-up), with a local clock that pauses without pausing the tree.
- In the learner's own work: Give one moving thing of yours a rate in stated units and a pause of its own.
- Borrows: tangent_slope_workbench, riemann_sum_workbench, read (understand).
- Check: At max_fps 30 and 144 the mover covers the same distance per second. Contrast: A per-frame constant without delta does not.
- Carries forward: Rates in time; a fixed step; a local pause.
- Basis: [M] tutorial matches the real workbench and says the variable is x, not time; ImmediateMesh draws every plot and is never named. Flow_Field (the other hall) stays an encounter.

**49 · W15_many_rooms** at `Change_Intro` (workshop): Many rooms and a hub
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: After CP4 (course exit A) the room has two scenes and a session owner, and the next sequences add heavy systems. Change_Intro's own subject is a rate stated per exhibit.
- New: none. Returns: `scene.change` (change), `scene.autoload`, `scene.instancing`, `editor.scene_tree` (change), `scene.groups_paths` (change), `editor.version_control`.
- Make (worked example): Reorganise my_room: rooms/<sequence>/<exhibit>.tscn, one scene per exhibit; shared/ for player.tscn, door.tscn and Session.gd; a hub room whose W05 doors lead to each exhibit through change_scene_to_file; 'Save Branch as Scene' to split what has grown inside room.tscn; unique names (%Name) where paths broke. From here every stop starts a new exhibit scene. Commit the move as one change.
- In the learner's own work: Choose the order of the hub's doors and say what a visitor meets first.
- Check: Every exhibit opens from the hub and runs alone with F6; the Monitors for one exhibit no longer include the others. Contrast: Move a scene file outside the FileSystem dock: its uid or path links break; moved inside the dock, they hold.
- Carries forward: A project that can keep growing: one scene per exhibit, a hub, and profiling that measures one exhibit at a time.
- Basis: [M] In the draft 99 of 111 stops added to one room, and heavy items (a 17x17 floor, per-cell CA bodies, an 8000-cube sponge, a marching-cubes field, 2000 boids) would have measured each other.

Encounters without a making lesson in this path: `Flow_Field`.

### 7. forces

- **Today [M]:** eleven of thirteen tutorials are prose describing the engine features each adapter uses. Nothing is built. Twelve lesson adapters extend `machine_stage.gd`, which no tutorial names. Every hall has a headless probe that no tutorial teaches, and the probes are untracked.
- **Proposed [P]:** four main making halls, the checks workshop (W16) and a character branch (W17). `Vectors_Act1_WhatAVectorIs`, `VFM_02_Operations`, `Vectors_Act2_VectorArithmetic`, `VFM_05_Launch`, `Vectors_Act4a/4b`, `VFM_07_Gravity` and `VFM_08_Arena` stay encounters. `VFM_08_Arena` (subclass one creature, override its target search, ray sight) is the obvious optional studio.

**50 · VFM_03_Motion** (hall): A force for a second
- Lesson: fragment-rewrite; curriculum kind build (motion); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `phys.forces`. Returns: `phys.bodies` (understand), `phys.shapes_layers` (change), `space.transform`, `gd.lifecycle`, `other:renderer_choice`.
- Make (worked example): A zero-gravity RigidBody3D pushed with apply_central_force(global_basis * f) for one second; predict delta_v = F * t / m first; mass, linear_damp, axis locks, can_sleep, continuous_cd; a collision layer shared only with four walls. Then the time-step experiment: the same per-tick damping at 60 and at 90 physics ticks per second. Confirm the README's physics engine before running.
- In the learner's own work: Give one object of yours weight, a push, and a layer scheme you can explain.
- Borrows: VectorMotion / motion_chamber, probe_motion_chamber.gd (34 checks, UNTRACKED), read (understand).
- Check: The measured delta_v is within tolerance of the prediction. Contrast: Per-tick damping gives different results at 60 and 90 Hz (NOC review: 0.451 vs 0.294 amplitude over 6 s); a delta-correct damping agrees.
- Carries forward: Engine integration compared with a prediction; the physics rate as a variable.
- Basis: [M] XR Tools sets physics ticks from the headset refresh rate (start_xr.gd), so desktop and Quest differ. [M] the course project sets GodotPhysics3D; [D] new 4.6 projects default to Jolt; kits set no physics engine. The README line from W03 names which one the room runs.

**51 · Vectors_Act3_FieldsAndMotion** (hall): Your own integrator
- Lesson: prose-rewrite; curriculum kind compare (force); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.lifecycle`, `gd.arrays`, `space.vector3`, `mesh.procedural`.
- Make (worked example): One fixed-step integrator (accumulator, STEP = 1/120, 0.25 s catch-up cap) drives two particles from one field: one assigns velocity, one adds acceleration; both leave trails.
- In the learner's own work: Drive something of yours with your integrator and keep it for later halls.
- Borrows: VectorFieldFlow field_receivers, read (understand).
- Check: 30 Hz and 60 Hz frame partitions give the same trajectory. Contrast: Replacing the fixed step with raw delta breaks the agreement.
- Carries forward: One learner-owned stepper that later halls can reuse instead of rewriting (Act4b and VFM_07 each reimplement one today).
- Basis: [M] tutorial is prose (-76/+18 rewrite); three integrators are written separately across forces.

**52 · W16_checks_without_you** at `Vectors_Act3_FieldsAndMotion` (workshop): A check that runs without you
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: Act3's integrator carries an exact claim to check. CLAUDE.md asks for 'a negative test proving the new behavior actually bites'.
- New: `test.checks`. Returns: `gd.errors`, `editor.run_debug` (change).
- Make (worked example): Two routes to one check. In the editor: checks/integrator_check.tscn, run with F6, prints PASS or FAIL and calls get_tree().quit(code). From a terminal: check_integrator.gd extends SceneTree, run with godot --headless --script; on Windows use the _console.exe build, or read the exit code with 'echo $LASTEXITCODE' in PowerShell. A two-line terminal primer: cd into the project; run the command. Predict the result first; then break the accumulator on purpose and see the check fail.
- In the learner's own work: Write one check for a claim your room makes, and one broken version that proves the check can fail.
- Check: Exit code 0 on the correct integrator. Contrast: Exit code 1 on the broken one (the negative test that proves the check bites).
- Carries forward: Repeatable checks, and a list of what headless cannot see (no frames drawn, MultiMesh reads identity, shader errors only at first draw).
- Basis: [M] every forces hall ships a headless probe (probe_field_receivers 39 checks, probe_gravity_relations 51; both UNTRACKED); test.checks is never taught. [M] commons/testing holds 931 scripts; no GUT or gdUnit is installed. [M] CLAUDE.md: the Desktop v4.6 exe is 'non-console'.

**53 · Change_Choreography** (hall, WT only): Extend a small base; keep an invariant
- Lesson: prose-rewrite; curriculum kind compare (force); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.classes` (change), `gd.const_enum`, `scene.instancing`, `scene.lifetime` (change).
- Make (worked example): Write phase_rod_array (45 lines) on top of machine_stage.gd (26 lines): extend it, override act() with a match on button ids; then a conveyor that spawns RigidBody3D.new() parcels and frees them under a cap of 48, printing admitted - collected == boxes.size().
- In the learner's own work: Pull a base class out of two machines of yours, as TimedMover was at Trans_Pit.
- Borrows: machine_stage.gd (understand).
- Check: The invariant holds after 1000 parcels. Contrast: Forget to erase a freed parcel from the array: the invariant breaks and is_instance_valid reports it.
- Carries forward: Inheritance chosen on purpose; lifetime kept under a cap.
- Basis: [M] 12 of 13 forces lesson adapters extend machine_stage.gd and no tutorial names it; Change_Choreography is in forces only in the working tree.

**54 · W17_character_studio** at `VFM_09_Legs` (workshop, branch): An imported body that moves
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: The first hall whose primary is a skeleton. Critique #6 asks for import and animation before Soft Bodies for character-focused learners.
- New: `anim.tree_skeletal`. Returns: `assets.import`, `anim.player`.
- Make (worked example): Import a rigged CC0 glTF character; play its clips in the AnimationPlayer; an AnimationTree blend (idle to walk) driven by the learner's player velocity; read a bone through a BoneAttachment3D.
- In the learner's own work: Optional: the player gets a visible body.
- Borrows: a CC0 rigged character (use); four_leg_critter (Skeleton3D + FABRIK3D), read (understand).
- Check: The blend follows the speed. Contrast: get_bone_global_pose() ignores the IK modifier; the BoneAttachment3D reading does not.
- Carries forward: The character pipeline for learners who want one.
- Basis: [M] VFM_09_Legs' primary is a Skeleton3D with FABRIK3D legs; AnimationTree appears in 6 files. [M memory] bone poses hide the modifier.

**55 · Vectors_Act5_ForceAsPlace** (hall): A place that changes what enters it
- Lesson: prose-rewrite; curriculum kind compare (force); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.areas` (change), `input.player` (understand), `gd.dictionaries`, `design.loop`, `scene.lifetime`.
- Make (worked example): An Area3D that replaces gravity with an @export acceleration for any RigidBody3D and for the learner's player inside it: save gravity_scale in a Dictionary keyed by body on enter, restore on exit; the player's velocity is modified before move_and_slide(). Use it to bridge a gap.
- In the learner's own work: Make one crossing in your room that a body can only make through a field.
- Borrows: vector_machine, force_field_zone, field_carry_provider, read (understand).
- Check: Gravity is back after leaving. Contrast: Free a body while it is inside: the Dictionary keeps a dead key.
- Carries forward: An Area3D gravity zone that restores each body's gravity_scale on exit.
- Basis: [M] Area3D appears earlier only in HEAD Tutorial_Disco; the CharacterBody3D pipeline is never taught before this plan's W07.

Encounters without a making lesson in this path: `Vectors_Act1_WhatAVectorIs`, `VFM_02_Operations`, `Vectors_Act2_VectorArithmetic`, `VFM_05_Launch`, `Vectors_Act4a_KineticForces`, `Vectors_Act4b_Oscillation`, `VFM_07_Gravity`, `VFM_08_Arena`.

### 8. formfinding

- **Today [M]:** five fragment pages taken from shipped code, and none has a scaffold to run it in. The working-tree `FormFinding_Descent` dropped its code, which `FormFinding_Forge` still refers to.
- **Proposed [P]:** three making halls, in the order stopping, joints, then a game loop. None introduces a new capability; they deepen conditions, forces and design. `Catenary` (Curve3D) and `Relaxation` (a RefCounted Verlet class) are optional studios. `Annealing` keeps the named bridge from `curriculum.json` issue `annealing`: its seeded proposal stream is supplied.

**56 · FormFinding_Descent** (hall): Step, run, reset, stop
- Lesson: prose-rewrite; curriculum kind build (descent); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.lifecycle`, `gd.conditions`, `mesh.procedural`, `test.checks`, `ui.controls`, `gd.const_enum`.
- Make (worked example): An optimiser node: one update per fixed interval accumulated in _process; three named stop conditions (step limit, small slope, left frame) in an enum; a capped trail in one reused ImmediateMesh; STEP, RUN and RESET as HUD Buttons.
- In the learner's own work: Something in your room that settles by a rule and says why it stopped.
- Borrows: descent_landscape_lab, read (understand).
- Check: A headless check: it stops on SMALL SLOPE within 160 steps. Contrast: Remove the step limit on a flat saddle: it never stops.
- Carries forward: Named stopping reasons that a check can assert.
- Basis: [M] the working-tree rewrite (94 -> 13 lines, no code) dropped the HEAD code, so Forge's 'same three lines as the first map's marble' points at code the learner no longer sees. The page needs new code.

**57 · FormFinding_Equilibrium** (hall): Solve, then hang it for real
- Lesson: fragment-rewrite; curriculum kind build (constraint); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.forces` (understand), `phys.bodies`.
- Make (worked example): Hang a two-level mobile from RigidBody3D pieces and HingeJoint3D in the editor at the pivots the lever law solves; run and watch whether it balances.
- In the learner's own work: Hang something of yours where its balance is computed first and then tested.
- Borrows: calder_mobile (computes balance, freezes its bodies), read (understand).
- Check: The solved pivots hang level. Contrast: Move one pivot 5 cm: it tilts.
- Carries forward: Joints; the difference between a computed and a simulated balance.
- Basis: [M] calder_mobile freezes its RigidBody3D children, so the balance is computed, not simulated. [D] Jolt joint parameters differ from GodotPhysics3D. Recursion in this hall stays an excerpt; it is taught at Fractal_Recursion.

**58 · FormFinding_Forge** (hall): Settle to win
- Lesson: fragment-rewrite; curriculum kind compare (search_cost); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `design.loop` (understand), `gd.signals_own`, `anim.tween`, `phys.bodies`, `gd.conditions`.
- Make (worked example): A stacking puzzle: RigidBody3D blocks count as settled when every linear and angular speed stays under a threshold for 1.5 s; emit solved; tween a reward; retry.
- In the learner's own work: A small puzzle in an exhibit of yours, tried by one person who did not make it.
- Borrows: balance_puzzle, read (understand).
- Check: A stable stack triggers solved once. Contrast: A threshold that is too high declares a wobbling stack solved.
- Carries forward: A settled test over speeds and elapsed time that emits solved once.
- Basis: [M] survey: 'the sequence's first real game'.

Encounters without a making lesson in this path: `FormFinding_Catenary`, `FormFinding_Relaxation`, `FormFinding_Annealing`.

### 9. wavefunctions

- **Today [M]:** six tutorials rewritten in September quote shipped code, and their next-pointers chain across half the sequence. The other six are April code for classes that do not exist.
- **Proposed [P]:** three making halls: a signal with arguments, a rendered note, and an instrument with buses and saved settings. `WaveFunctions_Synthesis_Lab`'s `ambient_patch` (runtime buses and effects, voices rendered on a worker thread) is an optional audio branch. The six illustrative halls stay encounters until rewritten (section 5).

**59 · WaveFunctions_Intro** (hall, desktop + xr steps): Who detects, who announces, who responds
- Lesson: fragment-rewrite; curriculum kind build (oscillation); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.signals_own` (change), `gd.lifecycle`, `xr.interaction`, `gd.conditions`.
- Make (worked example): A pendulum integrated in _physics_process; centre_crossed(dir, omega) emitted on a sign change above a speed threshold; one cube driven by the signal and one by its own clock. xr route: the bob's grabbed / released signals, and the desktop hook that stands in for them.
- In the learner's own work: Give one of your objects a signal with arguments that two other objects use differently.
- Borrows: control_pendulum.gd (672 lines, 4 signals: oscillation_updated, grabbed, released, centre_crossed), read (understand).
- Check: One crossing per pass. Contrast: Threshold 0: jitter at rest emits many.
- Carries forward: Signals with arguments; one grab reached by an XR route and a desktop route.
- Basis: [M] tutorial matches shipped control_pendulum.gd (signals at l.63-65, l.70). [M memory] the desktop carry does not emit an XR pickable's picked_up/dropped; artifacts need desktop hooks.

**60 · WaveFunctions_Effect_Sound** (hall): Render a note
- Lesson: fragment-rewrite; curriculum kind build (wave); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `audio.generate`. Returns: `gd.packed_arrays` (understand), `audio.playback` (understand), `gd.loops`.
- Make (worked example): A per-sample loop: sine times an envelope, into a PackedByteArray with encode_s16, wrapped in an AudioStreamWAV (mix_rate, 16-bit format) and played on an AudioStreamPlayer3D; a moved object's position maps to pitch.
- In the learner's own work: Make one object of yours sound its own position.
- Borrows: DualBallFMController, ValueMapper3D, read (understand).
- Check: 440 Hz matches a reference tone. Contrast: A wrong mix_rate shifts the pitch.
- Carries forward: Samples computed in a loop and played as a stream.
- Basis: [M] the float-to-AudioStreamWAV step is shown nowhere; the working-tree rewrite removed the only AudioStreamGenerator lesson in the sequence.

**61 · WaveFunctions_AirMusic** (hall): An instrument someone can turn down
- Lesson: fragment-rewrite; curriculum kind compare (sound); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `audio.playback` (change), `phys.areas`, `access.a11y` (understand), `ui.layout`, `data.save` (understand).
- Make (worked example): Bars with Area3D strike zones; strike speed to volume_db; one AudioStreamPlayer3D per voice; a bus layout (Master, SFX, Music); volume and mute sliders in the W13 settings panel with AudioServer.set_bus_volume_db, saved with ConfigFile in user:// together with text size, sensitivity and (xr route) the W14 comfort choice.
- In the learner's own work: Give your room's sound a setting that persists, including silence.
- Borrows: ResonatingMetallophone, CombinedWaveVisualizer, read (understand).
- Check: Muting SFX leaves music playing, after a restart too. Contrast: Replaying one player cuts its note; two players overlap.
- Carries forward: Voices, buses and settings saved with ConfigFile.
- Basis: [M] AudioServer buses are never taught; tutorial rewrite (uncommitted) quotes the shipped code. Proposal: 'Retain a chosen preset and allow silence.'

Encounters without a making lesson in this path: `WaveFunctions_Pendulum`, `WaveFunctions_Sine_Space`, `WaveFunctions_Unit_Circle`, `WaveFunctions_3D_Wave_Propagation`, `Wavefunctions_Bernini`, `WaveFunctions_John_Cage`, `Wavefunctions_Sky_Stairs`, `WaveFunctions_TrigWalkingPath`, `WaveFunctions_Synthesis_Lab`.

### 10. randomness

- **Today [M]:** `Random_Definition` is the only runnable study outside the opening, and it is untracked. Five halls quote shipped code. The April halls (`Randomness_10_PRINT_Algorithm`, `Random_Cubes`, `Random_Rotate_Random_XYZ`, `Random_Space_Geometry`, `Random_Pheromone`, `Random_Space`) are illustrative and not runnable.
- **Proposed [P]:** four making halls ending in the capstone game, with CP5 there. `await` is first taught at `Random_Remove`, where a stale coroutine is the lesson, and a per-frame work cap at `Random_Walk`.

**62 · Random_Definition** (hall, not startable at HEAD): Reset, request, assign
- Lesson: runnable; curriculum kind build (random); tutorial.md modified. Starts from: doc/book/studies/random-definition (UNTRACKED) as a worked example; my_room (the learner's own project, from W02 on) (at HEAD: absent). Runnable as a worked example; the my_room step is new writing.
- New: `data.rng`. Returns: `gd.functions`, `gd.loops`, `mat.standard`, `data.save`.
- Make (worked example): Run the existing six-step study as a worked example (read-only). Then in a new exhibit of my_room: a seeded arrangement of the learner's collectibles or tiles; save the seed and the channel roles to user://; restore after restart.
- In the learner's own work: Make one arrangement of yours recoverable from a seed.
- Borrows: display.gd (builds cubes and materials, never draws) (use).
- Check: The same seed gives the same arrangement after a restart. Contrast: One unused draw shifts every later assignment.
- Carries forward: A seeded generator whose seed is saved.
- Basis: [M] the only runnable study outside the opening; UNTRACKED (0 of 21 files); verification.json is in the iteration folder. Its stated prerequisites (Array, Colour) point at halls whose tutorials are stubs or prose.

**63 · Random_Remove** (hall): Without replacement, and a stale timer
- Lesson: fragment-rewrite; curriculum kind build (random); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.async` (understand). Returns: `scene.lifetime`, `gd.dictionaries`, `data.rng`, `phys.shapes_layers`.
- Make (worked example): Floor cells removed by seeded draws without replacement (a Dictionary as a set, remove_at from candidates); a delayed removal written with await get_tree().create_timer(t).timeout, guarded by a generation counter across RESET; the cell's collider is disabled with set_deferred.
- In the learner's own work: Give one delayed action of yours a guard, so a reset cancels it.
- Borrows: RemoveRandom.gd, random_removal_arena, read (understand).
- Check: RESET during a pending removal removes nothing afterwards. Contrast: Without the guard, the old coroutine removes a cell from the new run.
- Carries forward: await, and the fact that a coroutine can outlive the state it was for.
- Basis: [M] tutorial quotes shipped RemoveRandom.gd; await is presupposed there and taught nowhere before.

**64 · Random_Walk** (hall): A walker you can replay
- Lesson: fragment-rewrite; curriculum kind build (random); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `perf.budget`. Returns: `data.rng`, `mesh.procedural`, `gd.lifecycle`, `perf.profiling`.
- Make (worked example): A reusable walker Node: private seeded generator, fixed-step accumulator with MAX_CATCHUP_STEPS, reflection at walls, a trail; then a CharacterBody3D version that collides with the room's real walls.
- In the learner's own work: Put a walker in one exhibit of yours with a cap on how much it may do per frame.
- Borrows: random_walk_terrarium, read (understand).
- Check: Replaying the seed replays the path. Contrast: Stall a frame for 1 s: capped catch-up versus a runaway burst.
- Carries forward: A reusable agent with a per-frame work cap.
- Basis: [M] tutorial quotes shipped code and inherits Pendulum-style accumulation.

**65 · Random_Game** (hall): Randomness someone can read
- Lesson: prose-rewrite; curriculum kind compare (distribution); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `design.loop` (change), `gd.const_enum`, `gd.async`, `scene.instancing`, `scene.lifetime`, `fx.particles`, `data.rng` (understand), `audio.playback`.
- Make (worked example): Stones with enum states that stand or sink on seeded random waits shown before they happen (telegraph rings); a capped projectile spawner that instantiates and queue_frees bodies with particle bursts; REPLAY restores positions and the wait streams.
- In the learner's own work: A crossing game in an exhibit of yours whose chance a player can learn to read.
- Borrows: random_cycle_cube.gd, CubeSpawner.gd, read (understand).
- Check: The same seed gives the same sequence of waits. Contrast: An untelegraphed wait: players cannot learn it (watch one person try).
- Carries forward: Chance made visible before it acts, tested on a player.
- Basis: [M] survey: 'the sequence's capstone game'; tutorial is an encounter guide with two real snippets.

**66 · CP5_play_it_twice** at `Random_Game` (checkpoint): A place someone can play twice
- Input, sound and one meaningful variation.
- A saved configuration (seed and settings, with ConfigFile).
- A second person can enter, act, restart, and recover something they made.
- Replay from a seed reproduces the sequence of waits (not claimed to reproduce physics across devices).
- A tagged commit.
- Open task: Make the stones' waits fairer to a slower player without changing the seed.
- Evidence: the build; the seed file; a check of the replay; the commit tag.
- Basis: Proposal's composition checkpoint after sequences 6-12, placed at Random_Game because the survey marks it as the sequence's capstone game; the shaders sequence has no tutorials to carry a checkpoint yet.

Encounters without a making lesson in this path: `Random_Entropy`, `Randomness_10_PRINT_Algorithm`, `Random_Cubes`, `Random_Rotate_Random_XYZ`, `Random_Gaussian`, `Random_Mushrooms`, `Random_Space_Geometry`, `Randomness_Examples_of_Randomness`, `Random_Pheromone`, `Random_Space`.

### 11. noise

- **Today [M]:** eight encounter routes. `Lab_Path` is a 127-line template for classes, a `GameState` and an environment `.tres` that do not exist. No learner configures a `FastNoiseLite`.
- **Proposed [P]:** the proposal's "one modest terrain", with field, sampler, mesh and collider kept as four parts. `Noise_One`'s relief shader is supplied and read; the learner's first whole shader is `Shader_01_Shaping`.

**67 · Noise_Columns** (hall): One scalar, two sources
- Lesson: fragment-rewrite; curriculum kind build (noise); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `data.noise`. Returns: `perf.profiling` (change), `perf.budget`, `mesh.procedural`.
- Make (worked example): A procedural column mesh driven by one source function; swap sin(t) and FastNoiseLite.get_noise_2d(t, 0); rebuild at a capped rate and print Time.get_ticks_usec() per rebuild.
- In the learner's own work: Drive one shape of yours from noise and measure its rebuild.
- Borrows: MeltingBerniniColumns, read (understand).
- Check: The printed rebuild cost stays under the budget at 12 Hz. Contrast: Rebuilding every frame shows the cost.
- Carries forward: Noise as a function; rebuilds timed in microseconds.
- Basis: [M] nobody creates or configures a FastNoiseLite in the working-tree tutorials; HEAD's version explained the 12 Hz cap and usec cost. [M memory] a NoiseTexture2D's first image is synchronous (assign with set_deferred).

**68 · Noise_One** (hall): Relief that does not hold you
- Lesson: prose-rewrite; curriculum kind build (noise); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.shapes_layers`, `data.noise`, `mesh.procedural`, `input.player`.
- Make (worked example): The same noise heightfield twice: a supplied vertex-shader relief on a subdivided plane (read at understand depth; writing shaders starts at Shader_01), and an ArrayMesh with create_trimesh_shape(). Walk both.
- In the learner's own work: Two patches of ground, one of them only a picture; say which a visitor can trust.
- Borrows: the relief shader (supplied) (understand); noisetorus, noiselayers, read (understand).
- Check: The ArrayMesh patch carries the player. Contrast: Raise the shader amplitude: the picture changes and the walking does not. The displaced relief keeps the plane's normals, so it is lit as if flat unless the shader also sets NORMAL [K, not run].
- Carries forward: Visible deformation distinguished from collision.
- Basis: [M] vertex versus fragment stages are named without any earlier shader lesson.

**69 · Noise_Space_10** (hall): A terrain you can walk
- Lesson: prose-rewrite; curriculum kind compare (field_body); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `data.noise` (understand), `mesh.procedural` (change), `gd.packed_arrays`, `input.player`, `phys.shapes_layers`.
- Make (worked example): FastNoiseLite (type, frequency, octaves, seed as @export) sampled on a grid, times an edge envelope; one PackedVector3Array feeds both an ArrayMesh (shared grid vertices, generate_normals) and a ConcavePolygonShape3D; rebuilds are refused while the player stands on the patch.
- In the learner's own work: A walkable terrain exhibit whose seed you chose.
- Borrows: noise_space walkgrid, read (understand).
- Check: The player walks the patch after a reseed; the slopes are smoothly lit. Contrast: Rebuild while standing on it: the player drops or pops (why the refusal exists). Here shared vertices and averaged normals are right, the opposite of Animatedcube's flat faces.
- Carries forward: Field, sampler, mesh and collider as four separable parts.
- Basis: [M] HEAD tutorial was a generic template (fictional NoiseParameters class). Proposal: 'do not teach every terrain algorithm before making one modest terrain'.

Encounters without a making lesson in this path: `Random_Noise_Types`, `Noise_Voxel`, `Noise_6_Wall`, `Noise_Inside_Noise`, `Noise_Perlin_Simplex`, `Lab_Path`.

### 12. shaders

- **Today [M]:** no tutorials. Each `final.md` reads GLSL well.
- **Proposed [P]:** every stop here needs a new `tutorial.md` (section 5, item 6). The feedback study is a branch built in the learner's room only; the hall stays as it is, because its `final.md` is written about the missing piece.

**70 · Shader_01_Shaping** (hall): Your first whole shader
- Lesson: new-page; curriculum kind build (shader); tutorial.md none. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `shader.spatial` (understand), `ui.controls`, `res.shared_unique`, `ui.world_space`.
- Make (worked example): shaping.gdshader written by the learner from an empty file: render_mode unshaded; uniform float frequency : hint_range(...); fragment() using UV, TIME, step and smoothstep; on a QuadMesh; a slider bound with set_shader_parameter; per-object values without sharing (duplicated material or instance uniform).
- In the learner's own work: An object of yours with a shader you wrote, and one parameter a visitor may change.
- Borrows: ShaderRackPanel and the hall's shader_defs pattern, read (understand).
- Check: The slider changes only this object. Contrast: Declare 'const float PI = 3.14': a SHADER ERROR that appears only at first draw (PI, TAU and E are built in).
- Carries forward: A shader file the learner wrote, a uniform bound to a slider, and the first-draw SHADER ERROR.
- Basis: [M] 0 of 6 shader halls has a tutorial.md; final.md reads GLSL. [M memory] the compile gate cannot see a SHADER ERROR.

**71 · Shader_11_QueerRubber** (hall): What a surface answers to
- Lesson: new-page; curriculum kind compare (shader_body); tutorial.md none. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `light.env` (change), `shader.spatial`, `mat.textures`.
- Make (worked example): A fresnel rim from dot(NORMAL, VIEW) written into EMISSION, then into ALBEDO, under three coloured OmniLight3Ds; on the learner's own cube, bind a texture to the sampler the way the hall does not.
- In the learner's own work: A surface of yours that answers to the eye as well as the lamp.
- Borrows: the hall's staged bodies (use).
- Check: With lights off, the emissive rim remains and the albedo rim goes. Contrast: An unbound sampler reads white.
- Carries forward: Lamp, viewer and the surface's own rule as three separate inputs to a colour.
- Basis: [M] final.md footnote: the tear texture is never assigned in the hall. [M memory] an unbound emission texture is white; emission cannot make a black thing glow.

**72 · Shader_09_FBM** (hall): Water you cannot fall into
- Lesson: new-page; curriculum kind compare (shader_body); tutorial.md none. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `shader.spatial` (change), `phys.shapes_layers`, `data.noise`.
- Make (worked example): Port Noise_6_Wall's fBm loop into vertex() on a subdivided PlaneMesh; lay a StaticBody3D glass slab over it; walk.
- In the learner's own work: Water, or another picture that moves, in an exhibit of yours, and the thing that actually carries the body.
- Borrows: basin_water, read (understand).
- Check: The player walks on the glass over moving water. Contrast: Remove the slab: the player falls through the picture of water.
- Carries forward: Vertex displacement written by the learner, with the collider as a separate decision.
- Basis: [M] final.md l.45: 'So, what carries you. The glass does.' and 'The water has no collider at all.'

**73 · Shader_10_ReactionDiffusion** (hall, optional studio, not startable until its supplied parts are built): A shader that remembers
- Lesson: new-page; curriculum kind compare (shader_body); tutorial.md none. Starts from: my_room (the learner's own project, from W02 on) + ping-pong pair (to be built).
- New: `shader.viewport_feedback`, `shader.other`. Returns: `shader.spatial`, `perf.budget`.
- Make (worked example): In the learner's room only (the hall stays as it is): two SubViewports ping-pong a Gray-Scott step (canvas_item shader) through ViewportTexture as prev_texture, seeded with a small patch; the result on a 3D surface.
- In the learner's own work: Optional: a living surface.
- Borrows: a ping-pong pair (to be built [P]; the named 'shader-memory' bridge) (use).
- Check: At the rates written in the hall's shader (0.16, 0.08) the seed sits; at 1.0 and 0.5 it spreads, as final.md l.31 says: the spreading 'needs diffusion about six times faster than what is written'. Contrast: Without the feedback texture the square stays constant green, which is the hall's own subject.
- Carries forward: Two SubViewports that hand each other their last frame.
- Basis: [M] shader_10_reactiondiffusion.gd never sets prev_texture and has no SubViewport; final.md l.23-31 is built on that absence ('What the hall shows you is the exact shape of the missing piece'). curriculum issue shader-memory: supply the feedback before CA.

Encounters without a making lesson in this path: `Shader_05_Patterns`, `Shader_12_PinkExtravaganza`.

### 13. cellularautomata

- **Today [M]:** seven encounter routes. `CA_AgentsCircuits` teaches Wireworld for a hall that now shows Rule 90 and a recursive pyramid.
- **Proposed [P]:** two making halls. `CA_BeyondBinary`'s LINK can be taught as `connect()`/`disconnect()`, and `CA_SoftRules` (CPU Gray-Scott into `ImageTexture.update`, which closes `Shader_10`'s open loop) is an optional studio.

**74 · CA_Introduction** (hall): A row, a rule, two buffers
- Lesson: prose-rewrite; curriculum kind build (cell); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.typing` (change), `gd.arrays` (change), `mesh.multimesh`, `gd.packed_arrays`.
- Make (worked example): A typed row (Array[bool] or PackedByteArray), wrap (i - 1 + n) % n, the rule bit (rule >> neighbourhood) & 1, a new row swapped in on a fixed tick; history drawn into a MultiMesh.
- In the learner's own work: A pattern generator in an exhibit of yours with a rule number you chose.
- Borrows: ca_rule_explorer, read (understand).
- Check: Rule 90 from one cell draws the Sierpinski figure. Contrast: Updating in place (one buffer) draws something else.
- Carries forward: State, neighbourhood, schedule and two buffers as four named parts.
- Basis: [M] working-tree tutorial names _apply_rule / _advance without code; HEAD taught 2D Life, mismatched to the hall's 1D explorer; bitwise operators are taught nowhere.

**75 · CA_GameOfLife** (hall): A history you can fall through
- Lesson: prose-rewrite; curriculum kind build (cell); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.shapes_layers`, `phys.bodies`, `input.player`, `perf.profiling`, `editor.run_debug`.
- Make (worked example): Each live cell of the rule history becomes floor: one StaticBody3D per cell, then one merged ConcavePolygonShape3D; profile both; walk the gaps with Debug > Visible Collision Shapes on.
- In the learner's own work: A floor made by a rule in an exhibit of yours.
- Borrows: ca_bridge, read (understand).
- Check: The player falls where the rule left a gap; the collision overlay shows the same gaps. Contrast: Per-cell bodies versus one merged shape: frame time.
- Carries forward: A rule history turned into floor, first as one body per cell, then as one merged shape.
- Basis: [M memory] a settled CA keeps paying (15-76 ms a frame measured for BaseCA works).

Encounters without a making lesson in this path: `CA_ElementaryRules`, `CA_BeyondBinary`, `CA_ExpandingSpace`, `CA_SoftRules`, `CA_AgentsCircuits`, `CA_EdgeOfChaos`.

### 14. fractals

- **Today [M]:** only `Fractal_Recursion` carries code, and that code is generic. The working tree dropped `Fractal_JuliaSet`, `Fractal_MandelbrotSet` and `Fractal_CrossSequence`, and took the GPU fractal works with them.
- **Proposed [P]:** three making halls: recursion and its stack, editor previews, and measured growth.

**76 · Fractal_Recursion** (hall): A base case and an explicit stack
- Lesson: fragment-rewrite; curriculum kind build (recursion); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `gd.recursion` (understand). Returns: `perf.budget` (understand), `gd.functions`, `gd.arrays`, `gd.loops` (change).
- Make (worked example): _draw_circles(center, r, level) with an explicit base case; then the same with an Array used as a stack and a per-frame work budget so depth 8 does not stall.
- In the learner's own work: A recursive ornament of yours, drawn both ways.
- Borrows: example_8_3_recursion_circles_vr, read (understand).
- Check: Both versions produce the same count. Contrast: Remove the base case: a stack overflow error.
- Carries forward: A recursive function with a base case, and the same work done with an explicit stack under a per-frame budget.
- Basis: [M] the only fractal tutorial still carrying code; generic, with undefined draw_segment/spawn_cube_at; [I] it claims tail calls 'can be optimised into a loop', which GDScript does not do.

**77 · Fractal_RecursiveTrees** (hall): Preview in the editor
- Lesson: prose-rewrite; curriculum kind build (recursion); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `tool.editor`. Returns: `gd.recursion`, `space.transform` (change), `gd.export` (change).
- Make (worked example): A tree generator as a @tool script with @export depth that previews in the editor behind Engine.is_editor_hint(); breadth-first (one generation per GROW from a queue) versus depth-first recursion. Return to shared/point.tscn and give its setter an editor preview.
- In the learner's own work: A generator of yours that you tune without running the game.
- Borrows: recursive_tree_lesson desk, read (understand).
- Check: Changing depth in the Inspector redraws in the editor. Contrast: Generated children given an owner get saved into the .tscn; without the is_editor_hint() guard, runtime code runs in the editor.
- Carries forward: A @tool generator that previews in the editor behind Engine.is_editor_hint().
- Basis: [M] 214 files use @tool; tool.editor is never taught. Primitives_Ignorance promised this preview.

**78 · Fractal_MengerSponge** (hall): 20 of 27, timed
- Lesson: prose-rewrite; curriculum kind build (recursion); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `mesh.multimesh` (change), `phys.shapes_layers`, `perf.profiling`, `gd.recursion`.
- Make (worked example): Recurse the 20-of-27 rule to depth 2 or 3 into one MultiMesh plus one merged collision shape; time generation and draw; refuse rebuild while someone is inside.
- In the learner's own work: A sponge exhibit to walk through, measured before it is optimised.
- Borrows: menger_lesson, museum flight box, read (understand).
- Check: 20, 400, 8000 cubes at depths 1, 2, 3. Contrast: One MeshInstance3D per cube at depth 3: read the frame time.
- Carries forward: Cube counts and frame times at depths 1-3, measured before any optimisation.
- Basis: [M] HEAD had the MultiMesh comparison; the working tree is desk prose.

Encounters without a making lesson in this path: `Fractal_CantorSet`, `Fractal_KochSierpinski`, `Fractal_GoldenSpiral`, `Fractal_Synthesis`.

### 15. lsystems

- **Today [M]:** seven desk routes and one hall with no tutorial (`LSystems_Shape_Grammars`). HEAD's cumulative `LSystem` class would collide with the project's existing global classes.
- **Proposed [P]:** four making halls built on the existing `utils/lsystem.gd`. `Assemblage_Same_Desire` stays an encounter.

**79 · LSystems_Grammar_Lab** (hall): Rewrite, then read
- Lesson: prose-rewrite; curriculum kind build (grammar); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.strings` (change), `gd.dictionaries`, `mesh.procedural`, `gd.signals_own`, `gd.classes`.
- Make (worked example): expand_once(s): for c in s: out += rules.get(c, c), under a symbol budget; a turtle draws into an ImmediateMesh; drawing_changed updates a separate readout. Borrow utils/lsystem.gd and utils/turtle_3d.gd; they already declare global classes, so the learner's scripts must not declare class_name LSystem or Turtle3D (Trans_Pit's error, met again).
- In the learner's own work: A small language of yours with rules you wrote.
- Borrows: utils/lsystem.gd, utils/turtle_3d.gd (existing global classes) (understand).
- Check: One rewrite of F gives 5 segments and 9 symbols. Contrast: Over budget: stop with a message, not a freeze.
- Carries forward: Grammar kept separate from its interpretation.
- Basis: [M] HEAD's cumulative LSystem class would collide with the project's global LSystem, Turtle3D, GrowthAnimator and GeneticTreeSculptor; draw_line is 2D-only.

**80 · LSystems_Growth** (hall): A stack of saved states
- Lesson: prose-rewrite; curriculum kind build (grammar); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.arrays`, `gd.dictionaries`, `space.transform`, `gd.errors`.
- Make (worked example): [ pushes {pos, dir, length} onto an Array, ] pops it; STEP replays a recorded trace of interpreter records.
- In the learner's own work: Branching growth in an exhibit of yours.
- Borrows: growth_lesson desk, read (understand).
- Check: Brackets restore the saved heading. Contrast: An extra ] on an empty stack: a guarded error, not a crash.
- Carries forward: The explicit stack of saved states (no tutorial anywhere earlier contains push/pop).
- Basis: [M] a stack data structure appears in no earlier tutorial, working tree or HEAD.

**81 · LSystems_Architecture** (hall): A grammar you can walk
- Lesson: prose-rewrite; curriculum kind compare (grammar_space); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.bodies`, `phys.shapes_layers`, `input.player`, `editor.run_debug`.
- Make (worked example): Turtle centrelines become corridors: BoxMesh walls with StaticBody3D / BoxShape3D at a chosen clear width; test with the learner's CharacterBody3D capsule, with Visible Collision Shapes on.
- In the learner's own work: A generated corridor exhibit whose width you chose for a named body.
- Borrows: architecture_lesson (machine_stage.box solid walls), read (understand).
- Check: 0.8 m clear width passes the learner's capsule; 0.5 m does not. Contrast: Visual width versus collision width, seen in the collision overlay.
- Carries forward: A corridor width tested against the player's capsule radius.
- Basis: [M] clear width against a body diameter assumes a player collider never built as a making step in the working tree.

**82 · LSystems_Living** (hall): Genes as a Resource
- Lesson: prose-rewrite; curriculum kind compare (grammar_space); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `res.custom`. Returns: `res.shared_unique` (change), `data.save`, `gd.export`, `gd.signals_own`, `gd.classes`.
- Make (worked example): 'class_name Genes extends Resource' with @export gene fields; plant a snapshot with duplicate(true) passed through a signal; save it as .tres with ResourceSaver.
- In the learner's own work: A saved recipe of yours as a typed Resource.
- Borrows: genetic_tree_sculptor, CritterDNA, read (understand).
- Check: Editing genes after planting leaves the planted tree unchanged. Contrast: Pass the resource without duplicate: the planted tree changes too.
- Carries forward: A class_name Resource with exported genes, saved as .tres.
- Basis: [M] only 22 files extend Resource; genetic_tree_sculptor already exports a CritterDNA Resource through a signal. [D] a .tres from outside can run scripts: load only your own.

Encounters without a making lesson in this path: `LSystems_Grammars_And_Curves`, `LSystems_Competition`, `LSystems_Shape_Grammars`, `Assemblage_Same_Desire`.

### 16. proceduralgeneration

- **Today [M]:** seven desk guides. The desk they describe (`pg_workshop.gd`) is untracked. The HEAD fragments describe other constructions than the installed works.
- **Proposed [P]:** two making halls, CP6, and a 2D branch.

**83 · PG_Genetic_Evolution** (hall): A genome, a builder, a score
- Lesson: prose-rewrite; curriculum kind build (selection); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `res.custom`, `data.save`, `scene.instancing` (change), `data.rng` (change), `res.shared_unique`.
- Make (worked example): The genome as the Living Resource; a builder instantiates primitive parts from it; a score; the elite saved to user:// so the held witness survives restart.
- In the learner's own work: A generator of yours that keeps its best result across restarts.
- Borrows: GeneticProgramming (@tool), selection_lesson, read (understand).
- Check: The same seed gives the same generation. Contrast: A child mutating a shared genome changes its parent.
- Carries forward: A genome Resource, a builder that instantiates parts from it, and a saved elite.
- Basis: [M] HEAD tutorial modelled walking creatures the installed work does not have; the working tree is desk prose.

**84 · PG_Caves_Mazes** (hall): A route for a particular body
- Lesson: prose-rewrite; curriculum kind build (growth); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `nav.navigation`. Returns: `gd.arrays`, `gd.packed_arrays`, `phys.shapes_layers`, `input.player`, `data.rng`, `editor.run_debug`.
- Make (worked example): Carve a maze (explicit-stack depth-first) or a cave from a seed; bake a NavigationRegion3D with the player's capsule radius as the agent radius; send a NavigationAgent3D to the exit with Debug > Visible Navigation on; report failure and regenerate.
- In the learner's own work: A generated level exhibit with a tested route.
- Borrows: caverandomwalk, maze_generator_vr, read (understand).
- Check: The agent reaches the exit; the navigation overlay shows the baked route. Contrast: A route that exists in the array but is narrower than the capsule: no path.
- Carries forward: A route in the array distinguished from a route for a body.
- Basis: [M] nav.navigation is never taught; Navigation*3D appears in 11 files; Ada's own routing is the Python grid pathfinder.

**85 · CP6_generated_place** at `PG_Caves_Mazes` (checkpoint): A generated place a body can use
- A generator with a reproducible recipe (seed plus parameters saved).
- An inspectable result.
- One editable constraint (corridor width).
- A spawn check, an exit, and a clearance test for the player's own capsule (the navigation agent with the player's radius).
- A route back from a failed generation (reject and regenerate, reported).
- A tagged commit.
- Open task: Rebuild the generator in a fresh exhibit with no kit and no copied code, from your own notes.
- Evidence: the build; a check that fails on a too-narrow corridor; the commit tag.
- Course exit: B: generative game development.
- Basis: Proposal's generator checkpoint and 'Do not equate an attractive generated scene with a finished level'. The rebuild task is critique item 7's.

**86 · PG_Mirrored_Patterns** (hall, optional studio): 2D inside 3D
- Lesson: prose-rewrite; curriculum kind build (growth); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `twod.basics`. Returns: `shader.viewport_feedback`, `ui.world_space`.
- Make (worked example): A 2D cellular field drawn with Node2D inside a SubViewport, its ViewportTexture on a 3D panel; then Trace, grid or walk translated into native 2D (CharacterBody2D, Camera2D, TileMapLayer).
- In the learner's own work: Optional: a 2D screen in the room.
- Borrows: mirror_cellular_texture_for_3d, read (understand).
- Check: The panel updates with the 2D field. Contrast: 2D y points down.
- Carries forward: A 2D field in a SubViewport shown on a 3D panel, and one study redone in native 2D.
- Basis: [M] only 29 files use 2D nodes; [D] Godot's own path teaches 2D first.

Encounters without a making lesson in this path: `PG_Space_Colonization`, `PG_Branching_Growth`, `PG_Percolation_Network`, `PG_Sculpted_Forms`.

### 17. softbodies

- **Today [M]:** nine prose guides that quote `SoftBody3D` properties without naming the class. HEAD taught a hand-written mass-spring solver the halls do not use.
- **Proposed [P]:** two making halls on Godot's own soft body and joints. The character studio moved earlier, to W17. `SoftBodies_Affect_Theory_Visualization` (radiolaria particles) and `ProceduralGeneration_Reaction_Diffusion_Systems` (a SubViewport canvas) are optional returns to particles and feedback.

**87 · SoftBodies_Soft_Body_Deformation** (hall): Godot's own soft body
- Lesson: prose-rewrite; curriculum kind compare (soft); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: `phys.softbody`. Returns: `gd.export`, `phys.bodies`, `mesh.primitive`.
- Make (worked example): A SoftBody3D from a subdivided BoxMesh; two points pinned with set_point_pinned; stiffness, damping and pressure as @export values.
- In the learner's own work: Something soft in an exhibit of yours.
- Borrows: jelly_cube, read (understand).
- Check: RESET of the coefficients does not restore the shape. Contrast: Pressure on an open mesh does not inflate it.
- Carries forward: A SoftBody3D with pinned points and exported coefficients.
- Basis: [M] no tutorial in either state names SoftBody3D, though every soft hall's primary uses it. [D] under Jolt SoftBody3D and Area3D do not interact.

**88 · SoftBodies_Carusell** (hall): Driven and responding
- Lesson: prose-rewrite; curriculum kind compare (soft); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.forces` (change), `space.rotation`, `phys.softbody`, `phys.bodies`, `anim.player` (understand).
- Make (worked example): RigidBody3D and SoftBody3D bodies hung by PinJoint3D from a rotating AnimatableBody3D ring, driven once by an AnimationPlayer track (physics callback) and once in _physics_process; STOP zeroes the command.
- In the learner's own work: A driven ring in an exhibit of yours whose passengers keep responding after it stops.
- Borrows: revolving_joy_ride, read (understand).
- Check: After STOP the bodies keep swinging. Contrast: Freezing the bodies stops them at once.
- Carries forward: PinJoint3D passengers on a ring driven once by animation and once by code.
- Basis: [M] no tutorial introduces PinJoint3D or any Joint3D.

Encounters without a making lesson in this path: `SoftBodies_Cloth_Physics`, `SoftBodies_Obsticals`, `SoftBodies_Obsticals_Part2`, `SoftBodies_Playground_of_Joy`, `SoftBodies_Affect_Theory_Visualization`, `ProceduralGeneration_Reaction_Diffusion_Systems`, `Topology_Entropy_Morphogenesis`.

### 18. isosurfaces

- **Today [M]:** nine working-tree desk rewrites removed HEAD's cumulative extraction arc. Four fragment halls remain, one of them the only compute-shader lesson.
- **Proposed [P]:** four making halls that restore the arc (samples, extractor, brush, walkable cave) with the marching tables supplied. Threads and compute are a branch; compute needs a renderer other than the room's Compatibility.

**89 · ISO_Introduction** (hall): Samples before triangles
- Lesson: prose-rewrite; curriculum kind build (iso); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `data.noise`, `gd.loops`, `mesh.multimesh`, `gd.packed_arrays`.
- Make (worked example): density(p) from FastNoiseLite; a triple loop computing each cell's 8-bit corner mask; the samples shown as a MultiMesh of points before any surface.
- In the learner's own work: A visible field in an exhibit of yours.
- Borrows: voxel_noise_demo, read (understand).
- Check: Moving the level changes which samples count as inside. Contrast: Halving the resolution loses thin parts.
- Carries forward: Field, level, sample and case number as four named parts.
- Basis: [M] working-tree rewrite keeps two quoted lines of HEAD's march() loop; the learner writes nothing today.

**90 · ISO_ShapesGallery** (hall): One extractor, many fields
- Lesson: prose-rewrite; curriculum kind build (iso); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.functions` (change), `mesh.procedural`.
- Make (worked example): extract(field: Callable) -> ArrayMesh through SurfaceTool.generate_normals(), with the triangle table supplied; sphere, torus and gyroid fields; union = min, subtraction = max(a, -b).
- In the learner's own work: A small sculpture of yours made of functions.
- Borrows: TRI_TABLE and edge tables (use).
- Check: Six fields through one extractor. Contrast: A thin handle disappears at low resolution while the formula still contains it.
- Carries forward: Functions passed as values; a reusable extractor.
- Basis: [M] HEAD's extract(field: Callable) fragment was the most extensible in the ISO arc; the working tree quotes compute-shader GLSL instead.

**91 · ISO_Sculpting** (hall, desktop + xr steps): A brush and a dirty region
- Lesson: prose-rewrite; curriculum kind compare (implicit); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.packed_arrays` (change), `perf.budget` (change), `phys.queries` (understand), `xr.interaction`.
- Make (worked example): The field in a PackedFloat32Array with idx(x, y, z); add or erase a spherical brush at the centre-screen ray hit (desktop) or at the controller position (xr route); remesh only the dirty region.
- In the learner's own work: A volume in an exhibit of yours that a visitor can sculpt.
- Borrows: MarchingCubesSculptVR, read (understand).
- Check: Brushing one corner rebuilds only that region. Contrast: Remeshing the whole field per stroke: read the frame time.
- Carries forward: Edits stored as contributions; local rebuilds.
- Basis: [M] HEAD had brush() and remarch_region(); the working tree removed them.

**92 · ISO_Caves** (hall): Inside is one calculation
- Lesson: prose-rewrite; curriculum kind compare (implicit); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.shapes_layers`, `mesh.procedural`, `input.player`.
- Make (worked example): make_walkable(mesh): StaticBody3D + CollisionShape3D from create_trimesh_shape(); winding inverted for an interior; a guaranteed route carved along a Curve3D; walk inside.
- In the learner's own work: A cave exhibit of yours with a route you guaranteed.
- Borrows: marchingcubes_inside_cave, read (understand).
- Check: The player walks the carved route. Contrast: Without inverting the winding the inside faces are culled.
- Carries forward: make_walkable(): a generated interior with its winding inverted and a carved route.
- Basis: [M] HEAD taught make_walkable; the working tree dropped it.

**93 · ISO_CaveGeneration** (hall, optional studio): The main-thread rule
- Lesson: fragment-rewrite; curriculum kind compare (implicit); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `perf.threads`, `other:compute_shader`. Returns: `perf.budget`, `gd.packed_arrays`, `other:renderer_choice`. Names as outside: `other:gdextension`.
- Make (worked example): Read TerrainGeneratorBase: compute dispatch, buffer readback, a Thread that builds vertex arrays, the ArrayMesh and collider built on the main thread. Then move the learner's CPU extraction onto WorkerThreadPool, publish with call_deferred, and wait every task id. The compute part needs a Forward+ or Mobile renderer (RenderingDevice), not the room's Compatibility renderer [K].
- In the learner's own work: Optional: rebuilds that do not stall.
- Borrows: TerrainGeneratorBase and MarchingCubes.glsl (understand).
- Check: Frame time stays flat during a rebuild. Contrast: Adding a node to the tree from the worker thread: an error. A task never waited: a crash at exit.
- Carries forward: Worker threads that build arrays, and a main thread that alone touches the scene tree.
- Basis: [M memory] a dropped WorkerThreadPool task crashed Godot at exit until every id was waited. [M] the only tutorial that teaches compute. Native extensions (GDExtension) are named here as outside the course.

Encounters without a making lesson in this path: `ISO_LookupTable`, `ISO_TorusGyroid`, `ISO_FlatTerrain`, `ISO_PortalLandscape`, `ISO_AnimatedNoise`, `ISO_Metaballs`, `ISO_ImplicitModeling`, `ISO_RhizomeBody`.

### 19. boolean_surfaces

- **Today [M]:** no tutorials at HEAD. The working tree has three untracked prose pages with one code line between them.
- **Proposed [P]:** CSG as an editor blockout tool, then bake to a mesh.

**94 · Boolean_Verbs** (hall): Blockout with verbs
- Lesson: prose-rewrite; curriculum kind build (boolean); tutorial.md untracked. Starts from: my_room (the learner's own project, from W02 on).
- New: `mesh.csg`. Returns: `editor.scene_tree`, `editor.viewport3d` (change), `phys.shapes_layers`.
- Make (worked example): Union, intersection and difference in the editor with a CSGCombiner3D; reorder operands in the Scene dock; place parts by typing transform values; use_collision on; walk into the result.
- In the learner's own work: A shelter exhibit blocked out by hand.
- Check: Reversing a subtraction's operands gives a different solid. Contrast: use_collision off: the shelter is a picture.
- Carries forward: Editor composition in which operand order matters.
- Basis: [M] at HEAD no tutorial names a CSG node; the working-tree tutorial is untracked prose with one code line. [M memory] the museum's walk map cannot see CSG collision.

**95 · Boolean_Works** (hall): Prototype to mesh
- Lesson: prose-rewrite; curriculum kind build (boolean); tutorial.md untracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `mesh.csg` (change), `perf.profiling`, `phys.shapes_layers`.
- Make (worked example): Carve an inhabitable burrow from earlier geometry; bake it to a static mesh plus a trimesh collider; compare live CSG and baked frame cost.
- In the learner's own work: Bake your shelter and keep its opening.
- Borrows: boolean_burrow (UNTRACKED), subtraction_suite (bake_static_mesh), read (understand).
- Check: The baked shelter keeps its opening and its collision. Contrast: Live CSG rebuilt at runtime: the cost.
- Carries forward: A CSG blockout baked into a static mesh with a trimesh collider.
- Basis: [M] boolean_burrow is untracked; subtraction_suite already calls bake_static_mesh().

Encounters without a making lesson in this path: `Boolean_Gallery`.

### 20. swarmintelligence

- **Today [M]:** seven fragment pages written in April. They are abstract 2D code, and the installed works are embodied: `CharacterBody3D` agents, `ImageTexture` trails, `MultiMesh` flocks.
- **Proposed [P]:** three making halls, each optimising only against something measured. `SwarmIntelligence_PhysarumColony` is an optional texture and shader return.

**96 · SwarmIntelligence_FlowFields** (hall): Click a target, follow a field
- Lesson: fragment-rewrite; curriculum kind build (agent); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `phys.queries` (change), `input.events` (change), `nav.navigation`, `gd.arrays`.
- Make (worked example): With the mouse released (the room's UI rule), a click in _unhandled_input casts a ray from the mouse position (project_ray_origin / project_ray_normal) to set a target; a BFS distance field; CharacterBody3D agents follow it; the same obstacles with AStarGrid2D or a NavigationAgent3D for comparison.
- In the learner's own work: Agents in an exhibit of yours that come when called.
- Borrows: FlowFieldMain, FlowAgent, read (understand).
- Check: Agents reach the clicked cell around obstacles. Contrast: Clicking through a UI panel must not set a target.
- Carries forward: A hand-made field beside the engine's navigation.
- Basis: [M] tutorials identical at HEAD and in the working tree (2026-04-24); abstract 2D code, installed work is embodied.

**97 · SwarmIntelligence_Boids_Algorithm** (hall): From nodes to one MultiMesh
- Lesson: fragment-rewrite; curriculum kind build (agent); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `mesh.multimesh`, `perf.budget`, `perf.profiling`, `gd.classes`, `space.vector3` (change).
- Make (worked example): Boids first as one Node each, then as data in arrays drawn by one MultiMeshInstance3D with a spatial hash; profile at 50, 500 and 2000.
- In the learner's own work: A flock exhibit, optimised only after it was measured.
- Borrows: boids_aquarium (already contains both steps), read (understand).
- Check: The spatial hash keeps frame time flat as N grows. Contrast: All-pairs neighbour search: O(N^2) in the Profiler.
- Carries forward: An optimisation made against a measured problem.
- Basis: [M] tutorial says 'spatial partitioning reduces this' without teaching it.

**98 · SwarmIntelligence_Agent_Based_Modeling_ABM** (hall): An agent with states and a sensor
- Lesson: fragment-rewrite; curriculum kind build (agent); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.const_enum` (change), `phys.areas`, `scene.groups_paths`, `input.player`.
- Make (worked example): A CharacterBody3D agent with enum states and match; an Area3D perception sensor replaces the all-pairs group scan.
- In the learner's own work: Agents in an exhibit of yours that notice the player.
- Check: The agent changes state when the player enters its sensor. Contrast: get_nodes_in_group scanning every frame: the cost.
- Carries forward: An agent whose enum state changes when a body enters its Area3D sensor.
- Basis: [M] no installed work matches the tutorial; its reset calls initialise_swarm(), defined only in the PSO tutorial two halls later.

Encounters without a making lesson in this path: `SwarmIntelligence_PhysarumColony`, `SwarmIntelligence_Ant_Colony_Optimization`, `SwarmIntelligence_Particle_Swarm_Optimization`, `SwarmIntelligence_Swarm_Intelligence_Algorithms`.

### 21. machinelearning

- **Today [M]:** eight April fragment pages, none runnable. `ML_Evolution` and `ML_Synthesis` teach something other than their hall's primary work.
- **Proposed [P]:** two making halls, where training state becomes saved data and a claim about learning becomes a test. `ML_Neural_Networks`, trained in Timer-driven batches, is optional.

**99 · ML_Classification** (hall): A decision field you can save
- Lesson: fragment-rewrite; curriculum kind build (learning); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `mat.textures`, `ui.controls`, `data.save`, `gd.functions`, `input.actions`.
- Make (worked example): k-means stepped by a Button and an action; a predict(Vector2) Callable painted into an Image on a floor quad; the session saved to and loaded from user:// JSON.
- In the learner's own work: A classifier exhibit the visitor can step and keep.
- Borrows: enhanced_kmeans (FileAccess sessions), read (understand).
- Check: Reloading restores the clusters. Contrast: SimpleNN.forward on weights nobody initialised: crash (the tutorial's own bug).
- Carries forward: Training state kept as saveable data.
- Basis: [M] all 8 ML tutorials identical at HEAD and working tree (2026-04-24), none runnable as written.

**100 · ML_Perception** (hall): A convergence you can assert
- Lesson: fragment-rewrite; curriculum kind build (network); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `test.checks` (understand), `gd.loops`, `gd.arrays`.
- Make (worked example): Perceptron.train() returns true on convergence; a headless check asserts AND converges and XOR does not.
- In the learner's own work: A check in checks/ for one claim your room makes about learning or convergence.
- Check: AND passes, XOR fails, as predicted. Contrast: Remove the epoch cap: XOR never returns.
- Carries forward: A claim about learning written as a test.
- Basis: [M] tutorial is complete enough to run once dataset entries are constructed.

Encounters without a making lesson in this path: `ML_Evolution`, `ML_Gradient_Landscape`, `ML_Neural_Networks`, `ML_Sequence_Memory`, `ML_Generative`, `ML_Synthesis`.

### 22. graphtheory

- **Today [M]:** eight April fragment pages. The `Graph` class never defines the `neighbours()` it is called with. No spine tutorial mentions the engine's A*.
- **Proposed [P]:** three making halls that open the route machinery the learner already used at `PG_Caves_Mazes`, drawn over the learner's own hub of exhibits.

**101 · GT_Foundations** (hall): Data and view apart
- Lesson: fragment-rewrite; curriculum kind build (graph); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.classes`, `scene.nodes_resources` (understand), `gd.dictionaries`.
- Make (worked example): A RefCounted Graph (vertices, edges, adjacency, neighbours()) and a separate GraphView Node3D that draws it with the Point_Lines segment variant.
- In the learner's own work: A graph of your own exhibits, drawn from the hub's doors.
- Borrows: the learner's segment variant from Point_Lines (understand).
- Check: Changing the data redraws the view. Contrast: add_child() on a RefCounted: an error (data is not a node).
- Carries forward: A RefCounted Graph and a separate Node3D view that redraws from it.
- Basis: [M] the tutorial's Graph is RefCounted yet calls add_child; neighbours() is called in three halls and defined in none.

**102 · GT_Pathfinding** (hall): Open the route machinery
- Lesson: fragment-rewrite; curriculum kind build (path); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `nav.navigation` (change), `gd.arrays`, `gd.functions`.
- Make (worked example): Hand-written BFS beside an AStar3D; disable a point and query again, as impatient_river does; path drawn with the segment variant.
- In the learner's own work: A route between your exhibits that changes when a door closes.
- Borrows: impatient_river (AStar3D), read (understand).
- Check: Disabling a point changes the returned path. Contrast: An unreachable goal: an empty path, handled.
- Carries forward: The engine's A* opened and compared with a hand-written search.
- Basis: [M] the tutorial's PriorityQueue does not exist in Godot; no spine tutorial mentions AStar3D, AStarGrid2D or navigation.

**103 · GT_Network_Analysis** (hall): Colour by a measure
- Lesson: fragment-rewrite; curriculum kind build (path); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `res.shared_unique`, `mat.standard` (change), `gd.dictionaries` (change).
- Make (worked example): Colour each vertex by a centrality with its own material.
- In the learner's own work: Your graph shows its hubs, and you say what the measure leaves out.
- Check: Each vertex keeps its own colour. Contrast: The tutorial's version: material_override is null (crash) or shared (every node recolours).
- Carries forward: Shared versus unique, as a bug the learner can recognise.
- Basis: [M] colour_by_centrality treats material_override as a StandardMaterial3D that GT_Foundations never assigned.

Encounters without a making lesson in this path: `GT_Layout`, `GT_Connectivity`, `GT_Spanning_Trees`, `GT_Flow`, `GT_Matching`.

### 23. foundationscrisis

- **Today [M]:** eight April controller fragments. Three preload scenes that do not exist, and some pages carry stray generator tokens.
- **Proposed [P]:** every hall here is kind "reflect" in `curriculum.json` (nodes `assumption` and `limit`, whose borrow says "no forced coding quota"). The three studios on budgets, viewpoint and validation are optional. `Euclid_Parallel`'s plaque-emits-read signal is an optional return to W05.

**104 · Godel_Incompleteness** (hall, optional studio): Not found within budget
- Lesson: fragment-rewrite; curriculum kind reflect (limit); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `perf.budget`, `gd.async`, `ui.world_space`.
- Make (worked example): Optional. A search spread over frames with an explicit step budget and a cancel; the readout distinguishes 'not found within budget' from 'no answer'.
- In the learner's own work: Optional: a search of yours that can be stopped and says honestly why it stopped.
- Check: Cancel stops within one frame. Contrast: The same search in one loop: the frame stalls.
- Carries forward: A readout that separates 'not found within the budget' from 'no answer exists'.
- Basis: [M] tutorial fragments; [I] its prime-power encoding overflows 64-bit integers silently. curriculum node 'limit' is kind reflect: 'no forced coding quota'.

**105 · Escher_Impossible** (hall, optional studio, desktop + xr steps): A picture that needs a viewpoint
- Lesson: fragment-rewrite; curriculum kind reflect (limit); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `cam.camera3d`, `space.vector3`, `gd.signals_own`.
- Make (worked example): Optional. Read get_viewport().get_camera_3d() each frame and emit viewpoint_locked when the camera is aligned with the illusion's axis.
- In the learner's own work: Optional: an object of yours that only works from one place.
- Borrows: penrose_triangle, read (understand).
- Check: The signal fires when aligned. Contrast: In XR the tracked head moves the viewpoint: the tolerance must be wider.
- Carries forward: Logic that depends on where the camera is.
- Basis: [M] cam.camera3d is first taught today at this hall (spine 23); the tutorial's build_corners never fills its array. curriculum 'limit' is kind reflect.

**106 · Brouwer_Intuitionism** (hall, optional studio): Validate what you were given
- Lesson: fragment-rewrite; curriculum kind reflect (limit); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `res.custom`, `gd.errors`, `test.checks`.
- Make (worked example): Optional. Propositions as .tres custom Resources with required steps; validate() reports what is missing with push_error; a headless check loads every .tres and asserts.
- In the learner's own work: Optional: validation for your saved recipes.
- Check: A complete proposition passes; an incomplete one lists its missing steps. Contrast: A shared steps array between two propositions (shared resource) corrupts both.
- Carries forward: Validation that names what is missing.
- Basis: [M] the tutorial's preload res://commons/artifacts/foundations/proof_block.tscn does not exist; first 'extends Resource' in the spine. curriculum 'limit' is kind reflect.

Encounters without a making lesson in this path: `Euclid_Parallel`, `NonEuclidean_Spaces`, `Russell_Paradox`, `Florensky_Paraconsistent`, `Crisis_Synthesis`.

### 24. qfeplaboratory

- **Today [M]:** six April fragments. `QFEP_Phi_Term` has the only custom `signal` in any spine tutorial and never connects it. `QFEP_Sandbox` and `QFEP_Synthesis` are 9- and 7-line visitor instructions, and their Godot content sits in `technical.md`.
- **Proposed [P]:** `QFEP_Phi_Term` (kind reflect) is an optional studio. `QFEP_Sandbox` (kind compare) is the last main making hall: explicit wiring, a cut, and `UndoRedo` commands, whose undo does not undo what a cut connection delivered.

**107 · QFEP_Phi_Term** (hall, optional studio): Declare, emit, connect
- Lesson: fragment-rewrite; curriculum kind reflect (proxy); tutorial.md tracked. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.signals_own`, `gd.export`.
- Make (worked example): Optional. A dial that clamps in a setter and emits phi_changed(value); connect it to two receivers; the tutorial's missing connect() is the lesson.
- In the learner's own work: Optional: a control of yours with two listeners.
- Check: Both receivers respond. Contrast: Emit without connect: nothing, and no error.
- Carries forward: A declared signal that reaches two receivers.
- Basis: [M] the only custom signal declaration in any spine tutorial, with no connect(); morph_target.blend_shapes and .metallic are not MeshInstance3D properties. curriculum 'proxy' is kind reflect.

**108 · QFEP_Sandbox** (hall): Explicit wiring, a cut, and an undo
- Lesson: prose-rewrite; curriculum kind compare (coupling); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `scene.groups_paths`, `gd.signals_own`, `tool.editor`, `data.undo` (use).
- Make (worked example): Two handles wired to one receiver through a console that can CUT and CONNECT delivery; each CUT and CONNECT goes through UndoRedo (create_action, add_do_method, add_undo_method, commit_action). Then the same wiring by group lookup, with a misspelled group. Branch: an EditorInspectorPlugin for the reactor.
- In the learner's own work: Give one editing tool of yours an undo made of commands, and say what the undo does not undo.
- Borrows: technical.md's account of the 'qfep_slider' group that matched nothing (understand).
- Check: CUT keeps the last delivered values. Undoing a CUT restores the connection and does not restore the values delivered while it was cut. Contrast: A group lookup with a typo matches nothing, silently. Symmetry_Seventeen's snapshots kept states; UndoRedo keeps commands.
- Carries forward: References chosen over discovery; undo as commands.
- Basis: [M] working-tree tutorial is 9 lines of visitor instructions; the Godot content lives in technical.md. curriculum 'coupling' is kind compare, transfer: 'Cut a route without assuming its previous effect is undone.' [M] no runtime code uses UndoRedo; the Map Tool 3D editor plugin does (addons/map_tool_3d/map_tool_3d_plugin.gd l.143-200, tracked).

Encounters without a making lesson in this path: `QFEP_Introduction`, `QFEP_F_Term`, `QFEP_E_Term`, `QFEP_Lambda_Spectrum`, `QFEP_Edge_Of_Chaos`, `QFEP_Synthesis`.

### 25. postfoundationscrisis

- **Today [M]:** eight September essays with one verified excerpt each and no making.
- **Proposed [P]:** every hall is kind "reflect" (nodes `situation` and `assembly`), so the four studios are optional. W18 and CP7 sit at `PostCrisis_Synthesis` because `assembly.make` is "A first independent work built from selected earlier capabilities"; W18 adds no new capability. The working tree already has the data link the optional studio reads: the Assembly Laboratory pose is saved to `user://` and read back by `assembly_return` and by the ledger's `visitor_record` mode.

Reflect halls and what this plan does at them:

| stop | curriculum kind | in this plan |
|---|---|---|
| Primitives_Melencolia | reflect (geometry_return) | main, no new code |
| Godel_Incompleteness | reflect (limit) | optional studio |
| Escher_Impossible | reflect (limit) | optional studio |
| Brouwer_Intuitionism | reflect (limit) | optional studio |
| QFEP_Phi_Term | reflect (proxy) | optional studio |
| CriticalAlgorithms_Applied_Ethics | reflect (situation) | optional studio |
| SpeculativeComputation_Collective_Knowledge | reflect (situation) | optional studio |
| AdvancedLaboratory_Lab_Equipment_Simulation | reflect (assembly) | optional studio |
| PostCrisis_Synthesis | reflect (assembly) | optional studio |

**109 · CriticalAlgorithms_Applied_Ethics** (hall, optional studio): Check who can see
- Lesson: prose-rewrite; curriculum kind reflect (situation); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `access.a11y`, `phys.queries`, `gd.loops`.
- Make (worked example): Optional. Generate seating layouts in a loop, then raycast a sightline from every seat to an interpreter point; report blocked seats.
- In the learner's own work: Optional: a sightline check for one of your exhibits.
- Borrows: room_shape_demonstrator, read (understand).
- Check: Blocked seats are listed. Contrast: Equal spacing does not guarantee sightlines.
- Carries forward: A list of seats whose sightline a raycast found blocked.
- Basis: [M] the tutorial names sightlines but tests none. curriculum 'situation' is kind reflect.

**110 · SpeculativeComputation_Collective_Knowledge** (hall, optional studio): History with sources
- Lesson: prose-rewrite; curriculum kind reflect (situation); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `data.undo`, `gd.dictionaries`, `mesh.multimesh`. Names as outside: `net.multiplayer`.
- Make (worked example): Optional. Each piece carries a provenance record (source, time); DISPUTE and REVISE reuse the QFEP_Sandbox UndoRedo, so the history is browsable and each step names who made it.
- In the learner's own work: Optional: provenance on your undo history.
- Borrows: peer_production_tool, read (understand).
- Check: Undo, then redo, returns the same arrangement and source. Contrast: A snapshot-only history (Symmetry) keeps states, not who changed them.
- Carries forward: An undo history in which each step records who made it.
- Basis: [M] The hall says it is 'not a live collaborative editor': networking is named here as outside. curriculum 'situation' is kind reflect.

**111 · AdvancedLaboratory_Lab_Equipment_Simulation** (hall, optional studio): Rates, and a pose that returns
- Lesson: prose-rewrite; curriculum kind reflect (assembly); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `gd.lifecycle`, `test.checks`, `phys.forces`.
- Make (worked example): Optional. The docking spring run at two physics rates and its damping made correct for delta; read how AssemblyPoseRecord.gd saves a released pose through a .tmp file and a rename (the pattern W18 uses).
- In the learner's own work: Optional: one of your springs made rate-independent.
- Borrows: Part.gd, AssemblyPoseRecord.gd, read (understand).
- Check: Same settle time at 60 and 90 Hz. Contrast: Per-frame damping disagrees across rates.
- Carries forward: A spring whose settle time does not depend on the physics rate.
- Basis: [M] AssemblyPoseRecord.gd writes user://ada_research/assembly_pose.json via .tmp and rename (working tree); the tutorial does not mention the body study. curriculum 'assembly' is kind reflect.

**112 · PostCrisis_Synthesis** (hall, optional studio): A record read in another room
- Lesson: prose-rewrite; curriculum kind reflect (assembly); tutorial.md modified. Starts from: my_room (the learner's own project, from W02 on).
- New: none. Returns: `data.save`, `scene.change`, `scene.autoload`.
- Make (worked example): Optional. Read back, in this exhibit, a record written in another exhibit (user:// file plus session state): counting versus remembering.
- In the learner's own work: Optional: two of your exhibits that remember each other.
- Borrows: accountability_ledger visitor_record mode, assembly_return, read (understand).
- Check: The record written in exhibit A appears in exhibit B after a restart. Contrast: A counter that survives while its evidence (the ring buffer) does not.
- Carries forward: A user:// record written in one exhibit and read in another.
- Basis: [M] the working-tree map enables visitor_record; the tutorial still describes prewritten lines every six seconds. curriculum 'assembly' is kind reflect; its make is 'A first independent work built from selected earlier capabilities', which CP7 carries.

**113 · W18_release** at `PostCrisis_Synthesis` (workshop, desktop + xr steps): Release
- Lesson: new-page. Starts from: my_room (the learner's own project, from W02 on).
- Why here: PostCrisis_Synthesis is kind assembly, whose make is 'A first independent work built from selected earlier capabilities'. The release completes that work; it adds no new capability, only returns. Distribution already appeared at W06 and CP3.
- New: none. Returns: `export.build`, `access.a11y` (change), `editor.version_control` (change), `data.save` (change), `xr.setup`, `other:renderer_choice`, `gd.errors` (change).
- Make (worked example): Desktop and (xr route) Quest builds with explicit include/exclude filters; the settings file becomes versioned and atomic (write settings.tmp, then rename; a version field; validation and a named fallback on load); credits with licences; a tagged release; instructions for a player outside the developer's machine.
- In the learner's own work: Choose what your release promises a player, and test that promise on someone else.
- Check: A person who has never seen the project installs, plays, changes a setting and finds it kept. A settings file from the previous version loads or falls back by name. Contrast: A build missing a runtime data file because of a filter. A write killed half-way leaves the old settings intact.
- Carries forward: A release route and a save format that can change.
- Basis: [M] the spine's last tutorial ends on a proposed experiment, not a release; the course project has no desktop preset. AssemblyPoseRecord.gd already writes through .tmp and rename.

**114 · CP7_release** at `PostCrisis_Synthesis` (checkpoint): A small complete world
- An independently authored small but complete game or exploratory world (curriculum assembly.make).
- Source and a reproducible build route.
- Settings that persist through a versioned save; undo with commands for one editing tool.
- An account of one decision revised after another person's encounter.
- A tagged release.
- Open task: Name one promise the work makes, test it bodily, and revise the responsible operation (curriculum assembly.transfer).
- Evidence: the release; the account.
- Course exit: C: systems and artistic research.
- Basis: Proposal's final work; curriculum node 'assembly'.

Encounters without a making lesson in this path: `CriticalAlgorithms_Algorithmic_Bias_Visualization`, `SpeculativeComputation_Paraconsistent_Engineering`, `SpeculativeComputation_Situated_Computation`, `SpeculativeComputation_Rhizome_Network`.

---

## 4. Coverage [P]

Placement key:

- **main:** every learner on the path meets it (on the xr route for the two xr capabilities).
- **branch:** an optional studio or an optional step at a named stop.
- **outside:** named as a boundary and not taught.

"Depth at first" is the depth at the first meeting; "deepest on main" is the greatest depth any main stop sets, and where. The "requires met?" column checks the survey's prerequisite graph against this path's order; the two exceptions are explained in A.1.

| capability | first stop | depth at first | deepest on main (where) | placement | route | returns at | requires met? |
|---|---|---|---|---|---|---|---|
| `editor.project` | day_zero | understand | understand (day_zero) | main | both | W02_scene_from_nothing, W03_known_revision, W06_export_it | yes |
| `editor.run_debug` | day_zero | use | change (W16_checks_without_you) | main | both | Point_Zero, Point_One, Point_Coordinates, Point_Lines, W01_break_it_on_purpose, W08_headset_day, W11_two_rooms, Color_Rainbow, W16_checks_without_you, CA_GameOfLife, LSystems_Architecture, PG_Caves_Mazes | yes |
| `editor.scene_tree` | day_zero | use | change (W15_many_rooms) | main | both | Point_Coordinates, W02_scene_from_nothing, W15_many_rooms, Boolean_Verbs | yes |
| `other:csharp_dotnet` | day_zero | - | - | outside | both | none | yes |
| `gd.functions` | Point_Zero | use | change (ISO_ShapesGallery) | main | both | Point_Lines, Point_Trace, Point_Line_Grid, Point_Triangle_Context, Point_Animatedcube, Primitives_Portals, W05_signal_and_door, Trans_Introduction, Tutorial_Pattern, Symmetry_Seventeen, Change_Intro, Random_Definition, Fractal_Recursion, ISO_ShapesGallery, ML_Classification, GT_Pathfinding | yes |
| `gd.lifecycle` | Point_Zero | use | understand (Change_Intro) | main | both | Point_One, Point_Lines, Point_Trace, Point_Animatedcube, Trans_Pre, W07_body_and_camera, Trans_Pit, Tutorial_Disco, Change_Intro, VFM_03_Motion, Vectors_Act3_FieldsAndMotion, FormFinding_Descent, WaveFunctions_Intro, Random_Walk, AdvancedLaboratory_Lab_Equipment_Simulation | yes |
| `gd.strings` | Point_Zero | use | change (LSystems_Grammar_Lab) | main | both | Point_Lines, LSystems_Grammar_Lab | yes |
| `gd.variables` | Point_Zero | use | understand (Point_Lines) | main | both | Point_Lines, Color_Rainbow | yes |
| `scene.groups_paths` | Point_Zero | use | change (W15_many_rooms) | main | both | Trans_Translation, Trans_Pit, W14_game_in_headset, W15_many_rooms, SwarmIntelligence_Agent_Based_Modeling_ABM, QFEP_Sandbox | yes |
| `mesh.primitive` | Point_One | understand | understand (Point_One) | main | both | W02_scene_from_nothing, Primitives_Ignorance, Color_Context_Placed, SoftBodies_Soft_Body_Deformation | yes |
| `phys.bodies` | Point_One | use | understand (Trans_Rotation) | main | both | W02_scene_from_nothing, Trans_Introduction, W07_body_and_camera, Trans_Rotation, Trans_Pit, VFM_03_Motion, FormFinding_Equilibrium, FormFinding_Forge, CA_GameOfLife, LSystems_Architecture, SoftBodies_Soft_Body_Deformation, SoftBodies_Carusell | no, see A.1 |
| `phys.shapes_layers` | Point_One | use | change (VFM_03_Motion) | main | both | Point_Coordinates, W02_scene_from_nothing, Primitives_Polythedra, W05_signal_and_door, W07_body_and_camera, Trans_Translation, Color_Paint, VFM_03_Motion, Random_Remove, Noise_One, Noise_Space_10, Shader_09_FBM, CA_GameOfLife, Fractal_MengerSponge, LSystems_Architecture, PG_Caves_Mazes, ISO_Caves, Boolean_Verbs, Boolean_Works | yes |
| `scene.nodes_resources` | Point_One | use | understand (Color_Context_Placed) | main | both | W02_scene_from_nothing, Color_Context_Placed, GT_Foundations | yes |
| `editor.viewport3d` | Point_Coordinates | use | change (Boolean_Verbs) | main | both | W02_scene_from_nothing, Primitives_Melencolia, Boolean_Verbs | yes |
| `space.transform` | Point_Coordinates | use | change (Fractal_RecursiveTrees) | main | both | Trans_Introduction, W07_body_and_camera, Trans_Translation, W08_headset_day, W09_room_in_headset, Color_Paint, VFM_03_Motion, Fractal_RecursiveTrees, LSystems_Growth | yes |
| `space.vector3` | Point_Coordinates | use | change (SwarmIntelligence_Boids_Algorithm) | main | both | Point_Lines, Point_Trace, Point_Triangle_Context, Primitives_Polythedra, Point_Animatedcube, Color_Paint, Vectors_Act3_FieldsAndMotion, SwarmIntelligence_Boids_Algorithm, Escher_Impossible | yes |
| `xr.interaction` | Point_Coordinates | use | understand (W14_game_in_headset) | main | xr | W14_game_in_headset, WaveFunctions_Intro, ISO_Sculpting | no, see A.1 |
| `gd.conditions` | Point_Lines | use | change (Trans_Pit) | main | both | Point_Trace, W01_break_it_on_purpose, W05_signal_and_door, Trans_Pit, Tutorial_Tiling_Floor, FormFinding_Descent, FormFinding_Forge, WaveFunctions_Intro | yes |
| `gd.arrays` | Point_Trace | use | change (CA_Introduction) | main | both | W01_break_it_on_purpose, Point_Line_Grid, Point_Triangle_Context, Point_Animatedcube, Primitives_Ignorance, Array, Tutorial_Pattern, Symmetry_Seventeen, Vectors_Act3_FieldsAndMotion, CA_Introduction, Fractal_Recursion, LSystems_Growth, PG_Caves_Mazes, SwarmIntelligence_FlowFields, ML_Perception, GT_Pathfinding | yes |
| `gd.loops` | Point_Trace | use | change (Fractal_Recursion) | main | both | W01_break_it_on_purpose, Point_Line_Grid, Primitives_Portals, Array, Tutorial_Tiling_Floor, Tutorial_Disco, Color_Context_Placed, Color_Rainbow, WaveFunctions_Effect_Sound, Random_Definition, Fractal_Recursion, ISO_Introduction, ML_Perception, CriticalAlgorithms_Applied_Ethics | yes |
| `gd.typing` | Point_Trace | use | change (CA_Introduction) | main | both | W01_break_it_on_purpose, CA_Introduction | yes |
| `input.actions` | Point_Trace | use | understand (W07_body_and_camera) | main | both | Point_Animatedcube, W05_signal_and_door, W07_body_and_camera, W10_pause_and_retry, Color_Flashlight, Color_Rainbow, ML_Classification | yes |
| `gd.errors` | W01_break_it_on_purpose | use | change (W18_release) | main | both | Array, Pattern_Foundry, W16_checks_without_you, LSystems_Growth, Brouwer_Intuitionism, W18_release | yes |
| `other:docs_lookup` | W01_break_it_on_purpose | use | use (W01_break_it_on_purpose) | main | both | none | yes |
| `light.env` | W02_scene_from_nothing | use | change (Shader_11_QueerRubber) | main | both | Point_Triangle_Context, W05_signal_and_door, Primitives_Melencolia, Color_Flashlight, Shader_11_QueerRubber | yes |
| `scene.instancing` | W02_scene_from_nothing | use | change (PG_Genetic_Evolution) | main | both | Primitives_Polythedra, Point_Animatedcube, Primitives_Ignorance, W04_import_one_thing, W05_signal_and_door, Primitives_Melencolia, Trans_Pre, Array, W15_many_rooms, Change_Choreography, Random_Game, PG_Genetic_Evolution | yes |
| `scene.new_scene` | W02_scene_from_nothing | understand | understand (W02_scene_from_nothing) | main | both | Primitives_Polythedra | yes |
| `editor.version_control` | W03_known_revision | use | change (Tutorial_Disco) | main | both | W04_import_one_thing, W06_export_it, Tutorial_Disco, W15_many_rooms, W18_release | yes |
| `mat.standard` | Point_Triangle_Context | use | change (GT_Network_Analysis) | main | both | W04_import_one_thing, Primitives_Melencolia, Color_Context_Placed, Color_Flashlight, Color_Nails, W12_particles, Random_Definition, GT_Network_Analysis | yes |
| `mesh.procedural` | Point_Triangle_Context | use | change (Noise_Space_10) | main | both | Primitives_Polythedra, Point_Animatedcube, Color_Rainbow, Change_Intro, Vectors_Act3_FieldsAndMotion, FormFinding_Descent, Random_Walk, Noise_Columns, Noise_One, Noise_Space_10, LSystems_Grammar_Lab, ISO_ShapesGallery, ISO_Caves | yes |
| `gd.packed_arrays` | Primitives_Polythedra | use | change (ISO_Sculpting) | main | both | Point_Animatedcube, WaveFunctions_Effect_Sound, Noise_Space_10, CA_Introduction, PG_Caves_Mazes, ISO_Introduction, ISO_Sculpting, ISO_CaveGeneration | yes |
| `gd.export` | Primitives_Ignorance | understand | change (Fractal_RecursiveTrees) | main | both | Trans_Pre, Color_Context_Placed, Change_Intro, Fractal_RecursiveTrees, LSystems_Living, SoftBodies_Soft_Body_Deformation, QFEP_Phi_Term | yes |
| `assets.import` | W04_import_one_thing | understand | understand (W04_import_one_thing) | main | both | Trans_Rotation, W17_character_studio | yes |
| `mat.textures` | W04_import_one_thing | use | change (Color_Paint) | main | both | Tutorial_Tiling_Floor, Color_Paint, Pattern_Foundry, Tutorial_Pattern, Symmetry_Seventeen, Shader_11_QueerRubber, ML_Classification | yes |
| `gd.signals_own` | W05_signal_and_door | understand | change (WaveFunctions_Intro) | main | both | Trans_Translation, Trans_Pit, W10_pause_and_retry, Color_Nails, W11_two_rooms, W12_particles, FormFinding_Forge, WaveFunctions_Intro, LSystems_Grammar_Lab, LSystems_Living, Escher_Impossible, QFEP_Phi_Term, QFEP_Sandbox | yes |
| `cam.camera3d` | Primitives_Melencolia | use | understand (W07_body_and_camera) | main | both | W07_body_and_camera, W08_headset_day, Color_Flashlight, Escher_Impossible | yes |
| `export.build` | W06_export_it | understand | change (W08_headset_day) | main | both | W08_headset_day, Pattern_Foundry, W18_release | yes |
| `other:renderer_choice` | W06_export_it | use | understand (W08_headset_day) | main | both | W08_headset_day, W12_particles, VFM_03_Motion, ISO_CaveGeneration, W18_release | yes |
| `space.interpolation` | Trans_Pre | understand | understand (Trans_Pre) | main | both | Trans_Pit | yes |
| `space.rotation` | Trans_Pre | use | understand (Trans_Rotation) | main | both | Trans_Rotation, SoftBodies_Carusell | yes |
| `input.events` | W07_body_and_camera | use | change (SwarmIntelligence_FlowFields) | main | both | W10_pause_and_retry, W13_settings, Color_Paint, SwarmIntelligence_FlowFields | yes |
| `input.player` | W07_body_and_camera | use | understand (Vectors_Act5_ForceAsPlace) | main | both | Trans_Rotation, Vectors_Act5_ForceAsPlace, Noise_One, Noise_Space_10, CA_GameOfLife, LSystems_Architecture, PG_Caves_Mazes, ISO_Caves, SwarmIntelligence_Agent_Based_Modeling_ABM | yes |
| `anim.tween` | Trans_Translation | use | use (Trans_Translation) | main | both | Trans_Pit, FormFinding_Forge | yes |
| `other:path3d_curves` | Trans_Translation (optional step) | use | use (Trans_Translation) | branch | both | none | yes |
| `phys.areas` | Trans_Translation | understand | change (Vectors_Act5_ForceAsPlace) | main | both | Color_Rainbow, W12_particles, Vectors_Act5_ForceAsPlace, WaveFunctions_AirMusic, SwarmIntelligence_Agent_Based_Modeling_ABM | yes |
| `scene.lifetime` | Trans_Translation | use | change (Change_Choreography) | main | both | Array, W11_two_rooms, Change_Choreography, Vectors_Act5_ForceAsPlace, Random_Remove, Random_Game | yes |
| `anim.player` | Trans_Rotation | use | understand (SoftBodies_Carusell) | main | both | W17_character_studio, SoftBodies_Carusell | yes |
| `audio.playback` | Trans_Rotation | use | change (WaveFunctions_AirMusic) | main | both | Array, WaveFunctions_Effect_Sound, WaveFunctions_AirMusic, Random_Game | yes |
| `xr.setup` | W08_headset_day | use | understand (W09_room_in_headset) | main | xr | W09_room_in_headset, W14_game_in_headset, W18_release | yes |
| `design.loop` | Trans_Pit | use | change (Random_Game) | main | both | W10_pause_and_retry, Vectors_Act5_ForceAsPlace, FormFinding_Forge, Random_Game | yes |
| `gd.classes` | Trans_Pit | understand | change (Change_Choreography) | main | both | W11_two_rooms, Change_Choreography, LSystems_Grammar_Lab, LSystems_Living, SwarmIntelligence_Boids_Algorithm, GT_Foundations | yes |
| `gd.const_enum` | Trans_Pit | understand | change (SwarmIntelligence_Agent_Based_Modeling_ABM) | main | both | Change_Intro, Change_Choreography, FormFinding_Descent, Random_Game, SwarmIntelligence_Agent_Based_Modeling_ABM | yes |
| `other:pause_process_mode` | W10_pause_and_retry | use | use (W10_pause_and_retry) | main | both | W13_settings, Change_Intro | yes |
| `scene.change` | W10_pause_and_retry | use | change (W15_many_rooms) | main | both | W11_two_rooms, W15_many_rooms, PostCrisis_Synthesis | yes |
| `ui.controls` | W10_pause_and_retry | use | understand (W13_settings) | main | both | Color_Nails, Color_Grid_Pallet, W13_settings, FormFinding_Descent, Shader_01_Shaping, ML_Classification | yes |
| `mesh.gridmap` | Array (optional step) | understand | understand (Array) | branch | both | none | yes |
| `mesh.multimesh` | Tutorial_Disco | use | change (Fractal_MengerSponge) | main | both | W12_particles, Color_Grid_Pallet, CA_Introduction, Fractal_MengerSponge, ISO_Introduction, SwarmIntelligence_Boids_Algorithm, SpeculativeComputation_Collective_Knowledge | yes |
| `perf.profiling` | Tutorial_Disco | use | change (Noise_Columns) | main | both | Color_Flashlight, W12_particles, Random_Walk, Noise_Columns, CA_GameOfLife, Fractal_MengerSponge, Boolean_Works, SwarmIntelligence_Boids_Algorithm | yes |
| `gd.dictionaries` | Color_Context_Placed | understand | change (GT_Network_Analysis) | main | both | Color_Grid_Pallet, Pattern_Foundry, Vectors_Act5_ForceAsPlace, Random_Remove, LSystems_Grammar_Lab, LSystems_Growth, GT_Foundations, GT_Network_Analysis, SpeculativeComputation_Collective_Knowledge | yes |
| `res.shared_unique` | Color_Context_Placed | understand | change (LSystems_Living) | main | both | Color_Nails, Pattern_Foundry, Symmetry_Seventeen, Shader_01_Shaping, LSystems_Living, PG_Genetic_Evolution, GT_Network_Analysis | yes |
| `scene.autoload` | W11_two_rooms | understand | understand (W11_two_rooms) | main | both | W15_many_rooms, PostCrisis_Synthesis | yes |
| `fx.particles` | W12_particles | understand | understand (W12_particles) | main | both | Random_Game | yes |
| `ui.world_space` | Color_Grid_Pallet | understand | change (W14_game_in_headset) | main | both | W14_game_in_headset, Shader_01_Shaping, PG_Mirrored_Patterns, Godel_Incompleteness | yes |
| `access.a11y` | W13_settings | use | change (W18_release) | main | both | W14_game_in_headset, WaveFunctions_AirMusic, CriticalAlgorithms_Applied_Ethics, W18_release | yes |
| `ui.layout` | W13_settings | understand | understand (W13_settings) | main | both | WaveFunctions_AirMusic | yes |
| `phys.queries` | Color_Paint | use | change (SwarmIntelligence_FlowFields) | main | both | W14_game_in_headset, ISO_Sculpting, SwarmIntelligence_FlowFields, CriticalAlgorithms_Applied_Ethics | yes |
| `data.save` | Pattern_Foundry | use | change (W18_release) | main | both | WaveFunctions_AirMusic, Random_Definition, LSystems_Living, PG_Genetic_Evolution, ML_Classification, PostCrisis_Synthesis, W18_release | yes |
| `shader.spatial` | Tutorial_Pattern | use | change (Shader_09_FBM) | main | both | Shader_01_Shaping, Shader_11_QueerRubber, Shader_09_FBM, Shader_10_ReactionDiffusion | yes |
| `data.undo` | Symmetry_Seventeen | understand | understand (Symmetry_Seventeen) | main | both | QFEP_Sandbox, SpeculativeComputation_Collective_Knowledge | yes |
| `phys.forces` | VFM_03_Motion | use | change (SoftBodies_Carusell) | main | both | FormFinding_Equilibrium, SoftBodies_Carusell, AdvancedLaboratory_Lab_Equipment_Simulation | yes |
| `test.checks` | W16_checks_without_you | use | understand (ML_Perception) | main | both | FormFinding_Descent, ML_Perception, Brouwer_Intuitionism, AdvancedLaboratory_Lab_Equipment_Simulation | yes |
| `anim.tree_skeletal` | W17_character_studio | use | - | branch | both | none | yes |
| `audio.generate` | WaveFunctions_Effect_Sound | understand | understand (WaveFunctions_Effect_Sound) | main | both | none | yes |
| `data.rng` | Random_Definition | use | change (PG_Genetic_Evolution) | main | both | Random_Remove, Random_Walk, Random_Game, PG_Genetic_Evolution, PG_Caves_Mazes | yes |
| `gd.async` | Random_Remove | understand | understand (Random_Remove) | main | both | Random_Game, Godel_Incompleteness | yes |
| `perf.budget` | Random_Walk | use | change (ISO_Sculpting) | main | both | Noise_Columns, Shader_10_ReactionDiffusion, Fractal_Recursion, ISO_Sculpting, ISO_CaveGeneration, SwarmIntelligence_Boids_Algorithm, Godel_Incompleteness | yes |
| `data.noise` | Noise_Columns | use | understand (Noise_Space_10) | main | both | Noise_One, Noise_Space_10, Shader_09_FBM, ISO_Introduction | yes |
| `shader.other` | Shader_10_ReactionDiffusion | use | - | branch | both | none | yes |
| `shader.viewport_feedback` | Shader_10_ReactionDiffusion | use | - | branch | both | PG_Mirrored_Patterns | yes |
| `gd.recursion` | Fractal_Recursion | understand | understand (Fractal_Recursion) | main | both | Fractal_RecursiveTrees, Fractal_MengerSponge | yes |
| `tool.editor` | Fractal_RecursiveTrees | understand | understand (Fractal_RecursiveTrees) | main | both | QFEP_Sandbox | yes |
| `res.custom` | LSystems_Living | understand | understand (LSystems_Living) | main | both | PG_Genetic_Evolution, Brouwer_Intuitionism | yes |
| `nav.navigation` | PG_Caves_Mazes | understand | change (GT_Pathfinding) | main | both | SwarmIntelligence_FlowFields, GT_Pathfinding | yes |
| `twod.basics` | PG_Mirrored_Patterns | use | - | branch | both | none | yes |
| `phys.softbody` | SoftBodies_Soft_Body_Deformation | understand | understand (SoftBodies_Soft_Body_Deformation) | main | both | SoftBodies_Carusell | yes |
| `other:compute_shader` | ISO_CaveGeneration | use | - | branch | both | none | yes |
| `other:gdextension` | ISO_CaveGeneration | - | - | outside | both | none | yes |
| `perf.threads` | ISO_CaveGeneration | understand | - | branch | both | none | yes |
| `mesh.csg` | Boolean_Verbs | understand | change (Boolean_Works) | main | both | Boolean_Works | yes |
| `net.multiplayer` | SpeculativeComputation_Collective_Knowledge | - | - | outside | both | none | yes |

**Branch [P]:**

- `mesh.gridmap` as an optional step at `Array`: Ada's own JSON grid does this job.
- `other:path3d_curves` as an optional step at `Trans_Translation`.
- `anim.tree_skeletal` at W17, for character-focused learners.
- `shader.other` and `shader.viewport_feedback` at `Shader_10_ReactionDiffusion`.
- `perf.threads` and `other:compute_shader` at `ISO_CaveGeneration`.
- `twod.basics` at `PG_Mirrored_Patterns`, as the door into Godot's 2D. [D] Godot teaches 2D first, and a native 2D course would teach its own APIs.

**Outside [P]:**

- `net.multiplayer`. It is named at `SpeculativeComputation_Collective_Knowledge`, which says of itself that it is "not a live collaborative editor". A two-person room would be a new tested deliverable.
- `other:gdextension` (native extensions), named at `ISO_CaveGeneration`.
- `other:csharp_dotnet`, named at Day Zero: the course uses Godot 4.6 Standard with GDScript.

**Also outside, and not in the vocabulary:** VisualShader as an authoring path; remote services; complex rigs and retargeting; editor plugins beyond one inspector (QFEP_Sandbox branch); console and store publishing.

**Deliberately thin:**

- `space.rotation`: quaternion slerp is optional at Trans_Rotation.
- `input.events`: remapping is not built; W13 adjusts sensitivity only.
- `access.a11y`: text-to-speech and controller focus navigation are named, not built.

**Depth check (from the build):** a "change" meeting at which a prerequisite has not yet reached "understand":

- none

---

## 5. What to fix in the current tutorials first

These are ranked by how early the problem sits on the path and by how many later stops depend on it. Nothing here is a claim that the fix is small.

1. **Make the opening exist at HEAD, or say plainly that it does not.** Everything in 1.5 is untracked. At HEAD the chain `Point_One` (old fragments) → `Point_Lines` (assumes Coordinates) is broken, `curriculum.json` does not validate, and 0 `day_zero`, 2 `Point_One`, 3 `Point_Coordinates`, 5 `Point_Trace`, 62 `Random_Definition`, 73 `Shader_10_ReactionDiffusion` cannot be started. This is Palle's decision: track the kits, or ship them as release zips. Parts belong to other sessions, so post on the forum before anyone commits (thread 260929-ia2d6 is the related open one).
2. **`Point_Trace`: rewrite it list-first, as the ruling asks, and build its two supplied parts.**
   - `curriculum.json` issue `trace-list` is marked `next`.
   - Build `mover.gd` (four named actions through `Input.get_vector`) and the line-strip helper (contract `draw(list)`). Neither exists; without them the stop cannot start.
   - Stop describing the amber short-memory dot as installed. It is absent from `Point_Trace/map_data.json` in both states, yet `tutorial.md` l.58 and `final.md` l.75-79 and l.98 describe it (PRIMITIVES_LINEAGE l.67).
3. **`Point_Lines`: add the `distance_between` variation and re-run its verification.** The tested tutorial gains a learner-written function and the zero-length guard; `verification.json` must be renewed before the stop is called runnable again.
4. **Pickup delivery** (issue `pickup`, priority 1).
   - Build a reduced XR starter for the `Point_Coordinates` kit.
   - Track `point_held.tscn`.
   - Decide how XR Tools reaches a learner, since `/addons/*` is gitignored while `addons/README.md` calls the add-on vendored.
5. **Transformation's missing body and scenes.**
   - `Trans_Pre` says "Start with the cube learned in Primitives", but no Primitives tutorial makes a cube scene. The plan's `Primitives_Polythedra` and `Point_Animatedcube` stops supply one.
   - The helper names `rotate_y()`/`scale()` in `Trans_Introduction` would shadow `Node3D` members [I].
   - `Trans_Translation` has a helper block pasted verbatim from `Trans_Introduction`, in the middle of the page.
   - The `Trans_Scale` rewrite removed the hall's only learner-writable code.
6. **array_tutorial.**
   - Write `Array/tutorial.md`: the hall has none, and its loop explanation lives only in `final.md`.
   - Rewrite `Tutorial_Disco/tutorial.md` against `disco_controls` and `standalone_disco`. Today it describes an Area3D-per-tile recorder with undefined `DANCE_TILE_SCENE`, `play_tone_for`, `find_tile`, and it points to `Chamber_Arrays` (deferred).
7. **Write the six shader tutorials, starting with `Shader_01_Shaping`.** Until then `Noise_6_Wall`, `Tutorial_Pattern` and `Array_Patterns` read shader code with no lesson behind them. Leave `Shader_10_ReactionDiffusion` as it is: its `final.md` (l.23-31) is written about the missing feedback texture ("What the hall shows you is the exact shape of the missing piece"). The ping-pong study belongs in the learner's room.
8. **Fix or relabel tutorials that describe things that do not exist**, as "illustrative, not runnable" if they cannot be rewritten yet. In walking order:
   - `Lab_Path`;
   - `WaveFunctions_Unit_Circle`, `WaveFunctions_3D_Wave_Propagation`, `Wavefunctions_Bernini`, `WaveFunctions_John_Cage`;
   - `Randomness_10_PRINT_Algorithm`, `Random_Cubes`, `Random_Rotate_Random_XYZ`, `Random_Space_Geometry`, `Random_Pheromone`, `Random_Space`;
   - `CA_AgentsCircuits` (Wireworld against a Rule 90 hall);
   - `SwarmIntelligence_Agent_Based_Modeling_ABM`, `SwarmIntelligence_Ant_Colony_Optimization`, `SwarmIntelligence_Swarm_Intelligence_Algorithms`;
   - `ML_Evolution`, `ML_Synthesis`;
   - graph theory's `neighbours()`/`bfs_distances()`/`PriorityQueue`;
   - foundations' missing preloads and `<<</MAP>>>` tokens;
   - QFEP's four missing scenes.
9. **Replace stale next-pointers:**
   - Pointers to `Chamber_*` halls that are not on the walk:
     - `Chamber_Swarm`, from `SwarmIntelligence_Swarm_Intelligence_Algorithms`;
     - `Chamber_ProcGen` and `Chamber_SoftBodies`, from HEAD's `PG_Mirrored_Patterns` and `Topology_Entropy_Morphogenesis`;
     - these three were removed from the spine on 2026-09-02;
     - `Chamber_Arrays`, from `Tutorial_Disco` (deferred);
     - `Chamber_ML`, "Chamber Foundations", `Chamber_CA` and `Chamber_LSystems`, from `ML_Synthesis`, `Crisis_Synthesis`, and HEAD's `CA_EdgeOfChaos` and `LSystems_Living` (not in their sequences).
   - `Noise_Perlin_Simplex` points to CA although Shaders and `Lab_Path` come between.
   - `GT_Matching` claims "the curriculum's spine ends with the matching problem".
   - `ML_Neural_Networks` sends the learner back to the single neuron.
   - `Random_Space` calls itself the finale although `Random_Game` follows.
10. **Class-name collisions.** HEAD lsystems code declares `LSystem`, `Turtle3D`, `GrowthAnimator` and `GeneticTreeSculptor`, which already exist as global classes. `SwarmIntelligence_Swarm_Intelligence_Algorithms` presents several `class_name`s as one file. A learner who pastes either gets "hides a global script class" (see `tools/check_global_classes.py`). The path now teaches that error at `Trans_Pit`.
11. **Working-tree rewrites that removed teaching code later halls rely on:**
    - `FormFinding_Descent` (Forge refers back to it);
    - the ISO arc: `make_walkable`, `brush()`, `extract(field: Callable)`;
    - `WaveFunctions_Effect_Sound` (the only `AudioStreamGenerator` lesson).

    Where the rewrite is kept, move the removed code into the making stop that now needs it.
12. **Stale self-descriptions in the agreements:**
    - `TUTORIAL_LINEAGE.md` l.55, `PRIMITIVES_LINEAGE.md` l.66 and `STUDENT_TOOLBOX.md` l.80 still say the Line tutorial starts with an 8x8 grid.
    - `ada_encyclopedia/public/tutorial/*.json` still lists symmetry and lacks tiling and shaders.
    - `doc/book/iterations/2026-09-29-tutorial-lineage/DECISIONS.md` (l.3, l.29) says 67 targets and 203 halls; the live figures are 71 and 204. It is a dated iteration record, so the drift is worth noting where the atlas is described, not a reason to edit the record.
13. **Renderer and physics facts that a lesson will trip over:**
    - The Quest build of the course project runs the Mobile renderer, which drops SSAO, SSR, SDFGI and volumetric fog.
    - Foveation is probably inert [I].
    - Kits and the course project use different renderers and possibly different physics engines [I].

    The path names these where a learner meets them: the README at W03, the export preset at W06, the headset at W08, the physics engine at `VFM_03_Motion`, compute at `ISO_CaveGeneration`.

---

## 6. The outside proposal and critique

### Adopt [P]

- **From the proposal:**
  - the learner's continuing project;
  - borrowing recorded at three levels;
  - the per-lesson contract (section 2.3 adds "returns", route, lesson status and a contrasting case);
  - composition checkpoints and three course exits;
  - "Debugging should enter through actual small constructions";
  - early and repeated export;
  - "Audio should not be silent until Wavefunctions" (the first sound plays at `Trans_Rotation`);
  - "do not teach every terrain algorithm before making one modest terrain";
  - "Introduce advanced optimisation only against an observed problem";
  - XR as an overlapping route;
  - keeping reset, replay, restore, reload and undo apart (`Point_Animatedcube`, `Symmetry_Seventeen`, `QFEP_Sandbox`);
  - a command such as `set_seed(value)` that does not depend on its caller.
- **From the critique:**
  - an explicit programming progression: condition and function with a return at `Point_Lines`, list and loop at `Point_Trace`, errors at W01;
  - a scene made from nothing (W02);
  - a complete event exercise (W05, with its return at `Trans_Pit`);
  - lifetime, then two rooms, then restart persistence (`Array`, W11, `Pattern_Foundry`);
  - one coherent example of player, camera, UI and pause (W07, W10, W13), including the test that "clicking the menu must not activate the object behind it", now checked at `Color_Paint`, where there is an object to activate;
  - particles (W12);
  - import and animation before Soft Bodies (W04, W17);
  - game-design practice with another person (W10, `FormFinding_Forge`, `Random_Game`);
  - its checkpoints (CP1 to CP4);
  - item 7, "the bridge from following to solving": documentation lookup at W01 (F1 and Ctrl+click into the class reference); one open task at every checkpoint; rebuild exercises in a fresh scene at W02, CP4 and CP6.
- **Position on AI-assisted work [P].** Adopted as a named practice with one rule: an assistant's answer is a claim, checked like any other. The learner predicts, runs, and looks up in the class reference every API an assistant proposes before using it, and no checkpoint accepts code its author cannot explain line by line. The checkpoints' session records note where an assistant was used.

### Already done in the repo, in the working tree only [M]

- The proposal's manifest exists as `doc/book/tutorial-lineage/curriculum.json` (71 nodes), with `tools/build_tutorial_lineage.py` and the live `/tutorial-lineage` atlas. It is not at `doc/book/tutorial_path.json`.
- The vertical-chain priority exists: `curriculum.json` `priority` is `[pickup, line-grid, trace-list]`, and TUTORIAL_LINEAGE l.79 agrees.
- "Lists before the Array sequence" is already a ruling (TUTORIAL_LINEAGE l.71; STUDENT_TOOLBOX l.34).
- "Contact before a complete player" is already done by the working-tree `Point_One` study with `contact_probe.gd`.
- Point Zero's programming start (names, values, retained state, once versus repeatedly) is in the committed `Point_Zero/tutorial.md`.
- The three roles (excerpt, step, borrow) are in STUDENT_TOOLBOX l.13-17.

### Wrong, outdated or in conflict [M]

- **Coordinates content.** The proposal's opening table puts a target test, a Boolean condition and a named input action in `Point_Coordinates`. The critique adds the condition-versus-event target there. Both conflict with the ruling that distance and target state are deferred. The plan keeps the exercise and moves it to W05.
- **Pickup.** The proposal omits pickup from the opening table. The ruling makes object-side pickup `Point_Coordinates`' learning target, first in the hall's order (tutorial.md l.7-11), and this plan follows that order.
- **This plan's own W02 departs from the Point One rulings.** `STUDENT_TOOLBOX.md` keeps camera, floor and lighting as parts to borrow until they become "the subject of an encounter" (l.17), says "Inspect the removable sun without teaching its renderer" (l.31) and "Preparation is a prerequisite, not a repeated lesson" (l.67). W02 rebuilds a floor and a light from nothing. Reason: after CP1 the learner needs a project of their own, and the kits cannot become it. The departure is limited: W02 comes after the kit chain, not between `Point_One` and `Point_Coordinates` as in the draft; the camera stays borrowed until `Primitives_Melencolia`; and the curriculum's own subject for light, `Color_Flashlight`, is unchanged. The alternative Palle may prefer: start `my_room` at `Color_Flashlight` and keep stops 8-33 in copies of a supplied reference room.
- **A proposed `route: "xr"` attribute on `curriculum.json`'s `coordinates -> xr` edge** (in the draft's section 7.3) would change the agreement that makes the supplied XR route a prerequisite of `coordinates`. It is taken out of the technical proposals and put to Palle as a question: should a desktop-only learner be able to pass `Point_Coordinates`, and with what named loss?
- **Stale or misread details:**
  - "The committed `primitives.json` still begins with Point_One" is true at HEAD only.
  - "Remote inspector" should read Remote scene tree.
  - Portals' Button and Timer controls exist in the hall (`final.md` l.11-47) but not in its tutorial.
  - The "material properties" at `Point_One` are not in the current tutorial.
- **Placement conflicts.**
  - Saving the object as a scene at `Primitives_Polythedra` conflicts with the agreement's Cube shelf. The plan does both: the save at Polythedra, instances of the cube at `Point_Animatedcube`.
  - Import and export at `Primitives_Melencolia` conflict with its reflective ruling. Import moves to `Primitives_Ignorance`; export stays as a separate, code-free stop after the hall.
- **Unsupported claims.**
  - "Ways through the halls" could not be found and is unverifiable.
  - The proposal's "supplied tested setup" for XR is not reproducible from git (XR Tools gitignored, Quest route unverified).
- **The critique on import.** "Asset import and animation earlier than Soft Bodies" partly misreads the proposal, which already had an import encounter at Melencolia and AnimationPlayer in Transformation.
- **The critique's barrier exercise.** Placing it at Coordinates or Lines conflicts with `Point_Lines/tutorial.md` l.56, where the barrier is supplied and "not a prerequisite for making our first segment". W05 keeps the exercise until the learner has conditions, a moving point and a project.
- **Neither text mentions:**
  - that XR Tools changes the physics rate with the headset (60 vs 72/90 Hz; the NOC review measured per-tick damping at 0.451 vs 0.294 amplitude over 6 s);
  - that the Quest build runs the Mobile renderer while the kits run Compatibility;
  - that the course project pins `GodotPhysics3D` while new 4.6 projects default to Jolt;
  - that headless probes draw no frames.

  The plan places each of these at a stop: VFM_03_Motion, W08, W03 and W16.

---

## 7. Implementation order [P]

The order is set by prerequisites first and by how much has to be written second. Writing load per segment, main stops only, from the lesson statuses:

| segment | stops | main | runnable | fragment-rewrite | prose-rewrite | new-page | kits or helpers to build |
|---|---|---|---|---|---|---|---|
| day_zero to CP1_opening | 0-7 | 8 | 5 | 1 | 0 | 2 | Point_Trace |
| W02_scene_from_nothing to CP2_composition | 8-20 | 13 | 0 | 7 | 0 | 6 | - |
| Trans_Pre to CP3_playable_room | 21-30 | 10 | 0 | 5 | 0 | 5 | - |
| Array to CP4_two_rooms_that_remember | 31-47 | 17 | 0 | 3 | 8 | 6 | - |
| Change_Intro to CP5_play_it_twice | 48-66 | 18 | 1 | 9 | 5 | 3 | - |
| Noise_Columns to CP6_generated_place | 67-85 | 18 | 0 | 2 | 12 | 4 | - |
| PG_Mirrored_Patterns to CP7_release | 86-114 | 19 | 0 | 8 | 9 | 2 | - |

1. **Prove the first vertical chain: Day Zero → `Point_Zero` → `Point_One` → `Point_Coordinates` → `Point_Lines` → `Point_Trace` → W01 → CP1.**
   - This follows the curriculum priority `[pickup, line-grid (resolved), trace-list]` and the proposal's §9.3, and it is the only segment built mostly from runnable pages.
   - Deliverables:
     - the list-first `Point_Trace/tutorial.md`, `mover.gd` and the line-strip helper;
     - the `distance_between` addition to `Point_Lines`, re-verified;
     - the reduced XR starter for `Point_Coordinates`, and `point_held.tscn` tracked;
     - W01 and CP1 written as short pages;
     - each kit's starting scene made equal to the previous kit's finished state;
     - the kits tracked, or zipped as a release (section 5, item 1).
2. **Test it in three separate ways, and record each separately.**
   - (a) **Native run.** Run each stated step from its stated starting material: headless `verify.gd` where one exists, plus a windowed look, because headless draws no frames.
   - (b) **One beginner, with no gap-filling.** Follow, vary, transfer (TUTORIAL_LINEAGE l.69). Record every confusion, the elapsed time, and every point where the teacher had to supply something. Record a session estimate per stop from this, into the JSON's `session_estimate`.
   - (c) **The pickup step on a headset**, separately, since "Native tests cannot stand in for a headset trial."
   - Set each lesson's status from these results only.
3. **Second chain: the rest of the short course, CP1 → CP2 → CP3.** After CP1 the prerequisites leave no other order: every later segment needs `my_room`, which W02 creates, and the player, UI and export that CP3 closes. The lesson statuses support the same choice. The two segments hold 23 main stops: 12 fragment rewrites and 11 new pages (workshops and checkpoints), and no prose-only page, so every hall in them has installed code a rewrite can quote. From `Array` on, prose rewrites appear, whose steps must be written from nothing (8 of 17 stops in the CP3 → CP4 segment, 12 of 18 in CP5 → CP6). W08 needs one verified headset run before it is published.
4. **Keep the manifest in `curriculum.json`, but do not edit it yet.** Propose an extension on the forum first, because other sessions own that file. The proposed additions per node:
   - `starter` and `checkpoint`: `{head, working_tree}` paths;
   - `reuses`: node ids or files;
   - `borrows_depth`: a list of `{part, depth: use|understand|change, revisit | boundary}`;
   - `godot_new` and `godot_returns`: capability ids from the shared vocabulary, with depths, and the vocabulary itself in a sibling `godot_capabilities.json` taken from `godot_path.json`;
   - `check`: `{expect, contrast}`;
   - `carries`;
   - `lesson_status` with the date checked;
   - `verified`: `{native, learner, headset}`, each a date and file or null.

   Two node kinds should be added: `workshop` and `checkpoint`, each with `at_hall` (halls stay `[]`, so walking-order coverage is untouched). `tools/build_tutorial_lineage.py` could then run the checks `build_plan_v2.py` runs here. The question of a desktop-only route through `coordinates` goes to Palle separately (section 6).
5. **Then proceed segment by segment, CP3 → CP4 → CP5 → CP6 → CP7.** Fix the tutorials in the order of section 5. Write `Shader_01_Shaping` before any stop from `Noise_One` onward is taught, and the reflect halls' optional studios last.
6. **Keep a teaching release** pinned to one Godot version and one kit set while the research branch keeps moving. Say which state (HEAD or working tree) each release describes.
7. **Pacing.** Until the trial measures sessions, the plan offers cuts rather than hours: the **short course** is stops 0-30 (Day Zero to CP3) and first meets all 33 capabilities of the survey's minimum complete game; the three course exits follow at CP4, CP6 and CP7.

---

## 8. Sieve pass

**Q1. Does this thicken the cognitive water?** Mostly yes, if the distinctions stay the point.

- The halls already turn on material decisions: a surface that does not stop you, a count that is not a frame time, a picture of water that does not carry you. The path gives the learner the means to make and unmake those decisions in a project of their own.
- The borrowing depths give the learner a handle on what they are standing on without having built it.
- The checks with a contrasting case make a claim testable by the person who made it, and the open tasks at checkpoints ask for a choice nobody has pre-solved.

**Q2. What is foreclosed?** Five things.

- **The other halls get demoted.** Choosing 89 hall stops (78 on the main track) makes the other 115 halls read as secondary, although the rulings say they carry encounters that need no code.
- **Ada's strangeness can be flattened into generic practice.** Standard game-development workshops (pause menu, particles, export, a hub) pull Ada towards convention. The room could become a competent generic game instead of a place where a collider disagrees with the surface that seems to promise it.
- **The coverage table invites scoreboard reading.** 90 capabilities with a depth column is a coverage figure, not a measure of learning.
- **The desktop-only exception is a real loss.** A cohort that takes it never meets the project's primary medium, and the path can be completed without a headset.
- **The late reflect halls lose making.** Making their studios optional follows the ruling, and it also means the last main making hall is `QFEP_Sandbox`.

**Q3. What lives in the dark spot?** Two things, one generative and one sealing.

- **Generative:** the transfer prompts. Each stop names a capability and asks for a choice; the worked example is one answer among many, and what the learner builds with it is not specified.
- **Sealing:** nothing here has been tried by a learner or run in Godot. Every first stop is a hypothesis about understanding, and the green validation in `build_plan_v2.py` checks order, route and depth labels, not whether anyone learns anything.

---

## Appendix

### A.1 Prerequisites met after their first stop

The build lists each of these, and each has a stated reason.

- `phys.bodies` at Point_One: requires scene.new_scene@W02_scene_from_nothing, space.transform@Point_Coordinates. Ruling order. Point_One builds a StaticBody3D inside the supplied study.tscn; 'The surrounding construction is supplied' (STUDENT_TOOLBOX l.45), so the learner meets bodies before making a scene of their own (W02) and before the frame is named (Point_Coordinates).
- `xr.interaction` at Point_Coordinates: requires xr.setup@W08_headset_day, gd.signals_own@W05_signal_and_door. Ruling (TUTORIAL_LINEAGE l.37-43; PRIMITIVES_LINEAGE l.82): Point_Coordinates teaches the object side of pickup in the course project's prepared XR scene, and 'Input bindings, controller tracking, release physics and signal programming need not all become new subjects in Point Coordinates.' The rig (xr.setup) is supplied until W08, and signals are supplied until W05.

### A.2 Stop index

"HEAD" says whether the stop's starting material exists at HEAD ("ok"), is missing ("not startable"), or whether the hall itself is absent from HEAD's walk ("WT only").

| # | stop | kind | sequence | at hall | route | lesson | HEAD | new capabilities |
|---|---|---|---|---|---|---|---|---|
| 0 | day_zero | workshop | preface | - | both | runnable | not startable | editor.project, editor.scene_tree, editor.run_debug |
| 1 | Point_Zero | hall | primitives | Point_Zero | desktop | runnable | WT only | gd.variables, gd.functions, gd.lifecycle, gd.strings, scene.groups_paths |
| 2 | Point_One | hall | primitives | Point_One | desktop | runnable | not startable | scene.nodes_resources, mesh.primitive, phys.bodies, phys.shapes_layers |
| 3 | Point_Coordinates | hall | primitives | Point_Coordinates | both | runnable | WT only | xr.interaction, space.vector3, space.transform, editor.viewport3d |
| 4 | Point_Lines | hall | primitives | Point_Lines | desktop | runnable | ok | gd.conditions |
| 5 | Point_Trace | hall | primitives | Point_Trace | desktop | fragment-rewrite | not startable | input.actions, gd.arrays, gd.loops, gd.typing |
| 6 | W01_break_it_on_purpose | workshop | primitives | Point_Trace | desktop | new-page | ok | gd.errors, other:docs_lookup |
| 7 | CP1_opening | checkpoint | primitives | Point_Trace | both | new-page | ok | - |
| 8 | W02_scene_from_nothing | workshop | primitives | Point_Line_Grid | desktop | new-page | ok | scene.new_scene, scene.instancing, light.env |
| 9 | W03_known_revision | workshop | primitives | Point_Line_Grid | desktop | new-page | ok | editor.version_control |
| 10 | Point_Line_Grid | hall | primitives | Point_Line_Grid | desktop | fragment-rewrite | ok | - |
| 11 | Point_Triangle_Context | hall | primitives | Point_Triangle_Context | desktop | fragment-rewrite | ok | mesh.procedural, mat.standard |
| 12 | Primitives_Polythedra | hall | primitives | Primitives_Polythedra | desktop | fragment-rewrite | ok | gd.packed_arrays |
| 13 | Point_Animatedcube | hall | primitives | Point_Animatedcube | desktop | fragment-rewrite | ok | - |
| 14 | Primitives_Ignorance | hall | primitives | Primitives_Ignorance | desktop | fragment-rewrite | ok | gd.export |
| 15 | W04_import_one_thing | workshop | primitives | Primitives_Ignorance | desktop | new-page | ok | assets.import, mat.textures |
| 16 | Primitives_Portals | hall | primitives | Primitives_Portals | desktop | fragment-rewrite | ok | - |
| 17 | W05_signal_and_door | workshop | primitives | Primitives_Portals | desktop | new-page | ok | gd.signals_own |
| 18 | Primitives_Melencolia | hall | primitives | Primitives_Melencolia | desktop | fragment-rewrite | ok | cam.camera3d |
| 19 | W06_export_it | workshop | primitives | Primitives_Melencolia | desktop | new-page | ok | export.build, other:renderer_choice |
| 20 | CP2_composition | checkpoint | primitives | Primitives_Melencolia | desktop | new-page | ok | - |
| 21 | Trans_Pre | hall | transformation | Trans_Pre | desktop | fragment-rewrite | ok | space.interpolation, space.rotation |
| 22 | Trans_Introduction | hall | transformation | Trans_Introduction | desktop | fragment-rewrite | ok | - |
| 23 | W07_body_and_camera | workshop | transformation | Trans_Introduction | desktop | new-page | ok | input.events, input.player |
| 24 | Trans_Translation | hall | transformation | Trans_Translation | desktop | fragment-rewrite | ok | phys.areas, anim.tween, scene.lifetime, other:path3d_curves |
| 25 | Trans_Rotation | hall | transformation | Trans_Rotation | desktop | fragment-rewrite | ok | anim.player, audio.playback |
| 26 | W08_headset_day | workshop | transformation | Trans_Scale | xr | new-page | ok | xr.setup |
| 27 | W09_room_in_headset | workshop | transformation | Trans_Scale | xr | new-page | ok | - |
| 28 | Trans_Pit | hall | transformation | Trans_Pit | desktop | fragment-rewrite | ok | gd.classes, gd.const_enum, design.loop |
| 29 | W10_pause_and_retry | workshop | transformation | Trans_Pit | desktop | new-page | ok | ui.controls, other:pause_process_mode, scene.change |
| 30 | CP3_playable_room | checkpoint | transformation | Trans_Pit | both | new-page | ok | - |
| 31 | Array | hall | array_tutorial | Array | desktop | new-page | ok | mesh.gridmap |
| 32 | Tutorial_Tiling_Floor | hall | array_tutorial | Tutorial_Tiling_Floor | desktop | prose-rewrite | WT only | - |
| 33 | Tutorial_Disco | hall | array_tutorial | Tutorial_Disco | desktop | fragment-rewrite | ok | mesh.multimesh, perf.profiling |
| 34 | Color_Context_Placed | hall | color | Color_Context_Placed | desktop | prose-rewrite | ok | gd.dictionaries, res.shared_unique |
| 35 | Color_Flashlight | hall | color | Color_Flashlight | desktop | prose-rewrite | WT only | - |
| 36 | Color_Nails | hall | color | Color_Nails | desktop | prose-rewrite | ok | - |
| 37 | W11_two_rooms | workshop | color | Color_Nails | desktop | new-page | ok | scene.autoload |
| 38 | Color_Rainbow | hall | color | Color_Rainbow | desktop | prose-rewrite | WT only | - |
| 39 | W12_particles | workshop | color | Color_Rainbow | desktop | new-page | WT only | fx.particles |
| 40 | Color_Grid_Pallet | hall | color | Color_Grid_Pallet | desktop | fragment-rewrite | WT only | ui.world_space |
| 41 | W13_settings | workshop | color | Color_Grid_Pallet | desktop | new-page | WT only | ui.layout, access.a11y |
| 42 | Color_Paint | hall | color | Color_Paint | desktop | fragment-rewrite | WT only | phys.queries |
| 43 | W14_game_in_headset | workshop | color | Color_Paint | xr | new-page | WT only | - |
| 44 | Pattern_Foundry | hall | tiling | Pattern_Foundry | desktop | prose-rewrite | ok | data.save |
| 45 | Tutorial_Pattern | hall | tiling | Tutorial_Pattern | desktop | prose-rewrite | ok | shader.spatial |
| 46 | Symmetry_Seventeen | hall | tiling | Symmetry_Seventeen | desktop | prose-rewrite | ok | data.undo |
| 47 | CP4_two_rooms_that_remember | checkpoint | tiling | Symmetry_Seventeen | both | new-page | ok | - |
| 48 | Change_Intro | hall | change | Change_Intro | desktop | fragment-rewrite | ok | - |
| 49 | W15_many_rooms | workshop | change | Change_Intro | desktop | new-page | ok | - |
| 50 | VFM_03_Motion | hall | forces | VFM_03_Motion | desktop | fragment-rewrite | ok | phys.forces |
| 51 | Vectors_Act3_FieldsAndMotion | hall | forces | Vectors_Act3_FieldsAndMotion | desktop | prose-rewrite | ok | - |
| 52 | W16_checks_without_you | workshop | forces | Vectors_Act3_FieldsAndMotion | desktop | new-page | ok | test.checks |
| 53 | Change_Choreography | hall | forces | Change_Choreography | desktop | prose-rewrite | WT only | - |
| 54 | W17_character_studio | workshop (optional) | forces | VFM_09_Legs | desktop | new-page | ok | anim.tree_skeletal |
| 55 | Vectors_Act5_ForceAsPlace | hall | forces | Vectors_Act5_ForceAsPlace | desktop | prose-rewrite | ok | - |
| 56 | FormFinding_Descent | hall | formfinding | FormFinding_Descent | desktop | prose-rewrite | ok | - |
| 57 | FormFinding_Equilibrium | hall | formfinding | FormFinding_Equilibrium | desktop | fragment-rewrite | ok | - |
| 58 | FormFinding_Forge | hall | formfinding | FormFinding_Forge | desktop | fragment-rewrite | ok | - |
| 59 | WaveFunctions_Intro | hall | wavefunctions | WaveFunctions_Intro | both | fragment-rewrite | ok | - |
| 60 | WaveFunctions_Effect_Sound | hall | wavefunctions | WaveFunctions_Effect_Sound | desktop | fragment-rewrite | ok | audio.generate |
| 61 | WaveFunctions_AirMusic | hall | wavefunctions | WaveFunctions_AirMusic | desktop | fragment-rewrite | ok | - |
| 62 | Random_Definition | hall | randomness | Random_Definition | desktop | runnable | not startable | data.rng |
| 63 | Random_Remove | hall | randomness | Random_Remove | desktop | fragment-rewrite | ok | gd.async |
| 64 | Random_Walk | hall | randomness | Random_Walk | desktop | fragment-rewrite | ok | perf.budget |
| 65 | Random_Game | hall | randomness | Random_Game | desktop | prose-rewrite | ok | - |
| 66 | CP5_play_it_twice | checkpoint | randomness | Random_Game | both | new-page | ok | - |
| 67 | Noise_Columns | hall | noise | Noise_Columns | desktop | fragment-rewrite | ok | data.noise |
| 68 | Noise_One | hall | noise | Noise_One | desktop | prose-rewrite | ok | - |
| 69 | Noise_Space_10 | hall | noise | Noise_Space_10 | desktop | prose-rewrite | ok | - |
| 70 | Shader_01_Shaping | hall | shaders | Shader_01_Shaping | desktop | new-page | ok | - |
| 71 | Shader_11_QueerRubber | hall | shaders | Shader_11_QueerRubber | desktop | new-page | ok | - |
| 72 | Shader_09_FBM | hall | shaders | Shader_09_FBM | desktop | new-page | ok | - |
| 73 | Shader_10_ReactionDiffusion | hall (optional) | shaders | Shader_10_ReactionDiffusion | desktop | new-page | not startable | shader.viewport_feedback, shader.other |
| 74 | CA_Introduction | hall | cellularautomata | CA_Introduction | desktop | prose-rewrite | ok | - |
| 75 | CA_GameOfLife | hall | cellularautomata | CA_GameOfLife | desktop | prose-rewrite | ok | - |
| 76 | Fractal_Recursion | hall | fractals | Fractal_Recursion | desktop | fragment-rewrite | ok | gd.recursion |
| 77 | Fractal_RecursiveTrees | hall | fractals | Fractal_RecursiveTrees | desktop | prose-rewrite | ok | tool.editor |
| 78 | Fractal_MengerSponge | hall | fractals | Fractal_MengerSponge | desktop | prose-rewrite | ok | - |
| 79 | LSystems_Grammar_Lab | hall | lsystems | LSystems_Grammar_Lab | desktop | prose-rewrite | ok | - |
| 80 | LSystems_Growth | hall | lsystems | LSystems_Growth | desktop | prose-rewrite | ok | - |
| 81 | LSystems_Architecture | hall | lsystems | LSystems_Architecture | desktop | prose-rewrite | ok | - |
| 82 | LSystems_Living | hall | lsystems | LSystems_Living | desktop | prose-rewrite | ok | res.custom |
| 83 | PG_Genetic_Evolution | hall | proceduralgeneration | PG_Genetic_Evolution | desktop | prose-rewrite | ok | - |
| 84 | PG_Caves_Mazes | hall | proceduralgeneration | PG_Caves_Mazes | desktop | prose-rewrite | ok | nav.navigation |
| 85 | CP6_generated_place | checkpoint | proceduralgeneration | PG_Caves_Mazes | both | new-page | ok | - |
| 86 | PG_Mirrored_Patterns | hall (optional) | proceduralgeneration | PG_Mirrored_Patterns | desktop | prose-rewrite | ok | twod.basics |
| 87 | SoftBodies_Soft_Body_Deformation | hall | softbodies | SoftBodies_Soft_Body_Deformation | desktop | prose-rewrite | ok | phys.softbody |
| 88 | SoftBodies_Carusell | hall | softbodies | SoftBodies_Carusell | desktop | prose-rewrite | ok | - |
| 89 | ISO_Introduction | hall | isosurfaces | ISO_Introduction | desktop | prose-rewrite | ok | - |
| 90 | ISO_ShapesGallery | hall | isosurfaces | ISO_ShapesGallery | desktop | prose-rewrite | ok | - |
| 91 | ISO_Sculpting | hall | isosurfaces | ISO_Sculpting | both | prose-rewrite | ok | - |
| 92 | ISO_Caves | hall | isosurfaces | ISO_Caves | desktop | prose-rewrite | ok | - |
| 93 | ISO_CaveGeneration | hall (optional) | isosurfaces | ISO_CaveGeneration | desktop | fragment-rewrite | ok | perf.threads, other:compute_shader |
| 94 | Boolean_Verbs | hall | boolean_surfaces | Boolean_Verbs | desktop | prose-rewrite | ok | mesh.csg |
| 95 | Boolean_Works | hall | boolean_surfaces | Boolean_Works | desktop | prose-rewrite | ok | - |
| 96 | SwarmIntelligence_FlowFields | hall | swarmintelligence | SwarmIntelligence_FlowFields | desktop | fragment-rewrite | ok | - |
| 97 | SwarmIntelligence_Boids_Algorithm | hall | swarmintelligence | SwarmIntelligence_Boids_Algorithm | desktop | fragment-rewrite | ok | - |
| 98 | SwarmIntelligence_Agent_Based_Modeling_ABM | hall | swarmintelligence | SwarmIntelligence_Agent_Based_Modeling_ABM | desktop | fragment-rewrite | ok | - |
| 99 | ML_Classification | hall | machinelearning | ML_Classification | desktop | fragment-rewrite | ok | - |
| 100 | ML_Perception | hall | machinelearning | ML_Perception | desktop | fragment-rewrite | ok | - |
| 101 | GT_Foundations | hall | graphtheory | GT_Foundations | desktop | fragment-rewrite | ok | - |
| 102 | GT_Pathfinding | hall | graphtheory | GT_Pathfinding | desktop | fragment-rewrite | ok | - |
| 103 | GT_Network_Analysis | hall | graphtheory | GT_Network_Analysis | desktop | fragment-rewrite | ok | - |
| 104 | Godel_Incompleteness | hall (optional) | foundationscrisis | Godel_Incompleteness | desktop | fragment-rewrite | ok | - |
| 105 | Escher_Impossible | hall (optional) | foundationscrisis | Escher_Impossible | both | fragment-rewrite | ok | - |
| 106 | Brouwer_Intuitionism | hall (optional) | foundationscrisis | Brouwer_Intuitionism | desktop | fragment-rewrite | ok | - |
| 107 | QFEP_Phi_Term | hall (optional) | qfeplaboratory | QFEP_Phi_Term | desktop | fragment-rewrite | ok | - |
| 108 | QFEP_Sandbox | hall | qfeplaboratory | QFEP_Sandbox | desktop | prose-rewrite | ok | - |
| 109 | CriticalAlgorithms_Applied_Ethics | hall (optional) | postfoundationscrisis | CriticalAlgorithms_Applied_Ethics | desktop | prose-rewrite | ok | - |
| 110 | SpeculativeComputation_Collective_Knowledge | hall (optional) | postfoundationscrisis | SpeculativeComputation_Collective_Knowledge | desktop | prose-rewrite | ok | - |
| 111 | AdvancedLaboratory_Lab_Equipment_Simulation | hall (optional) | postfoundationscrisis | AdvancedLaboratory_Lab_Equipment_Simulation | desktop | prose-rewrite | ok | - |
| 112 | PostCrisis_Synthesis | hall (optional) | postfoundationscrisis | PostCrisis_Synthesis | desktop | prose-rewrite | ok | - |
| 113 | W18_release | workshop | postfoundationscrisis | PostCrisis_Synthesis | both | new-page | ok | - |
| 114 | CP7_release | checkpoint | postfoundationscrisis | PostCrisis_Synthesis | both | new-page | ok | - |

### A.3 Files

All paths are in this folder, `doc/book/iterations/claude-godot-path-2026-09-30/`.

- `PLAN.md`: this file. `godot_path.json`: its machine-readable twin (same stop and capability ids).
- `plan_stops_v2.py`: the plan data. `plan_template_v2.md`: the prose. `build_plan_v2.py`: builds and validates both outputs.
- `survey_bundle.json`: the measured survey. `c2_spine.json`: HEAD and working-tree hall lists. `tracked_tutorials.txt`, `tutorial_status.txt`: git state of every `tutorial.md` on 2026-09-30.
- `inputs/`: the outside proposal and its follow-up critique that Palle supplied on 2026-09-30, kept as the data this plan tested.
- The first draft (`PLAN_draft.md` and its build files) stayed in the session scratchpad; A.4 records what the review changed.

### A.4 Review notes

The review round raised 47 problems (2 blockers, 23 majors, 22 minors) and a mechanical check listing 8 prerequisite violations. All 47 are addressed. Of the 8 violations, 6 are gone because the capabilities moved; `phys.bodies` and `xr.interaction` remain as the two A.1 exceptions. Where a fix differs from the reviewer's, or an item is declined, the reason is below; other items were applied as proposed.

**Differs or declined.**

- **XR at `Point_Coordinates`.** One reviewer proposed recording the grab as a museum encounter, counting `xr.interaction` first in an XR workshop after W08, and removing the A.1 exception. The other showed that pickup is the hall's learning target in every standing agreement (TUTORIAL_LINEAGE l.37-43, PRIMITIVES_LINEAGE l.82, intent.md l.7, tutorial.md l.7-11). The agreements win: pickup stays first in the hall, on the xr route, in the course project, and the A.1 exception stays with the ruling as its reason. From the first reviewer the plan takes the two projects, the route field, the starter flags and the consistent labels (`xr.setup` and `xr.interaction` are main-placement, xr-route).
- **The headset day.** One reviewer asked for a 'headset day' (their W08a) to be kept out of the main sequence; the other for W08 to be main. Both are main-track stops on the xr route (W08, W09). W08 is a one-off session scheduled when a device is available; the desktop-only exception is named in 2.1, and the build checks that no desktop stop depends on either.
- **Renderer choice at the draft's W01 (now W02).** `other:renderer_choice` requires `export.build` in the survey's graph, so it is counted at W06. The README line naming renderer and physics engine is written at W03, as asked.
- **W04 (now W05) at `Point_Line_Grid`.** Kept at `Primitives_Portals`, with the reason restated as prerequisites and the barrier at `Point_Lines` as the field anchor, because `Point_Line_Grid` now hosts the creation of `my_room` and version control.
- **"List groups as new" at `Trans_Translation`.** `scene.groups_paths` is first met at `Point_Zero` (`$Greeting`); a capability cannot be new twice. Translation records it as a return at understand depth and says it is the first use of groups.
- **`space.vector3` at `Point_Lines`.** Kept at `Point_Coordinates` at use depth (reading and writing a position's components), as the survey records, because `space.transform` there requires it. Distance stays at `Point_Lines`.
- **An input lesson written by the learner at `Point_Trace`.** Taken in the lighter form `curriculum.json` allows (`trace.borrow`: "Input receiver and line-strip rendering"): a supplied `mover.gd` [to be built] that reads named actions, opened at understand depth, with one action added by the learner and a comparison with `contact_probe.gd`'s raw keys. `input.actions` is first met there.
- **The 500-sphere measurement at `Primitives_Ignorance`.** Removed rather than moved, following the other reviewer's point that the hall's own question is a resolution for a stated use. Code instancing is first taught at `Array`.
- **`Primitives_Melencolia` workshops.** Import moved to `Primitives_Ignorance`. Export stays at Melencolia as a separate, code-free stop, and CP2 stays there; neither adds code to a reflect hall.
- **Session estimates.** Not invented. The JSON field `session_estimate` stays empty until the trial; the short course is defined instead.
- **Tagged commit at every checkpoint.** From CP2 on. CP1 comes before version control (W03), so its evidence is a dated copy of the study folders.

**Knock-on changes the reviewers did not ask for.**

- `gd.async` moved from `Trans_Pit` to `Random_Remove` (the pusher now pauses with a Timer node), and so `perf.budget` moved from `FormFinding_Descent` to `Random_Walk`. This keeps `Trans_Pit` at three new capabilities after `class_name` arrived there.
- `audio.playback` moved from `Trans_Translation` to `Trans_Rotation` (a placed creak from a method track); the "freed player cuts its sound" contrast moved to `Array`.
- `design.loop` moved from the menu workshop to `Trans_Pit` (the written failure decision), and `scene.change` stays with the retry at W10 so that the short course covers the whole minimum game.
- `editor.viewport3d` is first met at `Point_Coordinates` (the move gizmo in local and global space), because `space.transform` requires it and W02 now comes later. `mat.standard` is first met at `Point_Triangle_Context`, `cam.camera3d` at `Primitives_Melencolia`.
- The Label3D responder in the signal workshop became a lamp, so `ui.world_space` is first met where it can be at use depth after `ui.controls` (`Color_Grid_Pallet`).
- The build now checks depth (no "change" without an earlier "understand"), route dependence and minimum-game coverage; section 4 prints the deepest depth each capability reaches.

**Workshop ids, draft to final.** Workshops are renumbered in path order.

| draft id | final id | change |
|---|---|---|
| W01_scene_from_nothing | W02_scene_from_nothing | moved after CP1; camera, WorldEnvironment and material moved out |
| W02_known_revision | W03_known_revision | moved after CP1 |
| W03_break_it_on_purpose | W01_break_it_on_purpose | same place; adds class-reference lookup and an @onready fault |
| W04_signal_and_door | W05_signal_and_door | same hall; reason restated |
| W05_import_one_thing | W04_import_one_thing | moved from Melencolia to Primitives_Ignorance |
| W06_export_it | W06_export_it | same |
| W07_body_and_camera | W07_body_and_camera | adds input rules and the 'player' group |
| W08_room_in_headset | W08_headset_day + W09_room_in_headset | split; xr route |
| W09_menu_pause_retry | W10_pause_and_retry + W13_settings | split; settings moved to Color_Grid_Pallet |
| W10_two_rooms | W11_two_rooms | same |
| W11_particles | W12_particles | basis corrected; now a comparison |
| - | W14_game_in_headset | new; xr route |
| - | W15_many_rooms | new |
| W12_checks_without_you | W16_checks_without_you | adds an in-editor route and the Windows console note |
| W13_character_studio | W17_character_studio | same (branch) |
| W14_release | W18_release | takes the versioned atomic save |
