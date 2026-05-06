# Artifact Creation Package — 20 Missing Decorative Artifacts

## What This Is

Ada Research is a Godot 4.x VR educational project. The game world is a grid-based map system where **artifacts** (3D objects) are placed via tokens in map JSON files. 20 artifact tokens exist in maps but have no implementation — they spawn as placeholder cubes. This package has everything needed to build them all.

---

## The Pattern: How An Artifact Works

Every artifact follows the same 3-file pattern:

### 1. GDScript (`.gd`) — The artifact logic

```gdscript
extends Node3D
class_name MyArtifact

## One-line doc comment describing what this is.

# --- Configuration ---
@export var some_param: float = 1.0

func _ready() -> void:
    # Build all meshes/labels procedurally here
    _build()

func _build() -> void:
    # Create MeshInstance3D nodes, Label3D nodes, materials, etc.
    # Add them as children with add_child()
    pass

## Grid system integration — accept configuration from map data
func apply_grid_config(config_data: Dictionary) -> void:
    # Optional: read config keys, rebuild if needed
    pass
```

**Key rules:**
- `extends Node3D` always
- `class_name` is PascalCase of the lookup_name
- Everything procedural in `_ready()` — no external assets/textures needed
- Use `add_child()` to attach generated meshes
- `apply_grid_config()` is optional but good practice

### 2. Scene (`.tscn`) — Minimal wrapper

```
[gd_scene format=3]

[ext_resource type="Script" path="res://commons/artifacts/FOLDER_NAME/SCRIPT_NAME.gd" id="1_script"]

[node name="NodeName" type="Node3D"]
script = ExtResource("1_script")
```

**Note:** When Godot opens the project, it auto-assigns `uid://` values. Don't worry about UIDs — just omit them and Godot adds them.

### 3. Registry Entry (`.json`) — How the spawner finds it

Add to the appropriate registry file in `commons/artifacts/registry/`:

```json
"lookup_name_here": {
    "name": "Human Readable Name",
    "lookup_name": "lookup_name_here",
    "description": "What this artifact shows/does.",
    "scene": "res://commons/artifacts/FOLDER_NAME/SCRIPT_NAME.tscn",
    "category": "showcase",
    "include_in_map_data": true,
    "map_ready": true,
    "map_sequences": ["sequence_name"],
    "sequence": "sequence_name"
}
```

**Registry files to use:**
| Artifact Theme | Registry File |
|---|---|
| WFC, tiling | `arrays.json` |
| Gödel, Russell, Escher, self-reference | `foundations.json` |
| QFEP badges/formulas | `qfep.json` |
| Bifurcation, chaos | `chaos.json` |
| Neural network, ML | `machinelearning.json` or `machinelearning_extra.json` |
| Graph theory, network | `algorithms_misc.json` |
| Art (Mondrian, Judd, Magritte) | `foundations.json` (art-math section) |
| General/coordinates | `commons_artifacts.json` |
| Audio/spectrum | `arrays.json` or `commons_artifacts.json` |

---

## The Spawning Pipeline

Map files (`map_data_post_*.json`) have an `interactables` layer — a 2D array of token strings.

**Token format:** `lookup_name:rotation:y_offset:scale`

Examples:
- `array_carpet:0:0:0.3` → no rotation, floor level, scale 0.3×
- `self_referential_sign:0:2:0.3` → no rotation, Y+2.0 (wall height), scale 0.3×
- `spectrum_analyser:90:0:0.5` → rotated 90°, floor level, scale 0.5×
- `xyz_coordinates` → plain token, no overrides (default scale/position)

**What the grid system does with the token:**
1. Parses token → lookup_name + overrides (rotation, y_position, uniform_scale)
2. Looks up lookup_name in merged registry (all JSON files)
3. Loads the scene path from the registry entry
4. Instantiates the scene
5. Sets `position` to grid world coordinates
6. Applies overrides: `position.y += y_offset`, `scale *= uniform_scale`, rotation
7. Calls `apply_grid_config(config_data)` if the method exists

**If lookup_name isn't in any registry → placeholder cube.**

---

## Mesh Building Recipes

These are the common patterns for procedural 3D content in Godot 4.x:

### Flat Panel (wall-mounted display, badge, sign)
```gdscript
var mesh_inst = MeshInstance3D.new()
var quad = QuadMesh.new()
quad.size = Vector2(0.6, 0.4)
mesh_inst.mesh = quad

var mat = StandardMaterial3D.new()
mat.albedo_color = Color(0.2, 0.15, 0.1)
mat.roughness = 0.8
mesh_inst.material_override = mat
add_child(mesh_inst)
```

### Box/Frame (border, shelf, block)
```gdscript
var box_inst = MeshInstance3D.new()
var box = BoxMesh.new()
box.size = Vector3(0.5, 0.02, 0.005)  # wide, thin, shallow
box_inst.mesh = box
box_inst.position = Vector3(0, 0.2, 0)  # offset
add_child(box_inst)
```

### Sphere (node in graph, orb, badge element)
```gdscript
var sphere_inst = MeshInstance3D.new()
var sphere = SphereMesh.new()
sphere.radius = 0.02
sphere.height = 0.04
sphere_inst.mesh = sphere
add_child(sphere_inst)
```

### Cylinder (arrow shaft, bar, column)
```gdscript
var cyl_inst = MeshInstance3D.new()
var cyl = CylinderMesh.new()
cyl.top_radius = 0.005
cyl.bottom_radius = 0.005
cyl.height = 0.3
cyl_inst.mesh = cyl
add_child(cyl_inst)
```

### Cone (arrowhead)
```gdscript
var cone_inst = MeshInstance3D.new()
var cone = CylinderMesh.new()
cone.top_radius = 0.0
cone.bottom_radius = 0.015
cone.height = 0.04
cone_inst.mesh = cone
add_child(cone_inst)
```

### Text Label (3D text in space)
```gdscript
var label = Label3D.new()
label.text = "Hello World"
label.font_size = 32
label.pixel_size = 0.001
label.modulate = Color.WHITE
label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
label.position = Vector3(0, -0.15, 0.001)
add_child(label)
```

### Texture from Image (procedural pixel art)
```gdscript
var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
for y in range(height):
    for x in range(width):
        image.set_pixel(x, y, some_color)
var texture = ImageTexture.create_from_image(image)

var mat = StandardMaterial3D.new()
mat.albedo_texture = texture
mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # pixel art look
```

### Glow / Emission
```gdscript
var mat = StandardMaterial3D.new()
mat.emission_enabled = true
mat.emission = Color(1.0, 0.8, 0.2)
mat.emission_energy_multiplier = 1.5
```

### Transparency
```gdscript
var mat = StandardMaterial3D.new()
mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
mat.albedo_color = Color(0.2, 0.4, 0.8, 0.3)  # alpha = 0.3
```

### Floor-lying quad (carpet, tile)
```gdscript
mesh_inst.rotation_degrees.x = -90
mesh_inst.position.y = 0.005  # avoid z-fighting
```

---

## The 20 Artifacts To Build

### File Location Convention
Each artifact goes in: `commons/artifacts/{lookup_name}/{lookup_name}.gd` and `.tscn`

---

### GROUP A: Wall Panels & Signs (flat display, Label3D + backing)

**These all share the same structure:** QuadMesh backing panel + Label3D text + optional BoxMesh frame border.

#### 1. `self_referential_sign` (4 maps, `0:2:0.3`)
Wall sign with a self-referential sentence. Y=2.0 means high on wall.
- Panel: dark wood color `Color(0.25, 0.18, 0.12)`
- Text: `"This sentence has thirty-six letters."` (or similar quine)
- Frame: 4 thin BoxMesh borders, slightly lighter wood

#### 2. `lambda_wall_slider` (3 maps, `0:1:0.4`)
Lambda calculus notation panel. Y=1.0 = eye level on wall.
- Panel: dark slate `Color(0.15, 0.15, 0.2)`
- Text lines via multiple Label3D:
  - `"λx.x"` (identity)
  - `"λf.λx.f(f(x))"` (Church numeral 2)
  - `"λn.λf.λx.n f (f x)"` (successor)
- Title Label3D: `"Lambda Calculus"`

#### 3. `phi_wall_slider` (3 maps, `0:1:0.4`)
Golden ratio panel. Same structure as lambda_wall_slider.
- Panel: warm gold-tinted `Color(0.2, 0.18, 0.1)`
- Draw golden rectangles as nested BoxMesh outlines (2D on panel surface)
- Text: `"φ = 1.618..."` and `"φ² = φ + 1"`
- Golden spiral approximated as line segments or small quads

#### 4. `qfep_formula_display` (3 maps, `0:1.5:0.5`)
Larger panel showing QFEP equations. Scale 0.5 = prominent.
- Panel: deep blue-black `Color(0.08, 0.08, 0.15)`
- Main formula Label3D: `"QFE = F − λE(S) + φΔE(S,t)"`
- Sub-labels explaining each term:
  - `"F = Free Energy (order-seeking)"`
  - `"λE(S) = Entropy Drive"`
  - `"φΔE(S,t) = Rate Sensitivity"`
- Glow emission on the formula text

---

### GROUP B: Badges (small wall plaques, `scale 0.2`)

**All badges:** Small QuadMesh (~0.4×0.3) + frame + title Label3D + subtitle. Y offset ~1.5.

#### 5. `incompleteness_badge` (4 maps, `0:1.5:0.2`)
- Title: `"INCOMPLETENESS"`
- Subtitle: `"This system cannot prove its own consistency."`
- Frame color: gold `Color(0.7, 0.55, 0.2)`
- Panel: dark `Color(0.1, 0.1, 0.12)`

#### 6. `qfep_master_badge` (3 maps, `0:1.5:0.2`)
- Title: `"QFEP MASTER"`
- Subtitle: `"Edge of chaos navigator"`
- Frame: iridescent green `Color(0.2, 0.8, 0.4)`
- Panel: dark blue `Color(0.05, 0.05, 0.15)`

#### 7. `visual_philosopher_badge` (1 map, `0:1.5:0.2`)
- Title: `"VISUAL PHILOSOPHER"`
- Subtitle: `"Art ∩ Mathematics"`
- Frame: warm purple `Color(0.5, 0.2, 0.6)`
- Panel: dark `Color(0.1, 0.08, 0.12)`

---

### GROUP C: Floor Displays (texture on flat quad)

#### 8. `wfc_tile_mosaic` (7 maps, `0:0:0.3`)
Like `array_carpet` — procedural texture on a floor-lying QuadMesh.
- Generate a WFC (Wave Function Collapse) solved grid:
  - Use a simple tile set: 4-6 tile types with color-coded adjacency rules
  - Solve a ~16×16 grid using constraint propagation + backtracking
  - Each tile = a solid color or 2×2 pixel pattern
- Render solved grid as Image → ImageTexture → material
- `TEXTURE_FILTER_NEAREST` for crisp pixels
- QuadMesh size ~0.8×0.8, rotation_degrees.x = -90

**WFC algorithm sketch:**
```
1. Initialize all cells with all possible tile types
2. Pick cell with fewest possibilities (lowest entropy)
3. Collapse it to one random choice
4. Propagate constraints to neighbors (remove incompatible tiles)
5. Repeat until all cells collapsed or contradiction
6. On contradiction: backtrack or restart with new seed
```

#### 9. `escher_tessellation_tile` (1 map, `0:0:0.5`)
Floor tile with Escher-style interlocking shapes.
- Generate a deformed tessellation texture:
  - Start with a regular grid (e.g., 8×8)
  - Apply edge-matching deformations to simulate interlocking
  - Color alternating shapes in 2-3 colors
- Same floor-quad approach as array_carpet
- Scale 0.5 = relatively large floor piece

---

### GROUP D: 3D Procedural Sculptures

#### 10. `xyz_coordinates` (7 maps, plain token)
Standard 3D coordinate gizmo — 3 colored arrows.
- Red X-axis: CylinderMesh shaft + cone arrowhead + Label3D "X"
- Green Y-axis: same in green + "Y"
- Blue Z-axis: same in blue + "Z"
- Each arrow: shaft length ~0.3, shaft radius 0.005, cone tip 0.04 tall
- Labels at arrow tips, font_size 24
- Use emission for vivid colors

#### 11. `network_sculpture` (3 maps, `0:1:0.3`)
3D graph with nodes and edges. Petersen graph (10 nodes, 15 edges) is a good choice.
- Nodes: small SphereMesh (radius 0.015) with emission
- Edges: thin CylinderMesh connecting node pairs
  - To orient a cylinder between two points:
    ```gdscript
    var mid = (a + b) / 2.0
    var diff = b - a
    var length = diff.length()
    cyl_inst.position = mid
    # Look at direction and rotate to align
    if diff.length() > 0.001:
        cyl_inst.look_at_from_position(mid, b, Vector3.UP)
        cyl_inst.rotate_object_local(Vector3.RIGHT, PI/2)
    ```
- Petersen graph node positions: 5 outer pentagon + 5 inner pentagram, all in 3D

#### 12. `neural_landscape` (4 maps, `0:0:0.4`)
3D loss landscape surface.
- Generate a height field from a parametric function with local minima:
  ```
  f(x,y) = sin(x*3)*cos(y*3)*0.3 + sin(x*5+1)*sin(y*4+2)*0.15 + cos(x*2-y*3)*0.1
  ```
- Build as an `ArrayMesh` (SurfaceTool) or use `ImmediateMesh`:
  ```gdscript
  var st = SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  # Generate grid of vertices with heights from f(x,y)
  # Add normals, UVs, then commit
  var mesh = st.commit()
  ```
- Color by height: blue (low/minimum) → green (mid) → red (high/maximum)
- Floor-mounted, scale 0.4

#### 13. `bifurcation_diagram_3d` (3 maps, `0:0.5:0.3`)
Logistic map bifurcation diagram as 3D points.
- For r from 2.5 to 4.0 (stepped by ~0.005):
  - Iterate x(n+1) = r * x(n) * (1 - x(n)) for ~200 warmup steps
  - Record next ~50 x values
  - Plot as small BoxMesh or use `MultiMesh` for performance
- X-axis = r parameter, Y-axis = stable x values
- Color: blue for stable regions, red for chaotic, green at edge
- Elevated (Y offset 0.5)

#### 14. `russell_set_display` (4 maps, `0:1:0.4`)
Nested transparent boxes representing the self-containing set paradox.
- 4-5 nested transparent BoxMesh cubes, each slightly smaller
- Outermost: `Color(0.3, 0.3, 0.8, 0.15)` (blue tint, very transparent)
- Each inner: different color tint, slightly more opaque
- A Label3D: `"S = { x | x ∉ x }"` floating near the center
- Question Label3D: `"S ∈ S ?"` with emission glow
- Arrow or line looping back pointing at itself (self-reference visual)

#### 15. `escher_staircase_mini` (1 map, `0:1:0.3`)
Miniature impossible staircase — 4 flights forming a square loop.
- 4 sets of ~4 steps each, arranged in a square
- Each step: small BoxMesh (e.g., 0.05 × 0.01 × 0.03)
- Steps ascend along each side, but the 4th side connects back to the start at the same height
- This creates a visual paradox (works best from certain angles)
- Stone gray color `Color(0.6, 0.6, 0.65)`

#### 16. `judd_minimalist_box` (1 map, `0:0.5:0.4`)
Donald Judd stack — evenly spaced horizontal box shelves.
- 6 identical BoxMesh shelves stacked vertically with equal spacing
- Each box: `Vector3(0.4, 0.03, 0.2)` (wide, thin, medium depth)
- Spacing: 0.08 between each
- Colors: industrial tones — anodized aluminum `Color(0.7, 0.7, 0.75)` or copper `Color(0.7, 0.4, 0.3)`
- All same color (Judd's trademark uniformity)

---

### GROUP E: Art Panels (procedural texture + frame)

#### 17. `mondrian_composition` (1 map, `0:1:0.3`)
Procedural Mondrian grid painting.
- Algorithm: recursive binary space partition
  - Start with full rectangle
  - Randomly split horizontally or vertically
  - Recurse on sub-rectangles (depth 3-5)
  - Assign colors: mostly white, some red/blue/yellow
- Render to Image → ImageTexture (e.g., 128×128)
- Black grid lines (2-3px thick) between regions
- Display on QuadMesh + BoxMesh black frame border
- Use seeded `RandomNumberGenerator` for deterministic output

#### 18. `droste_effect_frame` (1 map, `0:2:0.3`)
Recursive picture frame.
- Outer frame: 4 BoxMesh borders (warm brown)
- Inner content: a smaller QuadMesh with a texture showing a smaller frame
- Render 4-5 levels of recursion as a single Image:
  - Draw frame border → shrink → draw frame border → shrink → ...
  - Fill innermost with a solid color or pattern
- Or: use nested QuadMesh children at decreasing scale (0.6× each level)

#### 19. `magritte_pipe_frame` (1 map, `0:1.5:0.4`)
"This is not a pipe" — framed display.
- Frame: 4 BoxMesh borders, ornate gold `Color(0.6, 0.5, 0.2)`
- Panel: cream/beige `Color(0.9, 0.88, 0.82)`
- Pipe shape: build from CylinderMesh (bowl) + CylinderMesh (stem) + SphereMesh (bowl interior)
  - Or simpler: draw pipe silhouette as dark pixels on an Image texture
- Label3D below pipe: `"Ceci n'est pas une pipe"` in italic-looking small text
- Classic museum frame aesthetic

---

### GROUP F: Animated / Special

#### 20. `spectrum_analyser` (1 map, `90:0:0.5`)
Audio frequency spectrum bars.
- 16-32 vertical BoxMesh bars side by side
- Each bar: different height (randomized or sine-wave pattern for static display)
- Colors: gradient from green (low freq) → yellow → red (high freq)
- Optional: animate heights in `_process()` using sin waves at different frequencies
- Rotation 90° in token means the grid rotates it — build it facing forward
- Bar width: ~0.02 each, gap: 0.005, height range: 0.05-0.3

---

## Batch Creation Strategy

Since many artifacts share patterns, build them in groups:

1. **Start with badges** (3 artifacts) — simplest, just panel + text + frame
2. **Wall panels** (3 artifacts) — same as badges but larger, more text
3. **Floor textures** (2 artifacts) — Image generation + floor quad
4. **Simple 3D** (xyz_coordinates, judd_minimalist_box) — basic mesh stacking
5. **Complex 3D** (network_sculpture, neural_landscape, bifurcation_diagram_3d, russell_set_display, escher_staircase_mini) — more math
6. **Art panels** (mondrian, droste, magritte) — procedural texture + frame
7. **Special** (spectrum_analyser) — animated bars

For each artifact:
1. Create directory: `commons/artifacts/{name}/`
2. Write `.gd` script
3. Write `.tscn` scene
4. Add registry entry to appropriate JSON file
5. Test: the token in map files should now resolve instead of showing placeholder cube

---

## Reference Implementation: `array_carpet`

This is the most complete reference. See:
- `commons/artifacts/array_carpet/array_carpet.gd` (244 lines)
- `commons/artifacts/array_carpet/array_carpet.tscn` (7 lines)
- Registry entry in `commons/artifacts/registry/arrays.json` under `"array_carpet"`

Key patterns it demonstrates:
- `class_name ArrayCarpet`
- `@export` vars for configuration
- Procedural texture generation (Image → ImageTexture)
- Floor-lying QuadMesh (rotation_degrees.x = -90, y offset 0.005)
- `apply_grid_config()` for map data configuration
- Reading from TraceData singleton for live data
- Signal connection for live updates
- Default fallback when no data available

---

## Quick Checklist Per Artifact

- [ ] Directory created at `commons/artifacts/{lookup_name}/`
- [ ] `.gd` file with `extends Node3D`, `class_name`, procedural `_ready()`
- [ ] `.tscn` file with Node3D root + script ext_resource
- [ ] Registry entry in correct JSON file with `"map_ready": true`
- [ ] `lookup_name` in registry matches the token in map files exactly
- [ ] Scene path in registry matches actual file location
