# koch_curve.py — Koch snowflake curve
# Source gist: https://gist.github.com/palletorsson/7135e4ed0268f3f79cfc85b46c86d1f8
# Doc section: Koch curve
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import cos, sin, pi

def create_koch_vertex(bm, pt):
    return bm.verts.new((pt[0], pt[1], pt[2]))

def create_koch_edge(bm, v1, v2):
    return bm.edges.new((v1, v2))

def koch_snowflake_iteration(bm, v1, v2, depth):
    if depth == 0:
        create_koch_edge(bm, v1, v2)
    else:
        # Calculate new vertices
        v3 = create_koch_vertex(bm, ((2 * v1.co[0] + v2.co[0]) / 3, (2 * v1.co[1] + v2.co[1]) / 3, (2 * v1.co[2] + v2.co[2]) / 3))
        v4 = create_koch_vertex(bm, ((v1.co[0] + v2.co[0]) / 2 + (v2.co[1] - v1.co[1]) * sin(pi / 3) / 3, (v1.co[1] + v2.co[1]) / 2 + (v1.co[0] - v2.co[0]) * sin(pi / 3) / 3, (v1.co[2] + v2.co[2]) / 2))
        v5 = create_koch_vertex(bm, ((v1.co[0] + 2 * v2.co[0]) / 3, (v1.co[1] + 2 * v2.co[1]) / 3, (v1.co[2] + 2 * v2.co[2]) / 3))
        
        # Call koch_snowflake_iteration recursively
        koch_snowflake_iteration(bm, v1, v3, depth - 1)
        koch_snowflake_iteration(bm, v3, v4, depth - 1)
        koch_snowflake_iteration(bm, v4, v5, depth - 1)
        koch_snowflake_iteration(bm, v5, v2, depth - 1)


def create_koch_snowflake(depth):
    # Create a new mesh and object
    mesh = bpy.data.meshes.new("KochSnowflake")
    obj = bpy.data.objects.new("KochSnowflake", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    
    bm = bmesh.new()

    # Initial vertices
    v1 = create_koch_vertex(bm, (0, 0, 0))
    v2 = create_koch_vertex(bm, (1, 0, 0))
    
    # Start the recursive function
    koch_snowflake_iteration(bm, v1, v2, depth)

    # Update the mesh with new data
    bm.to_mesh(mesh)
    bm.free()

create_koch_snowflake(3)  # Example call with 3 iterations
