# supershape.py — Gielis supershape
# Source gist: https://gist.github.com/palletorsson/c1d4ee77b63b8620126cbb9712957a1e
# Doc section: Supershape
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import bmesh
from math import cos, sin, pi, fabs, pow

# Superformula parameters
m = 14.23
a = -0.06
b = 2.78
n1 = 0.5
n2 = -0.48
n3 = 1.5

# Scale of the shape
scale = 3

# Number of vertices along the latitudes and longitudes
Unum = 50
Vnum = 50

# Increment angles
Uinc = pi / (Unum / 2)
Vinc = (pi / 2) / (Vnum / 2)

# Create mesh and object
mesh = bpy.data.meshes.new("SuperShape")
obj = bpy.data.objects.new("SuperShape", mesh)

# Set mesh location
obj.location = bpy.context.scene.cursor.location if hasattr(bpy.context.scene.cursor, 'location') else bpy.context.scene.cursor.position
bpy.context.collection.objects.link(obj)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)

# Use bmesh to create vertices
bm = bmesh.new()

def superformula(theta, m, n1, n2, n3):
    """ Superformula function for a single angle """
    part1 = (1 / a) * cos(m * theta / 4)
    part1 = fabs(part1) ** n2
    part2 = (1 / b) * sin(m * theta / 4)
    part2 = fabs(part2) ** n3
    part3 = part1 + part2
    r = part3 ** (-1 / n1)
    return r

# Generate vertices
for i in range(Unum + 1):
    theta = i * Uinc - pi
    for j in range(Vnum + 1):
        phi = j * Vinc - pi / 2
        r1 = superformula(phi, m, n1, n2, n3)
        r2 = superformula(theta, m, n1, n2, n3)
        x = scale * r1 * cos(phi) * r2 * cos(theta)
        y = scale * r1 * sin(phi) * r2 * cos(theta)
        z = scale * r2 * sin(theta)
        bm.verts.new((x, y, z))

# Ensure the bmesh will always be valid
bm.verts.ensure_lookup_table()

# Create faces
for i in range(Unum):
    for j in range(Vnum):
        A = bm.verts[i * (Vnum + 1) + j]
        B = bm.verts[i * (Vnum + 1) + j + 1]
        C = bm.verts[(i + 1) * (Vnum + 1) + j + 1]
        D = bm.verts[(i + 1) * (Vnum + 1) + j]
        bm.faces.new((A, B, C, D))

# Update bmesh to mesh
bm.to_mesh(mesh)
bm.free()

# Set smooth shading
for poly in mesh.polygons:
    poly.use_smooth = True

# Add subdivision surface modifier
subsurf_mod = obj.modifiers.new(name="Subsurf", type='SUBSURF')
subsurf_mod.levels = 2

# Update mesh geometry
mesh.update()
mesh.calc_normals()

