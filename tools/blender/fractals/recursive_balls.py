# recursive_balls.py — Recursive ball subdivision
# Source gist: https://gist.github.com/palletorsson/89a2a28a0e41d985ce662b5fa8a60f0e
# Doc section: Recursive Balls
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

spread = 3
outer_sphere_size = 0.1  # Size of the outermost sphere in each recursion

sphere_list = []

def mirror_sphere(x, y, size, base_z=0):
    if size > 4:
        # Calculate the Z position so smaller spheres are higher up
        z_pos = base_z + (4 - size) * 0.001
        
        point = (x, y, z_pos)
        sphere_list.append([point, size])
        
        # Recursion
        new_size = size * 0.5
        new_base_z = z_pos + size * 0.5  # Raise the next level
        mirror_sphere(x + (size / spread), y, new_size, new_base_z)
        mirror_sphere(x - (size / spread), y, new_size, new_base_z)
        mirror_sphere(x, y + (size / spread), new_size, new_base_z)
        mirror_sphere(x, y - (size / spread), new_size, new_base_z)

def create_sphere(location, radius):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)

# Start the recursive function
mirror_sphere(1, 1, 40)

# Create the spheres in Blender
for s in sphere_list:
    create_sphere(s[0], s[1])
