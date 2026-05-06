# ten_print.py — 3D 10 PRINT maze algorithm
# Source gist: https://gist.github.com/palletorsson/b948fdf5dd3b1c98e26580c7352d0b1f
# Doc section: Joy Divisions
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

# Function to deselect all objects
def deselect_all():
    bpy.ops.object.select_all(action='DESELECT')

# Grid size
rows, cols = 10, 10
spacing = 1

# Verify 'Zero' and 'One' objects exist
if 'Zero' in bpy.data.objects and 'One' in bpy.data.objects:
    zero = bpy.data.objects['Zero']
    one = bpy.data.objects['One']

    created_objects = []  # List to keep track of the created objects

    for row in range(rows):
        for col in range(cols):
            # Randomly choose 'Zero' or 'One'
            choice = random.choice([zero, one])

            # Create a new instance
            obj = bpy.data.objects.new(f"{choice.name}_instance_{row}_{col}", choice.data)
            bpy.context.collection.objects.link(obj)

            # Position the instance on the XZ plane
            obj.location = (0, row * spacing, col * spacing)
            # Optionally, rotate
            #obj.rotation_euler = (0, 0, random.choice([0, 3.14159]))

            created_objects.append(obj)

    # Selecting all created objects
    for obj in created_objects:
        obj.select_set(True)

    # Make sure the context is correct
    bpy.context.view_layer.objects.active = created_objects[0]

    # Join all selected objects into one
    bpy.ops.object.join()

else:
    print("Error: Objects named 'Zero' and 'One' not found.")
