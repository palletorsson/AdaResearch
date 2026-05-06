# Grid Editor Architecture

A 2D grid-based editor for designing layouts that render in 3D. Used for glass rack apparatus, pipe systems, audio racks, etc.

## Core Concepts

### Orientation Planes

The 2D grid maps to 3D space based on the subset's `orientation.plane`:

| Plane | Grid X → | Grid Y → | Depth | Use Case |
|-------|----------|----------|-------|----------|
| **XZ** | X axis | Z axis | Y (up) | Top-down: pipes, floor layouts |
| **YZ** | Z axis | Y axis | X (forward) | Side view: glass rack, chemistry |
| **XY** | X axis | Y axis | Z (forward) | Front view: wall rack, audio |

### Grid Size

`orientation.grid_size` defines meters per grid cell:
- Glass rack: 0.1m (10cm per cell)
- Big pipes: 2.0m per cell
- Audio rack: 0.08m (8cm per cell)

### Element Sizing

Element `size: [width, height]` in grid cells:
- `width` = horizontal span (grid X)
- `height` = vertical span (grid Y)

Actual 3D dimensions:
```
3d_width = size[0] * grid_size
3d_height = size[1] * grid_size
```

## File Structure

```
tools/grid_editor/
├── scenes/
│   └── main.tscn          # Main editor scene
├── scripts/
│   ├── editor_main.gd     # UI, 3D preview, file ops
│   ├── grid_canvas.gd     # 2D grid interaction
│   └── subset_loader.gd   # JSON subset loading
└── subsets/
    ├── glass_rack.json    # Chemistry apparatus
    ├── big_pipes.json     # Industrial pipes
    └── audio_rack.json    # Modular synth rack
```

## Subset JSON Format

```json
{
  "id": "glass_rack",
  "name": "Glass Rack",
  "orientation": {
    "plane": "YZ",           // Which 3D plane
    "grid_size": 0.1,        // Meters per cell
    "up_axis": "Y"           // Which axis is "up"
  },
  "defaults": {
    "tube_radius": 0.015     // Subset-wide defaults
  },
  "categories": [
    {"id": "tubes", "name": "Tubes", "color": "#2196F3"}
  ],
  "elements": [
    {
      "id": "straight",
      "name": "Straight Tube",
      "category": "tubes",
      "size": [1, 2],        // 1 wide, 2 tall
      "icon": "│",           // 2D display
      "segment_type": "straight",  // 3D generator type
      "scene": "res://...",  // Or use actual scene file
      "scene_scale": [1,1,1] // Optional scale
    }
  ]
}
```

## 3D Generation

### Scene-based Elements
If element has `scene` path, loads the .tscn file directly.
Optional `scene_scale` adjusts size.

### Procedural Elements (Glass Rack)
If element has `segment_type`, generates geometry using SurfaceTool:

| segment_type | Description | Size Pattern |
|--------------|-------------|--------------|
| `straight` | Vertical tube | [1, N] |
| `corner` | 90° elbow | [1, 1] or [2, 2] |
| `sbend` | S-curve diagonal | [2, 2] |
| `ubend` | 180° turn | [2, 1] |
| `ypipe` | Y-splitter | [2, 2] |
| `junction` | T-junction | [2, 2] |
| `cross` | 4-way cross | [2, 2] |
| `spiral` | Helix condenser | [1, 4] |
| `flask` | Round bottom flask | [2, 3] |
| `beaker` | Open cylinder | [2, 2] |

### Glass Rack Junctions (2×2 Elements)

All junctions occupy a 2×2 grid and connect via 2-unit tubes at their edges:

**S-bend (2×2)**:
- Enters bottom-left (Y=0, Z=0)
- Exits top-right (Y=height, Z=width)
- Smooth S-curve connects diagonally (cosine interpolation)

**Corner (2×2)**:
- Enters from bottom (Y=0)
- Exits to right (Z=width)
- 90° smooth elbow

**U-bend (2×2)**:
- Two openings at top (Y=height)
- Semicircle dips down to Y≈0
- ∪ shape

**T-junction (2×2)**:
- Main path vertical through center
- Branch exits to right at midpoint
- Three connection points

**Y-pipe (2×2)**:
- Single inlet at bottom
- Two outlets diverging at top
- Angled fork

**Cross (2×2)**:
- Four-way intersection
- Vertical + horizontal paths cross at center

### Mesh Generation Pattern

All tubes use the same pattern:
1. Generate center points along curve
2. Calculate tangent at each point
3. Create tube ring perpendicular to tangent
4. Connect rings with triangles
5. Generate normals for smooth shading

```gdscript
# Example: tube ring generation
var tangent = curve_derivative.normalized()
var binormal = Vector3(1, 0, 0)  # Perpendicular to YZ
var normal = binormal.cross(tangent).normalized()

for s in segments:
    var angle = (s / segments) * TAU
    var offset = (normal * cos(angle) + binormal * sin(angle)) * radius
    add_vertex(center + offset)
```

## 2D Grid Interaction

### Placement
- Click element in list → start drag
- Click on grid → place element
- Elements snap to grid cells

### Manipulation
- **Double-click**: Rotate 90°
- **R key**: Rotate selected/dragging
- **Drag**: Move placed element
- **Delete/Backspace**: Remove selected
- **Right-click**: Cancel operation

### Preview
- 3D preview updates on every change
- Right-drag to orbit camera
- Scroll to zoom

## Adding New Subsets

1. Create `subsets/my_subset.json`
2. Add to `SUBSET_FILES` array in `subset_loader.gd`
3. Define orientation, categories, elements
4. Either:
   - Reference existing scenes (`scene` property)
   - Add procedural generation in `editor_main.gd`

## Adding New Procedural Elements

1. Add `segment_type` to JSON element
2. Add case in `_create_glass_segment()` match
3. Create `_create_glass_X_smooth()` function
4. Create `_generate_X_mesh_yz()` for the geometry
