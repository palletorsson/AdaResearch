# random_balls.py — Random ball placement
# Source gist: https://gist.github.com/palletorsson/1d90fde6f05069aafaa0e4ca53803d42
# Doc section: Use Random
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random

def get_point(coord, points, bound):
    fx = random.randint(-1, 1)
    new_coord = coord + fx
    if abs(new_coord) > bound:
        return 'next'
    if new_coord in points:
        return 'next'
    return new_coord

def set_origin():
    return [0, 0, 0]

def run_sequence(bound, points, x_points, y_points):
    pt_current = set_origin()
    for i in range(30):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=pt_current)
        old_pt = bpy.context.object

        add_new_point = False
        x_point = get_point(pt_current[0], x_points, bound)
        if x_point != 'next':
            pt_current[0] = x_point
            x_points.append(pt_current[0])
            add_new_point = True

        y_point = get_point(pt_current[1], y_points, bound)
        if y_point != 'next':
            pt_current[1] = y_point
            y_points.append(pt_current[1])
            add_new_point = True

        if add_new_point:
            old_pt.location = pt_current
            bpy.ops.mesh.primitive_uv_sphere_add(radius=2, location=pt_current)

# Main logic
for _ in range(5):
    bound = 10
    pts = [set_origin()]
    x_points = [pts[0][0]]
    y_points = [pts[0][1]]
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=pts[0])
    run_sequence(bound, pts, x_points, y_points)
