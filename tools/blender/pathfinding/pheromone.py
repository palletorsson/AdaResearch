# pheromone.py — Ant pheromone trails
# Source gist: https://gist.github.com/palletorsson/9ffd087e58c90793ca3f54da8e87148c
# Doc section: Pheromone trails
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random
import bmesh
import numpy as np

grid_size = 100
grid = [[0] * grid_size for _ in range(grid_size)]
pheromone_value = 0.5
ant_position = (grid_size // 2, grid_size // 2)

def add_pheromone(x, y):
    grid[x][y] += pheromone_value

def get_neighbors(x, y):
    neighbors = []
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        nx, ny = x + dx, y + dy
        if 0 <= nx < grid_size and 0 <= ny < grid_size:
            neighbors.append((nx, ny))
    return neighbors

def move_ant():
    global ant_position
    x, y = ant_position
    neighbors = get_neighbors(x, y)
    next_pos = random.choice(neighbors)
    ant_position = next_pos
    add_pheromone(*next_pos)

for _ in range(10000):
    move_ant()



def create_grid_mesh(pheribe_grid):
    # Convert the list to a NumPy array
    pheribe_grid = np.array(pheribe_grid)

    # Get the dimensions of the grid
    grid_shape = pheribe_grid.shape
    num_rows, num_cols = grid_shape
 

    # Create a new mesh object
    mesh = bpy.data.meshes.new("GridMesh")
    obj = bpy.data.objects.new("GridObject", mesh)

    # Create the vertices
    vertices = []
    for i in range(num_rows):
        for j in range(num_cols):
            x = i
            y = j
            z = pheribe_grid[i, j]  # Set z value from pheribe grid
            vertices.append((x, y, z))

    # Create the faces
    faces = []
    for i in range(num_rows - 1):
        for j in range(num_cols - 1):
            v1 = i * num_cols + j
            v2 = v1 + 1
            v3 = v1 + num_cols
            v4 = v3 + 1
            faces.append((v1, v2, v4, v3))

    # Set the vertices and faces of the mesh
    mesh.from_pydata(vertices, [], faces)
    mesh.update()

    # Link the mesh object to the scene
    scene = bpy.context.scene
    scene.collection.objects.link(obj)

# Example usage
create_grid_mesh(grid)


