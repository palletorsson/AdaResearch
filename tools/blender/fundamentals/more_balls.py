# more_balls.py — Many balls in a composition
# Source gist: https://gist.github.com/palletorsson/55bd1129e048e30bfadc63790473216e
# Doc section: Extra more balls
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

def create_balloon_row(location, size, num_balloons_row):
    balloons = []
    # Create a row of three balloons side by side
    for j in range(num_balloons_row):
        # Horizontal offset for each balloon in the row
        offset_x = (j - num_balloons_row // 2) * size * 2  # Center the row around the original location
        new_location = (location[0] + offset_x, location[1], location[2])
        
        bpy.ops.mesh.primitive_uv_sphere_add(radius=size, location=new_location)
        
        # Store the new balloon
        balloon = bpy.context.active_object
        balloons.append(balloon)
        
    return balloons

def create_balloon_stack(base_location, num_levels, num_balloons_row, size_variation):
    # Create a vertical stack of balloon rows
    balloons = []
    location = base_location
    for i in range(num_levels):
        # Determine the size of the balloons
        size = (i + 1) * 0.1  # Increment the size at each level
        
        # Create a row of balloons at this level
        row_balloons = create_balloon_row(location, size, num_balloons_row)
        balloons.extend(row_balloons)
        
        # Update the location for the next level
        location = (location[0], location[1], location[2] + size * 2)
        
    return balloons

# Base location for the bottom row of balloons
base_location = (0, 0, 0)

# Number of levels in the stack
num_levels = 10

# Number of balloons in each row
num_balloons_row = 3
size_variation = 1
# Create the balloon stack
create_balloon_stack(base_location, num_levels, num_balloons_row, size_variation)

# Deselect all to clear the selection
bpy.ops.object.select_all(action='DESELECT')


def create_balloon_triangle(base_location, num_levels, size_variation):
    # Create a vertical triangle of balloons
    balloons = []
    location = base_location
    for i in range(num_levels):
        # Determine the size of the balloon
        size = (num_levels - i) * 0.1  # Decrease the size as we go up
        
        # Calculate the starting x position for this level
        start_x = base_location[0] - i * size
        
        for j in range(i + 1):  # Number of balloons on this level
            # Horizontal offset for each balloon in the row
            offset_x = j * size * 2  # Spacing between balloons
            new_location = (start_x + offset_x, base_location[1], location[2])
            
            bpy.ops.mesh.primitive_uv_sphere_add(radius=size, location=new_location)
            
            # Store the new balloon
            balloon = bpy.context.active_object
            balloons.append(balloon)
        
        # Update the location for the next level
        location = (base_location[0], base_location[1], location[2] + size * 2)
        
    return balloons

# Base location for the bottom balloon
base_location = (0, 0, 0)

# Number of levels in the stack (also the number of balloons on the base level)
num_levels = 10

# Allowed variation in size (currently unused, but you can include it in size calculation if needed)
size_variation = 0.2

# Create the balloon stack in a vertical triangle
create_balloon_triangle(base_location, num_levels, size_variation)

# Deselect all to clear the selection
bpy.ops.object.select_all(action='DESELECT')
