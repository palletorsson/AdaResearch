# klein_bottle.py — Klein bottle parametric surface
# Source gist: https://gist.github.com/palletorsson/e18b8ea968f90ac6a6a0d9887ebca646
# Doc section: Klein Bottle
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import cos, sin, pi

def klein_bottle(u, v, num_u, num_v):
    half = u < pi
    r = 4 * (1 - cos(u) / 2)
    if half:
        x = 6 * cos(u) * (1 + sin(u)) + r * cos(u) * cos(v)
        y = 16 * sin(u) + r * sin(u) * cos(v)
    else:
        x = 6 * cos(u) * (1 + sin(u)) + r * cos(v + pi)
        y = 16 * sin(u)
    z = r * sin(v)
    return x, y, z

# Generate vertices
verts = []
num_u = 40
num_v = 40
for i in range(num_u):
    u = 2 * pi * (i / (num_u - 1))
    for j in range(num_v):
        v = 2 * pi * (j / (num_v - 1))
        verts.append(klein_bottle(u, v, num_u, num_v))

# Generate faces
faces = []
for i in range(num_u - 1):
    for j in range(num_v - 1):
        a = i * num_v + j
        b = ((i + 1) % num_u) * num_v + j
        c = ((i + 1) % num_u) * num_v + (j + 1)
        d = i * num_v + (j + 1)
        faces.append([a, b, c, d])

# Create mesh and object
mesh = bpy.data.meshes.new('KleinBottle')
obj = bpy.data.objects.new('KleinBottle', mesh)
bpy.context.collection.objects.link(obj)

# Create mesh from given verts, faces.
mesh.from_pydata(verts, [], faces)

# Update mesh with new data
mesh.update()
