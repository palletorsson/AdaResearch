# random_circle.py — Random circle composition
# Source gist: https://gist.github.com/palletorsson/193c4c0b6515dbbe3201ebe5ddd59d2c
# Doc section: Use Random
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import sin, cos, pi
import random
# Define the number of points in the shape
num_points = 100

# Define the Fourier series as a circle for simplicity (radius = 1)
def fourier_series_circle(t, num_terms=1):
    # Since it's a circle, we only need the first term of the series
    return cos(t), sin(t)

# Create a mesh and object
mesh = bpy.data.meshes.new(name='FourierSeries')
obj = bpy.data.objects.new(name='FourierSeries', object_data=mesh)
bpy.context.collection.objects.link(obj)

# Create a bmesh to construct the geometry
bm = bmesh.new()


# Calculate the points in the Fourier series and add them to the bmesh
prev_vert = None
for i in range(num_points + 1):
    t = (i / num_points) * 2 * pi
    x, y = fourier_series_circle(t)
    vert = bm.verts.new((x, y, random.random()))
    # Update the index tables after adding vertices
    bm.verts.ensure_lookup_table()
    if prev_vert:
        bm.edges.new((prev_vert, vert))
    prev_vert = vert

# Update the index tables before closing the loop
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()

# Close the loop
first_vert = bm.verts[0]
bm.edges.new((prev_vert, first_vert))

# Write the bmesh back to the mesh
bm.to_mesh(mesh)
bm.free()
