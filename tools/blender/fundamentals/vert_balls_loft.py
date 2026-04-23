# vert_balls_loft.py — Vertex-positioned ball loft
# Source gist: https://gist.github.com/palletorsson/301283b44ec0c1742358cc02becdd3ec
# Doc section: Vertices ball loft
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
import random

def create_line_random(quantity, y_offset, bm):
    new_verts = []
    for x in range(quantity):
        if x == 0 or x == quantity - 1:
            z = 0
        else:
            z = random.random() * 10  # Random Z value for inner vertices
        vert = bm.verts.new((x * 10, y_offset * 10, z))  # Create vertex
        new_verts.append(vert)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.5, location=vert.co)
    return new_verts  # Return the new vertices directly

def create_line_straigth(quantity, y_offset, bm):
    new_verts = []
    for x in range(quantity):
        vert = bm.verts.new((x * 10, y_offset * 10, 0))  # Create vertex
        new_verts.append(vert)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1.5, location=vert.co)
    return new_verts  # Return the new vertices directly
    
all_vertex_coords = []  
# Main function to create grid of lines and simulate lofting
def create_lofted_grid(quantity, lines_count):
    mesh = bpy.data.meshes.new("LoftedGridMesh")
    obj = bpy.data.objects.new("LoftedGrid", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)

    bm = bmesh.new()
    previous_line_verts = []

    # Create lines and connect them to simulate lofting
    for i in range(lines_count):
        bm.verts.ensure_lookup_table()  # Ensure the vertex lookup table is up to date
        bm.edges.ensure_lookup_table()  # Ensure the edge lookup table is up to date
        if i == 0 or i == lines_count-1:
            current_line_verts = create_line_straigth(quantity, i, bm)
        else:
            current_line_verts = create_line_random(quantity, i, bm)
        

        # Create faces between consecutive lines
        if previous_line_verts:
            for j in range(quantity - 1):
                face_verts = [
                    previous_line_verts[j],
                    previous_line_verts[j + 1],
                    current_line_verts[j + 1],
                    current_line_verts[j]
                ]
                bm.faces.new(face_verts)

        previous_line_verts = current_line_verts

    bm.to_mesh(mesh)  # Update the mesh with bmesh data
    bm.free()  # Free and prevent further access

# Call the function with desired parameters
create_lofted_grid(30, 30)


