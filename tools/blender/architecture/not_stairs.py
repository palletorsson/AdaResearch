# not_stairs.py — Irregular stair-like structure
# Source gist: https://gist.github.com/palletorsson/b9823b4088b2ddf6104d5f26fdb0ddec
# Doc section: Not stairs
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import  bmesh
import random 
# The function to perform a series of extrusions on a selected face
def extrude_face(obj, extrude_dist, lift_dist, num_extrudes, direction='NORMAL'):
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_mode(type='FACE')
    for x in range(10):
        for i in range(10):
            bpy.ops.mesh.extrude_region_move(TRANSFORM_OT_translate={"value": (random.random()*3, random.random()*3, random.random()*3), "orient_type": direction})
        for i in range(10):
            bpy.ops.mesh.extrude_region_move(TRANSFORM_OT_translate={"value": (-random.random()*3, -random.random()*3, random.random()*3), "orient_type": direction})

    bpy.ops.object.mode_set(mode='OBJECT')

# Create a cube to start with
bpy.ops.mesh.primitive_cube_add(size=2)
cube = bpy.context.active_object

# Make sure the cube is the active object
bpy.context.view_layer.objects.active = cube
bpy.ops.object.mode_set(mode='EDIT')

# Select the face to start with
bpy.ops.mesh.select_all(action='DESELECT')
bpy.context.tool_settings.mesh_select_mode = (False, False, True)
bpy.ops.object.mode_set(mode='OBJECT')  # switch to object mode to use bmesh

# Get the mesh data
mesh = cube.data
bm = bmesh.new()
bm.from_mesh(mesh)

# Select the top face based on its normal (assumed to be the one facing up)
for face in bm.faces:
    if face.normal.z > 0.9:  # Adjust this value as needed for your specific case
        face.select = True
        break

# Update the mesh with the new selection
bm.to_mesh(mesh)
mesh.update()
bpy.ops.object.mode_set(mode='EDIT')  # switch back to edit mode

# Perform the extrusions
extrude_face(cube, 2, 1, 2)

# Now select the next face to the right and repeat
# You will need to identify the correct face based on your mesh structure
# and repeat the selection and extrusion process.
# This step is a placeholder for the logic you need to implement.
# ... (select the next face and perform extrusions)

# Clean up bmesh
bm.free()

# Switch back to object mode
bpy.ops.object.mode_set(mode='OBJECT')
