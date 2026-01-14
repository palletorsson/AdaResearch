# Point Animatedcube - Technical Tutorial

## Cube Structure: 8 Vertices, 12 Edges, 6 Faces

```gdscript
# Define cube vertices
var vertices = [
    Vector3(-0.5, -0.5, -0.5),  # v0 - back bottom left
    Vector3( 0.5, -0.5, -0.5),  # v1 - back bottom right
    Vector3( 0.5,  0.5, -0.5),  # v2 - back top right
    Vector3(-0.5,  0.5, -0.5),  # v3 - back top left
    Vector3(-0.5, -0.5,  0.5),  # v4 - front bottom left
    Vector3( 0.5, -0.5,  0.5),  # v5 - front bottom right
    Vector3( 0.5,  0.5,  0.5),  # v6 - front top right
    Vector3(-0.5,  0.5,  0.5)   # v7 - front top left
]

# 12 edges connect vertices
var edges = [
    [0,1], [1,2], [2,3], [3,0],  # Back face
    [4,5], [5,6], [6,7], [7,4],  # Front face
    [0,4], [1,5], [2,6], [3,7]   # Connecting edges
]

# 6 faces (each a quad, rendered as 2 triangles)
var faces = [
    [0,1,2,3],  # Back
    [4,5,6,7],  # Front
    [0,4,7,3],  # Left
    [1,5,6,2],  # Right
    [0,1,5,4],  # Bottom
    [3,2,6,7]   # Top
]
```

## Procedural Cube Construction Animation

```gdscript
extends Node3D

enum ConstructionPhase { VERTICES, EDGES, FACES }
var current_phase = ConstructionPhase.VERTICES
var phase_progress = 0.0
var animation_speed = 1.0

func _process(delta):
    phase_progress += delta * animation_speed

    match current_phase:
        ConstructionPhase.VERTICES:
            animate_vertices()
            if phase_progress >= 1.0:
                advance_phase()

        ConstructionPhase.EDGES:
            animate_edges()
            if phase_progress >= 1.0:
                advance_phase()

        ConstructionPhase.FACES:
            animate_faces()
            if phase_progress >= 1.0:
                restart_animation()

func animate_vertices():
    # Show vertices appearing one by one
    var vertices_to_show = int(phase_progress * 8)
    for i in range(vertices_to_show):
        show_vertex(i)

func animate_edges():
    # Draw edges connecting vertices
    var edges_to_show = int(phase_progress * 12)
    for i in range(edges_to_show):
        draw_edge(edges[i])

func animate_faces():
    # Fill in faces between edges
    var faces_to_show = int(phase_progress * 6)
    for i in range(faces_to_show):
        render_face(faces[i])
```

## Volume and Collision

```gdscript
# Calculate cube volume
var size = 1.0
var volume = size * size * size  # 1.0 cubic units

# Create collision shape
var collision_shape = CollisionShape3D.new()
var box_shape = BoxShape3D.new()
box_shape.size = Vector3(size, size, size)
collision_shape.shape = box_shape

# Point-in-volume test
func is_inside_cube(point: Vector3, cube_min: Vector3, cube_max: Vector3) -> bool:
    return (point.x >= cube_min.x and point.x <= cube_max.x and
            point.y >= cube_min.y and point.y <= cube_max.y and
            point.z >= cube_min.z and point.z <= cube_max.z)
```

## Removing Reflections (Unshaded Mode)

```gdscript
# From our earlier fix to animatedcubebuilder.gd
var material = StandardMaterial3D.new()
material.albedo_color = Color(0.3, 0.7, 1.0)
material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No reflections
material.cull_mode = BaseMaterial3D.CULL_BACK
```

This removes environmental reflections, making geometric form visually pure.

## Cube as Voxel Unit

```gdscript
# Voxel grid using cubes
var voxel_size = 1.0
var grid_dimensions = Vector3i(10, 5, 10)

for x in range(grid_dimensions.x):
    for y in range(grid_dimensions.y):
        for z in range(grid_dimensions.z):
            var position = Vector3(x, y, z) * voxel_size
            # Each cell is a potential cube
            if should_create_voxel(x, y, z):
                create_cube_at(position)
```

Cubes tile 3D space perfectly - they're the atomic unit of voxel worlds.

## Key Takeaway

The cube is **8 points + 12 lines + 6 surfaces = 1 volume**. It synthesizes all previous primitives into the first form that **occupies space**, **blocks passage**, and **governs visibility**. The animated construction reveals geometry as **temporal assembly**, not instantaneous appearance.
