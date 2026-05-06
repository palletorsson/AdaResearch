# double_torus.py — Double torus
# Source gist: https://gist.github.com/palletorsson/db831449abdc2417685a7ca49430917a
# Doc section: Double torus
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import sin, cos, pi

# Function to create a torus mesh
def create_torus(name, major_radius, minor_radius):
    bpy.ops.mesh.primitive_torus_add(
        location=(0, 0, 0), 
        major_radius=major_radius, 
        minor_radius=minor_radius
    )
    obj = bpy.context.object
    obj.name = name
    return obj

# Function to create a double torus
def create_double_torus():
    # Create first torus
    torus1 = create_torus('Torus1', 1, 0.3)
    
    # Create second torus
    torus2 = create_torus('Torus2', 1, 0.3)
    
    # Rotate and move the second torus to interlock with the first
    torus2.rotation_euler[2] = pi / 2
    torus2.location.x = 1
    
    # Merge the two tori into one mesh
    bpy.ops.object.select_all(action='DESELECT')
    torus1.select_set(True)
    torus2.select_set(True)
    bpy.context.view_layer.objects.active = torus1
    bpy.ops.object.join()  # Join into a single object
    
    # Apply transformation to make it a single mesh
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)



# Create the double torus
create_double_torus()
