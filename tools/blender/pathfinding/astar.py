# astar.py — A* pathfinding
# Source gist: https://gist.github.com/palletorsson/317a938c2637a5b42fbf1ec2a2768266
# Doc section: Path finding
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
import random
from mathutils import Vector
from queue import PriorityQueue

# Define the grid size and the number of obstacles
grid_size = 30
obstacle_rate = 0.3


# Create a new mesh and object
mesh = bpy.data.meshes.new("GridMesh")
obj = bpy.data.objects.new("Grid", mesh)

# Link the object to the scene
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Create a bmesh instance to manipulate the mesh
bm = bmesh.new()

# Create vertices for the grid
for y in range(grid_size):
    for x in range(grid_size):
        bm.verts.new((x, y, 0))

bm.verts.ensure_lookup_table()

# Randomly distribute obstacles
obstacles = set()
while len(obstacles) < int(grid_size * grid_size * obstacle_rate):
    obstacle = (random.randint(0, grid_size - 1), random.randint(0, grid_size - 1))
    obstacles.add(obstacle)

for obstacle in obstacles:
    x, y = obstacle
    idx = y * grid_size + x
    bm.verts[idx].co.z = 1  # Raise the Z coordinate to visualize the obstacle
    
# Function to check if a cell is blocked
def is_blocked(x, y):
    return (x, y) in obstacles

# A* Pathfinding algorithm
def heuristic(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])

def astar_search(start, goal):
    frontier = PriorityQueue()
    frontier.put((0, start))
    came_from = {}
    cost_so_far = {}
    came_from[start] = None
    cost_so_far[start] = 0

    while not frontier.empty():
        current = frontier.get()[1]

        if current == goal:
            break

        for dx in [-1, 0, 1]:
            for dy in [-1, 0, 1]:
                if dx == 0 and dy == 0:
                    continue  # Skip the current cell
                next = (current[0] + dx, current[1] + dy)
                if 0 <= next[0] < grid_size and 0 <= next[1] < grid_size and not is_blocked(*next):
                    new_cost = cost_so_far[current] + 1
                    if next not in cost_so_far or new_cost < cost_so_far[next]:
                        cost_so_far[next] = new_cost
                        priority = new_cost + heuristic(goal, next)
                        frontier.put((priority, next))
                        came_from[next] = current
    return came_from, cost_so_far

# Create the path
start, goal = (0, 0), (grid_size - 1, grid_size - 1)
came_from, cost_so_far = astar_search(start, goal)

# Trace the path from the goal to the start
current = goal
path = []
while current != start:
    path.append(current)
    current = came_from.get(current, start)
path.append(start)
path.reverse()

# Update the mesh
bm.to_mesh(mesh)
obj.data.update()

# Create a path object
path_mesh = bpy.data.meshes.new("PathMesh")
path_obj = bpy.data.objects.new("Path", path_mesh)
bpy.context.collection.objects.link(path_obj)

# Create a bmesh for the path
path_bm = bmesh.new()

# Add the path as edges
prev_vert = None
for x, y in path:
    vert = path_bm.verts.new((x, y, 1))
    if prev_vert:
        path_bm.edges.new((prev_vert, vert))
    prev_vert = vert

# Update the path mesh
path_bm.to_mesh(path_mesh)
path_obj.data.update()
