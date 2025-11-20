# Guide: How to "Play" Ada Research by Reading the Files

This guide explains how to navigate and experience the Ada Research VR educational system by reading its source files.

## Project Overview

**Ada Research** is a VR computational geometry education system built in Godot + XR Tools. It teaches algorithms through dual lenses: technical implementation + queer theory critique. Maps are designed as 3D spaces where players walk through and interact with educational content displayed on clipboards, grabbable objects, and primitives.

## How to Start: The Map Sequence System

### 1. Begin with `map_sequences.json`

**Location:** `C:\Users\palle\Documents\GitHub\AdaResearch\commons\maps\map_sequences.json`

This file defines learning sequences (like chapters in a book). Each sequence contains:
- `name`: Display name
- `description`: What the sequence teaches
- `maps`: **Array of map names in order** ← This is your playlist!
- `learning_objectives`: Educational goals
- `unlock_requirements`: Prerequisites

**Example - The "primitives" sequence:**
```json
"primitives": {
	"name": "name Primitives",
	"maps": [
		"Point_Zero",      ← Start here!
		"Point_1",         ← Then this
		"Point_Context",   ← Then this
		"Point_Line",
		...
	]
}
```

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

**Interpretation:**
- `"0"` = empty space
- `"1"` = place 1 cube at this grid position
- `"2"` = stack 2 cubes (raised platform)
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

**Common codes:**
- `"t"` = teleporter (to next map)
- `"s"` = spawn point
- `"origin"` = origin marker
- `"la:point"` = label annotation
- `"3t:text"` = floating text marker

#### **Layer 3: `interactables`** (Educational objects)
```json
"interactables": [
	["origin", " ", " ", "code_display:-90:2#tutorial:point_zero", " "],
	["arrow:180:0:0.2", " ", " ", " ", " "],
	[" ", " ", "dark_sphere", " ", " "]
]
```

**Format:** `type:rotation:height:scale#config`

**Common objects:**
- `code_display:-90:2#tutorial:point_zero`
  - Type: clipboard
  - Rotation: -90 degrees
  - Height: 2 units
  - Loads tutorial: "point_zero"

- `arrow:180:0:0.2`
  - Type: arrow primitive
  - Rotation: 180 degrees
  - Height: 0
  - Scale: 0.2

- `grab_sphere_point:180`
  - Grabbable point sphere
  - Rotation: 180 degrees

- `dark_sphere`
  - Ambient darkening effect

- `vectorpoint:180:1:5`
  - Coordinate axes display

### How to Visualize a Map

1. **Read the `structure` layer** - sketch out where blocks are placed
2. **Overlay the `utilities`** - mark where teleporters, spawns, labels are
3. **Add the `interactables`** - note what educational content appears where

**Example - Point_Zero visualization:**
```
Structure:          Overlays:
1 1 1 0 0 0 0      origin → (0,0)
1 1 1 0 0 0 0      arrow → (0,1)
1 0 1 0 0 0 0      code_display → (3,0)
1 1 1 0 0 0 0      dark_sphere → (3,2)
0 0 0 0 0 0 0      teleporter → (1,2)
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

## How to "Play" the Game

### Step-by-Step Process

**1. Start with a sequence**
```bash
Read: commons/maps/map_sequences.json
Find: "primitives" → "maps" array
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
Find: "point_zero" → "content"
Read the text content
```

**5. Imagine the experience**
- Where is the player standing?
- What do they see around them?
- What can they grab?
- What text are they reading?

**6. Find the teleporter**
- Look in `utilities` layer for `"t"`
- Note its position - this is the exit

**7. Move to next map**
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
  commons/context/clipboard/tutorial_text.json → "point_zero"

Content summary:
  - Philosophical intro about Vector3.ZERO
  - Heidegger's thrownness
  - "Can creation exist without an interface?"
```

**Map 2: Point_1**
```bash
Read: commons/maps/Point_1/map_data.json

Structure: Large platform with notch cut at (5,6)
Interactables:
  - dark_sphere at (3,2)
  - grab_sphere_point at (3,3) ← Can pick this up!
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
  - code_display at (2,4) → "point_axioms"
  - grab_sphere_point_with_text at (3,4)
  - draw_dot at (4,4)
  - code_display at (5,4) → "the_trace"

Also:
  - dark_sphere at (4,3)
  - vectorpoint axes at (1,11)
  - teleporter at (5,6)

Read tutorials:
  1. "point_axioms" → Technical: how to code a point
  2. "the_trace" → Critical: queer theory critique

Experience:
  - Museum gallery layout
  - Two clipboards flanking interactive objects
  - Teaches through multiple modalities
  - Technical ↔ Critical dialectic
```

## Key Files Reference

### Map System
- **Sequences:** `commons/maps/map_sequences.json`
- **Individual maps:** `commons/maps/{MapName}/map_data.json`

### Tutorial Content
- **Index:** `commons/context/clipboard/tutorial_text.json`
- **Text files:** `commons/context/clipboard/tutorial_text/*.gd`

### Scene Files
- **Clipboard display:** `commons/context/clipboard/codeDisplay.tscn`
- **Text UI:** `commons/primitives/panels/DigitalPaper/TextUIControl.tscn`
- **Base scene:** `commons/scenes/base.tscn`

### Grid System
- **Artifacts catalog:** `commons/artifacts/grid_artifacts.json` (4454 lines - master lookup table!)
  - Maps keys like "code_display" → scene files like "res://commons/context/clipboard/codeDisplay.tscn"
  - Contains descriptions and metadata for all placeable objects

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
- "What does X erase?"
- Non-Euclidean perspectives
- Bodies, duration, resistance

### Reading the Dialectic

Watch for this pattern:
1. **Introduce** concept (poetic/philosophical)
2. **Teach** implementation (technical/code)
3. **Critique** what was just taught (queer theory)
4. **Embody** through VR interaction (physical)

### Map Pairing Pattern: Simple → Context

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
- Point_1 → Point_Context
- Point_Line → Point_Line_Context
- Point_Triangle → Point_Triangle_Context

Example in Point_Context:
- Left clipboard: technical point definition
- Center: grab the point (embodied)
- Right clipboard: critique of discretization
- You stand between these frameworks

## Tips for Navigating

### Finding Specific Content

**To find all maps in a sequence:**
```bash
grep -A 20 '"primitives"' commons/maps/map_sequences.json
```

**To find tutorial content:**
```bash
grep "point_axioms" commons/context/clipboard/tutorial_text.json -A 5
```

**To see all tutorial files:**
```bash
ls commons/context/clipboard/tutorial_text/*.gd
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

1. Type: `code_display` → Look this up in grid_artifacts.json
2. Rotation: `-90` → Rotated 90 degrees counterclockwise
3. Height: `2` → Placed 2 units above ground
4. Config: `#tutorial:point_zero` → Loads this tutorial ID

Then trace the full chain:
```
"code_display" key
  ↓
commons/artifacts/grid_artifacts.json
  ↓
"code_display": { "scene": "res://commons/context/clipboard/codeDisplay.tscn" }
  ↓
Scene file instantiated with parameters
  ↓
Config parameter: "tutorial:point_zero"
  ↓
commons/context/clipboard/tutorial_text.json
  ↓
"point_zero": { "content": "..." }
  ↓
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

### Why Three Layers?

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
1. Open `commons/maps/map_sequences.json`
2. Pick a sequence, note the `maps` array
3. For each map name:
   - Read `commons/maps/{MapName}/map_data.json`
   - Visualize the three layers
   - Look up tutorial content in `tutorial_text.json`
   - Read the text (inline or in .gd file)
   - Find teleporter position
4. Move to next map

**To understand the project philosophy:**
- Read Point_Zero, Point_1, Point_Context in sequence
- Notice the technical ↔ critical oscillation
- Pay attention to spatial architecture (raised platforms, galleries, voids)
- The project teaches **and** critiques computational thinking simultaneously

---

*This guide allows you to experience Ada Research by reading its source files, tracing the same journey a VR player would take through the virtual space.*
