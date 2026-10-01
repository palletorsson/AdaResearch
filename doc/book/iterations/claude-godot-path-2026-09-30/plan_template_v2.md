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

Size of the path [P]: {{STOPS}} stops. That is {{MAKING_HALLS}} hall stops ({{BRANCH_HALLS}} of them optional studios, {{REFLECT_OPTIONAL}} of those at halls `curriculum.json` marks "reflect"), {{WORKSHOPS}} workshops including Day Zero (1 of them a branch), and {{CHECKPOINTS}} checkpoints. The other {{ENCOUNTERS}} of the 204 halls stay encounters; two of them (`Trans_Scale`, `VFM_09_Legs`) host a workshop. {{CAPS}} capabilities are placed: {{PLACEMENT}}.

### What can be taught today [M, checked 2026-09-30]

Every stop carries a lesson status: **runnable** (a runnable study covers the stop's core make), **fragment-rewrite**, **prose-rewrite**, or **new-page** (workshops, checkpoints, halls with no `tutorial.md`).

- All stops: {{STATUS_TOTALS}}.
- Hall stops only: {{HALL_STATUS_TOTALS}}.
- Stops with a runnable page today, in the working tree: {{TEACHABLE_TODAY}}. The first five are the opening. `Random_Definition` runs on desktop as a worked example, but its step in the learner's project is new writing.
- Everything else has to be written or rewritten before it can be taught. For {{NO_NEW_SUPPORTED}} hall stops, none of the capabilities this plan first meets there appears in what the survey found the current tutorial teaching.
- Not startable at HEAD: {{NOT_HEAD}}. `Point_Trace` and `Shader_10_ReactionDiffusion` are not startable anywhere until their supplied parts are built.
- At halls that exist only in the working tree: {{WT_ONLY}}.

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

{{HEAD_WT_TABLE}}

In total 15 halls exist only in the working tree and 7 only at HEAD. {{WT_ONLY_N}} stops of this path sit at working-tree-only halls; each is tagged "WT only" in its header and in A.2. A reader at HEAD would also walk `Trans_AxisDecomposition`, `Trans_RotationSpectacle`, `Accumulation_Riemann`, `Change_Reconciliation`, `Fractal_JuliaSet`, `Fractal_MandelbrotSet` and `Fractal_CrossSequence`, which this plan never mentions, and would meet `PG_Percolation_Network` before `PG_Branching_Growth` and `SoftBodies_Carusell` before `SoftBodies_Cloth_Physics`.

**Untracked, and so absent at HEAD:**

- the opening apparatus: `doc/book/day-zero.md`, `STUDENT_TOOLBOX.md`, `TUTORIAL_LINEAGE.md`, `PRIMITIVES_LINEAGE.md`, `BOOK_FRAME.md`;
- the curriculum tooling: `doc/book/tutorial-lineage/curriculum.json`, `tools/build_tutorial_lineage.py`, and the encyclopedia `/tutorial-lineage` and `/book-review` routes;
- the study kits `day-zero` (0 of 5 files tracked), `point-one` (0 of 15), `point-coordinates` (0 of 7) and `random-definition` (0 of 21). `point-zero` (7 of 7) and `point-lines` (9 of 10) are tracked;
- the whole `commons/maps/Point_Coordinates/` folder, and the tutorials of `Tutorial_Tiling_Floor`, `Boolean_Verbs` and `Boolean_Works`;
- parts this plan borrows or reads: `commons/primitives/point/point_held.tscn`, `doc/book/studies/point-one/contact_probe.gd`, `commons/primitives/point/point_sun_switch.gd`, `commons/artifacts/regularity/disco_controls.gd`, `commons/testing/probe_motion_chamber.gd`, `probe_field_receivers.gd`, `probe_gravity_relations.gd` and `probe_rainbow_celebration.gd`, and `boolean_burrow`. Each is tagged UNTRACKED where a stop uses it. (`rainbow.gd`, `rainbow_celebration.gd` and `rainbow_spark_burst.gd` are tracked.)

**Consequences.**

- At HEAD the opening cannot be walked from Day Zero: {{NOT_HEAD}} have no starting material. `my_room` itself can be started at HEAD, because W02 creates it from an empty project.
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
  - xr only: {{XR_STOPS}};
  - desktop steps plus xr steps: {{BOTH_STOPS}};
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
- "Do not force an equal code quota across the spine." (`STUDENT_TOOLBOX.md` l.25) `tutorial-lineage/README.md`: "reflect = return critically without compulsory new code." So the {{REFLECT_OPTIONAL}} late reflect halls carry optional studios only (table under sequence 25 in section 3), and `Primitives_Melencolia` has no new code.
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

{{SEQ:preface}}

### 1. primitives

- **Today [M]:**
  - Four runnable desktop studies (`Point_Zero`, `Point_One`, `Point_Coordinates`, `Point_Lines`) give editor habits, `_ready`/`_process`, members, node and resource separation, colliders, `Vector3`, local and global position, and `b - a`.
  - After that, 7 of the 8 tutorials read excerpts of installed sources. `Primitives_Portals` offers helpers with no harness to run them in.
- **Proposed [P]:**
  - All twelve halls keep a making job, because `PRIMITIVES_LINEAGE.md` already assigns one to each. `Point_Line_Grid` stays a comparison and `Primitives_Melencolia` stays reflective.
  - The kit chain runs to CP1. `Point_One` → `Point_Coordinates` → `Point_Lines` stay adjacent, as `TUTORIAL_LINEAGE.md` l.79 asks.
  - The first `if` and the first function with parameters and a return value come at `Point_Lines`; the list, the loop and named input actions at `Point_Trace`.
  - Six workshops: debugging and the class reference (W01), `my_room` from nothing (W02), version control (W03), import (W04), a signal and a door (W05), export (W06).
  - Heavy stops: {{HEAVY}}. The first two are what the verified studies already do, all at use depth. `Point_Coordinates`' four are the hall's own subject (reference frames) plus the ruled pickup. `Point_Trace`'s input actions come through a supplied mover.

{{SEQ:primitives}}

### 2. transformation

- **Today [M]:** seven fragment tutorials and no player. `Trans_Scale` shrank to 16 lines of prose in the working tree. `Trans_Introduction` and `Trans_Translation` repeat one helper block. No transformation map has a hazard, and `Trans_Pit`'s tutorial says it has no enforced failure.
- **Proposed [P]:**
  - Five making halls; the body and camera (W07); a headset day and the scale comparison on the xr route (W08, W09); HUD, pause and retry (W10).
  - `class_name` is first taught at `Trans_Pit`, as a base the learner's own pusher and gate share.
  - CP3 ends the short course (stops 0-30), which first meets every capability of the survey's minimum complete game.
  - `Trans_Body` stays an encounter. Its `carve_grid` with `LeakData` is a reading for W11's question of what survives.
  - Walk-in objects are called "collectibles"; "pickup" is kept for grabbing.

{{SEQ:transformation}}

### 3. array_tutorial

- **Today [M]:** `Array` has no `tutorial.md`. `Tutorial_3D` and the two tiling halls are stubs of 5 to 9 lines. `Tutorial_Disco` is stale.
- **Proposed [P]:**
  - `Array` carries the lifetime lesson (critique #4) and the first code form of instancing.
  - `Tutorial_Tiling_Floor` gives the first computed texture.
  - `Tutorial_Disco` gives the first MultiMesh and the first profiling, measured against the node grid, and the first branch before a risky rewrite.
  - `Tutorial_3D` becomes a variation inside `Array`.

{{SEQ:array_tutorial}}

### 4. color

- **Today [M]:** six prose guides and two fragment pages. Only `Color_Grid_Pallet`'s code matches the installed work. Lights, materials, signals and autoloads are used and never taught. Five of the eight halls exist only in the working tree.
- **Proposed [P]:** six making halls and four workshops: two rooms and an owner (W11), particles compared with the hall's bounded MultiMesh (W12), a settings panel (W13), and the game in the headset (W14, xr route). `Color_Paint` sets the room's rule for which input reaches the world.

{{SEQ:color}}

### 5. tiling

- **Today [M]:** five prose companions. The three `Ribbon_Patterns` halls that end the sequence have no tutorial and are untracked.
- **Proposed [P]:**
  - Saving across restarts (`Pattern_Foundry`), the first shader edit (`Tutorial_Pattern`) and a bounded undo of snapshots (`Symmetry_Seventeen`), then CP4.
  - `Ribbon_Patterns_03` (a versioned recipe with validation, a shader with `discard`, a saved costume) is the natural later branch for `gd.errors` at change depth. It needs a tutorial written first.

{{SEQ:tiling}}

### 6. change

- **Today [M]:** `Change_Intro` is the most code-bearing tutorial in its slice, and its code matches the workbench. It measures the rate in x, not in time.
- **Proposed [P]:** keep the plot, and add a rate in time with a fixed step and a local pause. Then W15 reorganises `my_room` into one scene per exhibit with a hub, before the heavy systems arrive. `Flow_Field` stays an encounter.

{{SEQ:change}}

### 7. forces

- **Today [M]:** eleven of thirteen tutorials are prose describing the engine features each adapter uses. Nothing is built. Twelve lesson adapters extend `machine_stage.gd`, which no tutorial names. Every hall has a headless probe that no tutorial teaches, and the probes are untracked.
- **Proposed [P]:** four main making halls, the checks workshop (W16) and a character branch (W17). `Vectors_Act1_WhatAVectorIs`, `VFM_02_Operations`, `Vectors_Act2_VectorArithmetic`, `VFM_05_Launch`, `Vectors_Act4a/4b`, `VFM_07_Gravity` and `VFM_08_Arena` stay encounters. `VFM_08_Arena` (subclass one creature, override its target search, ray sight) is the obvious optional studio.

{{SEQ:forces}}

### 8. formfinding

- **Today [M]:** five fragment pages taken from shipped code, and none has a scaffold to run it in. The working-tree `FormFinding_Descent` dropped its code, which `FormFinding_Forge` still refers to.
- **Proposed [P]:** three making halls, in the order stopping, joints, then a game loop. None introduces a new capability; they deepen conditions, forces and design. `Catenary` (Curve3D) and `Relaxation` (a RefCounted Verlet class) are optional studios. `Annealing` keeps the named bridge from `curriculum.json` issue `annealing`: its seeded proposal stream is supplied.

{{SEQ:formfinding}}

### 9. wavefunctions

- **Today [M]:** six tutorials rewritten in September quote shipped code, and their next-pointers chain across half the sequence. The other six are April code for classes that do not exist.
- **Proposed [P]:** three making halls: a signal with arguments, a rendered note, and an instrument with buses and saved settings. `WaveFunctions_Synthesis_Lab`'s `ambient_patch` (runtime buses and effects, voices rendered on a worker thread) is an optional audio branch. The six illustrative halls stay encounters until rewritten (section 5).

{{SEQ:wavefunctions}}

### 10. randomness

- **Today [M]:** `Random_Definition` is the only runnable study outside the opening, and it is untracked. Five halls quote shipped code. The April halls (`Randomness_10_PRINT_Algorithm`, `Random_Cubes`, `Random_Rotate_Random_XYZ`, `Random_Space_Geometry`, `Random_Pheromone`, `Random_Space`) are illustrative and not runnable.
- **Proposed [P]:** four making halls ending in the capstone game, with CP5 there. `await` is first taught at `Random_Remove`, where a stale coroutine is the lesson, and a per-frame work cap at `Random_Walk`.

{{SEQ:randomness}}

### 11. noise

- **Today [M]:** eight encounter routes. `Lab_Path` is a 127-line template for classes, a `GameState` and an environment `.tres` that do not exist. No learner configures a `FastNoiseLite`.
- **Proposed [P]:** the proposal's "one modest terrain", with field, sampler, mesh and collider kept as four parts. `Noise_One`'s relief shader is supplied and read; the learner's first whole shader is `Shader_01_Shaping`.

{{SEQ:noise}}

### 12. shaders

- **Today [M]:** no tutorials. Each `final.md` reads GLSL well.
- **Proposed [P]:** every stop here needs a new `tutorial.md` (section 5, item 6). The feedback study is a branch built in the learner's room only; the hall stays as it is, because its `final.md` is written about the missing piece.

{{SEQ:shaders}}

### 13. cellularautomata

- **Today [M]:** seven encounter routes. `CA_AgentsCircuits` teaches Wireworld for a hall that now shows Rule 90 and a recursive pyramid.
- **Proposed [P]:** two making halls. `CA_BeyondBinary`'s LINK can be taught as `connect()`/`disconnect()`, and `CA_SoftRules` (CPU Gray-Scott into `ImageTexture.update`, which closes `Shader_10`'s open loop) is an optional studio.

{{SEQ:cellularautomata}}

### 14. fractals

- **Today [M]:** only `Fractal_Recursion` carries code, and that code is generic. The working tree dropped `Fractal_JuliaSet`, `Fractal_MandelbrotSet` and `Fractal_CrossSequence`, and took the GPU fractal works with them.
- **Proposed [P]:** three making halls: recursion and its stack, editor previews, and measured growth.

{{SEQ:fractals}}

### 15. lsystems

- **Today [M]:** seven desk routes and one hall with no tutorial (`LSystems_Shape_Grammars`). HEAD's cumulative `LSystem` class would collide with the project's existing global classes.
- **Proposed [P]:** four making halls built on the existing `utils/lsystem.gd`. `Assemblage_Same_Desire` stays an encounter.

{{SEQ:lsystems}}

### 16. proceduralgeneration

- **Today [M]:** seven desk guides. The desk they describe (`pg_workshop.gd`) is untracked. The HEAD fragments describe other constructions than the installed works.
- **Proposed [P]:** two making halls, CP6, and a 2D branch.

{{SEQ:proceduralgeneration}}

### 17. softbodies

- **Today [M]:** nine prose guides that quote `SoftBody3D` properties without naming the class. HEAD taught a hand-written mass-spring solver the halls do not use.
- **Proposed [P]:** two making halls on Godot's own soft body and joints. The character studio moved earlier, to W17. `SoftBodies_Affect_Theory_Visualization` (radiolaria particles) and `ProceduralGeneration_Reaction_Diffusion_Systems` (a SubViewport canvas) are optional returns to particles and feedback.

{{SEQ:softbodies}}

### 18. isosurfaces

- **Today [M]:** nine working-tree desk rewrites removed HEAD's cumulative extraction arc. Four fragment halls remain, one of them the only compute-shader lesson.
- **Proposed [P]:** four making halls that restore the arc (samples, extractor, brush, walkable cave) with the marching tables supplied. Threads and compute are a branch; compute needs a renderer other than the room's Compatibility.

{{SEQ:isosurfaces}}

### 19. boolean_surfaces

- **Today [M]:** no tutorials at HEAD. The working tree has three untracked prose pages with one code line between them.
- **Proposed [P]:** CSG as an editor blockout tool, then bake to a mesh.

{{SEQ:boolean_surfaces}}

### 20. swarmintelligence

- **Today [M]:** seven fragment pages written in April. They are abstract 2D code, and the installed works are embodied: `CharacterBody3D` agents, `ImageTexture` trails, `MultiMesh` flocks.
- **Proposed [P]:** three making halls, each optimising only against something measured. `SwarmIntelligence_PhysarumColony` is an optional texture and shader return.

{{SEQ:swarmintelligence}}

### 21. machinelearning

- **Today [M]:** eight April fragment pages, none runnable. `ML_Evolution` and `ML_Synthesis` teach something other than their hall's primary work.
- **Proposed [P]:** two making halls, where training state becomes saved data and a claim about learning becomes a test. `ML_Neural_Networks`, trained in Timer-driven batches, is optional.

{{SEQ:machinelearning}}

### 22. graphtheory

- **Today [M]:** eight April fragment pages. The `Graph` class never defines the `neighbours()` it is called with. No spine tutorial mentions the engine's A*.
- **Proposed [P]:** three making halls that open the route machinery the learner already used at `PG_Caves_Mazes`, drawn over the learner's own hub of exhibits.

{{SEQ:graphtheory}}

### 23. foundationscrisis

- **Today [M]:** eight April controller fragments. Three preload scenes that do not exist, and some pages carry stray generator tokens.
- **Proposed [P]:** every hall here is kind "reflect" in `curriculum.json` (nodes `assumption` and `limit`, whose borrow says "no forced coding quota"). The three studios on budgets, viewpoint and validation are optional. `Euclid_Parallel`'s plaque-emits-read signal is an optional return to W05.

{{SEQ:foundationscrisis}}

### 24. qfeplaboratory

- **Today [M]:** six April fragments. `QFEP_Phi_Term` has the only custom `signal` in any spine tutorial and never connects it. `QFEP_Sandbox` and `QFEP_Synthesis` are 9- and 7-line visitor instructions, and their Godot content sits in `technical.md`.
- **Proposed [P]:** `QFEP_Phi_Term` (kind reflect) is an optional studio. `QFEP_Sandbox` (kind compare) is the last main making hall: explicit wiring, a cut, and `UndoRedo` commands, whose undo does not undo what a cut connection delivered.

{{SEQ:qfeplaboratory}}

### 25. postfoundationscrisis

- **Today [M]:** eight September essays with one verified excerpt each and no making.
- **Proposed [P]:** every hall is kind "reflect" (nodes `situation` and `assembly`), so the four studios are optional. W18 and CP7 sit at `PostCrisis_Synthesis` because `assembly.make` is "A first independent work built from selected earlier capabilities"; W18 adds no new capability. The working tree already has the data link the optional studio reads: the Assembly Laboratory pose is saved to `user://` and read back by `assembly_return` and by the ledger's `visitor_record` mode.

Reflect halls and what this plan does at them:

{{KIND_TABLE}}

{{SEQ:postfoundationscrisis}}

---

## 4. Coverage [P]

Placement key:

- **main:** every learner on the path meets it (on the xr route for the two xr capabilities).
- **branch:** an optional studio or an optional step at a named stop.
- **outside:** named as a boundary and not taught.

"Depth at first" is the depth at the first meeting; "deepest on main" is the greatest depth any main stop sets, and where. The "requires met?" column checks the survey's prerequisite graph against this path's order; the two exceptions are explained in A.1.

{{COVERAGE}}

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

{{DEPTH_NOTES}}

---

## 5. What to fix in the current tutorials first

These are ranked by how early the problem sits on the path and by how many later stops depend on it. Nothing here is a claim that the fix is small.

1. **Make the opening exist at HEAD, or say plainly that it does not.** Everything in 1.5 is untracked. At HEAD the chain `Point_One` (old fragments) → `Point_Lines` (assumes Coordinates) is broken, `curriculum.json` does not validate, and {{NOT_HEAD}} cannot be started. This is Palle's decision: track the kits, or ship them as release zips. Parts belong to other sessions, so post on the forum before anyone commits (thread 260929-ia2d6 is the related open one).
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

{{SEGMENT_LOAD}}

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
- **The coverage table invites scoreboard reading.** {{CAPS}} capabilities with a depth column is a coverage figure, not a measure of learning.
- **The desktop-only exception is a real loss.** A cohort that takes it never meets the project's primary medium, and the path can be completed without a headset.
- **The late reflect halls lose making.** Making their studios optional follows the ruling, and it also means the last main making hall is `QFEP_Sandbox`.

**Q3. What lives in the dark spot?** Two things, one generative and one sealing.

- **Generative:** the transfer prompts. Each stop names a capability and asks for a choice; the worked example is one answer among many, and what the learner builds with it is not specified.
- **Sealing:** nothing here has been tried by a learner or run in Godot. Every first stop is a hypothesis about understanding, and the green validation in `build_plan_v2.py` checks order, route and depth labels, not whether anyone learns anything.

---

## Appendix

### A.1 Prerequisites met after their first stop

The build lists each of these, and each has a stated reason.

{{EXCEPTIONS}}

### A.2 Stop index

"HEAD" says whether the stop's starting material exists at HEAD ("ok"), is missing ("not startable"), or whether the hall itself is absent from HEAD's walk ("WT only").

{{STOP_INDEX}}

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

{{ID_MAP}}
