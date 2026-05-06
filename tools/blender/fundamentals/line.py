# line.py — Single line of primitives
# Source gist: https://gist.github.com/palletorsson/2f2b095f5fb32c9f1ea3ad27f0d8efe3
# Doc section: One line
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random
import bmesh
# Define the number of points and the maximum Z value
quantity = 10
max_z = 10

# Create a new mesh and object
mesh = bpy.data.meshes.new("RandomLineMesh")
obj = bpy.data.objects.new("RandomLine", mesh)

# Link the object to the scene
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Use bmesh to add vertices and edges
bm = bmesh.new()
vertices = [bm.verts.new((x * 10, 0, random.random() * max_z)) for x in range(quantity)]

# Ensure lookup table is generated so we can index vertices
bm.verts.ensure_lookup_table()

# Add edges between consecutive vertices
for i in range(len(vertices) - 1):
    bm.edges.new((vertices[i], vertices[i + 1]))

# Update the bmesh to the mesh data
bm.to_mesh(mesh)
bm.free()

# Optionally convert the mesh to a curve for smoother connections
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.object.convert(target='CURVE')

# Set the curve to be 3D and polyline type for sharp edges
curve = obj.data
curve.dimensions = '3D'
for spline in curve.splines:
    spline.type = 'POLY'
