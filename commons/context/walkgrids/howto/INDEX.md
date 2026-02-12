# Walkable Spaces — How-To Index

Each file explains how to drop a space into your maps with code examples, parameter tables, and teaching suggestions.

## Core Spaces
- [sine_space_howto.md](sine_space_howto.md) — Perfect sine/cosine waves, the surveillance landscape
- [noise_space_howto.md](noise_space_howto.md) — Fractal noise, the resistance terrain
- [voronoi_space_howto.md](voronoi_space_howto.md) — Nearest-point territories, biological division
- [random_space_howto.md](random_space_howto.md) — Pure chaos, animated mathematical anarchy
- [fractal_space_howto.md](fractal_space_howto.md) — Diamond-square recursive terrain

## Cellular & Emergent
- [worley_space_howto.md](worley_space_howto.md) — Cracked earth, cell walls, dried mud
- [cellular_automata_space_howto.md](cellular_automata_space_howto.md) — Game of Life as geological layers
- [reaction_diffusion_space_howto.md](reaction_diffusion_space_howto.md) — Turing patterns: spots, stripes, coral

## Mathematical Structures
- [mandelbrot_space_howto.md](mandelbrot_space_howto.md) — Walk the boundary of decidability
- [lsystem_space_howto.md](lsystem_space_howto.md) — Branching grammars as ridge networks
- [wave_interference_space_howto.md](wave_interference_space_howto.md) — Superposition, double-slit, ripple tank
- [ridged_noise_space_howto.md](ridged_noise_space_howto.md) — Mountains, canyons, dragon spines
- [spherical_harmonics_space_howto.md](spherical_harmonics_space_howto.md) — Electron orbitals as terrain
- [flow_field_space_howto.md](flow_field_space_howto.md) — Vortices, sources, dipoles as potential energy

## Terrain & Simulation
- [domain_warp_space_howto.md](domain_warp_space_howto.md) — Quilez-style warped noise, marble, wood grain
- [erosion_space_howto.md](erosion_space_howto.md) — Hydraulic erosion carving river valleys

## Topology & Non-Euclidean
- [mobius_space_howto.md](mobius_space_howto.md) — Non-orientable Möbius strip
- [torus_space_howto.md](torus_space_howto.md) — Toroidal curvature, Villarceau circles
- [hyperbolic_space_howto.md](hyperbolic_space_howto.md) — Poincaré disk, negative curvature

## Meta
- [knowledge_terrain_space_howto.md](knowledge_terrain_space_howto.md) — The curriculum itself as walkable landscape

---

## Common Patterns

### Drop any space into a map scene
```gdscript
var space = preload("res://commons/context/walkgrids/some_space.tscn").instantiate()
space.space_size = Vector2(30, 30)   # Match your map's footprint
space.resolution = 80                 # 60-80 for VR, 100+ for desktop
space.height_scale = 2.0             # Adjust for walkability
space.position = Vector3(0, 0, 0)    # Align with map grid
add_child(space)
```

### Use TopologyManager to toggle spaces
```gdscript
var tm = TopologyManager.new()
tm.create_worley_space = true
tm.create_mandelbrot_space = true
add_child(tm)

# Navigate
tm.next_space()
tm.teleport_to_space_by_name("WorleySpace")

# Add at runtime
tm.add_space_at_runtime("erosion")
tm.add_space_at_runtime("spherical_harmonics")

# List active
print(tm.get_space_names())
```

### Apply the shared height-color shader
```gdscript
var shader_mat = ShaderMaterial.new()
shader_mat.shader = load("res://commons/context/walkgrids/terrain_height_color.gdshader")
shader_mat.set_shader_parameter("color_low", Color(0.1, 0.05, 0.2))
shader_mat.set_shader_parameter("color_mid", Color(0.4, 0.45, 0.5))
shader_mat.set_shader_parameter("color_high", Color(1.0, 0.9, 0.7))
shader_mat.set_shader_parameter("show_contours", true)
shader_mat.set_shader_parameter("contour_spacing", 0.5)
$SomeSpace/StaticBody3D/MeshInstance3D.material_override = shader_mat
```

### Side-by-side comparison template
```gdscript
for i in range(variants.size()):
    var space = SomeSpace.new()
    space.position.x = i * (space.space_size.x + 5.0)
    space.some_parameter = variants[i]
    space.seed_value = 42  # Same seed for fair comparison
    add_child(space)
```

### Replace a map's grid floor
```gdscript
# In a map scene, disable the default grid and add a walkgrid instead:
func _ready():
    $GridSystem.visible = false  # Or remove it
    
    var terrain = ErosionSpace.new()
    terrain.space_size = Vector2(grid_width * cube_size, grid_depth * cube_size)
    terrain.height_scale = 1.5
    terrain.position.y = -0.5
    add_child(terrain)
```
