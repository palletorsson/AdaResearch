# advanced_grid.py — Advanced grid arrangement
# Source gist: https://gist.github.com/palletorsson/e154b03b4c1efd87b027ba7cbd927b18
# Doc section: Switch to spheres
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

# Function to perform inset and translation in edit mode
def inset_and_translate(obj, inset_value, translation_z):
    # Switch to edit mode
    bpy.ops.object.mode_set(mode='EDIT')
    
    # Deselect all faces
    bpy.ops.mesh.select_all(action='DESELECT')
    
    # Switch to face select mode
    bpy.ops.mesh.select_mode(type='FACE')
    
    # Assuming the top face has the maximum Z coordinate, select it
    bpy.context.tool_settings.mesh_select_mode = (False, False, True)
    bpy.ops.object.mode_set(mode='OBJECT')  # Temporarily switch to object mode to use bmesh
    mesh = obj.data
    top_face = max(mesh.polygons, key=lambda p: p.center.z)
    top_face.select = True
    bpy.ops.object.mode_set(mode='EDIT')  # Go back to edit mode
    
    # Perform inset operation twice
    for _ in range(2):
        bpy.ops.mesh.inset(thickness=inset_value)
    
    # Move the face down along the Z axis
    bpy.ops.transform.translate(value=(0, 0, translation_z))
    
    # Go back to object mode
    bpy.ops.object.mode_set(mode='OBJECT')
    
# Create a random color material
def create_random_color_material():
    mat = bpy.data.materials.new(name="RandomColorMat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs['Base Color'].default_value = (random.random(), random.random(), random.random(), 1)
    bsdf.inputs['Metallic'].default_value = 0.3
    bsdf.inputs['Roughness'].default_value = 0.0
    return mat

# Function to animate scale in Z with randomness
def animate_scale_z(obj, start_frame, end_frame):
    # Ensure we're in object mode
    bpy.ops.object.mode_set(mode='OBJECT')

    # Define start and end scales with randomness
    start_scale_z = 1
    end_scale_z = random.uniform(0.5, 4.0)  # Random end scale between 0.5 and 2.0

    # Set the initial scale and insert a keyframe
    obj.scale[2] = start_scale_z
    obj.keyframe_insert(data_path="scale", frame=start_frame, index=2)

    # Set the final scale and insert another keyframe
    obj.scale[2] = end_scale_z
    obj.keyframe_insert(data_path="scale", frame=end_frame, index=2)


# Skapa en grid av kuber med varierande höjder
size = 1  # storleken på varje kub
grid_size = 10  # storleken på griden
inset_value = 0.1 * size  # Inset by 10% of the cube size
translation_z = -0.1 * size  # Translate down by 10% of the cube size
# Animation parameters
start_frame = 1
end_frame = 100
for x in range(grid_size):
    for y in range(grid_size):
        height = random.uniform(-0.2, 4.2) + 3  # slumpmässig höjd
        location = (x * size, y * size, height / 2)  # Adjust location for correct placement
        bpy.ops.mesh.primitive_cube_add(size=size, location=location)
        bpy.ops.transform.resize(value=(1, 1, random.random()*4+5))
        
        # Get the active object (the one just created)
        obj = bpy.context.object
        
        # Perform inset and translation
        inset_and_translate(obj, inset_value, translation_z)
        
        # Create and assign a random color material
        mat = create_random_color_material()
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)
            
        #animate_scale_z(obj, start_frame, end_frame)

# Set the scene to the start frame
bpy.context.scene.frame_set(start_frame)

# Set the end frame for the animation (optional)
bpy.context.scene.frame_end = end_frame