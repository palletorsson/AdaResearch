# mobius_strip.py — Mobius strip
# Source gist: https://gist.github.com/palletorsson/eaea436b228796854644e22b80d98137
# Doc section: A Mobius strip
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import sin, cos, pi

# Function to create a Möbius strip
def create_mobius_strip(width, twists, segments):
    # Create a new mesh and object
    mesh = bpy.data.meshes.new("MobiusMesh")
    obj = bpy.data.objects.new("MobiusStrip", mesh)

    # Link the object to the scene and make it active
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    # Create a bmesh instance to manipulate the mesh
    bm = bmesh.new()

    # Loop to create vertices
    for i in range(segments + 1):
        theta = (i / segments) * (2 * pi)
        for j in range(-width, width + 1):
            x = cos(theta) * (1 + (j / width) * sin(twists * theta / 2))
            y = sin(theta) * (1 + (j / width) * sin(twists * theta / 2))
            z = (j / width) * cos(twists * theta / 2)
            bm.verts.new((x, y, z))

    # Ensure all vertices are created before making faces
    bm.verts.ensure_lookup_table()

    # Loop to create faces, ensuring proper wrapping at the ends
    for i in range(segments):
        for j in range(2 * width):
            v1 = bm.verts[i * (2 * width + 1) + j]
            v2 = bm.verts[i * (2 * width + 1) + j + 1]
            v3 = bm.verts[(i + 1) * (2 * width + 1) + j + 1]
            v4 = bm.verts[(i + 1) * (2 * width + 1) + j]

            bm.faces.new((v1, v2, v3, v4))
    # Loop to create faces
    for i in range(segments):
        for j in range(2 * width):
            v1 = bm.verts[i * (2 * width + 1) + j]
            v2 = bm.verts[i * (2 * width + 1) + j + 1]
            v3 = bm.verts[(i + 1) * (2 * width + 1) + j + 1]
            v4 = bm.verts[(i + 1) * (2 * width + 1) + j]

          

    # Update the bmesh to the mesh
    bm.to_mesh(mesh)
    bm.free()

# Parameters for the Möbius strip
width = 10        # Number of vertices from center to edge
twists = 1        # Number of half-twists in the strip
segments = 48     # Number of segments along the strip

# Create the Möbius strip
create_mobius_strip(width, twists, segments)
