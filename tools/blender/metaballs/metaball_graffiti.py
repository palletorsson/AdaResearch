# metaball_graffiti.py — Metaball graffiti
# Source gist: https://gist.github.com/palletorsson/ec08b1b96da179e279dee0413e3f5e98
# Doc section: Metaball graffiti
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import math
import random
# Function to add a metaball to the scene
def add_metaball(mb, x, y, z, radius):
    element = mb.elements.new(type='BALL')
    element.co = (x, y, z)
    element.radius = radius
    return element

# Clear existing metaballs
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.select_by_type(type='META')
bpy.ops.object.delete()

# Create new metaball object
mb = bpy.data.metaballs.new('MetaBall')
obj = bpy.data.objects.new('MetaBallObject', mb)
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj

# Grid size
grid_size_x = 100
grid_size_y = 10

# Spacing between metaballs
spacing = 0.3

# Metaball size
mball_size = 0.1

# Create metaballs in a vertical plane
for i in range(grid_size_x):
    for j in range(grid_size_y):
        x = i * spacing
        y = 0  # All metaballs will have the same Y coordinate (vertical plane)
        z = j * spacing
        add_metaball(mb, x, y, z, random.random()*0.6)

# Update metaball resolution
mb.resolution = 0.1
mb.render_resolution = 0.1

# Update the scene
bpy.context.view_layer.update()
