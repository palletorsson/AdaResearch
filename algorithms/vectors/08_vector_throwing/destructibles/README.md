# Destructibles System

A collection of destructible objects with different destruction mechanics for the Vector Throwing scene.

## Test Overview

### Test 1: Simple Destroy Cube
**File:** `simple_destroy_cube.gd`

- **Type:** StaticBody3D
- **Behavior:** Destroys immediately on hit
- **Visual:** Shrinks and fades out
- **Use Case:** Basic one-hit destruction

**Properties:**
- `cube_size`: Size of the cube (default: 0.3)
- `target_color`: Color of the cube
- `points_value`: Points awarded on destruction

---

### Test 2: Health Cube
**File:** `health_cube.gd`

- **Type:** StaticBody3D
- **Behavior:** Requires multiple hits to destroy
- **Visual:** Changes color as health decreases, shakes on damage
- **Use Case:** Objects that require sustained damage

**Properties:**
- `max_health`: Number of hits required (default: 2)
- `target_color`: Initial color (blue)
- `damaged_color`: Color when damaged (orange)
- `show_health_label`: Display HP counter

**Features:**
- Health display label
- Progressive color change
- Shake animation on damage
- Explosion effect on destruction

---

### Test 4: Destructible Truncated Tetrahedron
**File:** `destructible_truncated_tetrahedron.gd`

- **Type:** Node3D container with RigidBody3D parts
- **Behavior:** Made of individual parts that can be destroyed separately
- **Visual:** Parts fall with physics and fade out
- **Use Case:** Objects that break into constituent pieces

**Properties:**
- `part_size`: Size of each part (default: 0.15)
- `base_color`: Color of parts with variation
- `points_per_part`: Points per part destroyed
- `enable_physics`: Whether parts have physics

**Features:**
- 12 individual destructible parts
- Physics-based destruction
- Color variation per part
- Tracks parts remaining

---

### Test 5: Cantor Recursion Box
**File:** `cantor_recursion_box.gd`

- **Type:** RigidBody3D
- **Behavior:**
  - Level 0: Hit by ball → splits into 4 boxes
  - Level 1: Boxes hit ground → each splits into 4 more
  - Level 2: Final boxes, no more splitting
- **Visual:** Recursive fractal-style splitting based on Cantor set
- **Use Case:** Recursive destruction, mathematical fractals

**Properties:**
- `box_size`: Size of the box
- `recursion_level`: Current recursion depth (0-2)
- `max_recursion`: Maximum recursion allowed
- `split_impulse_strength`: Force applied to split boxes
- `split_on_ball_hit`: Enable splitting on ball collision
- `split_on_ground_hit`: Enable splitting on ground collision

**Features:**
- 2 stages of recursion
- Physics-based splitting
- Cantor set pattern (removes middle third)
- Color variation by recursion level
- Each split creates 4 smaller boxes

**Pattern:**
```
Hit ball → 4 boxes
↓
Each box hits ground → 4 more boxes each = 16 total
```

---

### Test 6: Voronoi Sphere
**File:** `voronoi_sphere.gd`

- **Type:** RigidBody3D
- **Behavior:** Cracks into fragments using Voronoi-style pattern
- **Visual:** Explodes into irregular fragments
- **Use Case:** Realistic shattering effect

**Properties:**
- `sphere_radius`: Radius of the sphere (default: 0.3)
- `sphere_color`: Color of the sphere (purple)
- `fragment_count`: Number of fragments (default: 12)
- `crack_impulse_strength`: Explosion force
- `start_frozen`: Whether to start static

**Features:**
- Voronoi-based fragmentation
- Fragments explode outward from impact
- Random fragment sizes
- Physics on all fragments
- Auto-cleanup after 3 seconds

---

### Test 7: Voronoi Plane
**File:** `voronoi_plane.gd`

- **Type:** StaticBody3D
- **Behavior:** Cracks at the specific impact point with radial pattern
- **Visual:** Crack lines + fragments radiating from impact
- **Use Case:** Glass/ice breaking effects, localized destruction

**Properties:**
- `plane_size`: Size of the plane (default: 2.0 x 2.0)
- `plane_color`: Color of the plane (cyan)
- `fragment_count`: Number of fragments (default: 16)
- `crack_radius`: Radius of cracking effect (default: 0.8)
- `fragment_impulse_strength`: Force on fragments
- `show_crack_effect`: Show visual crack lines

**Features:**
- Impact-point-based cracking
- Radial Voronoi pattern
- Visual crack lines
- Fragments sized by distance from impact
- Stronger impulse for closer fragments
- Auto-cleanup after 4 seconds

---

## Test Scene

**File:** `destructibles_test_scene.tscn`

A comprehensive test scene featuring all destructible types arranged in a grid for easy testing.

### Layout:
- **Row 1:** Simple cubes and health cubes
- **Row 2:** Truncated tetrahedron, Cantor box, Voronoi sphere
- **Row 3:** Voronoi planes

### Features:
- 5 throwable balls with different colors
- Labels identifying each test
- Stats display (throws and destroyed count)
- Instructions panel

---

## Usage

### In VectorThrowing Scene:
```gdscript
var destructible = preload("res://algorithms/vectors/08_vector_throwing/destructibles/simple_destroy_cube.tscn")
var instance = destructible.instantiate()
instance.position = Vector3(0, 1, 3)
add_child(instance)

# Connect signals
instance.target_destroyed.connect(_on_target_destroyed)
```

### Signals:

**Simple Destroy Cube:**
- `target_destroyed(target: Node3D, impact_velocity: Vector3)`

**Health Cube:**
- `target_hit(target: Node3D, impact_velocity: Vector3, health_remaining: int)`
- `target_destroyed(target: Node3D, impact_velocity: Vector3)`

**Destructible Truncated Tetrahedron:**
- `part_destroyed(part: Node3D, impact_velocity: Vector3)`
- `fully_destroyed(target: Node3D)`

**Cantor Recursion Box:**
- `box_split(parent_box: Node3D, children: Array)`

**Voronoi Sphere:**
- `sphere_cracked(sphere: Node3D, impact_point: Vector3, impact_velocity: Vector3)`

**Voronoi Plane:**
- `plane_cracked(plane: Node3D, impact_point: Vector3, impact_velocity: Vector3)`

---

## Implementation Details

### Collision Detection
All destructibles use Area3D for detecting throwable balls:
- `collision_mask = 2` to detect objects on layer 2
- Objects in `"throwable"` group are detected
- Impact velocity is extracted from RigidBody3D balls

### Physics
- Simple/Health cubes: StaticBody3D (no physics)
- Tetrahedron parts: RigidBody3D with physics
- Cantor boxes: RigidBody3D with recursive physics
- Voronoi fragments: RigidBody3D with explosion physics

### Visual Effects
- Tween-based animations
- Material alpha blending for fade-outs
- Emission energy pulses
- Scale animations
- Particle-like fragment behavior

---

## Future Enhancements

Possible additions:
- Sound effects for each destruction type
- Particle systems for debris
- More complex Voronoi algorithms
- Custom fragment shapes
- Damage textures
- Chain reactions
- Environmental destruction

---

## Dependencies

- `res://algorithms/vectors/shared/vector_scene_base.gd` - Base scene class
- `res://algorithms/vectors/08_vector_throwing/throw_ball.tscn` - Throwable ball
- Godot 4.x StandardMaterial3D and RigidBody3D

---

Created: 2025
Last Updated: 2025
