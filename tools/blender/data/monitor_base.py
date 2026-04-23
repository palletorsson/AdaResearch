# monitor_base.py — Monitor base
# Source gist: https://gist.github.com/palletorsson/c7afc1a85d8498066a23f51f2bc1e396
# Doc section: Monitor base
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Create monitor frame
bpy.ops.mesh.primitive_cube_add(size=2, location=(0, 0, 0))
monitor_frame = bpy.context.object
monitor_frame.scale = (1.0, 0.1, 0.8)
monitor_frame.name = 'Monitor Frame'

# Create screen
bpy.ops.mesh.primitive_plane_add(size=1.6, location=(0, -1.01, 0))
screen = bpy.context.object

# Rotate the screen to face forward (if necessary)
screen.rotation_euler[0] = 1.5708  # Rotate 90 degrees on the X axis

#screen.scale = (1.0, 1.0, 0)  # Adjust scale after rotation
screen.name = 'Screen'

# Parent screen to monitor frame
screen.parent = monitor_frame


# Create a new material
screen_mat = bpy.data.materials.new(name="Screen Material")
screen_mat.use_nodes = True
nodes = screen_mat.node_tree.nodes

# Clear default nodes
for node in nodes:
    nodes.remove(node)

# Create an Emission node (to make the screen glow) and an Output node
emission_node = nodes.new(type='ShaderNodeEmission')
output_node = nodes.new(type='ShaderNodeOutputMaterial')

# Link Emission to Output
links = screen_mat.node_tree.links
link = links.new(emission_node.outputs[0], output_node.inputs[0])

# Set the color and strength of the Emission node (you can adjust these values)
emission_node.inputs['Color'].default_value = (0, 1, 0, 1)  # Green color
emission_node.inputs['Strength'].default_value = 5

# Assign material to screen
screen.data.materials.append(screen_mat)
