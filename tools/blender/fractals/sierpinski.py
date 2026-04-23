# sierpinski.py — Sierpinski pyramid
# Source gist: https://gist.github.com/palletorsson/36efb65dd34435143aa4f24263d986f5
# Doc section: Sierpinski pyramid
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from mathutils import Vector
from math import sqrt

# Function to create a tetrahedron
def create_tetrahedron(base_size, location):
    # Create a base tetrahedron
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=1, depth=sqrt(2), enter_editmode=True)
    bpy.ops.transform.resize(value=(base_size, base_size, base_size))
    bpy.ops.object.mode_set(mode='OBJECT')
    obj = bpy.context.object
    obj.location = location
    return obj

# Recursive function to create Sierpinski Pyramid
def create_sierpinski_pyramid(base_size, location, depth):
    if depth == 0:
        # Base case, create a single tetrahedron
        create_tetrahedron(base_size, location)
    else:
        # Calculate new size for the smaller tetrahedrons
        new_size = base_size / 2
        height = new_size 
        # Offsets for the new tetrahedrons
        offsets = [Vector((0, new_size, 0)),
                   Vector((height, -new_size / 2, 0)),
                   Vector((-height, -new_size / 2, 0)),
                   Vector((0, 0, height * 2))]
        # Create smaller tetrahedrons at the corners of the current tetrahedron
        for offset in offsets:
            new_location = location + offset * (2 / 3)
            create_sierpinski_pyramid(new_size, new_location, depth - 1)

# Delete all existing objects in the scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

# Set the base size and recursion depth
base_size = 2
depth = 5

# Create a new Sierpinski pyramid at the world origin
create_sierpinski_pyramid(base_size, Vector((0, 0, 0)), depth)

# Select all tetrahedrons and join them into a single mesh
bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        obj.select_set(True)
bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
bpy.ops.object.join()
