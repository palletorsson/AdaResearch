# ripple.py — Ripple pattern
# Source gist: https://gist.github.com/palletorsson/bd27c371c395651b9b9bfb9f380fb544
# Doc section: Ripple
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import sin, pi, sqrt
import random

# Parameters for the grid and ripple pattern
grid_size = 2  # Size of the grid (length of one side)
grid_resolution = 100  # How many squares on each side of the grid
ripple_count = 10  # Number of ripples
ripple_height = 0.6  # Maximum height of the ripples at the center
ripple_frequency = 5  # Frequency of the sine function
ripple_falloff = 0.1  # Falloff factor for the outer waves

# Delete all objects in the scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Create a new mesh object
mesh = bpy.data.meshes.new(name="RippleGrid")
obj = bpy.data.objects.new(name="RippleGridObject", object_data=mesh)

# Link the object to the scene
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Create a bmesh and grid
bm = bmesh.new()

# Create vertices
for x in range(grid_resolution + 1):
    for y in range(grid_resolution + 1):
        bm.verts.new((x * grid_size / grid_resolution - grid_size / 2,
                      y * grid_size / grid_resolution - grid_size / 2,
                      0))  # Z-coordinate will be modified later

# Ensure the bmesh will always be valid
bm.verts.ensure_lookup_table()

# Create faces
for x in range(grid_resolution):
    for y in range(grid_resolution):
        v1 = bm.verts[(y * (grid_resolution + 1)) + x]
        v2 = bm.verts[(y * (grid_resolution + 1)) + (x + 1)]
        v3 = bm.verts[((y + 1) * (grid_resolution + 1)) + (x + 1)]
        v4 = bm.verts[((y + 1) * (grid_resolution + 1)) + x]
        bm.faces.new((v1, v2, v3, v4))

# Apply the ripple pattern
for v in bm.verts:
    # Calculate distance from the center of the grid
    dist = sqrt(v.co.x**2 + v.co.y**2)
    max_dist = sqrt(2) * (grid_size / 2)

    # Apply the sine wave based on the distance
    # Decrease the amplitude of the wave as we move away from the center
    adjusted_ripple_height = ripple_height * (1 - (dist / max_dist)**ripple_falloff)
    z_offset = adjusted_ripple_height * sin(ripple_frequency * pi * dist / grid_size)
    v.co.z += z_offset

# Update the bmesh to the mesh
bm.to_mesh(mesh)
bm.free()

# Recalculate normals and set smooth shading
obj.data.update()
obj.data.calc_normals()
for poly in obj.data.polygons:
    poly.use_smooth = True
