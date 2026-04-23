# minecraft.py — Minecraft-like world from balls
# Source gist: https://gist.github.com/palletorsson/d0dc3c14e0dc615c3668e2a196488fea
# Doc section: Create a Minecraft world
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import mathutils

# Parameters
world_size_x = 20  # Width of the world in blocks
world_size_y = 20  # Length of the world in blocks
block_size = 2  # Size of each block
scale = 0.1  # Scale of the noise

def generate_block(x, y, z, block_size):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=block_size, enter_editmode=False, align='WORLD', location=(x, y, z), scale=(1, 1, 1))

   
    block = bpy.context.object
    return block

def create_minecraft_world(world_size_x, world_size_y, block_size, scale):
    for x in range(world_size_x):
        for y in range(world_size_y):
            # Use Perlin noise for height generation, with a constant third component (e.g., 0.0)
            nx = x * scale
            ny = y * scale
            nz = 0.0  # Constant Z value for 2D Perlin noise
            height = mathutils.noise.noise([nx, ny, nz])
            # Normalize and scale the height
            height = int((height + 1) / 2 * 5)  # Adjust the multiplier for height variation
            
            for z in range(height):
                generate_block(x * block_size, y * block_size, z * block_size, block_size)


create_minecraft_world(world_size_x, world_size_y, block_size, scale)
