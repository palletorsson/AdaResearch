# gol_portal.py — Game of Life as a portal
# Source gist: https://gist.github.com/palletorsson/e8ef4dbe22947e328122a0a42a475bbb
# Doc section: Game of life Portal
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

# Parameters
grid_size_x = 17
grid_size_y = 17
grid_size_z = 10  # Number of rounds
metaball_scale = 2.0
offSet = 1.5  # Adjust offset for better visualization

# Ensure the metaball object collection is created
if "Metaballs" not in bpy.data.collections:
    mb_collection = bpy.data.collections.new("Metaballs")
    bpy.context.scene.collection.children.link(mb_collection)
else:
    mb_collection = bpy.data.collections["Metaballs"]

# Initialize the grid for the first round
cubeList = [[[None for _ in range(grid_size_y)] for _ in range(grid_size_x)] for _ in range(grid_size_z)]

# Set the initial grid
initial_grid = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
] 

initial_grid = [
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
] 



def create_metaball(x, y, z):
    mb = bpy.data.metaballs.new("MetaElement")
    obj = bpy.data.objects.new("MetaElementObj", mb)
    mb_collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    element = mb.elements.new()
    element.radius = metaball_scale
    obj.location = (x * offSet, y * offSet, z * offSet)
    return obj




def initialize_grid():
    # Only initialize the first layer (z=0)
    for y in range(len(initial_grid)):
        for x in range(len(initial_grid[y])):
            if initial_grid[y][x] == 1:
                cubeList[0][x][y] = create_metaball(x, y, 0)


def create_metaball(x, y, z):
    mb = bpy.data.metaballs.new("MetaElement")
    obj = bpy.data.objects.new("MetaElementObj", mb)
    mb_collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    element = mb.elements.new()
    element.radius = metaball_scale
    obj.location = (x * offSet, y * offSet, z * offSet)
    return obj


def count_neighbors(x, y, z):
    neighbors = 0
    for dz in range(-1, 2):
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                nx, ny, nz = x + dx, y + dy, z + dz
                if 0 <= nx < grid_size_x and 0 <= ny < grid_size_y and 0 <= nz < grid_size_z:
                    if (dx, dy, dz) != (0, 0, 0) and cubeList[nz][nx][ny] is not None:
                        neighbors += 1
    return neighbors

def update_grid(z):
    for y in range(grid_size_y):
        for x in range(grid_size_x):
            neighbors = count_neighbors(x, y, z-1)
            if cubeList[z-1][x][y] is not None:
                # Metaball is alive
                if neighbors < 2 or neighbors > 3:
                    # Metaball dies
                    cubeList[z][x][y] = None
                else:
                    # Metaball stays alive
                    cubeList[z][x][y] = create_metaball(x, y, z)
            else:
                # Metaball is dead
                if neighbors == 4:
                    # Metaball becomes alive
                    cubeList[z][x][y] = create_metaball(x, y, z)
                else:
                    cubeList[z][x][y] = None

# Main simulation loop
initialize_grid()  # Initialize the first layer with random live and dead cells

for z in range(1, grid_size_z):
    update_grid(z)  # Update the grid for each layer