# elevator_tower.py — Random-twist elevator shaft for Blender
# Source gist: https://gist.github.com/palletorsson/98f1fba2622129c2393c1d2c6b02a31f
#
# Builds a square-plan shaft by stacking four corner columns whose layer
# heights drift a little more with each floor — small at the base, wobbly
# at the top. Spheres mark each joint, cylinders connect them vertically
# and horizontally, and the outer face gets triangulated.
import bpy
import random
from mathutils import Vector

# Clear existing mesh objects
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.select_by_type(type='MESH')
bpy.ops.object.delete()

# Parameters
num_layers = 10        # Number of layers along Z for each corner
shaft_height = 10.0    # Total height of the elevator shaft (used as reference for randomness)
base_size = 4.0        # Size of the base square
sphere_radius = 0.2
cylinder_radius = 0.05

# Define base corners
corners = [
    Vector((base_size / 2,  base_size / 2, 0)),
    Vector((base_size / 2, -base_size / 2, 0)),
    Vector((-base_size / 2, -base_size / 2, 0)),
    Vector((-base_size / 2,  base_size / 2, 0)),
]

# Generate points for each corner along Z-axis, with increasing randomness
points = []
for index, corner in enumerate(corners):
    corner_points = [Vector((corner.x, corner.y, 0))]
    current_z = 0
    for layer in range(1, num_layers):
        # Randomness grows with each layer (wobble increases upward)
        randomness_factor = random.uniform(-base_size / 4, base_size / 4) * layer / 10
        current_z += base_size + randomness_factor
        point = Vector((corner.x, corner.y, current_z))
        corner_points.append(point)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=sphere_radius, location=point)
    points.append(corner_points)


def create_cylinder_between_points(p1, p2, radius):
    mid_point = (p1 + p2) / 2
    direction = p2 - p1
    distance = direction.length
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=distance, location=mid_point)
    cylinder = bpy.context.object
    cylinder.rotation_mode = 'QUATERNION'
    cylinder.rotation_quaternion = direction.to_track_quat('Z', 'Y')


# Connect vertically at each corner, and horizontally between adjacent corners at each layer
for i in range(len(corners)):
    for j in range(num_layers - 1):
        create_cylinder_between_points(points[i][j], points[i][j + 1], cylinder_radius)
        next_corner = (i + 1) % len(corners)
        create_cylinder_between_points(points[i][j], points[next_corner][j], cylinder_radius)


def create_triangle(p1, p2, p3):
    mesh_data = bpy.data.meshes.new("triangle_mesh")
    mesh_obj = bpy.data.objects.new("Triangle", mesh_data)
    bpy.context.collection.objects.link(mesh_obj)
    verts = [p1, p2, p3]
    faces = [(0, 1, 2)]
    mesh_data.from_pydata(verts, [], faces)
    mesh_data.update()


# Triangulate the outside faces of the shaft
for j in range(num_layers - 1):
    for i in range(len(corners)):
        next_corner = (i + 1) % len(corners)
        create_triangle(points[i][j], points[next_corner][j], points[i][j + 1])
        create_triangle(points[next_corner][j], points[next_corner][j + 1], points[i][j + 1])
