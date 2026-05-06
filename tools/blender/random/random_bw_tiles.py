# random_bw_tiles.py — Random black-and-white tile pattern
# Source gist: https://gist.github.com/palletorsson/a9f546145b992440bc29418752204078
# Doc section: Random tiles
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

# Parameters
wall_width = 48  # Number of tiles in the width
wall_height = 16  # Number of tiles in the height
tile_size = 1  # Assuming each cube is 1 Blender Unit in size

# Ensure the starting point is centered
start_x = -wall_width * tile_size * 0.5
start_y = -wall_height * tile_size * 0.5

# Function to place a tile
def place_tile(x, y, tile_name):
    # Ensure the source object is deselected
    bpy.ops.object.select_all(action='DESELECT')
    
    # Select and duplicate the source object
    source_obj = bpy.data.objects[tile_name]
    source_obj.select_set(True)
    bpy.context.view_layer.objects.active = source_obj
    bpy.ops.object.duplicate(linked=False)
    
    # Get the new duplicated object
    new_tile = bpy.context.active_object
    
    # Move the new object to the desired location
    new_tile.location.x = x
    new_tile.location.y = y
    new_tile.location.z = 0

# Deselect all to start clean
bpy.ops.object.select_all(action='DESELECT')

# Create the wall
for i in range(wall_height):
    for j in range(wall_width):
        # Calculate the position for the current tile
        x = start_x + j * tile_size + tile_size / 2  # Centering each cube
        y = start_y + i * tile_size + tile_size / 2  # Centering each cube

        # Randomly choose between the black and white cube
        tile_name = "BlackCube" if random.random() < 0.5 else "WhiteCube"

        # Place the tile
        place_tile(x, y, tile_name)
