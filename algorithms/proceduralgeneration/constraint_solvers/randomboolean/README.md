# Random Boolean Carving 🔮

Procedural hole carving in 3D shapes using **CSG Boolean operations** and **random walks**.

## What This Does

Uses `CSGCombiner3D` + `CSGSphere3D` with **subtract operation** to carve organic tunnels and holes through solid shapes by placing spheres along algorithmically generated paths.

---

## 🚀 Quick Start

### Basic Random Walk Carving

1. **Open** `randboolean.tscn`
2. **Press F6** to play
3. See 3 cubes carved with different random walk patterns!

### Advanced Patterns

1. **Create new scene** with Node3D
2. **Add** CSGCombiner3D node
3. **Attach** `advanced_carver.gd` script
4. **Configure** in Inspector:
   - Pattern: Random Walk, Spiral, Branches, etc.
   - Walk steps, sphere radius, etc.
5. **Play scene** - instant carving!

---

## 📁 Files

- **`random_walk_carver.gd`** - Basic random walk carver
- **`advanced_carver.gd`** - Multiple patterns & effects
- **`randboolean.tscn`** - Demo scene with 3 examples
- **`README.md`** - This file

---

## 🎨 Carving Patterns

### 1. Random Walk (Default)
```gdscript
pattern = CarvePattern.RANDOM_WALK
```
- Wanders randomly through the cube
- Avoids crossing itself (optional)
- Organic, cave-like tunnels

### 2. Spiral
```gdscript
pattern = CarvePattern.SPIRAL
```
- Spirals from bottom to top
- Customizable turns and radius decay
- DNA helix or drill-like effect

### 3. Branches
```gdscript
pattern = CarvePattern.BRANCHES
```
- Tree-like branching structure
- Main trunk with side branches
- Organic root/vein patterns

### 4. Perlin Path
```gdscript
pattern = CarvePattern.PERLIN_PATH
```
- Follows Perlin noise field
- Smooth, flowing curves
- Natural-looking paths

### 5. Grid Tunnels
```gdscript
pattern = CarvePattern.GRID_TUNNELS
```
- Regular grid of straight tunnels
- Architectural/mechanical look
- Great for vents or pipes

---

## ⚙️ Parameters Guide

### Base Shape
```gdscript
cube_size = Vector3(10, 10, 10)  # Size of the solid
base_shape_type = "cube"          # cube, sphere, or cylinder
```

### Carving Settings
```gdscript
walk_steps = 60              # How many spheres to place
step_size = 0.5              # Distance between spheres
sphere_radius = 0.4          # Size of carving spheres
radius_variation = 0.2       # Randomize sphere sizes (0-1)
```

### Self-Crossing
```gdscript
avoid_self_crossing = true        # Prevent path from crossing itself
crossing_check_distance = 1.0     # How close is "crossing"
```

### Pattern-Specific
```gdscript
# Spiral
spiral_turns = 3.0                # Number of revolutions
spiral_radius_decay = 0.5         # How much spiral shrinks

# Branches
branch_probability = 0.15         # Chance to branch (0-1)
max_branches = 5                  # Maximum branches

# Perlin
perlin_scale = 0.3                # Noise frequency
perlin_strength = 2.0             # How much noise affects path
```

---

## 🎯 How CSG Carving Works

### The Setup
```
CSGCombiner3D (this script)
├── CSGBox3D (base solid - OPERATION_UNION)
├── CSGSphere3D (carve sphere 1 - OPERATION_SUBTRACTION)
├── CSGSphere3D (carve sphere 2 - OPERATION_SUBTRACTION)
├── CSGSphere3D (carve sphere 3 - OPERATION_SUBTRACTION)
└── ... more spheres along path
```

### Boolean Operations
- **UNION** (default) - Add geometry
- **SUBTRACTION** (operation = 2) - Remove geometry  ⭐ This carves!
- **INTERSECTION** - Keep only overlap

### The Algorithm
```
1. Create base solid shape (cube/sphere/cylinder)
   ↓
2. Generate path (random walk, spiral, etc.)
   ↓
3. For each point on path:
   - Create CSGSphere3D
   - Set operation to SUBTRACTION
   - Position at path point
   - Add as child of combiner
   ↓
4. CSG system automatically boolean-subtracts all spheres!
```

---

## 💡 Usage Examples

### Simple Cave
```gdscript
var carver = preload("res://algorithms/proceduralgeneration/randomboolean/random_walk_carver.gd").new()
add_child(carver)
carver.walk_steps = 50
carver.sphere_radius = 0.5
carver.cube_size = Vector3(12, 12, 12)
carver.generate_carved_cube()
```

### Spiral Sculpture
```gdscript
var carver = preload("res://algorithms/proceduralgeneration/randomboolean/advanced_carver.gd").new()
add_child(carver)
carver.pattern = CarvePattern.SPIRAL
carver.spiral_turns = 5.0
carver.base_shape_type = "sphere"
carver.generate()
```

### Branching Roots
```gdscript
var carver = advanced_carver.new()
carver.pattern = CarvePattern.BRANCHES
carver.max_branches = 8
carver.branch_probability = 0.25
carver.sphere_radius = 0.3
carver.generate()
```

### Grid Ventilation
```gdscript
var carver = advanced_carver.new()
carver.pattern = CarvePattern.GRID_TUNNELS
carver.sphere_radius = 0.25
carver.show_path_line = false
carver.generate()
```

---

## 🔧 Customization

### Change Base Shape Color
```gdscript
# In Inspector or code
base_material_color = Color(0.5, 0.3, 0.2)  # Brown stone
```

### Vary Sphere Sizes
```gdscript
radius_variation = 0.5  # Spheres range from 50%-150% of sphere_radius
```

### Make Thicker Tunnels
```gdscript
sphere_radius = 0.8     # Bigger spheres
step_size = 0.4         # Closer together = smoother tunnel
```

### Make Maze-Like Paths
```gdscript
avoid_self_crossing = false  # Allow crossing
walk_steps = 100             # Many steps
```

### Disable Path Line
```gdscript
show_path_line = false
```

---

## 🎨 Creative Ideas

### 1. Swiss Cheese
```gdscript
# Many short random walks
for i in range(10):
    var carver = random_walk_carver.new()
    carver.walk_steps = 15
    carver.sphere_radius = 0.6
    carver.random_seed = i
    base_combiner.add_child(carver)
```

### 2. Wormhole
```gdscript
pattern = CarvePattern.SPIRAL
spiral_turns = 1.0
sphere_radius = 1.5
base_shape_type = "cylinder"
```

### 3. Termite Tunnels
```gdscript
pattern = CarvePattern.BRANCHES
max_branches = 15
branch_probability = 0.3
sphere_radius = 0.2
```

### 4. Circuit Board
```gdscript
pattern = CarvePattern.GRID_TUNNELS
sphere_radius = 0.15
cube_size = Vector3(20, 2, 20)  # Flat slab
```

### 5. Organic Sponge
```gdscript
# Multiple Perlin paths
for i in range(5):
    var carver = advanced_carver.new()
    carver.pattern = CarvePattern.PERLIN_PATH
    carver.perlin_scale = 0.2 + i * 0.1
    carver.random_seed = i
    add_child(carver)
```

---

## 🐛 Troubleshooting

### "Path gets stuck"
- **Cause**: Random walk can't find valid moves
- **Fix**: 
  - Increase `cube_size`
  - Decrease `crossing_check_distance`
  - Set `avoid_self_crossing = false`

### "Spheres don't carve"
- **Cause**: CSGSphere3D operation not set to SUBTRACTION
- **Fix**: Check that `operation = CSGShape3D.OPERATION_SUBTRACTION` (value = 2)

### "Tunnel is choppy"
- **Cause**: Spheres too far apart
- **Fix**: Decrease `step_size` or increase `sphere_radius`

### "Too slow"
- **Cause**: Too many spheres or high sphere detail
- **Fix**:
  - Reduce `walk_steps`
  - Lower `radial_segments` and `rings` on spheres
  - Use simpler base shape

### "Path goes outside cube"
- **Cause**: Step size too large or bounds check failing
- **Fix**: 
  - Reduce `step_size`
  - Increase `cube_size`
  - Check `_is_valid_position()` logic

---

## 📊 Performance Tips

1. **Keep sphere count reasonable** (< 100 for realtime)
2. **Lower sphere detail**: 
   ```gdscript
   sphere.radial_segments = 6  # Instead of 16
   sphere.rings = 4            # Instead of 8
   ```
3. **Use smaller cubes** for testing (5x5x5)
4. **Disable path visualization** in production
5. **Bake to static mesh** for final use:
   ```gdscript
   # Export CSG to MeshInstance3D for better performance
   ```

---

## 🎓 Understanding Random Walks

### Self-Avoiding Walk
When `avoid_self_crossing = true`:
- Path cannot get within `crossing_check_distance` of itself
- Creates cleaner, non-overlapping tunnels
- Can get "stuck" if no valid moves available

### Standard Random Walk
When `avoid_self_crossing = false`:
- Path can cross itself freely
- Creates complex, maze-like patterns
- Never gets stuck
- More unpredictable

---

## 🔬 Advanced Techniques

### Multi-Pass Carving
```gdscript
# First pass: Large spheres for main tunnels
carver1.sphere_radius = 0.6
carver1.generate()

# Second pass: Small spheres for details
carver2.sphere_radius = 0.2
carver2.generate()
```

### Animated Carving
```gdscript
# Reveal spheres one by one
var reveal_index = 0
func _process(delta):
    if reveal_index < total_spheres:
        get_child(reveal_index).visible = true
        reveal_index += 1
```

### Path Export
```gdscript
# Get the path for other uses
var path = carver.get_path()
for point in path:
    # Place lights, enemies, collectibles, etc.
    place_object_at(point)
```

### Collision
```gdscript
# CSG automatically has collision!
# No extra work needed
var body = StaticBody3D.new()
body.add_child(carver)
# Now it's a solid with collisions
```

---

## 📚 Code Reference

### random_walk_carver.gd
```gdscript
# Simple, focused on random walk
walk_steps: int           # Number of steps
step_size: float          # Step distance
sphere_radius: float      # Carve sphere size
cube_size: Vector3        # Base cube size
avoid_self_crossing: bool # Prevent crossing
random_seed: int          # For reproducibility

generate_carved_cube()    # Main function
regenerate(seed)          # Regenerate with new seed
get_path()                # Returns path points
```

### advanced_carver.gd
```gdscript
# Multiple patterns, more options
pattern: CarvePattern     # Which pattern to use
base_shape_type: String   # cube, sphere, cylinder
radius_variation: float   # Randomize sphere sizes

# Pattern-specific
spiral_turns: float
branch_probability: float
perlin_scale: float

generate()                # Main function
regenerate(seed)          # New generation
```

---

## 🎬 Complete Workflow

```
1. Choose pattern (Random Walk, Spiral, Branches, etc.)
   ↓
2. Adjust parameters (steps, radius, size)
   ↓
3. Set random seed (for reproducibility)
   ↓
4. Run generate()
   ↓
5. CSG system carves holes automatically
   ↓
6. Result: Organic carved shape with tunnels!
```

---

## ✨ Tips for Best Results

1. **Start small**: Test with 20-30 steps first
2. **Match sphere overlap**: `step_size ≈ sphere_radius * 1.5`
3. **Use seeds**: Same seed = same result (great for level design)
4. **Combine patterns**: Run multiple carvers on one base
5. **Experiment**: Try extreme values to discover new effects!

---

## 🏆 Example Configurations

### Classic Cave
```gdscript
pattern = RANDOM_WALK
walk_steps = 60
sphere_radius = 0.5
avoid_self_crossing = true
```

### DNA Helix
```gdscript
pattern = SPIRAL
spiral_turns = 8.0
sphere_radius = 0.3
base_shape_type = "cylinder"
```

### Tree Roots
```gdscript
pattern = BRANCHES
max_branches = 10
branch_probability = 0.2
sphere_radius = 0.25
```

### Smooth Flow
```gdscript
pattern = PERLIN_PATH
perlin_scale = 0.2
perlin_strength = 1.5
sphere_radius = 0.4
```

---

Made with 🔮 for procedural CSG carving!

