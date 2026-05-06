# Sphere Splitting Approaches

Different methods for progressively fragmenting spheres into separated geometry.

---

## Approach 1: Planar Cut Sphere
**File:** `planar_cut_sphere.gd`

### Concept:
Splits sphere in half along a plane, then those halves can split in half again.

### How it Works:
1. Start with whole sphere
2. When hit, determine a cutting plane (based on impact direction)
3. Divide vertices into two groups (above/below plane)
4. Create two new half-spheres
5. Each half can be hit and split again

### Parameters:
- `max_split_levels` - How many times to split (3 = 8 pieces max)
- `split_impulse_strength` - Force pushing halves apart

### Progression:
```
Level 0: ● (whole)
Level 1: ◐◑ (2 halves)
Level 2: ◰◱◲◳ (4 quarters)
Level 3: 8 pieces
```

### Best For:
- Realistic cracking along impact direction
- Clean geometric splits
- Controllable fragment count

---

## Approach 2: Octree Subdivision
**File:** `octree_sphere.gd`

### Concept:
Divides sphere into 8 octants (like cutting along X, Y, Z axes), then each octant subdivides into 8 more.

### How it Works:
1. Start with whole sphere
2. When hit, divide into 8 cubic regions (octants)
3. Each octant gets part of sphere within its bounds
4. Each piece can subdivide into 8 more

### Parameters:
- `max_subdivision_levels` - Recursion depth (2 = 64 pieces)
- `explosion_strength` - Force pushing octants apart

### Progression:
```
Level 0: 1 sphere
Level 1: 8 octants
Level 2: 64 pieces (8×8)
Level 3: 512 pieces (8×8×8)
```

### Best For:
- Explosive fragmentation
- Uniform piece distribution
- Quick multiplication of fragments

---

## Approach 3: Sectored Sphere (Orange Wedges)
**File:** `sectored_sphere.gd`

### Concept:
Sphere divided like an orange into wedge sectors that can split into smaller wedges.

### How it Works:
1. Start with sphere divided into wedges (like pie slices)
2. Each wedge is a complete slice from center to surface
3. When wedge is hit, it splits into 2 sub-wedges
4. Or destroys completely if max subdivision reached

### Parameters:
- `initial_sectors` - Starting number of wedges (8 = orange slices)
- `can_subdivide` - Allow wedges to split further
- `explosion_strength` - Radial force

### Progression:
```
Level 0: 8 wedges (🍊)
Level 1: 16 wedges (each splits)
Level 2: 32 wedges
```

### Best For:
- Organic, fruit-like splitting
- Radial fragmentation
- Visual appeal

---

## Approach 4: CSG-Based Cutting (Most Realistic) ✅ IMPLEMENTED
**File:** `csg_cut_sphere.gd`

### Concept:
Use Godot's CSG (Constructive Solid Geometry) to actually cut meshes with boolean operations.

### How it Works:
1. Create cutting plane as CSGBox3D (thin box)
2. Orient plane along impact direction
3. Use CSG intersection to isolate each half
4. Bake the result into real meshes
5. Create RigidBody3D pieces with the baked meshes

### Implementation:
```gdscript
var csg_clip = CSGMesh3D.new()  # Original mesh
var csg_mask = CSGMesh3D.new()  # Cutting plane
csg_mask.operation = CSGShape3D.OPERATION_INTERSECTION

csg_clip.mesh = sphere_mesh
csg_mask.mesh = cutting_plane_box
csg_clip._update_shape()  # Force update

var result = csg_clip.get_meshes()  # Get baked mesh
```

### Parameters:
- `use_impact_plane` - Cut along impact direction
- `cutting_thickness` - Thickness of cutting plane
- `max_split_levels` - Recursion depth

### Pros:
- ✅ True geometric cutting
- ✅ Perfect mesh splits
- ✅ Clean cut surfaces
- ✅ Impact-direction aware
- ✅ Most realistic results

### Cons:
- ⚠️ More computationally expensive
- ⚠️ Requires CSG nodes in scene
- ⚠️ Async operations for performance

---

## Comparison Table

| Approach | Fragment Count | Geometric Accuracy | Performance | Complexity | Status |
|----------|---------------|-------------------|-------------|------------|--------|
| **Planar Cut** | 2^n | Medium | ⭐⭐⭐⭐ | Low | ✅ Implemented |
| **Octree** | 8^n | Low-Medium | ⭐⭐⭐⭐⭐ | Low | ✅ Implemented |
| **Sectored** | Custom | Medium | ⭐⭐⭐⭐ | Medium | ✅ Implemented |
| **CSG** | 2^n | High | ⭐⭐⭐ | High | ✅ Implemented |

---

## Usage Example

```gdscript
# Add to scene
var sphere = preload("res://path/to/planar_cut_sphere.tscn").instantiate()
sphere.position = Vector3(0, 1, 3)
sphere.max_split_levels = 3  # Can split 3 times
add_child(sphere)

# Listen for splits
sphere.piece_split.connect(_on_piece_split)

func _on_piece_split(parent, children):
    print("Split into %d pieces" % children.size())
```

---

## Recommendations

### For Breakable Glass/Ice:
Use **Planar Cut** - Clean splits along impact direction

### For Explosions:
Use **Octree** - Many pieces flying outward uniformly

### For Organic Objects (Fruits):
Use **Sectored** - Natural wedge splitting

### For Maximum Realism:
Use **CSG** - True geometric cuts (implement based on VoronoiGenerator pattern)

---

## Future Enhancements

1. **Hybrid Approach**: Combine methods (start sectored, then planar cut sectors)
2. **Impact-Based**: Fragment size varies by impact force
3. **Crack Propagation**: Cracks spread over time before splitting
4. **Texture Cracking**: Show crack textures before geometry splits
5. **Sound Effects**: Different sounds per split level
6. **Particle Effects**: Debris/dust on split

---

## 🎮 Showcase Scene

**File:** `sphere_splitting_showcase.tscn`

A comprehensive test scene featuring all 4 splitting approaches side-by-side:

### Layout:
```
[Planar Cut] [Octree] [Sectored] [CSG]
     ●           ●         ●        ●
```

### Features:
- 6 throwable balls with different colors
- Real-time piece count display
- Individual stats per sphere (pieces, splits)
- Live demonstration of all approaches
- Comprehensive instructions

### What You'll See:
- **Planar Cut** - Clean halving along impact plane
- **Octree** - Explosive fragmentation into 8 parts
- **Sectored** - Orange-slice wedge separation
- **CSG** - Perfect geometric cuts with boolean operations

### Usage:
Simply throw balls at each sphere and watch the different fragmentation patterns!

---

Created: 2025
For: AdaResearch Vector Throwing Destructibles System
All 4 approaches fully implemented and ready to use!
