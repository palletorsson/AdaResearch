# icosphere_skips.py — Icosphere with parametric bulge spikes
# Source gist: https://gist.github.com/palletorsson/14c1216083173683312ea9805c300db9
# Doc section: Parameters for the icosphere and the bulge spik
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import exp
import random
from mathutils import Vector

# Parameters for the icosphere and the bulge spik
sphere_radius = 1
bulge_factor = 0.1  # Increase the factor for a more pronounced bulge
num_objects = 10  # Number of objects to create

# Delete existing objects in the scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Function to create an icosphere with a bulge effect
def create_bulging_icosphere(location, radius, bulge_factor, center):
    # Create a new icosphere
    bpy.ops.mesh.primitive_ico_sphere_add(radius=radius, enter_editmode=False, align='WORLD', location=location, scale=(1, 1, 1))
    icosphere = bpy.context.object

    # Add a simple subdivision surface modifier
    subsurf_mod = icosphere.modifiers.new(name="Subdivision", type='SUBSURF')
    subsurf_mod.levels = 2
    bpy.context.view_layer.update()  # Update the view layer to ensure modifier is applied properly

    # Apply the modifier
    bpy.ops.object.modifier_apply(modifier=subsurf_mod.name)

    # Get the bmesh representation
    mesh = icosphere.data
    bm = bmesh.new()
    bm.from_mesh(mesh)

    # Ensure lookup table is generated before accessing vertices
    bm.verts.ensure_lookup_table()

    # Calculate the center of the icosphere
    center = center 

    # Apply bulge effect to each vertex
    for v in bm.verts:
        # Vector from the icosphere center to the current vertex
        direction = v.co - center
        distance = direction.length * (random.random() * 12.5)  # Distance from center to vertex

        # Calculate bulge using a Gaussian-like falloff
        bulge = exp(-distance**2 * bulge_factor)

        # Apply the bulge along the vertex normal
        v.co += v.normal * bulge * radius  # Scale the bulge effect as needed

    # Update the bmesh and mesh
    bm.to_mesh(mesh)
    bm.free()

    # Recalculate normals
    mesh.update()

# Create ten icospheres with bulge effects
for i in range(num_objects):
    center =  Vector((i,i,i))
    location = Vector((i * 3, 0, 0))  # Offset each icosphere by 3 units along the x-axis
    create_bulging_icosphere(location, sphere_radius, bulge_factor, center)
