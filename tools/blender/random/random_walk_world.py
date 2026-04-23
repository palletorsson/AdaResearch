# random_walk_world.py — Random walk over icosphere for terrain
# Source gist: https://gist.github.com/palletorsson/371d5f1b1fea8a0ebce9d82ba6aeabe8
# Doc section: Random walk world
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from random import choice

# Create a UV sphere
# Create an icosphere
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=6, radius=1, location=(0, 0, 0))
sphere_object = bpy.context.active_object

# Get the mesh data
mesh = sphere_object.data

# Create a bmesh from the mesh data
bm = bmesh.new()
bm.from_mesh(mesh)

# Ensure we can access the vertices and edges
bm.verts.ensure_lookup_table()
bm.edges.ensure_lookup_table()

# Choose a random starting vertex
current_vertex = choice(bm.verts)

# Random walk simulation (moves to adjacent vertices only)
for step in range(6000):  # Number of steps in the random walk
    # Get edges connected to the current vertex
    connected_edges = current_vertex.link_edges

    # Get adjacent vertices from those edges (excluding the current vertex)
    linked_verts = [edge.other_vert(current_vertex) for edge in connected_edges]

    # Randomly select the next vertex from the linked vertices
    next_vertex = choice(linked_verts)

    # Calculate the direction towards the center of the sphere
    direction_to_center = -next_vertex.normal  # Assuming the sphere is centered at the origin

    # Move the next vertex towards the center
    next_vertex.co += direction_to_center * 0.01 # Adjust the displacement magnitude as needed

    # Update the current vertex to be the next vertex for the following iteration
    current_vertex = next_vertex

# Random walk simulation (moves to adjacent vertices only)
for step in range(6000):  # Number of steps in the random walk
    # Get edges connected to the current vertex
    connected_edges = current_vertex.link_edges

    # Get adjacent vertices from those edges (excluding the current vertex)
    linked_verts = [edge.other_vert(current_vertex) for edge in connected_edges]

    # Randomly select the next vertex from the linked vertices
    next_vertex = choice(linked_verts)

    # Calculate the direction towards the center of the sphere
    direction_to_center = next_vertex.normal  # Assuming the sphere is centered at the origin

    # Move the next vertex towards the center
    next_vertex.co += direction_to_center * 0.01 # Adjust the displacement magnitude as needed

    # Update the current vertex to be the next vertex for the following iteration
    current_vertex = next_vertex
# Update the mesh with the new bmesh data
bm.to_mesh(mesh)
bm.free()

# Recalculate normals
mesh.update()

