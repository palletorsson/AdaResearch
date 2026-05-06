# softbody.py — Softbody simulation
# Source gist: https://gist.github.com/palletorsson/dc2b02252a0d93f94dc8792a45b64096
# Doc section: Softbody
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Ensure we're in object mode
bpy.ops.object.mode_set(mode='OBJECT')

# Select an existing object or create a new one
# For this example, let's assume we have a mesh object named 'MySoftBody'
soft_body_object = bpy.data.objects.get('MySoftBody')
if not soft_body_object:
    # Create a new sphere object if it doesn't exist
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(0, 0, 0))
    soft_body_object = bpy.context.object
    soft_body_object.name = 'MySoftBody'

# Enable soft body simulation for the object
soft_body_object.select_set(True)
bpy.context.view_layer.objects.active = soft_body_object
bpy.ops.object.modifier_add(type='SOFT_BODY')

# Access the soft body settings
soft_body_settings = soft_body_object.modifiers['Softbody'].settings

# Adjust some soft body settings
soft_body_settings.friction = 5
soft_body_settings.mass = 0.5
soft_body_settings.spring_length = 0.5

# You can also adjust collision and other specific settings as needed
# For example: soft_body_settings.use_self_collision = True

# Now you can run the simulation by playing the animation in Blender
