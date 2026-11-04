# Spine placement worklist: recent artifacts and ideas, by sequence

Made 3 November 2026 for Palle, who will walk the spine, add these into halls and arrange the maps. Each sequence below lists its halls in order and, under each hall, what is waiting for it. Nothing in this list has been placed. Every assignment is a proposal: one sorter per batch and one reviewer across the whole table, all reading the registry, the scripts and the hall blurbs. Change anything you disagree with.

## What is in it

- **Your 30 ideas** of 3 November (the list starting "The line inside large parallel lines"), marked **Idea**.
- **Recent artifacts that stand nowhere.** These are registry artifacts whose scene file was added since 1 October 2026 (or is not yet in git). They appear in no hall `map_data.json`, no museum plan or bake, no Void room or trial file, and no playground hall.
- **Recent artifacts that stand only in the Void tower or on the playground**, with no spine hall or museum hall yet.
- **The 49 dream figure families**, which the museum building dresses one per hall and the plan never deals. Each is sorted to the earliest sequence whose words its making needs.
- **Three large families**, summarised once rather than token by token: the 228 `mod_*` modular terms, the 36 `matter_reference` studies and the dream figures.

**Caveats:**
- 8 October is the date the repo landed, so "since 1 October" also includes older work that was committed that day.
- An artifact listed only in a sequence file or in the book counts as standing nowhere.

**Columns:**
- **Role:**
  - *primary*: the hall's main encounter;
  - *secondary*: beside it;
  - *pool*: one of many variants to curate from;
  - *infrastructure*: a tool or part.
- **Status:** where it stands now.
- **Conf.:** how sure the sort is. Low means look first.

The data is in [worklist.json](worklist.json): one row per item with sequence, hall, role, `also`, confidence, reason and question.

## Count by sequence

| Sequence | Items | Of which ideas |
|---|---|---|
| primitives | 57 | 4 |
| transformation | 30 | 2 |
| logic | 2 | 0 |
| array_tutorial | 4 | 1 |
| color | 11 | 1 |
| tiling | 8 | 0 |
| change | 1 | 0 |
| forces | 10 | 0 |
| formfinding | 1 | 0 |
| wavefunctions | 18 | 6 |
| randomness | 11 | 3 |
| noise | 3 | 0 |
| shaders | 2 | 1 |
| cellularautomata | 3 | 1 |
| fractals | 1 | 0 |
| lsystems | 1 | 0 |
| proceduralgeneration | 1 | 1 |
| softbodies | 4 | 1 |
| isosurfaces | 2 | 0 |
| boolean_surfaces | 3 | 0 |
| swarmintelligence | 1 | 0 |
| graphtheory | 1 | 0 |
| foundationscrisis | 2 | 2 |
| postfoundationscrisis | 7 | 1 |
| facade_assembly | 1 | 1 |
| particles | 1 | 1 |
| kit | 24 | 4 |

**Nothing waiting:** machinelearning, qfeplaboratory.

## 1. primitives

Halls: Point_Zero → Point_One → Point_Coordinates → Point_Lines → Point_Trace → Point_Line_Grid → Point_Triangle_Context → Primitives_Polythedra → Point_Animatedcube → Primitives_Ignorance → Primitives_Godot → Primitives_Columns → Primitives_Profiles → Primitives_Portals → Primitives_Melencolia

### Point_One

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `scaffold_workstation_points` (Scaffold workstation / points) | secondary | Void/playground only | high | The points station of the shared scaffold apparatus. It stands on Void floor 01 (Point_One), and its parts grow from points first. |

### Point_Lines

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The line inside large parallel lines (black rods to the ceiling, one line you walk between) | secondary | to build | medium | Point_Lines blurb already says 'Parallel lines organize direction'; a walk-between line among ceiling rods is that hall's idea at body scale (existing parallel_lines declares foundationscrisis/Euclid_Parallel). · also foundationscrisis, array_tutorial |
| `timber_plank_1m` (Timber plank / 1 m) | infrastructure | stands nowhere | high | construction_path puts kit:timber_plank_1m in Point_Lines: a measured segment given width and a collider (the line made into a building part). · also kit |
| `timber_plank_2m` (Timber plank / 2 m) | infrastructure | Void/playground only | high | Comes from primitive_kit.json: a carried, measured plank that freezes on release. It is building stock, reused as a part on the WaveFunctions_Intro floor (64) and inside sun_feather. · also primitives, wavefunctions |
| `timber_plank_4m` (Timber plank / 4 m) | infrastructure | stands nowhere | high | The same line-to-timber prefab as the 1 m plank; construction_path maps it to Point_Lines. Fixed copies support a path. · also kit |
| `tape_roll_barrier` (Tape roll / striped barrier) | pool | stands nowhere | medium | A striped tape that marks a boundary without making a collision wall; construction_path maps it to Point_Lines, and it also echoes the boundary argument of Point_Triangle_Context. · also kit |
| `tape_roll_masking` (Tape roll / masking) | pool | stands nowhere | high | Declared primitives: click start, click end for one strip, a line as a tool. construction_path maps kit:tape_roll_masking to Point_Lines. · also kit |
| `tape_roll_pink` (Tape roll / pink marking) | pool | stands nowhere | high | The same tape-line tool in pink; construction_path maps kit:tape_roll_pink to Point_Lines. · also kit |
| `scaffold_workstation_lines` (Scaffold workstation / lines) | secondary | Void/playground only | high | The rods stage of the scaffold apparatus, placed on Void floor 03 (Point_Lines) beside the tape station. |
| `tape_roll_printed` (Tape roll / printed) | secondary | stands nowhere | medium | The tape prints its own length, endpoints, heading and slope, which is Point_Lines' 'Lines, Networks, Measure'; construction_path puts the tape rolls in Point_Lines. · also kit |
| `tape_roll_station` (Tape / give a line a surface) | secondary | Void/playground only | high | It declares primitives and 'give a line a surface', and it stands on Void floor 03 (Point_Lines, 'What gives a line its force?'). |

### Point_Trace

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_sea_forms` (Dream Body — sea forms) | pool | dressed by the museum | low | The swan neck and four tentacles are beads laid along splines, spaced by their own radius (points along a path), with a radiolarian ring-lattice ball. · also isosurfaces, fractals |
| `trace_short_memory` (A line with a short memory) | pool | stands nowhere | high | A variant of the draw_dot recorder (it keeps only the last 32 positions), the same argument as the Trace hall's duration and residue; listed in trunk_branches and museum_core_encounters under primitives. |
| `bubble_brush` | secondary | Void/playground only | high | Its description reads 'A painting tool for Point Trace': dwell becomes sphere size and movement becomes a chain of points and lines. · also color |
| `hand_canvas` | secondary | stands nowhere | medium | A glass pane 'like Point Trace's GlassWall' that tracked fingertips paint. Marks accumulate as traces, tagged point_trace. · also color |
| `head_trace_projection` (A line you did not hold) | secondary | stands nowhere | high | It was written for Point_Trace (the headset path projected to the floor) and was taken out of the hall on 29 Sept; the text is kept in Point_Trace/trace-retired-encounters.md. |
| `line_trace_monitor` (Line and Trace / Live Illustration) | secondary | stands nowhere | high | Declared primitives. Two fixed endpoints keep the same segment while a moving point leaves three sampled routes, which is Point_Trace's line-versus-trace argument. |
| `stipple_jigsaw` | secondary | Void/playground only | high | Shares the bubble_brush registry and the point/trace tags; each punch leaves a dot, so dot spacing records speed over the interval, which is a point trace. · also change |
| `trace_paint_box` (Hand in / paint kept) | secondary | Void/playground only | high | A hand-drawn trace volume where strokes stay after the hand leaves. It is placed on Void floor 04 (Point Trace). |
| `trace_point_ball` (Trace ball / 28 cm) | secondary | stands nowhere | high | Its purpose is to tell the moving body apart from the stored trace; the Trace ramp records its path, and construction_path maps it to Point_Trace. · also forces |

### Point_Triangle_Context

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `surface_ball_test` (Surface test / white gravity points) | infrastructure | stands nowhere | medium | primitive-prefabs.json maps 'White balls / surface test' to Point_Triangle_Context. It is a reusable component that tests walkable surfaces, so it could also serve Primitives_Polythedra. · also kit |
| `timber_panel_1x1` (Timber panel / 1 × 1 m) | infrastructure | stands nowhere | high | 'Two triangles share a diagonal': the face made into a part. construction_path maps it to Point_Triangle_Context. · also kit |
| `timber_panel_2x1` (Timber panel / 2 × 1 m) | infrastructure | stands nowhere | high | A size variant of the triangle-pair face panel; construction_path maps kit:timber_panel_2x1 to Point_Triangle_Context. · also kit |
| `timber_panel_2x2` (Timber panel / 2 × 2 m) | infrastructure | stands nowhere | high | A size variant of the triangle-pair face panel; construction_path maps kit:timber_panel_2x2 to Point_Triangle_Context. · also kit |
| `pythagoras_cubicle` (Pythagoras / walls made of proofs) | secondary | stands nowhere | medium | Walls made of right-triangle area proofs (c² vs a²+b²), one step on from the triangle hall. Tagged void, so it may be meant for the tower instead. · also transformation |
| `pythagoras_floor` (Pythagoras / the same four panels) | secondary | stands nowhere | medium | Four congruent right triangles translate inside one square to leave c² or a²+b². It is a triangle area proof done by translation. Tagged void. · also transformation |
| `scaffold_workstation_surfaces` (Scaffold workstation / surfaces) | secondary | Void/playground only | high | The triangular-halves stage of the scaffold apparatus, placed on Void floor 05 (Triangle, map Point_Triangle_Context). |

### Primitives_Polythedra

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `wedge_blocker` (Striped wedge / wp ramp) | infrastructure | stands nowhere | high | It is the original wp walkable prism adapter; primitive-prefabs says the triangular-prism topology supplies a slope, and the wedge terms sit in Primitives_Polythedra. It works as a ramp part more than as an exhibit. · also kit |
| `dream_panel_robot` (Dream Body — panel robot) | pool | dressed by the museum | low | Panel armour of BoxMesh plates and bent shells held a gap off capsule limbs, with chrome sphere joints: solids assembled into a body. · also transformation |
| `pentagonal_bipyramid_7` (Pentagonal bipyramid / 7 vertices) | pool | stands nowhere | high | A 7-vertex comparison solid (an optional crystal study, 'seven vertices does not determine a unique solid'); construction_path maps it to Primitives_Polythedra. |
| `traffic_pyramid_5` (Traffic pyramid / 5 vertices) | pool | stands nowhere | high | A 5-vertex comparison solid kept as a pickable item (it marks a boundary); construction_path maps it to Primitives_Polythedra. |
| `pyramid_blocker` (Striped pyramid blocker) | secondary | Void/playground only | medium | Category is primitives: a closed five-faced solid, a polyhedron that blocks. Its tags 'construction' and 'reusable' also make it a kit part. · also kit |
| `scaffold_workstation_solids` (Scaffold workstation / wedge and pyramid) | secondary | Void/playground only | high | The description says Polyhedra adds its 1:10 wedge and pyramid shelf. It is placed on Void floor 06 (Polyhedra, map Primitives_Polythedra). |
| `tetrahedron_blocker` (Striped tetrahedron blocker) | secondary | stands nowhere | high | construction_path.json and primitive-prefabs.json place the tetrahedron (4 vertices) in Primitives_Polythedra, where a closed solid becomes an obstruction or a support. |

### Point_Animatedcube

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `platform_block` (One-metre platform / structure 2) | infrastructure | Void/playground only | high | A one-metre supporting cube with wp edge joins, already reused as building stock on the Void floors for FormFinding_Descent (58) and Random_Cubes (81); it is a construction part, not an argument of its own. · also formfinding, randomness |
| `scaffold_workstation_quads` (Scaffold workstation / full square faces) | secondary | Void/playground only | high | The full-square-faces stage of the scaffold apparatus, placed on Void floor 07 (Cube, Point_Animatedcube); it carries the wedge and pyramid shelf from Polyhedra. |
| `square_assembly_table` (Square faces / folded edge assembly) | secondary | Void/playground only | high | Folds square faces into a cube (the CUBE button sets 90 degrees) and is placed on Void floor 07, Point_Animatedcube. · also formfinding |
| `void_cube_walkway` (Cube + wedges / carried walk-up) | secondary | Void/playground only | high | It declares primitives and transformation and stands on Void floor 07 (Cube, map Point_Animatedcube); thirty cubes and wp ramps make a walkable platform out of the cube. · also transformation |

### Primitives_Godot

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_brass_stamen` (Dream Body — brass stamen) | pool | dressed by the museum | medium | The armature is built only from the engine's primitive shelf: 23 CylinderMesh pipes, 24 SphereMesh elbows, TorusMesh flanges and BoxMesh gear teeth. · also transformation |
| `dream_dragon` (Dream Body — dragon) | pool | dressed by the museum | medium | An S-spine of SphereMesh segments with cone ridges, capsule legs and PrismMesh frills, under a hexagonal scale texture. DreamIso is used only for its 'cast' value. · also tiling, isosurfaces |
| `dream_stijl_robot` (Dream Body — stijl robot) | pool | dressed by the museum | medium | A Rietveld body of BoxMesh slabs and bars that pass each other, with SphereMesh joints and CylinderMesh pins: primitive shelf parts in primary colours. · also color |

### Primitives_Columns

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_couch_lounge` (Dream Body — couch lounge) | pool | dressed by the museum | low | A reclining figure on a chaise built as a superellipsoid sweep (exponent 0.30/0.36), with a dip pressed in and lumpy sine-warped cushions. Its strongest axis value is 'melt'. · also softbodies |
| `resolution_colonnade` (Rings of Ash — Gallery) | pool | stands nowhere | high | The standalone 20x28 m gallery (map_ready false). Primitives_Columns already places resolution_colonnade_museum, and artifacts.md calls this one 'a separate source arrangement'. |
| `resolution_totem` (Rings of Ash — Resolution Totem) | pool | stands nowhere | high | It is the shared totem builder behind Primitives_Columns (radial segments and profile sampling); Columns' artifacts.md names it, and a single totem is a variant to curate from. |

### Primitives_Profiles

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Inside a profile array like inside fish bones (rib corridor) | secondary | to build | medium | A corridor of repeated profile sections (ribs) is a profile arrayed along a path, joining Primitives_Profiles to the array idea. · also array_tutorial |
| `dream_asawa_wire` (Dream Body — asawa wire) | pool | dressed by the museum | medium | The body is torus rings and swept cord laid on an invisible lathe surface built from a 15-key half-width profile, so the volume exists only as line. · also tiling |
| `dream_stella_wall` (Dream Body — stella wall) | pool | dressed by the museum | medium | A wall relief of extruded 2D outlines (annulus arcs, Archimedean spirals, triangulated sectors, plates with real holes) on four tilted depth planes. · also color |
| `dream_type_wrap` (Dream Body — type wrap) | pool | dressed by the museum | low | 54 to 78 swept bandage bands printed with huge cropped rectangle-stroke letters (E F H I L T O C U N Z): letter outlines carried onto a body. · also tiling |
| `dream_vasarely_beast` (Dream Body — vasarely beast) | pool | dressed by the museum | low | One continuous profile swept along a 25-point Catmull-Rom spine with a 25-key radius profile, routed through a hole in itself. · also isosurfaces |
| `cyrtoid_by_rule` (Cyrtoid, by rule) | secondary | stands nowhere | medium | Declared primitives first. Its first rules are a profile turned round its axis, which matches Profiles' 'follow a borrowed boundary into a body and keep the source beside it' (the source being Haeckel plate 31). · also proceduralgeneration, tiling |
| `letter_tyre` (O / Roll the closed sweep) | secondary | stands nowhere | high | The O glyph outline swept along a closed path into a tyre. Primitives_Profiles' blurb is about O surrounding an opening, and it comes from glyph_profile_gallery. · also softbodies |

### Primitives_Melencolia

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `melencolia_platform` (Melencolia / construction court) | primary | stands nowhere | medium | It recomposes the known kit (blocks, timber sheets, wedges) into a usable 5x5 court; construction_path and prefab-workbench map it to Primitives_Melencolia, the sequence's closing hall. |

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Plateau with an edge and a wedge entrance; wedges of different heights to a cylinder of white primitives; the same in colour; movable; later the kidney form; simplex-noise pits and plateaus like golf sand pits | primary | to build | medium | Wedges to a cylinder of white primitives is a primitives build; the same in colour and the simplex-noise pits extend it through color and noise. · also color, noise |
| **Idea:** The worker being and its six dancers; the flight bay; the biome_object stratum (built 2 Nov in the court, floor 210) | primary | to build | medium | Built 2 Nov in the court on floor 210; biome_object's ladder starts at Primitives and worker_being has a body per stage, so both run the whole spine, with the six dancers as a small swarm. · also swarmintelligence |
| `biome_primitives` (One world: from a point to a passage) | infrastructure | stands nowhere | low | A 12 m walkable biome ground that steps from point/line/trace/grid to triangles and solids, with rotation and scale revisits. It says it is a prototype and not installed in the spine. · also transformation |
| `playground_ball` (Playground ball / six sockets) | infrastructure | stands nowhere | medium | Declared primitives. The six-socket hub is 'the POINT of the inventory', a construction part joined by rods on the playground, not a hall exhibit. · also kit |
| `playground_rod` (Playground rod / two points) | infrastructure | stands nowhere | medium | Registry calls it 'the LINE of the inventory' (map_sequences primitives); it is an inventory item in commons/data/inventory/items.json that snaps between playground balls, so a construction part for the Void playground, not a hall exhibit. · also kit |

## 2. transformation

Halls: Trans_Pre → Trans_Introduction → Trans_Translation → Trans_Rotation → Trans_Scale → Trans_Body → Trans_Pit → Trans_Playground

### Trans_Translation

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_bacon_smear` (Dream Body — bacon smear) | pool | dressed by the museum | medium | Each of its 40 strokes is a sample point moved from p0 to p1, a displacement weighted by height that shears the body. Its 'cast' value marches the same strokes with DreamIso. · also change, isosurfaces |
| `trans_machine_suspended` (Rope / suspended construction cube) | pool | stands nowhere | low | A cube pulled on pinned rope links: translation bounded by gravity, contact and a slot. construction_path maps it to Trans_Translation. · also forces |
| `transport_cube_study` (TC / choose a journey) | pool | Void/playground only | medium | A parameter study of the transport cube, category transforms: the journey's direction is normalised in the local frame and rotates with the assembly. That is translation under a frame. It has only been tried in the tc_parameters trial. · also forces |
| `sun_feather` (Sun feather / ten transformed prefabs) | secondary | Void/playground only | medium | Ten planks around one insertion point, with sliders for rotation and uniform scale between copies. This is composed transforms, and it is placed on Void floor 15 (Trans_Translation). |
| `trans_machine_crank` (Wood crank / metal rod / piston) | secondary | stands nowhere | medium | Rotation drives a rod that translates a piston; construction_path puts all four machines in Trans_Translation (auto lane, unread). · also forces |

### Trans_Rotation

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Ada's hand spins like the rotating cubes; the recursive endless hand in 3D | secondary | to build | medium | Ada's hand spinning like rotating_cube is rotation applied to the body; the recursive endless hand is fractals' self-similarity. · also fractals |
| **Idea:** Large rotating discs with swirl patterns (Duchamp rotoreliefs) | secondary | to build | medium | Duchamp's rotoreliefs are flat swirl patterns that read as depth only when they rotate, so the illusion is a direct argument about rotation. · also color |
| `dream_botanic_mannequin` (Dream Body — botanic mannequin) | pool | dressed by the museum | medium | A lofted torso shell whose rings yaw with the square of height and carry contrapposto offsets, so the twist is in the geometry and five prints show it. · also tiling |
| `dream_ceramic_puppet` (Dream Body — ceramic puppet) | pool | dressed by the museum | medium | Each limb is a chain of capsule links on ball joints whose lean angle is integrated link by link. The cloth is a spanning-tree maze, so it could also go to GT_Spanning_Trees. · also graphtheory |
| `dream_deity_figurine` (Dream Body — deity figurine) | pool | dressed by the museum | medium | Four or six arms fanned around the torso by elevation angle, a tribhanga spine of yawed rings, and a trunk whose bend axis rotates each segment. · also array_tutorial |
| `dream_porcelain_doll` (Dream Body — porcelain doll) | pool | dressed by the museum | medium | 51 to 79 TorusMesh bands threaded along each limb, each turned about the limb axis by a precessing phase: a repeated turn becomes a spiral wrap. · also tiling |
| `care_shared_crossing` (Care / shared crossing) | secondary | Void/playground only | medium | Category is transforms, and it is a movable pivot crossing built between the Rotation gantries, where a chosen centre changes reach. · also postfoundationscrisis |
| `movable_pivot_walkway` (Plank / move the pivot) | secondary | Void/playground only | medium | Moving the bearing changes the centre of rotation of a walkable deck, so its argument is rotation about a pivot. It is currently placed on Void floor 15 (Trans_Translation). |
| `trans_machine_lever` (Working lever / two effort arms) | secondary | stands nowhere | low | A beam turning on a real hinge, pulled at two distances, which is rotation about a fixed centre (Trans_Rotation: 'the centre stays'). construction_path's auto lane says Trans_Translation instead. · also forces |
| `transformation_sampling` (Between the Pictures — Transformation Studies) | secondary | stands nowhere | low | Declared transformation and change: zoetrope drums rotating twelve poses through translation, rotation, scale and their composition. Its sampling and aliasing point could also suit change. · also change |

### Trans_Scale

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_batik_beast` (Dream Body — batik beast) | pool | dressed by the museum | low | Every mass is a non-uniformly squashed SphereMesh (stuffed-toy softness), worn under a batik print painted in code. · also tiling |
| `trans_machine_sorter` (Gravity / sort by physical size) | pool | stands nowhere | low | It sorts equal-mass spheres by physical size on identical rails, so scale has a consequence. construction_path's auto lane says Trans_Translation instead. · also forces |
| `barrier_scale_line` (DO NOT CROSS / from toy to architecture) | secondary | Void/playground only | medium | Nine DO NOT CROSS barriers grow from table toy to a 5.5 m structure, so the argument is scale. It is currently placed on Void floor 15 (Trans_Translation). |

### Trans_Body

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_horse_hybrid` (Dream Body — horse hybrid) | pool | dressed by the museum | low | A striding human body with a swept horse-head muzzle, marble skin and a 'beast' axis (horse, hydra, reliquary, blossom, swarm): a body transformed rather than an algorithm on show. · also primitives |
| `dream_oni_dragon` (Dream Body — oni dragon) | pool | dressed by the museum | low | A punching sphere-spine body whose 'possession' axis (three_faced, six_armed, brood) multiplies the body. Its 'fused' curse is the heaviest DreamIso use outside fetish_idol. · also primitives, isosurfaces |

### Trans_Pit

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_gehry_metal` (Dream Body — gehry metal) | pool | dressed by the museum | low | 13 to 21 bent sheets, each tipped, rolled and twisted about its own base so they lean past each other. Some are perforated with real holes. · also boolean_surfaces |

### Trans_Playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_masked_dancer` (Dream Body — masked dancer) | pool | dressed by the museum | low | A mid-step dancer whose spine segments yaw along a seeded 18 to 40 degree twist, one arm thrown out, under a mask shell with eye holes cut by omitting cells. · also randomness |
| `mod_s_descent_model` (modular · S descent / two-storey cutaway model) | pool | Void/playground only | medium | A modular term whose registry block declares chapter transformation (hollow section x curved path into slide, landing, slide). · also kit |
| `mod_s_portal_copies_model` (modular · One portal / falling from standing to its head) | pool | Void/playground only | medium | It declares chapter transformation: one portal under a half-turn, a translation and a curl, the transformations composed. · also primitives |
| `scaffold_workstation_crossing` (Scaffold workstation / carried crossing) | pool | Void/playground only | medium | A saved scaffold construction, registry category transformation, in which a 20 cm hand-model edge becomes 2 m at BUILD (a scale change) in neutral materials that come before Colour. No Void floor places it yet, so it sits with the other scaffold builds in Trans_Playground. · also primitives |
| `scaffold_workstation_display` (Assembly shop / glass test bay) | primary | Void/playground only | high | The glass test bay of the assembly shop, registry category transformation, placed on Void floor 20 (Transformation / Scaffold playgrounds, map Trans_Playground). · also primitives |

### new: Trans_Hierarchy

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `architecture_spine` (The Corridor Has a Spine) | primary | stands nowhere | medium | Eight bays in a parent-child Node3D chain. Local rotation, offset and a scale ratio compound down the hierarchy (0.9^7), which is transform composition. Category transforms. · also lsystems |
| `architecture_variations` (One Arcade, Four Operations) | secondary | stands nowhere | medium | Applies curve, hinge, field-repeat and stretch to architecture_spine's bay. These are rigid and deforming transforms side by side. Category transforms. · also array_tutorial |
| `model_overflow` (The Model Calls Itself) | secondary | stands nowhere | low | Three faults built on architecture_spine's bay: recursion with no base case, a forgotten transform restore, and vertex writes that wrap modulo. Category transforms; the recursion half also argues Fractal_Recursion. · also fractals, array_tutorial |

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `biome_inheritance` (Inherited forms: doors become banners) | infrastructure | stands nowhere | low | A map-driven biome layer whose panels are introduced, then raised at translation, turned at rotation, narrowed at scale, coloured at colour and patterned at tiling. It runs across sequences rather than sitting in one hall. · also color, tiling |

## 3. logic

Halls: Logic_Event → Logic_AND → Logic_Alternatives → Logic_Assemblage

### Logic_AND

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Family:** matter_reference (36 tokens: matter_reference, matter_reference_and, matter_reference_or, matter_reference_xor, matter_reference_not, matter_reference_nor, matter_reference_nand, marble_reference_and, marble_reference_or, marble_reference_xor, marble_reference_not, marble_reference_half ...) | pool | Void/playground only | medium | A family of physical logic gates (AND/OR/XOR/NOT/NAND/NOR, plus a marble half adder) whose result Jolt contacts decide. Tried in the matter_logic_reference trial. · also primitives |
| `matter_and` (Matter / AND) | primary | Void/playground only | high | Registry category is logic: a physical AND where a marble arrives only when both gaps are filled. · also forces |

## 4. array_tutorial

Halls: Array → Tutorial_3D → Tutorial_Tiling_Floor → Tutorial_Tiling_Walls → Tutorial_Disco

### Array

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_obi_frieze` (Dream Body — obi frieze) | pool | dressed by the museum | low | One plank primitive builds every figure, and the 'chorus' axis (rank, ring, spiral, cascade, huddle) arranges repeated figures. · also primitives, transformation |
| `array_index_bridge` (Array / hand selects the shaft) | primary | Void/playground only | high | Registry declares sequence array_tutorial; a 7x7 index grid whose index selects a real tile is the array-address lesson of the Array hall. · also logic |

### Tutorial_3D

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** New Order shirt of frequency but round space (pulsar ridgelines bent into a cylinder) | secondary | to build | medium | pulsar_visualizer declares array_tutorial; stacked pulsar ridgelines (the Unknown Pleasures plot) bent into a cylinder is an array wrapped into round space. · also wavefunctions |
| `suspension_passage` (Seven places for a passage) | pool | stands nowhere | medium | The original desktop study after Hatoum (map_ready false). Its museum adapter, reference_suspension, is already installed in Tutorial_3D, so this token is the source version. |

## 5. color

Halls: Color_Context_Placed → Color_Flashlight → Color_Nails → Color_Rainbow → Color_Pillar → Color_Grid_Pallet → Color_Paint → Color_Walls

### Color_Context_Placed

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `chroma_drum` | pool | stands nowhere | medium | Declared color. It belongs to the chroma DNA family (shingle/fin, colour decided by standpoint) alongside the chroma_stack and chroma_translation censuses already in Color_Context_Placed. |
| `dream_garet_still` (Dream Body — garet still) | pool | dressed by the museum | low | A toy plastic figure on Catmull-Rom capsule curves in three loud skins (waves, fishnet, bumps) with a cherry-and-orange still life: a placed colour assignment more than any one algorithm. · also wavefunctions |

### Color_Flashlight

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_paik_light` (Dream Body — paik light) | pool | dressed by the museum | low | A white plastic figure whose colour is carried by a second emission texture and raised emissive blobs: colour as light on a surface. · also shaders |

### Color_Rainbow

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_nana_gloss` (Dream Body — nana gloss) | pool | dressed by the museum | low | A Niki-de-Saint-Phalle ovoid dancer in glossy painted skins (meander, Voronoi mosaic, primary blobs). Its 'poured' and fused values march 28 parts with DreamIso. · also isosurfaces, shaders |

### Color_Grid_Pallet

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `chroma_life` | secondary | stands nowhere | medium | Declared color. Game of Life columns in which colour records the rule; it fits Color_Grid_Pallet's 'colour at an address... ask the rule to run once more'. · also cellularautomata |

### Color_Paint

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** You are the buckets for the painting (Jackson Pollock): pour mode on the paint bucket | secondary | to build | high | Color_Paint is 'color as action'; a pour mode in which the player is Pollock's bucket fits beside ball_painting_demo, and pollock_painting_in_3d already exists. · also randomness |
| `dream_clay_splash` (Dream Body — clay splash) | pool | dressed by the museum | medium | Its argument is flat paint splashes that ignore anatomy, with a 'paint' axis of flat, crust, flood and bloom. 'Melted' and 'fused' (DreamIso) are side values. · also isosurfaces, softbodies |
| `graffiti_stick` | secondary | Void/playground only | high | Three spray cans make a held gradient; each nozzle deposits exactly as the Colour Paint spray cans do. |
| `moving_canvas` | secondary | Void/playground only | medium | A motorised spray canvas painted by any spray tool, paired with graffiti_stick. Its rotate/scale/lift loops also teach transformation. · also transformation |
| `paint_station` (Paint the wood / tins, stains and timber panels) | secondary | stands nowhere | high | Declared color. Emulsion over stain on timber panels is subtractive mixing done by action, which matches Color_Paint's 'colour as action'. |

### Color_Walls

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `chroma_filter` | secondary | stands nowhere | high | Declared color. Three coloured panes cross in front of a white corner, and how many panes lie between you and the white depends on where you stand. Color_Walls' blurb: 'Step sideways and another colour gathers between the panes.' |

## 6. tiling

Halls: Pattern_Disco → Pattern_Foundry → Tutorial_Pattern → Array_Patterns → Symmetry_Seventeen → Pattern_Temple → Ribbon_Patterns_01 → Ribbon_Patterns_02 → Ribbon_Patterns_03

### Pattern_Foundry

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_hokusai_kimono` (Dream Body — hokusai kimono) | pool | dressed by the museum | medium | One lofted robe wearing six code-painted textile patterns (seigaiha lattice, wave combs, key-fret meander, peony scatter): a loom recipe on a bending sheet. · also primitives |
| `jacquard_weaver` (Twelve-hook Jacquard loom) | primary | Void/playground only | high | It declares tiling, and Pattern_Foundry's blurb already asks the visitor to follow a loom recipe; the punched cards drive the repeat. · also array_tutorial |
| `weave_layers` (A pick becomes a layer) | secondary | Void/playground only | high | It declares tiling and opens the jacquard_weaver's loom records into layers, so it is the loom's companion in the same hall. |

### Tutorial_Pattern

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_painted_chorus` (Dream Body — painted chorus) | pool | dressed by the museum | medium | Three columnar figures where the mark replaces the body: each 'mark' value (labyrinth, banded, marbled, scaled, sliced) rebuilds the segment geometry. · also color |

### Array_Patterns

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_griffin_plume` (Dream Body — griffin plume) | pool | dressed by the museum | low | Its skin is offset rows of shingled eye-spot ovals, rescaled on neck, belly and legs, worn by an S-spine sphere chain with plume fans. · also primitives |

### Symmetry_Seventeen

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_rocaille` (Dream Body — rocaille) | pool | dressed by the museum | low | Two entwined capsule-curve bodies dressed in ornament: wave stripes, a fish-scale lattice and volute filigree. 'Slumped' and 'fused' kiln values come off the same joints. · also isosurfaces, softbodies |

### Pattern_Temple

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_dotted_colossus` (Dream Body — dotted colossus) | pool | dressed by the museum | medium | The 'cladding' axis dresses one muscled body in dots, marble, running-bond brick, fur or drape, as world-triplanar textures and as geometry: dressing a surface as a receiver. · also noise |
| `dream_kruger_suit` (Dream Body — kruger suit) | pool | dressed by the museum | medium | The suit is one world-triplanar print (block glyphs, stripes, brush slashes, greek-key maze) that runs unbroken across about 75 primitives. · also primitives |

## 7. change

Halls: Change_Intro → Flow_Field

### Change_Intro

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_panton_pop` (Dream Body — panton pop) | pool | dressed by the museum | low | One continuous Panton S-ribbon whose spine is integrated from a keyed tangent angle, so the silhouette is one accumulated gesture. Oval holes are cut through the shell. · also boolean_surfaces |

## 8. forces

Halls: Vectors_Act1_WhatAVectorIs → VFM_05_Launch → VFM_03_Motion → Vectors_Act3_FieldsAndMotion → Vectors_Act4a_KineticForces → Vectors_Act4b_Oscillation → Change_Choreography → VFM_07_Gravity → VFM_09_Legs → VFM_08_Arena → Vectors_Act5_ForceAsPlace

### VFM_05_Launch

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `force_impact_club` (Oversized impact club) | secondary | stands nowhere | medium | Declared forces. A held club whose real collision sends the PointBody ball onward, i.e. a launch by impulse, which is the ballistics hall. |

### VFM_03_Motion

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `film_force_motion` (A force changes a journey) | secondary | stands nowhere | medium | A film of two force vectors summed head to tail bending a journey, then balanced forces leaving the motion as it was. That is VFM_03_Motion's 'what forces do over time' (Vectors_Act1 would be the other choice). |

### Vectors_Act4a_KineticForces

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `matter_friction_coast` (Matter / Keep Going) | pool | Void/playground only | high | The same impulse gives different stopping distances on different contact surfaces, so the friction is measured as a result. · also physicssimulation |
| `matter_friction_pull` (Matter / Almost Enough) | pool | Void/playground only | high | A hanging mass against static friction ('Almost Enough'), the threshold case among the friction studies. · also physicssimulation |
| `matter_friction_ramp` (Matter / Let Go) | pool | Void/playground only | high | Gravity and friction decide whether a cube slides on a tilted plank, which is the resistance theme of the kinetic-forces hall. · also physicssimulation |
| `matter_leaning_together` (Matter / Leaning Together) | secondary | Void/playground only | medium | A precarious gravity balance where forces cancel, with balance offsets you can tune. That matches the hall's line 'where forces cancel, form holds still'. · also forces |

### Vectors_Act4b_Oscillation

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `film_torque_purchase` (A longer arm, a smaller push) | secondary | stands nowhere | medium | The film compares crank arm length against push. Vectors_Act4b_Oscillation is the forces hall that already holds lever_balance and HingeCrank. · also transformation |

### Change_Choreography

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `paired_time` (A second together) | secondary | stands nowhere | high | Registry installed_maps names Change_Choreography, and that hall's artifacts, final and intent texts already describe it (two clocks with drift and offset, after Gonzalez-Torres), yet it is listed as unplaced. · also wavefunctions |

### VFM_09_Legs

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `support_polygon_lab` (What Lets a Body Stand?) | primary | stands nowhere | high | The VFM_09_Legs blurb ('Remove a support, shift a load, and release') is this lab, and its intent, final and artifacts texts name it, yet it is not placed. · also physicssimulation |

### VFM_08_Arena

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `arena_relation_lab` (What Makes an Encounter?) | primary | stands nowhere | high | VFM_08_Arena's blurb describes this artifact word for word: a creature turns when a candidate becomes visible, a meal changes what it does next, and carts collide under momentum. · also swarmintelligence |

## 9. formfinding

Halls: FormFinding_Descent → FormFinding_Catenary → FormFinding_Relaxation → FormFinding_Equilibrium → FormFinding_Annealing → FormFinding_Forge

### FormFinding_Equilibrium

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_tatlin_red` (Dream Body — tatlin red) | pool | dressed by the museum | low | A twisting, leaning tower triangulated from ring and rising edges so nearly every cell closes as a triangle, skewered by torn plates: a truss argument. · also graphtheory, transformation |

## 10. wavefunctions

Halls: WaveFunctions_Intro → WaveFunctions_Pendulum → WaveFunctions_Sine_Space → WaveFunctions_Unit_Circle → WaveFunctions_3D_Wave_Propagation → WaveFunctions_Effect_Sound → Wavefunctions_Bernini → WaveFunctions_John_Cage → WaveFunctions_AirMusic → Wavefunctions_Sky_Stairs → WaveFunctions_TrigWalkingPath → WaveFunctions_Synthesis_Lab

### WaveFunctions_Intro

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `scale_zoetrope` (Hand wheel / scale zoetrope) | primary | Void/playground only | high | A strobed disk (60 RPM at 12 Hz) whose 24 cubes come back each cycle. Registry category wavefunctions; it stands on Void floor 64 (WaveFunctions_Intro, 'the cube comes back'). · also transformation |
| `belt_drive` (Two wheels / one belt / 2:1) | secondary | Void/playground only | medium | Registry category is wavefunctions; two unequal circles at a 2:1 angular ratio sit next to the unit-circle study of rotation as a relation. · also transformation |
| `pillar_barber_roll` (Pillar / pink red white barber roll) | secondary | Void/playground only | high | Helical bands seem to climb under pure rotation, and a fixed witness shows the difference. It belongs to spinning_studies, category wavefunctions, and is placed on Void floor 64. · also transformation |
| `sine_yoke` (Hand wheel / visible sine yoke) | secondary | Void/playground only | high | A Scotch yoke: the crank's circular motion is carried out as the sine height of a cube. It is placed on Void floor 64, WaveFunctions_Intro. |
| `single_cube_turntable` (Hand wheel / one cube turntable) | secondary | Void/playground only | high | A hand-turned one-cube platform in the hand-wheel family, placed on Void floor 64 (WaveFunctions_Intro). Rotation as return. · also transformation |
| `torus_piston` (Wheel / cylinder / torus) | secondary | Void/playground only | high | A connecting rod turns wheel rotation into a periodic 1.60 m stroke. It belongs to the spinning_studies family, category wavefunctions, and is placed on Void floor 64. · also forces |

### WaveFunctions_Sine_Space

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_david_drape` (Dream Body — david drape) | pool | dressed by the museum | medium | The robe is the subject: swept panels whose folds are three sine harmonics in theta, with a phase that drifts with height so they spiral as they fall. · also softbodies |
| `sine_space_floor` (Sine space / the floor) | primary | Void/playground only | high | The walkable sin(x)*cos(z) ground (SineSpace.gd) is the sine space itself. It is only used so far as a pool-floor activity in principal_places. · also noise |

### WaveFunctions_Unit_Circle

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_piped_icing` (Dream Body — piped icing) | pool | dressed by the museum | low | 24 to 32 tubes, each one helical turn round the body advancing exactly one pitch: a circle stepped along an axis. · also softbodies |

### WaveFunctions_3D_Wave_Propagation

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** A still camera like a beach water view: zoomed-in waterline experiments on big screens, UI to move the camera (display_plate 'camera' content) | secondary | to build | medium | Zoomed-in waterline views on big screens show waves; a 'camera' content type for display_plate is the kit part that makes it possible. · also kit |
| **Idea:** Wavefunctions from the playground report (sine/interference floors; or Wave Function Collapse tiles) | secondary | to build | low | Sine and interference floors belong to wave propagation; Wave Function Collapse tiles are a different algorithm that the procgen registry already holds (wfc, wave_function_collapse). · also proceduralgeneration |

### WaveFunctions_Effect_Sound

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Waves: optimise the sound system; game sound explored through artifacts (sound-by-artifact inventory) | infrastructure | to build | medium | A sound-by-artifact inventory and sound-system pass is infrastructure that the wavefunctions sound halls (Effect_Sound, AirMusic, Synthesis_Lab) depend on. · also proceduralaudio |

### WaveFunctions_John_Cage

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Foley theatre: 'the bridge in a cage, the mike and a car', thunder sheet, rain drum, wind machine | secondary | to build | medium | Foley instruments (thunder sheet, rain drum, wind machine, a miked object in a cage) are the prepared-sound/found-noise lineage the John_Cage hall argues. · also proceduralaudio |
| `room_memory` (Room Memory - after Alvin Lucier) | secondary | stands nowhere | medium | After Alvin Lucier: PCM is passed recursively through a room-resonance model, which fits beside Cage as experimental music made from acoustics. Tagged wavefunctions. · also proceduralaudio |

### WaveFunctions_TrigWalkingPath

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_tube_reef` (Dream Body — tube reef) | pool | dressed by the museum | low | Tubes sweep on arches that twist round the column with their own phase, swirl and sine wobble, crossing each other. 'Fused' marches them with DreamIso. · also isosurfaces |

### WaveFunctions_Synthesis_Lab

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The modular synth (Eurorack racks exist: rack_303_acid, rack_808_drums, rack_moog_bass, ambient drone...) | primary | to build | high | The Eurorack racks (rack_303_acid etc.) live in the wavefunctions registry and the Synthesis_Lab is that sequence's patching hall. · also proceduralaudio |
| `ambient_listening_room` (Slow Circuits — Walk-in Instrument) | secondary | stands nowhere | medium | Registry category waves, tagged wavefunctions; its staged scene returns the visitor to WaveFunctions_Synthesis_Lab, and you enter it from Room Memory. · also proceduralaudio |

### new: WaveFunctions_Tape_Loops

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Tape loops: big machines with the word on the tape, 'right here right now' | primary | to build | medium | A tape loop with the word on it is a signal that returns, which is the wavefunctions title 'What Returns' as machinery (mod_tape exists in the registry). · also proceduralaudio |

## 11. randomness

Halls: Random_Definition → Random_Entropies → Random_Entropy → Random_Remove → Randomness_10_PRINT_Algorithm → Random_Cubes → Random_Rotate_Random_XYZ → Random_Walk → Random_Gaussian → Random_Mushrooms → Random_Space_Geometry → Randomness_Examples_of_Randomness → Random_Pheromone → Random_Space → Random_Game

### Random_Definition

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `seed_study` (Seed Study — 48 Values / Five Spatial Assignments) | secondary | stands nowhere | medium | One retained seeded set shown five ways, with keep and replay. Random_Definition already argues seed, replay and +1 DRAW over the same stream. |

### Randomness_10_PRINT_Algorithm

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** 64 code: the real code without rows (C64 10 PRINT one-liner, or real code as one ribbon) | pool | to build | high | ten_print declares randomness and is the C64 one-liner; showing the real code as one unbroken ribbon is another variant in that hall's family. |

### Random_Rotate_Random_XYZ

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_dubuffet` (Dream Body — dubuffet) | pool | dressed by the museum | medium | The art-brut look is stacked BoxMesh slabs, each turned 3 to 25 degrees at random on all three axes and pushed off the limb axis, which matches random rotate XYZ closely. · also transformation, primitives |

### Random_Walk

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `constructive_walk_bench` (A walk builds / 24 choices) | secondary | stands nowhere | medium | Category randomness, tagged random-walk. A seeded planar walk builds points and rods, with seed, replay and step controls. It says it is not yet installed in a hall. · also primitives |

### Random_Gaussian

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Go into a room with an X: round particles, gaussian blur (bokeh room) | secondary | to build | low | A bokeh room of round particles under gaussian blur makes the gaussian kernel the experience; it could equally be a shader or particle piece. · also shaders, particles |

### Random_Space_Geometry

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `random_structure_lattice` (Random Structures — Pipe Lattice) | pool | stands nowhere | low | Declared randomness. Seeded threshold choices add links between legal neighbours, which is randomness acting on connectivity (it could also serve graphtheory). · also graphtheory |
| `random_structure_spheres` (Random Structures — Raised Sphere Grid) | pool | stands nowhere | low | Declared randomness. It is the same BASELINE/SEED/KEEP/REPLAY family as the columns, with height drawn on a sphere grid; its note that it is not a Boolean union also touches boolean_surfaces. · also boolean_surfaces |
| `random_structure_tree` (Random Structures — Branching Tree) | pool | stands nowhere | low | Declared randomness. The 3-9-27 branching keeps its parent-child structure while seeded offsets vary the endpoints, so it could also be a bridge into lsystems or fractals. · also lsystems, fractals |
| `random_structure_columns` (Random Structures — Cylinder Field) | primary | stands nowhere | low | Declared randomness. Retained draws shape a 10x10 cylinder field (from your Rhino example), which is random geometry shaping space. The existing Random_Space_Geometry blurb is old grid-era text, so the family may want its own hall. · also noise |

### Random_Game

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dice_bridge` (Dice Bridge / build what chance supplies) | secondary | Void/playground only | medium | Registry category is randomness: a seeded die supplies an allowance of tiles and placement rules decide the route, a game with chance that replays its draw. · also primitives |

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Randomness: playground nodes more and more random (seeded jitter of a frame), optimising weight, alien architecture | primary | to build | medium | Seeded jitter of the playground frame nodes is chance acting on structure; optimising weight under that jitter borrows formfinding's question. · also formfinding |

## 12. noise

Halls: Random_Noise_Types → Noise_Columns → Noise_One → Noise_Voxel → Noise_6_Wall → Noise_Inside_Noise → Noise_Cellular → Noise_Box → Noise_Space_10 → Noise_Perlin_Simplex → Lab_Path

### Random_Noise_Types

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `landscape_flow_bench` (What Leaves? What Remains?) | secondary | stands nowhere | medium | Four trays compare sine, independent heights, Perlin and Worley F1 under the same rolling spheres. Comparing noise types is the core of the noise hall, even though the registry category is physicssimulation. · also physicssimulation, wavefunctions |

### Noise_Cellular

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_crackle_peak` (Dream Body — crackle peak) | pool | dressed by the museum | high | Its skin is cut into collage regions by nearest seed point, and one seamless jittered Worley routine at four cell counts makes the mosaic crazing and craquelure. · also tiling |
| `dream_mosaic_body` (Dream Body — mosaic body) | pool | dressed by the museum | medium | The skin is a wrapped jittered Voronoi lattice with an F2-F1 grout line, plus raised glass tesserae snapped to the surface. · also mosaicanalysis, tiling |

## 13. shaders

Halls: Shader_01_Shaping → Shader_05_Patterns → Shader_11_QueerRubber → Shader_09_FBM → Shader_12_PinkExtravaganza → Shader_10_ReactionDiffusion

### Shader_05_Patterns

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Shaders in the playground and in the endless museum (more Book of Shaders chapters as display plates) | pool | to build | medium | display_plate already carries a shader content (path + params), so more Book of Shaders chapters become a pool of plates for the shaders halls and the patterngeneration branch. · also patterngeneration |
| `tiling_weathered` (The same pattern, then time) | secondary | Void/playground only | medium | Registry category shaders. It runs the Tutorial_Tiling_Floor raster through wallpaper_tile.gdshader with aging layers; the shader adds only time. Its earlier note named Shader_05_Patterns as the intended hall, and no Void floor places it yet. · also tiling, array_tutorial |

## 14. cellularautomata

Halls: CA_Introduction → CA_ElementaryRules → CA_GameOfLife → CA_BeyondBinary → CA_ExpandingSpace → CA_SoftRules → CA_AgentsCircuits → CA_EdgeOfChaos

### CA_GameOfLife

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `ca_history_vault` (Walk through a recorded process) | secondary | stands nowhere | medium | A 2D cellular section stacked through 28 generations so that history becomes walkable architecture. That matches GoL's 'same past, differently dressed', and the sine-bent variants touch wavefunctions. · also wavefunctions |

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Cellular automata and L-systems making space for the biome (CA cave walls, L-system branches round the court) | secondary | to build | medium | CA cave walls and L-system branches growing round the biome court are generators that carve and frame the biome's space on the playground floor. · also lsystems |

### new: CA_Volume

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `ca_volume_lab` (A volume can become a room) | primary | stands nowhere | low | A 13-cubed, 26-neighbour 3D automaton whose solid, frame and shell readings change collision. No existing CA hall covers a volumetric neighbourhood. · also isosurfaces, proceduralgeneration |

## 15. fractals

Halls: Fractal_Recursion → Fractal_RecursiveTrees → Fractal_CantorSet → Fractal_KochSierpinski → Fractal_MengerSponge → Fractal_GoldenSpiral → Fractal_Synthesis

### Fractal_RecursiveTrees

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_coral_polyp` (Dream Body — coral polyp) | pool | dressed by the museum | high | A recursive static helper grows coral fronds that fork two or three ways, four levels deep, down to club tips. · also lsystems, isosurfaces |

## 16. lsystems

Halls: LSystems_Grammar_Lab → LSystems_Growth → LSystems_Grammars_And_Curves → LSystems_Architecture → LSystems_Competition → LSystems_Living → LSystems_Shape_Grammars → Assemblage_Same_Desire

### LSystems_Growth

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_lava_bloom` (Dream Body — lava bloom) | pool | dressed by the museum | medium | A recursive _grow helper, five levels deep, writhes a flowering bough with blossom sprays at the tips and leaves at the nodes, all over domain-warped ridged noise bark. · also fractals, noise |

## 17. proceduralgeneration

Halls: PG_Genetic_Evolution → PG_Space_Colonization → PG_Branching_Growth → PG_Percolation_Network → PG_Caves_Mazes → PG_Sculpted_Forms → PG_Mirrored_Patterns

### PG_Caves_Mazes

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The cave: an enclosed inside for immersion (sdf_cavern_room, cave halls) | primary | to build | medium | sdf_cavern_room declares proceduralgeneration and is a room-scale enclosed cavern; ISO_Caves already has an inside view built from an isosurface. · also isosurfaces |

## 18. softbodies

Halls: SoftBodies_Soft_Body_Deformation → SoftBodies_Cloth_Physics → SoftBodies_Carusell → SoftBodies_Obsticals → SoftBodies_Obsticals_Part2 → SoftBodies_Playground_of_Joy → SoftBodies_Affect_Theory_Visualization → ProceduralGeneration_Reaction_Diffusion_Systems → Topology_Entropy_Morphogenesis

### SoftBodies_Soft_Body_Deformation

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_print_inflatable` (Dream Body — print inflatable) | pool | dressed by the museum | medium | Pool-toy tubes on Bezier frames with welded seams, whose 'inflation' axis (taut, overblown, slack, deflated, bursting) asks how a body yields. · also tiling |

### SoftBodies_Cloth_Physics

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_hicks_fiber` (Dream Body — hicks fiber) | pool | dressed by the museum | low | Fibre is the mass: rope rings, lemniscate coils and helices draped over a mannequin, each ring stretched downward so the loops hang like wet wool. · also wavefunctions, forces |

### SoftBodies_Playground_of_Joy

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_mannerist_tumble` (Dream Body — mannerist tumble) | pool | dressed by the museum | low | Four bodies sinking into a heaped cloth mound of faceted lobes with sine fold ridges, frozen like fruit set in jelly. DreamIso is used for 'cast'. · also wavefunctions, isosurfaces |

### Topology_Entropy_Morphogenesis

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The biome as the space between structures of decay | secondary | to build | low | Life growing in the gaps of decaying structure is the entropy/morphogenesis argument; decay artifacts (entropy_ruin, decaying_bridge, random_decay_objects) already exist to be the structures. · also cellularautomata, randomness |

## 19. isosurfaces

Halls: ISO_Introduction → ISO_LookupTable → ISO_ShapesGallery → ISO_TorusGyroid → ISO_Sculpting → ISO_FlatTerrain → ISO_PortalLandscape → ISO_Caves → ISO_CaveGeneration → ISO_AnimatedNoise → ISO_Metaballs → ISO_ImplicitModeling → ISO_RhizomeBody

### ISO_Introduction

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_pierced_screen` (Dream Body — pierced screen) | pool | dressed by the museum | medium | The sheet is one implicit (u,v) outline minus ellipses, combined by smooth min and meshed by clipping grid cells against the zero contour. · also boolean_surfaces |

### ISO_ImplicitModeling

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_fetish_idol` (Dream Body — fetish idol) | secondary | dressed by the museum | high | The one body marched whole from SDF capsules smooth-unioned at 0.075 (dream_iso.gd), wearing dream_gloss.gdshader. em_layout.json already pins it to the isosurfaces chapter. · also shaders, qfeplaboratory |

## 20. boolean_surfaces

Halls: Boolean_Verbs → Boolean_Gallery → Boolean_Works

### Boolean_Verbs

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_lilac_quarry` (Dream Body — lilac quarry) | pool | dressed by the museum | low | Stacked bedding slabs all clipped by one world-space plane, so the cut chords read as a single quarried face, with bathers embedded in it. · also transformation, isosurfaces |

### Boolean_Works

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_hadid_shell` (Dream Body — hadid shell) | pool | dressed by the museum | low | A lofted shell where a seeded blob field removes clusters of quads to bore organic holes with rounded rims: a pierced volume at sculpture scale. · also isosurfaces, primitives |
| `mod_boolean_s_descent_model` (modular · Boolean Tunnel / one continuous S passage) | pool | Void/playground only | medium | It declares chapter transformation, but its expression (swept solid minus one connected bore) is a CSG subtraction, so Boolean_Works fits it better. · also transformation |

## 21. swarmintelligence

Halls: SwarmIntelligence_PhysarumColony → SwarmIntelligence_FlowFields → SwarmIntelligence_Boids_Algorithm → SwarmIntelligence_Agent_Based_Modeling_ABM → SwarmIntelligence_Ant_Colony_Optimization → SwarmIntelligence_Particle_Swarm_Optimization → SwarmIntelligence_Swarm_Intelligence_Algorithms

### SwarmIntelligence_FlowFields

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `flow_field_table` (Flow field / live museum table) | secondary | stands nowhere | high | Declared map_sequences swarmintelligence; it is a tabletop view of the existing 200-agent flow field, which is exactly the FlowFields hall's subject. · also change |

## 22. graphtheory

Halls: GT_Foundations → GT_Layout → GT_Pathfinding → GT_Network_Analysis → GT_Connectivity → GT_Spanning_Trees → GT_Flow → GT_Matching

### GT_Foundations

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `dream_pink_scaffold` (Dream Body — pink scaffold) | pool | dressed by the museum | low | Struts are drawn on a node graph (a nearest-neighbour connectivity pass plus mutually-near triangles), with welded spheres at nodes of degree three or more. · also formfinding |

## 24. foundationscrisis

Halls: Euclid_Parallel → NonEuclidean_Spaces → Russell_Paradox → Godel_Incompleteness → Escher_Impossible → Brouwer_Intuitionism → Florensky_Paraconsistent → Crisis_Synthesis

### NonEuclidean_Spaces

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Non-Euclidean space (noneuclidean_wing: bigger inside than out, looping corridor) | primary | to build | high | noneuclidean_wing declares foundationscrisis and is the seven-chamber H2/H3 walk-through that NonEuclidean_Spaces names. |

### Godel_Incompleteness

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Minecraft is Turing complete: block logic into paradox and crisis | secondary | to build | medium | Block logic built up until it is Turing-complete reaches the halting/incompleteness limit that Godel_Incompleteness stages; the gates themselves start in logic. · also logic, cellularautomata |

## 26. postfoundationscrisis

Halls: CriticalAlgorithms_Algorithmic_Bias_Visualization → CriticalAlgorithms_Applied_Ethics → SpeculativeComputation_Paraconsistent_Engineering → SpeculativeComputation_Situated_Computation → SpeculativeComputation_Collective_Knowledge → SpeculativeComputation_Rhizome_Network → AdvancedLaboratory_Lab_Equipment_Simulation → PostCrisis_Synthesis

### PostCrisis_Synthesis

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Background static: the calling future / convergence of human and machine intelligence (radio rack, ambient bed) | infrastructure | to build | low | A radio rack and ambient static bed as 'the calling future' of human-machine convergence fits the closing synthesis; as a sound bed it is infrastructure, not an exhibit. · also machinelearning, noise |

### new: PostCrisis_Chains

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| `chains_study_1` (Chains / Bodies Made for Others) | pool | Void/playground only | low | It declares no sequence. It is a worker-autonomy and care study on procedural Dream Bodies, closest to the applied-ethics and situated-computation halls of the post-crisis arc. · also qfeplaboratory |
| `chains_study_2` (Chains / Animated Futures) | pool | Void/playground only | low | A Chains study (Animated Futures) on the shared Dream Bodies request-and-refusal mechanic, so it goes with the rest of the set. · also qfeplaboratory |
| `chains_study_3` (Chains / The Refusal) | pool | Void/playground only | low | The Refusal: refusal changes the result, matching the post-crisis theme of agency over formalised control. · also qfeplaboratory |
| `chains_study_4` (Chains / Model B / The Unwanted Repair) | pool | Void/playground only | low | Model B / The Unwanted Repair is a Chains study on Dream Bodies about consent to repair. It ties to the model_b tooling and the ethics arc. · also softbodies |
| `chains_study_5` (Chains / Workers of All Bodies, Connect) | pool | Void/playground only | low | Workers of All Bodies, Connect is about collective negotiation of shared infrastructure, near SpeculativeComputation_Collective_Knowledge. · also swarmintelligence |
| `chains_study_6` (Chains / The Occupation) | pool | Void/playground only | low | The Occupation: residents take control of shared infrastructure, the last study in the Chains set. · also qfeplaboratory |

## Off-spine branch: facade_assembly

Halls: Facade_Assembly_Principle → Facade_Classical → Facade_Baroque → Facade_Venetian_Gothic → Facade_Rustication → Facade_Florence_Marble → Facade_NYC_Tenement → Facade_Critique

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The facade works as a central playground (facade parts, facade_room_cast) | primary | to build | medium | facade_room_cast declares facade_assembly and boolean_surfaces, and the facade parts form a composition kit that a central playground court can use. · also boolean_surfaces |

## Off-spine branch: particles

Halls: Particles_SingleAndArrays → Particles_Emitters → Particles_Forces → Particles_LifetimeAndTypes → Particles_Collision

### new: Particles_Exploded_Shed

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** The particle sequence (off-spine branch, 5 halls) and the exploded room (Cornelia Parker's exploded shed, prefab_sculpture mode) | primary | to build | medium | The off-spine particles branch (5 halls) has no frozen-explosion hall; Cornelia Parker's suspended shed as a prefab_sculpture mode is particles held at one instant. · also forces |

## Kit and tools (no single sequence)

### playground

| Item | Role | Status | Conf. | Why here |
|---|---|---|---|---|
| **Idea:** Agency gradually more abject (an abjection value on the worker being) | infrastructure | to build | low | An abjection value is a new axis on worker_being, which has a body per spine stage; agency growing through the stages lands hardest in the late arcs. · also postfoundationscrisis |
| **Idea:** Stream the parameters of the painting like sculptures, and the camera | infrastructure | to build | low | Streaming a painting's parameters and the camera into sculptures is a live-parameter channel (like the live update bridge), not one sequence's exhibit. · also color |
| **Idea:** A PDF of all artifacts with images, where Palle adds type and comments | infrastructure | to build | high | A PDF catalogue of every artifact for Palle to type and comment on is a curation tool outside the spine. |
| **Idea:** An artifact viewer in three.js for all artifacts (/artifact-3d-gallery exists, coverage gap) | infrastructure | to build | high | /artifact-3d-gallery is an encyclopedia viewer; closing its coverage gap is web tooling, not a hall. |
| **Family:** mod_* modular terms (228 tokens: mod_point, mod_mesh_color, mod_collider, mod_grabbable, mod_sphere_collider, mod_grab_sphere, mod_line, mod_tape, mod_plank, mod_plank_sizes, mod_stick, mod_trace, mod_hand_trace, mod_walk_line, mod_red_line, mod_parallel_lines, mod_line_plus, mod_cross_lines, mod_heath_mesh, mod_danger_x ...) | infrastructure | stands nowhere | high | Terms of the modular class system (commons/modular/terms.json), built from their parents at ready. These are building vocabulary, none of it placed, and they are not exhibits. |
| `construction_triangle_brace` (Temporary triangular steel bracing) | infrastructure | stands nowhere | high | A reusable steel chevron bracing bay, category construction, tagged void. Geometry and collision only. · also primitives |
| `display_plate` | infrastructure | stands nowhere | high | A slot-fitted plate showing a shader, wallpaper or colour, placed by a recipe's place_activity. It is a gallery building part, not a single exhibit. · also tiling, shaders |
| `flight_bay` | infrastructure | Void/playground only | high | A flight volume (museum_flight_box) sized for the biome court on floor 210. It is spatial infrastructure, not a teaching encounter. |
| `inventory_pin` (Pin) | infrastructure | stands nowhere | high | The inventory's freeze/release tool (physgun click), worn on the hand. Not a thing to place. |
| `inventory_rubber` (Rubber) | infrastructure | stands nowhere | high | The inventory's eraser tool, worn on the hand. Its description says 'Not a thing to place'. |
| `place_workshop_5fcebaaa02744416b9500e810b560a54` (Place / plastic pool) | infrastructure | Void/playground only | high | A generated receiving place with a matched workbench, kept as a Void trial experiment. Tags: playground, place parameters. |
| `place_workshop_7f4480baf3a2414f9e018afa5bd60f45` (Place / plastic pool) | infrastructure | Void/playground only | high | A second generated 'plastic pool' place with the same name and description as the first; a playground place-parameter experiment. |
| `playground_spec_hall` (Playground spec hall / a place spec walked) | infrastructure | Void/playground only | high | It compiles a playground place spec (commons/modular/places) into a walkable hall. It is a building tool for Void trial floors, not an exhibit. |
| `pocket_test` (Pocket test / a hundred balls) | infrastructure | Void/playground only | medium | A measuring instrument laid over any receiving surface: a hundred balls, pocket counts and the Shannon entropy of the surface's normals. It is placed by place_builder over playground activities. · also softbodies, randomness |
| `site_chainlink_panel` (Chain-link fence panel) | infrastructure | stands nowhere | high | Construction-site fence scenery prop, tags void/reusable/scenery. |
| `site_scaffold_tarp` (Scaffold with blue tarp) | infrastructure | stands nowhere | high | Construction-site scaffold bay prop, tags void/reusable/scenery. |
| `site_striped_barricade` (Striped folding barricade) | infrastructure | stands nowhere | high | Construction-site scenery prop (category construction, tags void/reusable/scenery). |
| `site_unfinished_wall` (Unfinished stud wall) | infrastructure | stands nowhere | high | Construction-site stud-wall prop meant to be moved or duplicated, tags void/reusable/scenery. |
| `site_work_light` (Tripod work light) | infrastructure | stands nowhere | high | Construction-site lighting prop, tags void/reusable/scenery. |
| `spatial_recipe` (Spatial lab recipe) | infrastructure | Void/playground only | high | A modular recipe area (commons/modular/recipe_area.tscn) that binds editable instances. It is a building container used on the Trans_Rotation floor (16) and in the spatial_lab and portal trials, not an exhibit. · also transformation |
| `sticky_map` (Sticky map / a contextual map on a pinboard) | infrastructure | stands nowhere | medium | An annotation pinboard that draws from commons/data/sticky_maps/<map>.json. Its only map so far is 'AI as a transforming assemblage', which points to ML synthesis, but the board itself is a general tool. · also postfoundationscrisis |
| `triangle_direction_sign` (Pink triangle / four directions) | infrastructure | stands nowhere | medium | A floor-origin signage prefab (pink triangle turned through four directions), tagged void and construction. It is a wayfinding part, not an exhibit. · also transformation |
| `worker_being` | pool | Void/playground only | medium | One being with a body per spine stage, like biome_object. It stands as the worker on the biome court (principal_places). By design it belongs to every sequence and to no single one. · also primitives, transformation |
| `ball_pit` (Ball pit / wade through) | secondary | Void/playground only | high | The pocket test in pit mode, placed by a receiving place in a pool on the playground ('the six playground pictures' one place type still to build'). It is about the body wading, not about one algorithm. · also softbodies |

## The large families

- **`mod_*`: 228 modular terms.** These come from `commons/modular/terms.json`: point, line, plank, collider, grabbable and so on. They are parts of the building system, not exhibits, so they stay out of the halls.
- **`matter_reference`: 36 studies.** They stand on Void floors only. The family holds more than gates:
  - gates: `matter_reference_*` and `marble_reference_*`;
  - if/else and list loops;
  - call stacks and stack/queue;
  - threshold studies;
  - a material array;
  - Collatz knitters.
  The reviewer proposes splitting it across the four Logic halls and `Array` (see the questions).
- **Dream figures:** they are listed in their sequences above as *pool*, under the hall the sorter thought fits best.

## Questions for Palle

Where a ruling changes the placement, it is asked here. Grouped by sequence, in spine order.

- **primitives / Point_Lines:** **Idea:** The line inside large parallel lines (black rods to the ceiling, one line you walk between). Should the walk-between rods stand in Point_Lines (a line among lines), or in Euclid_Parallel as the parallel postulate made walkable?
- **primitives / Point_Trace:** `head_trace_projection` (A line you did not hold). It was retired from Point_Trace on 29 Sept. Do you want it back, or kept as source only?
- **primitives / Point_Triangle_Context:** `pythagoras_cubicle` (Pythagoras / walls made of proofs). Spine (Point_Triangle_Context) or a Void tower floor? Its tags say void.
- **primitives / Point_Triangle_Context:** `pythagoras_floor` (Pythagoras / the same four panels). Could go to Trans_Translation instead (same triangles, translated): which argument do you want it to make?
- **primitives / Primitives_Columns:** `dream_couch_lounge` (Dream Body — couch lounge). A furniture-and-body piece: should it go in primitives as a superellipsoid study, or in a softbodies hall for its melt/sprawl repose?
- **primitives / Primitives_Columns:** `resolution_colonnade` (Rings of Ash — Gallery). The hall uses the _museum adapter. Is the standalone colonnade only a source, or should it get its own room?
- **primitives / Primitives_Profiles:** **Idea:** Inside a profile array like inside fish bones (rib corridor). Should the rib corridor go in Primitives_Profiles, or in array_tutorial's Array as a walk-through array?
- **primitives / Primitives_Profiles:** `dream_vasarely_beast` (Dream Body — vasarely beast). Four families are profiles swept along splines (vasarely_beast, tube_reef, print_inflatable, piped_icing). Do you want a sweep hall in primitives (e.g. new: Primitives_Sweeps) instead of scattering them?
- **primitives / Primitives_Profiles:** `cyrtoid_by_rule` (Cyrtoid, by rule). Your memory says Haeckel's Cyrtoidea plate opens the Godot course. Should this shell go in Primitives_Profiles (or Primitives_Columns), or at the start of the sequence?
- **primitives / Primitives_Melencolia:** `melencolia_platform` (Melencolia / construction court). Should the construction court become Primitives_Melencolia's main encounter, or stand beside the current Melencolia centrepiece?
- **primitives / playground:** **Idea:** Plateau with an edge and a wedge entrance; wedges of different heights to a cylinder of white primitives; the same in colour; movable; later the kidney form; simplex-noise pits and plateaus like golf sand pits. Should this be one playground plateau that grows stage by stage, or three placements (Primitives_Columns, a Color hall, Noise_One)?
- **primitives / playground:** **Idea:** The worker being and its six dancers; the flight bay; the biome_object stratum (built 2 Nov in the court, floor 210). Is the court on floor 210 the final home, or should worker_being and biome_object each also stand in one spine hall (e.g. Point_One)?
- **primitives / playground:** `biome_primitives` (One world: from a point to a passage). Should this be the ground for the primitives halls (a biome layer), or does it live on the Void playground beside the floor-210 biome court?
- **primitives / playground:** `playground_ball` (Playground ball / six sockets). Stays a playground/inventory part, or should a primitives hall (Point_Zero or Point_Lines) also show it as an exhibit?
- **primitives / playground:** `playground_rod` (Playground rod / two points). Should the rod/ball kit appear in a spine hall at all (Point_Lines would fit), or stay only in the inventory and on the playground floor?
- **transformation / Trans_Translation:** `trans_machine_crank` (Wood crank / metal rod / piston). The four machines (crank, lever, suspended cube, sorter): keep them together as one bay (Trans_Translation per construction_path, or Trans_Playground), or split them by operation?
- **transformation / Trans_Rotation:** `care_shared_crossing` (Care / shared crossing). It is built to span the existing Void Rotation gantries. Should it go into the Trans_Rotation hall, or stay on the Void floor?
- **transformation / Trans_Rotation:** `movable_pivot_walkway` (Plank / move the pivot). It sits on Void floor 15 (Trans_Translation, 'shared bridge'). Keep it there or move it to Trans_Rotation?
- **transformation / Trans_Rotation:** **Idea:** Ada's hand spins like the rotating cubes; the recursive endless hand in 3D. Trans_Rotation (or Trans_Body) for the spinning hand, and a separate Fractal_Recursion piece for the endless hand?
- **transformation / Trans_Rotation:** `transformation_sampling` (Between the Pictures — Transformation Studies). Should this zoetrope study go in Trans_Rotation, Trans_Pre (where translation, rotation and scale combine), or a change hall?
- **transformation / Trans_Scale:** `barrier_scale_line` (DO NOT CROSS / from toy to architecture). The Void tower already places it on Trans_Translation (floor 15, with sun_feather and movable_pivot_walkway). Keep it there or move it to Trans_Scale?
- **transformation / Trans_Playground:** `mod_s_descent_model` (modular · S descent / two-storey cutaway model). Should the modular terms be shown as exhibits in their declared chapter, or kept as construction kit for the Void?
- **transformation / Trans_Playground:** `scaffold_workstation_crossing` (Scaffold workstation / carried crossing). Should the carried crossing be a saved build in the Trans_Playground scaffold bay, or the closing piece of the Cube floor in primitives?
- **transformation / new: Trans_Hierarchy:** `architecture_spine` (The Corridor Has a Spine). This one, architecture_variations and model_overflow form a trilogy built on one bay. Should they become a new hierarchy/composition hall in transformation, or go into Trans_Playground?
- **transformation / new: Trans_Hierarchy:** `model_overflow` (The Model Calls Itself). Should this go with the architecture trilogy in transformation, or into Fractal_Recursion (how many times can 'again' happen, and what does it cost)?
- **transformation / playground:** `biome_inheritance` (Inherited forms: doors become banners). It changes per hall along primitives→tiling. Should it be a biome layer dealt into every hall, or one exhibit (if so, which hall)?
- **logic / Logic_AND:** **Family:** matter_reference (36 tokens: matter_reference, matter_reference_and, matter_reference_or, matter_reference_xor, matter_reference_not, matter_reference_nor, matter_reference_nand, marble_reference_and, marble_reference_or, marble_reference_xor, marble_reference_not, marble_reference_half ...). Split by hall? Gates (matter_/marble_reference_*) to Logic_AND, if/else and loops to Logic_Alternatives, threshold_* to Logic_Event, material_array/list_loop to array_tutorial Array, collatz/knitters to Logic_Assemblage.
- **array_tutorial / Tutorial_3D:** `suspension_passage` (Seven places for a passage). reference_suspension already stands in Tutorial_3D. Keep suspension_passage as a desktop source only, or place it too?
- **color / Color_Context_Placed:** `chroma_drum`. Into Color_Context_Placed's chroma censuses, or Color_Walls, where colour also depends on where you stand?
- **color / Color_Paint:** `moving_canvas`. Should the moving canvas pair with the spray tools in Color_Paint, or teach rotate/scale/lift in Trans_Playground?
- **forces / Vectors_Act4a_KineticForces:** `matter_leaning_together` (Matter / Leaning Together). It stands with the friction trio on Void floor 51; keep it in Kinetic Forces, or move it to FormFinding_Equilibrium as a balance study?
- **forces / Change_Choreography:** `paired_time` (A second together). The registry and the hall text say it is installed in Change_Choreography, but it is listed as unplaced. Is it missing from map_data or the plan?
- **wavefunctions / WaveFunctions_Intro:** `sine_yoke` (Hand wheel / visible sine yoke). The yoke states circle-to-sine exactly. Should it move to WaveFunctions_Unit_Circle, or stay with the hand wheels on Intro?
- **wavefunctions / WaveFunctions_3D_Wave_Propagation:** **Idea:** Wavefunctions from the playground report (sine/interference floors; or Wave Function Collapse tiles). Did you mean sine/interference floors (wavefunctions) or Wave Function Collapse tiles (proceduralgeneration)?
- **wavefunctions / WaveFunctions_3D_Wave_Propagation:** **Idea:** A still camera like a beach water view: zoomed-in waterline experiments on big screens, UI to move the camera (display_plate 'camera' content). Should the camera plate be a general display_plate content (kit), with the waterline view as its first wavefunctions use?
- **wavefunctions / WaveFunctions_John_Cage:** **Idea:** Foley theatre: 'the bridge in a cage, the mike and a car', thunder sheet, rain drum, wind machine. Foley theatre in WaveFunctions_John_Cage, or a new hall in the proceduralaudio branch (e.g. ProceduralAudio_Audio_Effects)?
- **wavefunctions / WaveFunctions_John_Cage:** `room_memory` (Room Memory - after Alvin Lucier). Lucier beside Cage in WaveFunctions_John_Cage, or ProceduralAudio_Audio_Effects (a filter run again and again)?
- **wavefunctions / WaveFunctions_Synthesis_Lab:** `ambient_listening_room` (Slow Circuits — Walk-in Instrument). It is a walk-in room you enter from Room Memory. Should it hang off the Synthesis Lab as a side room, or go into proceduralaudio?
- **randomness / Random_Gaussian:** **Idea:** Go into a room with an X: round particles, gaussian blur (bokeh room). Is the bokeh room about the gaussian (Random_Gaussian), about blur as a shader, or about particles?
- **randomness / Random_Space_Geometry:** `random_structure_columns` (Random Structures — Cylinder Field). The four Random Structures studies (columns, spheres, lattice, tree): put them in Random_Space_Geometry, or open a new hall such as Random_Structures?
- **randomness / Random_Game:** `dice_bridge` (Dice Bridge / build what chance supplies). It builds full size over a Void tower opening. Can it stand in a museum hall, or does it stay on the playground?
- **randomness / playground:** **Idea:** Randomness: playground nodes more and more random (seeded jitter of a frame), optimising weight, alien architecture. Keep the jittering frame on the Void playground, or give it a spine hall such as Random_Space_Geometry?
- **noise / Noise_Cellular:** `dream_mosaic_body` (Dream Body — mosaic body). Should this stay on the spine in Noise_Cellular, or join the off-spine mosaicanalysis halls (Mosaic_Byzantine_Gold)?
- **shaders / Shader_05_Patterns:** `tiling_weathered` (The same pattern, then time). Should the weathered tiling go to Shader_05_Patterns, or stand in tiling/Tutorial_Tiling_Floor next to the raster it ages?
- **shaders / Shader_05_Patterns:** **Idea:** Shaders in the playground and in the endless museum (more Book of Shaders chapters as display plates). Which halls receive the plates first: the six shaders halls, the playground, or the endless-museum walls?
- **cellularautomata / new: CA_Volume:** `ca_volume_lab` (A volume can become a room). Is a 3D CA a new hall, or should it go into CA_BeyondBinary or CA_ExpandingSpace?
- **proceduralgeneration / PG_Caves_Mazes:** **Idea:** The cave: an enclosed inside for immersion (sdf_cavern_room, cave halls). Should the immersive cave be PG_Caves_Mazes (sdf_cavern_room's declared home), or ISO_Caves's 'inside' half?
- **softbodies / Topology_Entropy_Morphogenesis:** **Idea:** The biome as the space between structures of decay. Is this a spine hall (Topology_Entropy_Morphogenesis, or Random_Remove), or a principle for how the biome fills the playground?
- **boolean_surfaces / Boolean_Verbs:** `dream_lilac_quarry` (Dream Body — lilac quarry). Is the quarry's single plane cut a boolean verb, or would you rather hang it in a geology or proceduralgeneration hall?
- **foundationscrisis / Godel_Incompleteness:** **Idea:** Minecraft is Turing complete: block logic into paradox and crisis. Start the block machine in Logic_Assemblage and pay it off in Godel_Incompleteness, or keep it to one hall?
- **postfoundationscrisis / PostCrisis_Synthesis:** **Idea:** Background static: the calling future / convergence of human and machine intelligence (radio rack, ambient bed). Should the static bed close the spine (PostCrisis_Synthesis or ML_Synthesis), or run as ambient sound across the museum?
- **postfoundationscrisis / new: PostCrisis_Chains:** `chains_study_1` (Chains / Bodies Made for Others). The six Chains studies (cyborg workers built from Dream Bodies) form a six-room run in commons/void/trials/chains_studies. Should they go to a new PostCrisis_Chains hall, to CriticalAlgorithms_Applied_Ethics, or to the playground court beside worker_being?
- **particles / new: Particles_Exploded_Shed:** **Idea:** The particle sequence (off-spine branch, 5 halls) and the exploded room (Cornelia Parker's exploded shed, prefab_sculpture mode). Should the exploded room be a sixth particles hall, or a prefab_sculpture variant placed inside Particles_Forces?
- **kit / playground:** `place_workshop_5fcebaaa02744416b9500e810b560a54` (Place / plastic pool). There are two generated 'Place / plastic pool' workshops. Keep both, or keep one?
- **kit / playground:** `pocket_test` (Pocket test / a hundred balls). Should the pocket test stay a playground instrument, or stand in Topology_Entropy_Morphogenesis as that hall's entropy measurement?
- **kit / playground:** `worker_being`. Should the worker being walk the spine with one stage-matched body per hall, or stay on the playground court?
- **kit / playground:** **Idea:** Agency gradually more abject (an abjection value on the worker being). Should the abjection gradient live on worker_being (the kit/playground, across all stages), or become a Machine Learning hall about agency?
- **kit / playground:** **Idea:** Stream the parameters of the painting like sculptures, and the camera. Which painting artifacts should be streamed first, and is the camera stream a viewer tool or an exhibit?
- **kit / playground:** `sticky_map` (Sticky map / a contextual map on a pinboard). Is the sticky map a tool any hall can host (with its own data file), or should the AI-assemblage board sit in ML_Synthesis or a post-crisis hall?

## How this was made

1. **The join** (Python, no agents). It took every registry entry and the date its scene file was first added in git. It then searched every hall map, `em_plan.json`, `em_bake.json`, every Void JSON (except the catalogue and capacity files) and the playground halls for the token.
2. **The sort.** Six read-only sorters each took one batch, with the spine and its exact hall names, and read registries, scripts and blurbs where the description was not enough.
3. **The review.** One reviewer read the whole table against the repo. It made 20 fixes: siblings sorted apart, rooms the Void already gives them, and two hall values that were not allowed.
4. **The check.** Every hall named here was checked against its sequence file. All of them exist, apart from those marked `new:` and `playground`.
