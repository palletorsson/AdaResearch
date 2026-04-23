# portal.py — Portal effect
# Source gist: https://gist.github.com/palletorsson/882b69cb32147d6bd6e0e7c774757ab7
# Doc section: Create a Portal
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import math
import random

print(random.randint(3, 9))
# Function to create a torus
def create_portal():
    # Add a torus
    bpy.ops.mesh.primitive_torus_add(align='WORLD', location=(0, 0, 0), rotation=(0, 0, 0), major_radius=1, minor_radius=0.25, abso_major_rad=1.25, abso_minor_rad=0.75)


    # Reference the torus object
    torus = bpy.context.object

    # Enter edit mode
    bpy.ops.object.mode_set(mode='EDIT')

    # Deselect all vertices
    bpy.ops.mesh.select_all(action='DESELECT')

    # Switch to vertex selection
    bpy.ops.mesh.select_mode(type="VERT")

    # Manipulate vertices to create a 'strange' shape
    bpy.ops.object.mode_set(mode='OBJECT')
    for vertex in torus.data.vertices:
        # Apply some transformation to each vertex
        # For example, using a sine wave to adjust the vertex position
        vertex.co.z += math.sin(vertex.co.x) * random.random()

    # Return to object mode
    bpy.ops.object.mode_set(mode='OBJECT')

# Run the function
create_portal()