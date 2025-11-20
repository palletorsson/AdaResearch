extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Cube[/b][/font_size][/center]
[center][i]Six Faces, First Volume[/i][/center]

If the Triangle enclosed a 2D area and the Quad deceived about planarity, then the Cube is the first geometry that truly occupies space. It has interior. It blocks. It displaces volume.

The Cube is the first form that says: this space is mine. You cannot pass through.

[hr]

[b]Six Planar Faces: The Enclosure Made Solid[/b]

A cube is six square faces arranged perpendicular to each other, creating a closed volume. Where the triangle drew a boundary on a plane, the cube creates a boundary in three dimensions.

[color=yellow][b]Code: The Cube Structure[/b][/color]
[code]
# 8 vertices define the corners
var v0 = Vector3(-0.5, -0.5, -0.5)  # Back bottom left
var v1 = Vector3(0.5, -0.5, -0.5)   # Back bottom right
var v2 = Vector3(0.5, 0.5, -0.5)    # Back top right
var v3 = Vector3(-0.5, 0.5, -0.5)   # Back top left
var v4 = Vector3(-0.5, -0.5, 0.5)   # Front bottom left
var v5 = Vector3(0.5, -0.5, 0.5)    # Front bottom right
var v6 = Vector3(0.5, 0.5, 0.5)     # Front top right
var v7 = Vector3(-0.5, 0.5, 0.5)    # Front top left

# 8 vertices, 12 edges, 6 faces
[/code]

Eight corners. Twelve edges. Six faces. One enclosed volume.

[hr]

[b]Vertices, Edges, Faces: The Anatomy of Volume[/b]

The cube's structure is precise:
- 8 vertices (corner points)
- 12 edges (lines connecting corners)
- 6 faces (square surfaces)

Each face is a quad (two triangles). The entire cube is 12 triangles.

[color=yellow][b]Code: Creating the Cube Mesh[/b][/color]
[code]
# Godot provides BoxMesh as a primitive
var box_mesh = BoxMesh.new()
box_mesh.size = Vector3(1, 1, 1)

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = box_mesh
add_child(mesh_instance)

# Internally: 6 faces x 2 triangles = 12 triangles
# Each face has outward-facing normals
[/code]

The cube is the first primitive complex enough to require careful normal calculation for each face.

[hr]

[b]Volumetric Presence: The Cube Occupies Space[/b]

Unlike the triangle or quad, which are infinitely thin surfaces, the cube has thickness. It has interior volume. It occupies a measurable region of 3D space.

[color=yellow][b]Code: Volume Calculation[/b][/color]
[code]
var width = 1.0
var height = 1.0
var depth = 1.0

var volume = width * height * depth  # 1.0 cubic units

# The cube claims this much space
# Nothing else can occupy it simultaneously
[/code]

Volume is the 3D measure of occupation. The cube displaces space.

[hr]

[b]Collision: The Cube Blocks[/b]

This is where geometry becomes physical. The cube does not just exist - it obstructs. You cannot pass through it. It enforces its boundaries through collision.

[color=yellow][b]Code: Collision Shape[/b][/color]
[code]
var static_body = StaticBody3D.new()
var collision_shape = CollisionShape3D.new()
var box_shape = BoxShape3D.new()

box_shape.size = Vector3(1, 1, 1)
collision_shape.shape = box_shape

static_body.add_child(collision_shape)
add_child(static_body)

# This cube now blocks movement
# Physics bodies will collide with it
[/code]

Collision is the enforcement of the boundary. The triangle said "inside or outside." The cube says "you cannot enter."

[hr]

[b]The Cube as Territorial Unit[/b]

The cube is the atomic unit of voxel space - the 3D pixel. Minecraft worlds are made of cubes. Architectural CAD begins with cubes. The cube is the building block of rectilinear space.

[color=yellow][b]Code: Voxel Grid[/b][/color]
[code]
var voxel_size = 1.0

for x in range(10):
    for y in range(5):
        for z in range(10):
            var position = Vector3(x, y, z) * voxel_size
            # Each position could hold a cube
            # The grid is made of cubic cells
[/code]

Cubes tile 3D space perfectly - no gaps, no overlaps. They are the Cartesian grid made solid.

[hr]

[b]Occlusion: The Cube Hides[/b]

Because the cube is opaque and volumetric, it occludes - it blocks sight as well as movement. What is behind the cube cannot be seen from the front.

[color=yellow][b]Code: Raycasting and Occlusion[/b][/color]
[code]
var space = get_world_3d().direct_space_state
var ray_query = PhysicsRayQueryParameters3D.new()

ray_query.from = Vector3(0, 0, -5)  # Camera position
ray_query.to = Vector3(0, 0, 5)     # Point behind cube

var result = space.intersect_ray(ray_query)

if result:
    # Ray hit the cube
    # Cannot see what is behind it
    print("Occluded by cube at: ", result.position)
[/code]

Occlusion is visual blocking. The cube not only occupies space - it controls visibility.

[hr]

[b]Inside and Outside: The 3D Binary[/b]

The triangle created inside/outside on a plane. The cube creates inside/outside in volume. A point is either within the cube's bounds or beyond them.

[color=yellow][b]Code: Point-in-Cube Test[/b][/color]
[code]
func is_point_inside_cube(point: Vector3, cube_min: Vector3, cube_max: Vector3) -> bool:
    return (point.x >= cube_min.x and point.x <= cube_max.x and
            point.y >= cube_min.y and point.y <= cube_max.y and
            point.z >= cube_min.z and point.z <= cube_max.z)

# True if inside, false if outside
# No third state permitted
[/code]

The cube divides all of 3D space into two categories: interior and exterior.

[hr]

[b]What the Cube Cannot Represent[/b]

The cube is rectilinear - all edges perpendicular, all faces planar and parallel. It cannot represent:

- Curves (spheres, cylinders require different primitives)
- Organic forms (bodies, terrain)
- Rotation without expanding bounding volume
- Non-axis-aligned orientation efficiently

The cube is optimized for Cartesian thinking - X, Y, Z aligned. It is the geometry of architecture, not biology.

[hr]

[b]The Cube as Fundamental Unit[/b]

The cube represents a profound shift: from abstract geometry to physical presence. It is the first primitive that feels like an object - something that takes up room, that must be navigated around, that divides space into accessible and inaccessible regions.

Every 3D game level is constructed from invisible cubes - collision volumes, trigger zones, spatial partitions. The cube is the unit of digital architecture.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Cube is six square faces enclosing volume - the first truly volumetric primitive. It has 8 vertices, 12 edges, 6 faces. It occupies space (volume), blocks movement (collision), and hides what is behind it (occlusion). The cube is the atomic unit of voxel space and rectilinear 3D architecture.

'''
