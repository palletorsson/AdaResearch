# create_pyramid.py — Pyramid construction
# Source gist: https://gist.github.com/palletorsson/85b96757b5afbe00d1320b78a9fd829c
# Doc section: Create pyramid
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh

# Function to create a pyramid
def create_pyramid(base_width, height):
    # Create a new mesh and object
    mesh = bpy.data.meshes.new("PyramidMesh")
    obj = bpy.data.objects.new("Pyramid", mesh)

    # Link the object to the scene
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    # Create a bmesh instance to manipulate the mesh
    bm = bmesh.new()

    # Define vertices for the base of the pyramid (assuming it's centered at the origin)
    v1 = bm.verts.new((-base_width/2, -base_width/2, 0))
    v2 = bm.verts.new((base_width/2, -base_width/2, 0))
    v3 = bm.verts.new((base_width/2, base_width/2, 0))
    v4 = bm.verts.new((-base_width/2, base_width/2, 0))
    
    # Define vertex for the apex of the pyramid
    v5 = bm.verts.new((0, 0, height))
    
    # Define faces (base and 4 sides)
    base_face = bm.faces.new((v1, v2, v3, v4))
    side_face_1 = bm.faces.new((v1, v2, v5))
    side_face_2 = bm.faces.new((v2, v3, v5))
    side_face_3 = bm.faces.new((v3, v4, v5))
    side_face_4 = bm.faces.new((v4, v1, v5))

    # Update the bmesh to the mesh
    bm.to_mesh(mesh)
    bm.free()

# Parameters for the pyramid
base_width = 2.0  # Width of the pyramid's base
height = 3.0      # Height of the pyramid from the base to the apex

# Create the pyramid
create_pyramid(base_width, height)
