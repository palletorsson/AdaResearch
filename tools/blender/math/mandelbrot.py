# mandelbrot.py — Mandelbrot set visualization
# Source gist: https://gist.github.com/palletorsson/a786a595af0e45419727c60065080e51
# Doc section: Mandelbrot
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from mathutils import Vector

# Mandelbrot set escape time function
def mandelbrot_escape(x, y, max_iter):
    c = complex(x, y)
    z = 0.0j
    for i in range(max_iter):
        z = z*z + c
        if (z.real*z.real + z.imag*z.imag) >= 4:
            return i
    return max_iter

# Parameters
width, height = 100, 100  # Size of the grid
scale = 0.05  # Scale of the grid
max_iter = 20  # Maximum number of iterations

# Create a new mesh and object
mesh = bpy.data.meshes.new("Mandelbrot")
obj = bpy.data.objects.new("Mandelbrot", mesh)

# Add the object into the scene
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Create a bmesh
bm = bmesh.new()

# Generate vertices
for x in range(width):
    for y in range(height):
        real = scale * (x - width / 2)
        imag = scale * (y - height / 2)
        iter = mandelbrot_escape(real, imag, max_iter)
        z = iter / max_iter
        vertex = bm.verts.new((real, imag, z))

# Generate faces
bm.verts.ensure_lookup_table()
for x in range(width - 1):
    for y in range(height - 1):
        v1 = bm.verts[y * width + x]
        v2 = bm.verts[y * width + x + 1]
        v3 = bm.verts[(y + 1) * width + x + 1]
        v4 = bm.verts[(y + 1) * width + x]
        bm.faces.new((v1, v2, v3, v4))

# Update the bmesh to the mesh
bm.to_mesh(mesh)
bm.free()