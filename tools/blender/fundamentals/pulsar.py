# pulsar.py — 3D pulsar animation
# Source gist: https://gist.github.com/palletorsson/4e8e2f0efd1b766a7083634b9ec489c2
# Doc section: Pulsar 3D
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import csv
import os


# Define dimensions and scales
height = 8.0
width = height / 1.138
top_margin = width / 13
amplitude = width / 350

# Path to the CSV file
# Path to the CSV file
csv_file_path = bpy.path.abspath(r'C:\Users\palle\Documents\Blender_Work\KONSTFACK/pulsar.csv')

# Function to read CSV data
def read_csv_data(filepath):
    with open(filepath, 'r') as csvfile:
        datareader = csv.reader(csvfile)
        data = [list(map(float, row)) for row in datareader]
    return data

# Read the CSV file
data = read_csv_data(csv_file_path)

# Function to create a gradient material
def create_gradient_material():
    material = bpy.data.materials.new(name="PinkGradient")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links

    # Clear default nodes
    nodes.clear()

    # Create necessary nodes
    output_node = nodes.new(type='ShaderNodeOutputMaterial')
    shader_node = nodes.new(type='ShaderNodeBsdfPrincipled')
    texture_node = nodes.new(type='ShaderNodeTexGradient')
    color_ramp_node = nodes.new(type='ShaderNodeValToRGB')

    # Set up the color ramp (gradient) node
    color_ramp_node.color_ramp.elements[0].color = (1, 0.4, 0.8, 1)  # Light pink
    color_ramp_node.color_ramp.elements[1].color = (0.8, 0.2, 0.4, 1)  # Darker pink

    # Link nodes
    links.new(shader_node.outputs['BSDF'], output_node.inputs['Surface'])
    links.new(texture_node.outputs['Fac'], color_ramp_node.inputs['Fac'])
    links.new(color_ramp_node.outputs['Color'], shader_node.inputs['Base Color'])

    return material

# Create the gradient material
pink_gradient_material = create_gradient_material()

# Function to create a 3D curve from data
def create_curve(data_row, row_index, material):
    # Create a curve data and object
    curve_data = bpy.data.curves.new('CurveData', 'CURVE')
    curve_data.dimensions = '3D'
    curve_obj = bpy.data.objects.new("CurveObj", curve_data)

    # Link object to the scene
    bpy.context.collection.objects.link(curve_obj)

    # Create a spline in the curve
    spline = curve_data.splines.new('POLY')
    spline.points.add(len(data_row) - 1)

    # Set points positions
    for i, val in enumerate(data_row):
        x = i * width / len(data_row)
        y = row_index * top_margin
        z = -val * amplitude
        spline.points[i].co = (x, y, z, 1)

    # Set bevel to give thickness to the curve
    curve_data.bevel_depth = 0.05
    curve_data.bevel_resolution = 3

    # Assign the pink gradient material to the curve
    curve_obj.data.materials.append(material)

    return curve_obj

# Create curves for each row in data
for index, row in enumerate(data):
    create_curve(row, index, pink_gradient_material)

# Additional scene setup and animation can be added here
