# circle_packing.py — 2D circle packing
# Source gist: https://gist.github.com/palletorsson/93d542d8f7a435dd8396f32e4d9a6b40
# Doc section: Circle packing
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from mathutils import Vector
from math import *
import random

# Clear the existing scene objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Parameters
main_circle_radius = 10
min_circle_radius = 0.1
max_circle_radius = 3
growth_step = 0.1
max_attempts = 1000
circles = []

# Function to check if a point is inside the main circle
def inside_main_circle(point):
    return point.length <= main_circle_radius

# Function to check for collision between new circle and existing circles
def check_collision(new_circle, circles):
    for circle in circles:
        if (circle[0] - new_circle[0]).length <= (circle[1] + new_circle[1]):
            return True
    return False

# Function to create a new circle mesh
def create_circle_mesh(radius, location):
    bpy.ops.mesh.primitive_circle_add(radius=radius, location=location)
    return bpy.context.object

# Main loop to create circles
for _ in range(max_attempts):
    # Randomly place a new small circle within the main circle
    angle = random.uniform(0, 2 * 3.14159)
    distance = random.uniform(0, main_circle_radius - max_circle_radius)
    location = Vector((cos(angle) * distance, sin(angle) * distance, 0))

    # Check if the location is inside the main circle and doesn't collide
    if inside_main_circle(location):
        new_circle = (location, min_circle_radius)
        if not check_collision(new_circle, circles):
            # Gradually increase the size of the circle until it touches another circle or the boundary
            while not check_collision(new_circle, circles) and inside_main_circle(new_circle[0] + Vector((new_circle[1], 0, 0))):
                new_circle = (new_circle[0], new_circle[1] + growth_step)
            # Add the new circle to the list
            circles.append(new_circle)
            # Create the mesh for the new circle
            create_circle_mesh(new_circle[1], new_circle[0])

# Create the main boundary circle for visual reference
create_circle_mesh(main_circle_radius, Vector((0, 0, 0)))
