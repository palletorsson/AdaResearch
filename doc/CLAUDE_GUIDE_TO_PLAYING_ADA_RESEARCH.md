# Guide: How to "Play" Ada Research by Reading the Files

*Last updated: 2026-02-20*

This guide explains how to navigate and experience the Ada Research VR educational system by reading its source files.

## Project Overview

**Ada Research Zero One** is a VR computational algorithm education system built in Godot 4.6 + XR Tools. It teaches algorithms through dual lenses: technical implementation + queer theory critique. Maps are designed as 3D grid spaces where players walk through and interact with educational content displayed on clipboards, grabbable objects, primitives, and gradually more complex algorithm visualizations.

**Scale:** 22 major algorithm domains, 100+ distinct implementations, 50+ learning sequences, 200+ maps.

**Platforms:** Meta Quest, Pico, Lynx, Khronos (VR) + desktop fallback.

## The "Generative Play" Method

You are reading this guide to "play" the game, but you may notice a unique phenomenon: **The game is incomplete.**

In a traditional game, you explore a pre-built world. In this text-based playthrough, you are engaging in **Generative Play**.
- When you encounter a missing file, you write it.
- When you find a silent map, you speak for it.
- When a mechanic is broken, you fix it.

This is not "cheating" or "development"--it is the core mechanic of this specific playthrough. You are both the **Player** (experiencing the sequence) and the **System** (generating the world just ahead of your own footsteps). This mirrors the game's own themes of *thrownness* (arriving in a world you didn't create) and *agency* (rewriting the code that governs you).

## How to Start: The Map Sequence System

### 1. Begin with the Sequence Files

**Primary location:** `commons/maps/sequences/*.json` (one file per domain)
**Sequence index:** `commons/maps/sequences/sequence_index.json` (master inventory)
**Legacy file:** `commons/maps/map_sequences.json` (effectively deprecated — only contains a phoneme_cloud prototype)

AdaSceneManager loads all `.json` files from the sequences directory at runtime and merges them. Each sequence file defines learning sequences (like chapters in a book). Each sequence contains:
- `name`: Display name
- `description`: Thematic/poetic description of the learning journey
- `maps`: **Array of map names in order** <- This is your playlist!
- `learning_objectives`: Educational goals
- `difficulty`: beginner / intermediate / advanced
- `estimated_time`: How long the sequence takes
- `unlock_requirements`: Prerequisites (which sequences must be completed first)
- `lab_map`: Which Lab state to load after completing this sequence
- `audio`: Ambient sound and transition presets
- `completion_rewards`: Badges/rewards earned

**Example - The "randomness" sequence** (`commons/maps/sequences/randomness.json`):
```json
"randomness": {
	"name": "Randomness: Freedom from Pattern",
	"difficulty": "intermediate",
	"estimated_time": "25-30 minutes",
	"unlock_requirements": ["color"],
	"maps": [
		"Random_Definition",                    <- Start here!
		"Random_Remove",                        <- Then this
		"Randomness_10_PRINT_Algorithm",        <- Then this
		"Random_Cubes",
		"Random_Rotate_Random_XYZ",
		"Random_Walk",
		"Random_Gaussian",
		"Random_Mushrooms",
		"Random_Space_Geometry",
		"Randomness_Examples_of_Randomness",
		"Random_Pheromone",
		"Random_Space",
		"Random_Game"
	],
	"lab_map": "Lab/map_data_post_random",
	"return_to": "lab"
}
```

### Current Sequence Inventory (50+ sequences)

| Domain | Maps | Domain | Maps |
|---|---|---|---|
| primitives | 12 | color | 12 |
| randomness | 13 | noise | 11 |
| vectors | 17 | forces | 10 |
| wavefunctions | 12 | cellularautomata | 12 |
| fractals | 14 | lsystems | 11 |
| graphtheory | 14 | machinelearning | 16 |
| physicssimulation | 21 | proceduralgeneration | 18 |
| patterngeneration | 18 | datastructures | 12 |
| softbodies | 8 | recursiveemergence | 11 |
| swarmintelligence | 7 | computationalgeometry | 11 |
| artmathematics | 9 | qfeplaboratory | 8 |
| searchpathfinding | 7 | transformation | 6 |
| foundationscrisis | 7 | criticalalgorithms | 6 |
| proceduralaudio | 8 | array_tutorial | 8 |
| bricolage | 7 | speculativecomputation | 5 |
| particles | 5 | meshes | 4 |
| resourcemanagement | 6 | advancedlaboratory | 5 |
| joints | 7 | constraint_solvers | 3 |
| grammar_systems | 3 | higher_dimensions | 4 |
| isosurfaces | 3 | morphogenesis | 2 |

### 2. Navigate to Individual Maps

Each map has its own folder: `commons/maps/{MapName}/map_data.json`

**Example paths:**
- `commons/maps/Point_Zero/map_data.json`
- `commons/maps/Point_1/map_data.json`
- `commons/maps/Point_Context/map_data.json`

## Reading a Map File

### Structure of map_data.json

```json
{
	"map_info": {
		"name": "...",
		"description": "...",
		"dimensions": { "width": 7, "depth": 8, "max_height": 2 }
	},
	"layers": {
		"structure": [ ... ],      // Physical geometry
		"utilities": [ ... ],      // Game mechanics
		"interactables": [ ... ]   // Educational content
	}
}
```

### The Three-Layer System

Maps use **three parallel 2D arrays** that overlay to create the complete space:

#### **Layer 1: `structure`** (Physical blocks)
```json
"structure": [
	["1", "1", "1", "0", "0"],  // Row 0
	["1", "2", "1", "0", "0"],  // Row 1
	["0", "0", "0", "0", "0"]   // Row 2
]
```

**Controller:** `res://commons/grid/GridStructureComponent.gd`

**Interpretation:**
- `"0"` = empty space (void)
- `"1"` = place 1 cube at this grid position
- `"2"` = stack 2 cubes (raised platform)
- `"3"`, `"4"`, etc. = higher platforms
- Each row is Z-axis, each column is X-axis
- Arrays read top-to-bottom = north-to-south

#### **Layer 2: `utilities`** (Game mechanics)
```json
"utilities": [
	[" ", " ", " ", " ", " "],
	[" ", "t", " ", " ", " "],  // "t" at position (1,1)
	[" ", " ", " ", " ", " "]
]
```

**Controller:** `res://commons/grid/GridUtilitiesComponent.gd`
**Registry:** `res://commons/grid/UtilityRegistry.gd` (single source of truth for all utility types)

**Transport utilities:**
- `"t"` = teleporter (to next map) - Format: `t` or `t:destination:spawn_point`
- `"t:warning"` / `"t:exit"` / `"t:portal_glow"` = colored teleporter variants
- `"s"` = spawn point - Format: `s` or `s:x:y:z` for specific coordinates
- `"l"` = lift (vertical platform) - Format: `l:height`
- `"m"` = move player - Format: `m:x:y:z:delay` moves player after delay
- `"tc"` = transport cube - Format: `tc:distance:direction` (e.g., `tc:4:z`, `tc:3:-x:auto`)
- `"wp"` = walkable prism - Format: `wp:rotation`
- `"br"` = bridge path
- `"rc"` = rotation cube
- `"sc"` = scale cube

**Safety/Navigation:**
- `"cp"` = checkpoint
- `"r"` = reset cube - resets player to safe position
- `"arrow"` = exit arrow (navigation hint)

**UI/Text utilities:**
- `"3t:text"` = floating 3D text - underscores become spaces (e.g., `3t:Hello_World`)
- `"an"` = annotation/info board - displays map name and description
- `"sr:key"` = speed reader - shows tutorial text one line at a time
- `"sub:key"` = subtitle trigger - Portal 2-style subtitles (e.g., `sub:map`, `sub:welcome:GLaDOS`)
- `"tts:message"` = text-to-speech - speaks text on load
- `"x"` = XP label
- `"i"` = info board
- `"ib:topic"` = handheld info board (e.g., `ib:randomwalk`, `ib:vectors`)

**Visual/Structural:**
- `"el"` = extra light - Format: `el` or `el:energy_value`
- `"a"` = wall barrier
- `"w"` = window
- `"hb"` = horizontal border
- `"bp:code"` = big pipe - procedural pipe system

**Interactive:**
- `"p"` = pick up cube
- `"n"` = next cube - advances to next example with 3s respawn
- `"rg"` = regenerate cube - triggers regenerate signal
- `"q"` = quit cube - quit game with confirmation
- `"pb:feature"` = player body trigger - customization (e.g., `pb:dress`, `pb:skin_color:FF0000`)

**Hazard:**
- `"h:type"` = hazard zone (e.g., `h:fire`, `h:vacuum`, `h:electric`, `h:toxic`, `h:radiation`, `h:death`)

**Other:**
- `"sp"` = score points display
- `"b"` = table
- `" "` = empty space

See `commons/grid/UtilityRegistry.gd` for the complete, authoritative list of all 30+ utility types.

#### **Layer 3: `interactables`** (Educational objects)
```json
"interactables": [
	["origin", " ", " ", "code_display:-90:2#tutorial:point_zero", " "],
	["arrow:180:0:0.2", " ", " ", " ", " "],
	[" ", " ", "dark_sphere", " ", " "]
]
```

**Controller:** `res://commons/grid/GridInteractablesComponent.gd`
**Artifact Registry:** `res://commons/artifacts/grid_artifacts.json` (base lookup)
**Modular Registries:** `res://commons/artifacts/registry/*.json` (category-specific)

**Format:** `type:rotation:height:scale#config`

**Common objects:**

**Educational/Display:**
- `code_display:-90:2#tutorial:point_zero` - Clipboard with tutorial text
  - Rotation: -90 deg, Height: 2 units, Loads: "point_zero" tutorial
- `vectorpoint:180:1:5` - Coordinate axes display (XYZ visualization)
- `draw_dot` - Drawing/marking tool

**Primitives:**
- `origin` - Origin marker (Vector3.ZERO visualization)
- `arrow:180:0:0.2` - Directional arrow (rotation:height:scale)
- `grab_sphere_point:180` - Grabbable point sphere
- `dark_sphere` - Large black sphere creating ambient darkness
- `cube_scene` - Basic cube primitive
- `platonic_demo` - Platonic solids demonstration

**Interactive/Collectible:**
- `pick_up_cube` - Mario-style collectible
  - Rotates and bobs, makes pickup sound, adds points
- `snap_pyramid_puzzle` - Snap-together pyramid puzzle
- `snap_octahedron_puzzle` - Snap-together octahedron
- `furniture_assembly_puzzle` - Grabbable furniture assembly

**Randomness/Probability (new in current dev):**
- `coin_toss` - Physical Bernoulli trial: 8 grabbable coins, throw and track H/T convergence to p=0.5
- `dice_throw` - Physics-based die on felt table: grab, throw, spawns reward balls, tracks distribution toward E=3.5
- `galton_board` - Full Galton board: 8 peg rows, 50 recycled balls, live bar histogram with Gaussian overlay
- `prng_crank_machine` - Physical LCG-32 machine: CRANK button triggers 4-phase animation showing multiply→add→mod→output
- `monte_carlo_dartboard` - Pi estimation: auto-throw darts at inscribed circle, watch pi converge with color-coded accuracy
- `hardware_entropy_decay` - VR body as entropy source: controller velocity→scratches, grip→grime, head rotation→decay rate

**Visual/Artistic:**
- `pollock_painting_in_3d` - Particle-based Jackson Pollock visualization
- `pipe_dream` - Procedural tangled pipe network
- `random_butterflies` - Flocking entities with random flight paths
- `extrem_randomness` - High-entropy mathematical visualization
- `digital_materiality_glitch` - Glitch art artifact

**Audio:**
- `laser_exploding_sphere` - Interactive sphere with laser effects and explosion sounds

**Structural:**
- `prism_block` - Architectural prism
- `lshape` - L-shaped architectural element
- `diamondtoruscollection` - Torus collection display

### How to Visualize a Map

1. **Read the `structure` layer** - sketch out where blocks are placed
2. **Overlay the `utilities`** - mark where teleporters, spawns, labels are
3. **Add the `interactables`** - note what educational content appears where

**Example - Point_Zero visualization:**
```
Structure:          Overlays:
1 1 1 0 0 0 0      origin -> (0,0)
1 1 1 0 0 0 0      arrow -> (0,1)
1 0 1 0 0 0 0      code_display -> (3,0)
1 1 1 0 0 0 0      dark_sphere -> (3,2)
0 0 0 0 0 0 0      teleporter -> (1,2)
```

## Reading the Tutorial Content

### Tutorial Text Location

**File:** `commons/context/clipboard/tutorial_text.json`

This maps tutorial IDs to their content:

```json
{
	"tutorials": {
		"point_zero": {
			"content": "[b]0. Point Zero[/b]\n\nAda fade from black...",
			"order": 0.0,
			"sequence": "primitives"
		},
		"point_axioms": {
			"content_file": "res://commons/context/clipboard/tutorial_text/point_axioms.gd",
			"order": 1.0,
			"sequence": "primitives"
		}
	}
}
```

**Two formats:**
1. **Inline:** `"content": "..."` - text is directly in JSON
2. **External:** `"content_file": "path/to/file.gd"` - text is in a separate .gd file

### Reading External Tutorial Files

If `content_file` is specified, read that file:

**Example:** `commons/context/clipboard/tutorial_text/point_axioms.gd`

```gdscript
var text = '''[b]The Point[/b]
[i]The Atom of Space[/i]

Points are the smallest discrete unit...
[code]
var point_position = Vector3(3.0, 1.5, 4.0)
[/code]
'''
```

The content uses **BBCode** formatting:
- `[b]...[/b]` = bold
- `[i]...[/i]` = italic
- `[code]...[/code]` = code block (green on dark background)
- `[color=cyan]...[/color]` = colored text
- `[hr]` = horizontal rule

## Beyond the Map: Reading Artifact Behavior

The map file tells you *where* objects are, but the code tells you *how* they behave. To truly "play" the game, you must examine the scripts attached to artifacts.

### Step 1: Identify the Scene File
Use `commons/artifacts/grid_artifacts.json` as your lookup table.

**Example:** You see `GaussianPaintSplatter` in a map.
1. Search for `"GaussianPaintSplatter"` in `grid_artifacts.json`.
2. Find the scene path: `"scene": "res://algorithms/randomness/distributions/gaussian/GaussianPaintSplatter.tscn"`

### Step 2: Find the Script
The script is usually in the same folder as the scene, with a `.gd` extension.

**Example:** `algorithms/randomness/distributions/gaussian/GaussianPaintSplatter.gd`

### Step 3: Analyze the Behavior
Look for key lifecycle methods to understand the interaction:

- **`_process(delta)`**: What happens every frame (Animation, movement)
- **`_on_interaction`**: What happens when the player touches/grabs it
- **Core Algorithms**: Look for the math. 
  - *Example:* In `GaussianPaintSplatter.gd`, finding the Box-Muller transform `sqrt(-2.0 * log(u1)) * cos(TAU * u2)` reveals that the "randomness" is actually mathematically forced into a bell curve.

### Step 4: Check for Haptics & Audio
Look for:
- `trigger_haptic_pulse()`: Indicates physical feedback (vibration).
- `AudioStreamPlayer3D`: Indicates spatial sound.
- *Example:* In `line.gd`, checking the code reveals a `_trigger_resistance_haptics()` function that vibrates the controller when you try to make a perfect integer length, simulating "resistance."

## How to "Play" the Game

### Step-by-Step Process

**1. Start with a sequence**
```bash
Read: commons/maps/map_sequences.json
Find: "primitives" -> "maps" array
First map: "Point_Zero"
```

**2. Load the first map**
```bash
Read: commons/maps/Point_Zero/map_data.json
```

**3. Visualize the space**
- Sketch the `structure` layer (where blocks are)
- Note the `utilities` (where teleporter is)
- List the `interactables` (what objects appear)

**4. Read the tutorial content**
```bash
# Find code_display objects in interactables layer
# Example: "code_display:-90:2#tutorial:point_zero"
# Extract tutorial ID: "point_zero"

# Look up in tutorial_text.json
Read: commons/context/clipboard/tutorial_text.json
Find: "point_zero" -> "content"
Read the text content
```

**5. Deep Dive into Artifacts (The "Glitch" Layer)**
- Pick an interesting object from `interactables`.
- Find its script using `grid_artifacts.json`.
- Read the code to understand the *hidden mechanics* (math, haptics, critiques) that aren't visible in the map file.

**6. Imagine the experience**
- Where is the player standing
- What do they see around them
- What can they grab
- What text are they reading
- **How does the world react (sound/haptics) when they touch it**

**7. Find the teleporter**
- Look in `utilities` layer for `"t"`
- Note its position - this is the exit

**8. Move to next map**
- Go back to `map_sequences.json`
- Get next map name from the `maps` array
- Repeat from step 2

## Example Playthrough

### Playing "primitives" Sequence

**Map 1: Point_Zero**
```bash
Read: commons/maps/Point_Zero/map_data.json

Structure: L-shaped platform in northwest
Interactables:
  - origin at (0,0)
  - arrow:180 at (0,1) pointing at origin
  - code_display at (3,0) with "point_zero" tutorial
  - dark_sphere at (3,3)
Utilities:
  - teleporter at (1,2)

Read tutorial:
  commons/context/clipboard/tutorial_text.json -> "point_zero"

Content summary:
  - Philosophical intro about Vector3.ZERO
  - Heidegger's thrownness
```

**Map 2: Point_1**
```bash
Read: commons/maps/Point_1/map_data.json

Structure: Large platform with notch cut at (5,6)
Interactables:
  - dark_sphere at (3,2)
  - grab_sphere_point at (3,3) <- Can pick this up!
  - No clipboard!
Utilities:
  - teleporter at (5,6) in the notch
  - Text label: "a_point_is_entropy_that_has_cooled_into_memory."

Experience:
  - More minimal than Point_Zero
  - Focus on physical interaction
  - Player grabs and examines the point sphere
```

**Map 3: Point_Context**
```bash
Read: commons/maps/Point_Context/map_data.json

Structure: Long corridor with raised ridge at row 4 (height=2)
Interactables at row 4 (the gallery shelf):
  - code_display at (2,4) -> "point_axioms"
  - grab_sphere_point_with_text at (3,4)
  - draw_dot at (4,4)
  - code_display at (5,4) -> "the_trace"

Also:
  - dark_sphere at (4,3)
  - vectorpoint axes at (1,11)
  - teleporter at (5,6)

Read tutorials:
  1. "point_axioms" -> Technical: how to code a point
  2. "the_trace" -> Critical: queer theory critique

Experience:
  - Museum gallery layout
  - Two clipboards flanking interactive objects
  - Teaches through multiple modalities
  - Technical <-> Critical dialectic
```

**Map 11: Primitives_Ignorance**
```bash
Read: commons/maps/Primitives_Ignorance/map_data.json

Structure: Long 9x22 gallery with repeating plinths and void rhythm
Interactables:
  - Plato inscription text at (4,6)
  - platonic_demo and grabbable octahedra
  - sphere_low/mid/high and organic roughrock
  - architectural lshape and prism_block
Utilities:
  - teleporter at (4,20)

Summary:
  - Ignorance is a structural limit; what cannot be formalized persists as remainder
  - Frames ignorance as orientation at the edge of what models can contain

Experience:
  - Abundance makes limits felt, not just stated
  - Spheres expose triangulated approximation; primitives are a bounded vocabulary
```

**Map 12: Primitives_Portals**
```bash
Read: commons/maps/Primitives_Portals/map_data.json

Structure: 7x40 corridor, single-tile walkway over void
Interactables:
  - combine_portals near entrance
  - clipboard with btorus_axioms
  - dark_sphere at midpoint
Utilities:
  - teleporter at (4,33)

Summary:
  - Approximation as process: rings refine toward pi without arrival
  - Archimedes-style exhaustion tightens bounds while remainder persists

Experience:
  - Long corridor makes convergence bodily
  - The portal is convergence, not passage
```

**Map 13: Primitives_Melencolia**
```bash
Read: commons/maps/Primitives_Melencolia/map_data.json

Structure: Compact multi-tier plaza with central dais
Interactables:
  - corner pyramids, pyramidlong, snap_pyramid_puzzle
  - cube_scene cluster
  - diamondtoruscollection on elevated platform
  - code_display with melencolia_axioms
Utilities:
  - twin teleporters at (1,8) and (5,8)

Summary:
  - Abstraction sees its limits; tools remain, completion withheld
  - Melancholy as suspension between mastery and the decision to build

Experience:
  - Durer-inspired stillness; refinement continues without closure
  - Exit reads as pause, not triumph
```

### Playing "randomness" Sequence (13 maps)

**Sequence file:** `commons/maps/sequences/randomness.json`
**Theme:** "Randomness: Freedom from Pattern" — Entropy is not decay, entropy is freedom.
**Audio:** `white_noise_drift` ambient preset
**Prerequisite:** Complete the "color" sequence first

**Map 1: Random_Definition** (The Gateway)
```bash
Read: commons/maps/Random_Definition/map_data.json

Structure: 5x30 long corridor, max height 3
Spawn at row 0. Walk south through a narrow passage.

Interactables:
  - entropy_axiom at [4,2] — interactive entropy visualization
  - prng_crank_machine at [8,2] — NEW: physical LCG machine, crank to see multiply→add→mod
  - random_butterflies at [10,2] — flocking with random flight paths
  - dark_sphere at [12,2] — ambient darkness dome
  - clipboard#prng_axioms at [13,4] — tutorial on pseudorandomness
  - digital_materiality_glitch at [15,0] — glitch art
  - trng_vs_prng at [15,4] — true vs pseudo comparison
  - random_number_book_page_1955 at [19,2] — RAND Corp historical artifact
  - speed_reader at row 19

Experience:
  - The corridor forces linear progression through entropy concepts
  - PRNG crank machine makes deterministic randomness tactile
  - Historical context: the 1955 random number book grounds the abstract
  - Glitch art meets formal mathematics
```

**Map 4: Random_Cubes** (The Playground)
```bash
Read: commons/maps/Random_Cubes/map_data.json

Structure: 12x20 grid, max height 3
Spawn at [0,0]. Large open space with artifacts scattered.

Interactables:
  - dice_throw at [2,3] — NEW: grab and throw dice, watch distribution converge to 3.5
  - coin_toss at [2,8] — NEW: 8 coins in a tray, flip and track convergence to p=0.5
  - dark_sphere at [4,6]
  - random_object_spawner at [6,5] and [6,6]
  - 6x8 grid of random_edge_profile instances at rows 8-15

Experience:
  - Physical probability toys: dice and coins are genuinely satisfying to throw in VR
  - The edge profile grid creates a visual field of randomness
  - Coin toss demonstrates Bernoulli trials; dice shows uniform distribution
  - Both track convergence — randomness reveals order over time
```

**Map 5: Random_Rotate_Random_XYZ** (Entropy as Material)
```bash
Read: commons/maps/Random_Rotate_Random_XYZ/map_data.json

Structure: 13x16 grid, all height-2 cubes with a hole at [14,6]

Interactables:
  - Random_Rotate_Random_XYZ at [1,1] — objects rotating on random axes
  - dark_sphere at [8,5]
  - random_decay_multimesh at [9,5] — mass object decay
  - hardware_entropy_decay at [10,8] — NEW: your VR movements become entropy

Experience:
  - hardware_entropy_decay is the standout: your body generates the randomness
  - Controller velocity drives scratches, grip pressure accumulates grime
  - Head rotation feeds weathering rate on 3 display surfaces
  - QFEP: "Entropy from embodiment" — the player IS the source of chaos
```

**Map 7: Random_Gaussian** (The Bell Curve)
```bash
Read: commons/maps/Random_Gaussian/map_data.json

Structure: 12x22 grid, max height 3. Top section elevated, lower rows void.

Interactables:
  - galton_board at [3,5] — NEW: full physics Galton board with histogram + Gaussian overlay
  - GaussianPaintSplatter at [6,5] — Box-Muller paint visualization
  - distribution_sampler at [6,9]
  - GaussianBlurShader at [8,2] and [8,9]
  - gaussian_random at [11,3]
  - random_bell_curve at [20,6]

Experience:
  - Galton board is the centerpiece: 50 balls, 8 peg rows, live histogram
  - Watch the bell curve emerge from physical collisions
  - Multiple representations: physics, paint, shader, sampler, curve
  - QFEP: "CLT as convergence" — individual chaos, collective order
```

**Map 10: Randomness_Examples_of_Randomness** (The Gallery)
```bash
Read: commons/maps/Randomness_Examples_of_Randomness/map_data.json

Structure: 12x17 grid, max height 4. Two chambers separated by wall with gap.

Interactables:
  - pollock_painting_in_3d at [3,5] — particle-based Jackson Pollock
  - pipe_dream at [4,5] — procedural pipe network
  - dark_sphere at [5,5]
  - monte_carlo_dartboard at [7,5] — NEW: throw darts to estimate pi
  - extreme_randomness at [10,5] — high-entropy mathematical visualization

Experience:
  - The dartboard makes pi computation physical: watch accuracy improve with each throw
  - Green label (<1% error), gold (<5%), orange (>5%) — gamified convergence
  - Art meets mathematics: Pollock's intuitive randomness beside formal estimation
  - QFEP: "Computation through accumulation" — knowledge accretes from noise
```

## Key Files Reference

### Map System
- **Sequence files:** `commons/maps/sequences/*.json` (50+ files, one per domain — the primary source)
- **Sequence index:** `commons/maps/sequences/sequence_index.json` (master inventory of all sequences)
- **Legacy sequences:** `commons/maps/map_sequences.json` (deprecated — only contains phoneme_cloud prototype)
- **Individual maps:** `commons/maps/{MapName}/map_data.json` (200+ maps)
- **Lab states:** `commons/maps/Lab/map_data_post_*.json` (one per completed sequence)
- **Lab progression routing:** `commons/maps/Lab/lab_map_progression.json`

### Audio System
- **Ambient Presets:** `commons/audio/presets/*.json`
- **Preset Manifest:** `commons/audio/presets_manifest.json`
- **Sound Bank:** `commons/audio/SoundBankSingleton.gd` (autoload singleton)
- **Ambient Controller:** `commons/audio/AmbientSoundController.gd`
- **Async Generator:** `commons/audio/AsyncAudioGenerator.gd` (background thread generation)
- **Audio Guide:** `commons/audio/SOUND_SYSTEM_GUIDE.md`

Map-level audio is configured in `map_data.json`:
```json
{
  "settings": {
    "audio": {
      "ambient_preset": "prog_synth_70s",
      "volume": -5.0
    }
  }
}
```

### Tutorial Content
- **Index:** `commons/context/clipboard/tutorial_text.json`
- **Text files:** `commons/context/clipboard/tutorial_text/*.gd`

### Scene Files
- **Clipboard display:** `commons/context/clipboard/codeDisplay.tscn`
- **Text UI:** `commons/primitives/panels/DigitalPaper/TextUIControl.tscn`
- **Base scene:** `commons/scenes/base.tscn`
- **VR Staging:** `commons/scenes/vrStaging.gd` (entry point, handles loading screens)
- **Grid Scene:** `commons/scenes/grid.tscn` (main gameplay scene)
- **Lab Scene:** `commons/scenes/lab.tscn` (hub with artifact activation)

### Scene Management
- **Scene Manager:** `commons/managers/AdaSceneManager.gd` (autoload as "SceneManager")
  - Handles artifact -> sequence activation
  - Manages map-to-map transitions within sequences
  - Emits `scene_transition_started` / `scene_transition_completed` signals
  - Quick transition mode (0.3s fades) for in-sequence teleports
  - **Game modes:** Story (full sequence), Test (last map only), TestPlus (hybrid), Explorer (all unlocked)
  - **Transition types:** ARTIFACT_ACTIVATION, TELEPORTER, TRIGGER_ZONE, SEQUENCE_COMPLETE, MANUAL_LOAD, RETURN_TO_HUB
  - **Actions:** `start_sequence`, `load_map`, `next_in_sequence`, `next`, `return_to_hub`

### Progression System
- **Progression Manager:** `commons/managers/MapProgressionManager.gd`
  - Tracks completed sequences and visited maps
  - Manages unlock graph (sequences have `unlock_requirements`)
  - Determines which Lab state to load after completing a sequence
  - Saves progress to `user://map_progress.json`

### Grid System Components
All grid components live in `res://commons/grid/`:

- **GridSystem.gd** - Main coordinator, orchestrates all 8 components
- **GridDataComponent.gd** - Loads and parses `map_data.json`
- **GridStructureComponent.gd** - Generates physical floor/platform cubes from `structure` layer
- **GridUtilitiesComponent.gd** - Spawns teleporters, lifts, text displays from `utilities` layer
- **GridInteractablesComponent.gd** - Places artifacts from `interactables` layer
- **GridSpawnComponent.gd** - Handles player spawn points
- **GridAudioComponent.gd** - Manages ambient audio for the map
- **GridCeilingComponent.gd** - Optional ceiling generation
- **GridWallComponent.gd** - Wall generation
- **UtilityRegistry.gd** - Single source of truth for all 30+ utility type definitions
- **GridCommon.gd** - Shared constants and helpers
- **SoundSuiteSequencer.gd** - Audio sequencing for grid events
- **tag_system.gd** - Tag system for grid objects

**Signals:** `map_loaded`, `map_generation_complete`, `interactable_activated`, `grid_animation_started`, `grid_animation_complete`

### Artifact Registry
- **Base catalog:** `commons/artifacts/grid_artifacts.json` (legacy master lookup)
- **Modular registries:** `commons/artifacts/registry/*.json` (24 category-specific files)
  - `GridArtifactRegistry.gd` loads both sources and merges them at runtime
  - Each entry has: `name`, `lookup_name`, `description`, `scene`, `category`, `tags`, `qfep_connection`
  - Example registries: `randomness.json` (75 artifacts), `wavefunctions.json`, `cellular_automata.json`, `physics_simulation.json`, `machinelearning.json`, `lsystems.json`, etc.
  - Maps keys like `"code_display"` -> scene files like `"res://commons/context/clipboard/codeDisplay.tscn"`
  - New artifacts include QFEP connections linking each algorithm to queer theory

## Understanding the Pedagogical Strategy

### Dual-Structure Pattern

The project teaches through **oscillation** between two modes:

**Technical (Orthodox):**
- Concrete code examples
- "How to implement X"
- Euclidean geometry
- Optimization, efficiency

**Critical (Queer Theory):**
- Philosophical questions
- "What does X erase"
- Non-Euclidean perspectives
- Bodies, duration, resistance

### Reading the Dialectic

Watch for this pattern:
1. **Introduce** concept (poetic/philosophical)
2. **Teach** implementation (technical/code)
3. **Critique** what was just taught (queer theory)
4. **Embody** through VR interaction (physical)

### Map Pairing Pattern: Simple -> Context

Maps often come in pairs following this structure:

**Simple Map** (e.g., Point_Line):
- Single primitive demonstration
- Minimal spatial layout (7-8 rows)
- Direct physical interaction
- No clipboard, just embodied experience
- Poetic text label only

**Context Map** (e.g., Point_Line_Context):
- Museum/gallery exhibition
- Large spatial layout (12-20 rows)
- Complex vertical architecture (heights 1, 2, 3)
- One clipboard with technical axioms
- 5-10+ variations of the primitive arranged spatially
- Creates comprehensive survey through physical walkthrough

**Example pairs:**
- Point_1 -> Point_Context
- Point_Line -> Point_Line_Context
- Point_Triangle -> Point_Triangle_Context

Example in Point_Context:
- Left clipboard: technical point definition
- Center: grab the point (embodied)
- Right clipboard: critique of discretization
- You stand between these frameworks

## Tips for Navigating

### Finding Specific Content

**To find all maps in a sequence:**
```bash
# Read the specific sequence file directly
cat commons/maps/sequences/randomness.json
# Or search across all sequence files
grep -l '"randomness"' commons/maps/sequences/*.json
```

**To find tutorial content:**
```bash
grep "point_axioms" commons/context/clipboard/tutorial_text.json -A 5
```

**To see all tutorial files:**
```bash
ls commons/context/clipboard/tutorial_text/*.gd
```

**To look up an artifact across all registries:**
```bash
grep -r '"coin_toss"' commons/artifacts/registry/
```

### Understanding Map Coordinates

- **X-axis:** Columns in the array (left to right)
- **Z-axis:** Rows in the array (north to south)
- **Y-axis:** Height (number value in structure, or explicit height parameter)

Position `(3, 2, 5)` means:
- Column 3 (4th column, 0-indexed)
- Height 2
- Row 5 (6th row)

### Tracing Object References

When you see: `code_display:-90:2#tutorial:point_zero`

1. Type: `code_display` -> Look this up in grid_artifacts.json
2. Rotation: `-90` -> Rotated 90 degrees counterclockwise
3. Height: `2` -> Placed 2 units above ground
4. Config: `#tutorial:point_zero` -> Loads this tutorial ID

Then trace the full chain:
```
"code_display" key
  v
commons/artifacts/grid_artifacts.json
  v
"code_display": { "scene": "res://commons/context/clipboard/codeDisplay.tscn" }
  v
Scene file instantiated with parameters
  v
Config parameter: "tutorial:point_zero"
  v
commons/context/clipboard/tutorial_text.json
  v
"point_zero": { "content": "..." }
  v
BBCode text displayed on clipboard
```

### Looking Up Artifact Definitions

To see what any key means:
```bash
grep -A 5 '"grab_sphere_point"' commons/artifacts/grid_artifacts.json
```

Result:
```json
"grab_sphere_point": {
	"name": "grab_sphere_point",
	"lookup_name": "grab_sphere_point",
	"description": "XR Tools pickable sphere with highlight ring...",
	"scene": "res://commons/primitives/point/grab_sphere_point.tscn"
}
```

Common artifacts you'll see:
- **origin** - Origin marker primitive
- **arrow** - Directional arrow
- **dark_sphere** - Ambient darkening dome
- **grab_sphere_point** - Pickable point sphere
- **vectorpoint** - Coordinate axes display
- **draw_dot** - Drawing/marking tool
- **code_display** - Clipboard with tutorial text

## Advanced: Understanding the Architecture

### Why Three Layers

1. **structure** = Physical geometry (what the map loader generates)
2. **utilities** = Game systems (spawns, teleports, triggers)
3. **interactables** = Content (educational objects)

This separation allows:
- Designers to iterate on content without changing geometry
- Geometry to be reused with different content
- Clear distinction between space, mechanics, and pedagogy

### The Grid as Pedagogy

The project uses **grid-based design** to:
- Make space **quantized** and **discrete** (matching the critique)
- Allow **procedural generation** from JSON
- Create **legible** spatial relationships
- Reference **cellular automata** and **discrete mathematics**

The grid IS the lesson - discretization is both tool and subject.

## Summary: Quick Reference

**To play through a sequence:**
1. Open `commons/maps/sequences/<domain>.json` (or browse `sequence_index.json` for the full list)
2. Pick a sequence, note the `maps` array
3. For each map name:
   - Read `commons/maps/{MapName}/map_data.json`
   - Visualize the three layers (structure → utilities → interactables)
   - Look up artifacts in `commons/artifacts/registry/*.json` for descriptions and QFEP connections
   - Look up tutorial content in `tutorial_text.json`
   - Read the text (inline or in .gd file)
   - Find teleporter position (exit to next map)
4. Move to next map
5. After the last map, note the sequence's `lab_map` — this is the expanded Lab state

**To understand the project philosophy:**
- Read Point_Zero, Point_1, Point_Context in sequence
- Notice the technical <-> critical oscillation
- Pay attention to spatial architecture (raised platforms, galleries, voids)
- Read the QFEP connections in artifact registries — every algorithm has a queer theory dimension
- The project teaches **and** critiques computational thinking simultaneously
- Entropy is not decay — entropy is freedom

**Current development highlights (Feb 2026):**
- 6 new physical probability artifacts in the randomness domain (coin_toss, dice_throw, galton_board, prng_crank_machine, monte_carlo_dartboard, hardware_entropy_decay)
- All 6 are registered in `commons/artifacts/registry/randomness.json` with QFEP connections
- All 6 are placed in existing randomness maps (Random_Cubes, Random_Definition, Random_Gaussian, Random_Rotate_Random_XYZ, Randomness_Examples_of_Randomness)
- 50+ sequences spanning 22 algorithm domains with 200+ maps
- Component-based grid system with 8 specialized components
- 30+ utility types across 11 categories

---

*This guide allows you to experience Ada Research by reading its source files, tracing the same journey a VR player would take through the virtual space.*
