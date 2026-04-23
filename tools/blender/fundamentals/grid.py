# grid.py — Zigzag patterns with object duplicates in a grid
# Source gist: https://gist.github.com/palletorsson/863441b938875780c1257105b2404582
# Doc section: Blender basics
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Grid dimensions
rows, cols = 10, 10  # Adjust the size of the grid as needed
spacing = 2.0  # Space between objects

# Check if 'Zero' and 'One' objects exist
if 'Zero' in bpy.data.objects and 'One' in bpy.data.objects:
    zero_obj = bpy.data.objects['Zero']
    one_obj = bpy.data.objects['One']

    duplicates = []  # List to keep track of all duplicates

    # Iterate over each row and column in the grid
    for row in range(rows):
        # Determine the starting object for the current row (zigzag effect)
        start_with_one = row % 2 == 0

        for col in range(cols):
            # Alternate between 'Zero' and 'One' based on the column, starting with the determined object for the row
            if (col % 2 == 0 and start_with_one) or (col % 2 != 0 and not start_with_one):
                choice_obj = one_obj
            else:
                choice_obj = zero_obj

            # Create a duplicate of the chosen object
            obj_duplicate = bpy.data.objects.new(name=f"{choice_obj.name}_dup_{row}_{col}", object_data=choice_obj.data.copy())
            bpy.context.collection.objects.link(obj_duplicate)

            # Set the location for each object to create the zigzag pattern
            obj_duplicate.location.x = 0
            obj_duplicate.location.y = col * spacing  # Adjust if you want to spread in Y
            obj_duplicate.location.z = row * spacing  # Create the pattern along Z

            # Add the duplicate to the list of objects to be joined
            duplicates.append(obj_duplicate)

    # Select and join the duplicated objects
    bpy.ops.object.select_all(action='DESELECT')  # Deselect all objects
    for obj in duplicates:
        obj.select_set(True)  # Select each duplicated object
    if duplicates:
        bpy.context.view_layer.objects.active = duplicates[0]  # Set active object to join to
        bpy.ops.object.join()  # Join the selected objects

else:
    print("Error: Objects named 'Zero' and 'One' not found.")
