extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]The Cube[/b][/font_size][/center]
[center][i]Six Faces, First Volume[/i][/center]

If the Triangle enclosed area and the Quad negotiated surface, the Cube is the first geometry that occupies volume. It has interior. It displaces space. It blocks passage.

The Cube is the first form that asserts: this space is taken.

[hr]

[b]Six Faces: Enclosure in Three Dimensions[/b]

A cube is six square faces arranged orthogonally, enclosing a finite region of space. Where the triangle drew a boundary on a plane, the cube extends enclosure into depth.

[color=yellow][b]Code: Cube Vertices[/b][/color]
[code]
var v0 = Vector3(-0.5, -0.5, -0.5)
var v1 = Vector3( 0.5, -0.5, -0.5)
var v2 = Vector3( 0.5, 0.5, -0.5)
var v3 = Vector3(-0.5, 0.5, -0.5)
var v4 = Vector3(-0.5, -0.5, 0.5)
var v5 = Vector3( 0.5, -0.5, 0.5)
var v6 = Vector3( 0.5, 0.5, 0.5)
var v7 = Vector3(-0.5, 0.5, 0.5)
[/code]

Eight corners. Twelve edges. Six faces.
One closed interior.

[hr]

[b]From Surface to Solid[/b]

Each face of the cube is a quad, internally rendered as two triangles. The cube as a whole is composed of twelve triangular faces.

[color=yellow][b]Code: Rendering the Cube[/b][/color]
[code]
var box_mesh = BoxMesh.new()
box_mesh.size = Vector3(1, 1, 1)

var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = box_mesh
add_child(mesh_instance)
[/code]

The cube is the first primitive where surface multiplication produces interior.

[hr]

[b]Volume: The Measure of Occupation[/b]

Unlike surfaces, volume excludes.
Only one thing can occupy a given volume at a time.

[color=yellow][b]Code: Volume[/b][/color]
[code]
var volume = 1.0 * 1.0 * 1.0 # cubic units
[/code]

Volume is not just measure — it is claim.

The cube does not merely appear in space.
It displaces what was there.

[hr]

[b]Collision: Enforced Boundaries[/b]

With volume comes obstruction.

[color=yellow][b]Code: Collision Shape[/b][/color]
[code]
var static_body = StaticBody3D.new()
var collision_shape = CollisionShape3D.new()
var box_shape = BoxShape3D.new()

box_shape.size = Vector3(1, 1, 1)
collision_shape.shape = box_shape

static_body.add_child(collision_shape)
add_child(static_body)
[/code]

The cube enforces its boundary.
Movement is stopped.

The triangle distinguished inside and outside.
The cube prevents entry.

[hr]

[b]Occlusion: Control of Visibility[/b]

The cube not only blocks movement — it blocks sight.

[color=yellow][b]Code: Occlusion[/b][/color]
[code]
var space = get_world_3d().direct_space_state
var ray = PhysicsRayQueryParameters3D.new()
ray.from = Vector3(0, 0, -5)
ray.to = Vector3(0, 0, 5)

var result = space.intersect_ray(ray)
[/code]

What lies behind the cube becomes inaccessible to vision.
The cube governs perception as well as motion.

[hr]

[b]Inside and Outside, Revisited[/b]

The triangle created an inside/outside distinction on a surface.
The cube extends this distinction into volume.

[color=yellow][b]Code: Point-in-Volume Test[/b][/color]
[code]
func is_inside(p, min, max):
return (
p.x >= min.x and p.x <= max.x and
p.y >= min.y and p.y <= max.y and
p.z >= min.z and p.z <= max.z
)
[/code]

A position is either inside or outside.
There is no gradient, no ambiguity.

[hr]

[b]The Cube as Spatial Unit[/b]

The cube is the fundamental unit of voxel space.
Entire worlds are built from cubic cells.

[color=yellow][b]Code: Voxel Space[/b][/color]
[code]
for x in range(10):
for y in range(5):
for z in range(10):
var cell = Vector3(x, y, z)
[/code]

Cubes tile three-dimensional space perfectly.
They are the Cartesian grid made solid.

[hr]

[b]What the Cube Cannot Express[/b]

The cube is rigid and rectilinear.

It cannot easily express:
• curvature
• organic form
• gradual transition
• porous boundaries

The cube is the geometry of construction, not growth.

[hr]

[b]The Cube as Architecture[/b]

With the cube, geometry becomes inhabitable and restrictive.
Space is no longer only measured or enclosed — it is regulated.

Walls, rooms, volumes, obstacles.
Navigation becomes necessary.

The cube is the first geometry that feels like an object.

[hr]

[color=cyan][b]Summary:[/b][/color]
The Cube is the first volumetric primitive. Six faces enclose interior space, producing volume, collision, and occlusion. It occupies space, blocks movement, and governs visibility. The cube is the atomic unit of voxel worlds and rectilinear digital architecture.'''
