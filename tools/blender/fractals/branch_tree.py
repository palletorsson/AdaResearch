# branch_tree.py — Recursive branching tree
# Source gist: https://gist.github.com/palletorsson/4e3f21422536bf3a920f764d321ff4ff
# Doc section: Branch tree
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from mathutils import Vector, Matrix
from math import radians, sin, cos

# Function to create a branch
def create_branch(bm, start, direction, length, angle, depth):
    if depth <= 0:
        return

    # Calculate the end position of the branch
    end = start + direction.normalized() * length
    verts = [bm.verts.new(p) for p in (start, end)]
    bm.edges.new(verts)
    
    # Calculate the direction for the new branches
    branch_direction1 = direction @ Matrix.Rotation(radians(angle), 4, 'Y')
    branch_direction2 = direction @ Matrix.Rotation(radians(-angle), 4, 'Y')
    
    # Recursively create the smaller branches
    create_branch(bm, end, branch_direction1, length * 0.7, angle, depth - 1)
    create_branch(bm, end, branch_direction2, length * 0.7, angle, depth - 1)

# Main function to create the tree
def create_tree():
    # Create a new mesh and object
    mesh = bpy.data.meshes.new(name="TreeMesh")
    obj = bpy.data.objects.new(name="Tree", object_data=mesh)
    
    # Link the object to the scene
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    
    # Create bmesh to construct the geometry
    bm = bmesh.new()
    
    # Define the base trunk of the tree
    start = Vector((0, 0, 0))
    direction = Vector((0, 0, 1))
    length = 5
    angle = 1000
    depth = 6  # Number of recursive branch generations
    
    # Create the fractal tree structure
    create_branch(bm, start, direction, length, radians(angle), depth)
    
    # Finish up and write the bmesh back to the mesh
    bm.to_mesh(mesh)
    bm.free()

# Clear existing objects in the scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Create the tree
create_tree()
