# keyframes.py — Simple keyframe animation example
# Source gist: https://gist.github.com/palletorsson/0746c4a56835fe92d87319046e5ae2ff
# Doc section: Simple Keyframe animation example
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Create a ball
bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(0, 0, 1))
ball = bpy.context.object
ball.name = 'BouncingBall'

# Clear any existing animation data
ball.animation_data_clear()

# Keyframe function
def add_keyframe(obj, frame, location):
    obj.location = location
    obj.keyframe_insert(data_path="location", frame=frame)

# Define bounce parameters
start_frame = 1
end_frame = 60
bounce_height = 1
floor_level = 0

# Set up keyframes for bouncing
for frame in range(start_frame, end_frame, 10):
    # Ball on the ground
    add_keyframe(ball, frame, (0, 0, floor_level + 1))
    
    # Ball at the peak of the bounce
    if frame + 5 < end_frame:
        add_keyframe(ball, frame + 5, (0, 0, bounce_height + 1))

# Set interpolation to 'BOUNCE'
for fcurve in ball.animation_data.action.fcurves:
    for kf in fcurve.keyframe_points:
        kf.interpolation = 'BOUNCE'

# Set end frame for the animation
bpy.context.scene.frame_end = end_frame
