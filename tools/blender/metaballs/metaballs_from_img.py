# metaballs_from_img.py — Metaballs placed from image data
# Source gist: https://gist.github.com/palletorsson/1c8bfd673e2b357a1d4fc3ed0ecf4df8
# Doc section: Metaballs from img
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import csv
from os.path import join
import random
csv_file_path = '/Users/pato/Documents/Processing/csvpixel/data/'

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

# Path to the CSV file (update with the correct path)
csv_file_path = join(bpy.path.abspath(csv_file_path), "pixels.csv")

# Spacing between metaballs
spacing = 0.5

# Metaball size
mball_size = 0.2

# Read the CSV and create metaballs
with open(csv_file_path, newline='') as csvfile:
    csvreader = csv.reader(csvfile, delimiter=',')
    next(csvreader)  # Skip the header row if there is one
    for i, row in enumerate(csvreader):
        for j, value in enumerate(row):
            if value == '1':
                # Create a metaball for each 'dark' pixel
                x = j * spacing
                y = 0  # Change this if you want to arrange metaballs in 3D space
                z = i * spacing
                add_metaball(mb, x, y, z, 0.5 +(random.random()*0.5))

# Update metaball resolution
mb.resolution = 0.2
mb.render_resolution = 0.2

# Update the scene
bpy.context.view_layer.update()


