# rhizome.py — Rhizome growth pattern
# Source gist: https://gist.github.com/palletorsson/e0656b60d31729edb69a18005a3ec936
# Doc section: Rhizome
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from mathutils import Vector
from random import uniform, choice

def create_rhizome_segment(start_point, direction, length=1, radius=0.1):
    # Create a cylinder to represent the rhizome segment
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16, radius=radius, depth=length,
        location=start_point + direction * length / 2)
    
    # Align the cylinder with the growth direction
    segment = bpy.context.object
    segment.rotation_mode = 'QUATERNION'
    segment.rotation_quaternion = direction.to_track_quat('Z', 'Y')
    return segment

def grow_rhizome(start_point, direction, recursion_depth, max_depth=5, length=1, variance=0.3):
    if recursion_depth > max_depth:
        return
    
    # Add some variance to the growth direction and length
    new_direction = direction.copy()
    new_direction.x += uniform(-variance, variance)
    new_direction.y += uniform(-variance, variance)
    #new_direction.z += uniform(-variance, variance)
    new_direction.normalize()
    
    new_length = length * uniform(1 - variance, 1 + variance)
    
    # Create a new segment
    segment = create_rhizome_segment(start_point, new_direction, length=new_length)
    
    # Decide randomly whether to branch or to continue growing straight
    if choice([True, False]):
        # Continue growing in the same direction
        new_start_point = start_point + new_direction * new_length
        grow_rhizome(new_start_point, new_direction, recursion_depth + 1, max_depth, length, variance)
    else:
        # Create a branch
        branch_direction = Vector((uniform(-1, 1), uniform(-1, 1), 0)).normalized()
        branch_start_point = start_point + new_direction * new_length * uniform(0.3, 0.7)
        grow_rhizome(branch_start_point, branch_direction, recursion_depth + 1, max_depth, length, variance)

# Initial start point and direction
initial_start = Vector((0, 0, 0))
initial_direction = Vector((1, 0, 0))

# Start growing the rhizome
grow_rhizome(initial_start, initial_direction, 0, max_depth=100, length=1, variance=0.1)
