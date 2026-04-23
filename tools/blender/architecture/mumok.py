# mumok.py — Random panel wall in Blender (MUMOK-inspired)
# Source gist: https://gist.github.com/palletorsson/d878a255fdb250bb1405226bf512da91
#
# Tiles a wall row-by-row with cuboid panels of random width and per-row
# random height, leaving a small gap between each. Looks like the offset,
# irregular stone cladding of the MUMOK facade in Vienna.
import bpy
import random

# Parameters
num_rows = 8
num_columns = 12       # Approximate number of panels per row
min_width = 0.5
max_width = 1.5
min_height = 0.5
max_height = 1.2
depth = 0.05
gap = 0.05
wall_height = 6.0


def create_panel(width, height, depth, location):
    """Create a rectangular panel with given dimensions at a location."""
    bpy.ops.mesh.primitive_cube_add(size=1, enter_editmode=False, align='WORLD', location=location)
    panel = bpy.context.object
    panel.scale = (width / 2, depth / 2, height / 2)
    return panel


def create_wall():
    """Generate the wall with rows and panels of varying sizes."""
    current_height = 0
    for row in range(num_rows):
        current_width = 0
        row_height = random.uniform(min_height, max_height)
        if current_height + row_height > wall_height:
            break
        while current_width < num_columns * max_width:
            panel_width = random.uniform(min_width, max_width)
            x = current_width + panel_width / 2
            z = current_height + row_height / 2
            create_panel(panel_width * 2, row_height * 2, depth, (x, 0, z))
            current_width += panel_width + gap
        current_height += row_height + gap


# Clear existing mesh objects
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.select_by_type(type='MESH')
bpy.ops.object.delete()

create_wall()
