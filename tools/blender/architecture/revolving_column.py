# revolving_column.py — Curve for revolving column lathe
# Source gist: https://gist.github.com/palletorsson/b5e228dfb585486fa923fab509d3cef0
# Doc section: Curve for revolving column
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import math

# Number of spiral turns
turns = 4

# Radius of the spiral
radius = 0.2

# Height of the spiral
height = 5

# Number of points per turn
points_per_turn = 32

# Total number of points
total_points = points_per_turn * turns

# Create a new curve data object
curve_data = bpy.data.curves.new(name="SpiralCurve", type='CURVE')
curve_data.dimensions = '3D'

# Create a new spline in the curve
spline = curve_data.splines.new(type='POLY')

# Add points to the spline
spline.points.add(total_points - 1)  # Total points is n-1 because the spline starts with 1 point by default

for i in range(total_points):
    angle = (math.pi * 2) * (i / points_per_turn)  # Calculate angle for the current point
    x = math.cos(angle) * radius  # X coordinate
    y = math.sin(angle) * radius  # Y coordinate
    z = (height / total_points) * i  # Z coordinate increases linearly
    
    spline.points[i].co = (x, y, z, 1)  # Set the point's coordinates (the 4th value, w, should be 1)

# Create a new object with the curve data
curve_object = bpy.data.objects.new("SpiralCurveObject", curve_data)

# Link the object to the current scene
bpy.context.collection.objects.link(curve_object)

# Make the curve object the active object
bpy.context.view_layer.objects.active = curve_object
