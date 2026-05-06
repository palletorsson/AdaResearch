# wavy_mesh.py — Wavy displaced mesh
# Source gist: https://gist.github.com/palletorsson/cca09d57ed983bac1e9bc4a9c1ab4de0
# Doc section: Wavy mesh
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import sin, pi
import random 

# Function to create a wavy mesh
def create_wavy_mesh(width, height, depth, num_waves, resolution):
    bpy.ops.mesh.primitive_plane_add(size=1)
    plane = bpy.context.active_object
    plane.scale = (width / 2, depth / 2, height / 2)

    # Subdivide the plane to increase its resolution
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.subdivide(number_cuts=resolution)
    bpy.ops.object.mode_set(mode='OBJECT')

    mesh = plane.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    change = random.random()
    # Apply a wave-like displacement to the vertices
    i = 0
    for v in bm.verts:
        # Calculate the displacement factor based on the vertex position
        
        if i % 20 == 0: 
            change = random.random()
        wave_factor = sin(num_waves * pi * v.co.x / width)
        v.co.z += wave_factor * height + (change * 0.5) 
        i=i+1

    # Update the mesh with the new vertex positions
    bm.to_mesh(mesh)
    bm.free()

# Define the dimensions of the wavy structure
width = 10
height = 0.5
depth = 5
num_waves = 100  # Number of waves across the width of the mesh
resolution = 100  # Number of subdivisions in the mesh

# Create the wavy mesh
create_wavy_mesh(width, height, depth, num_waves, resolution)
