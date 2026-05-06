# rule27.py — 1D Cellular Automaton — Rule 27
# Source gist: https://gist.github.com/palletorsson/7889a0a45d5df054d44718c4323f6584
# Doc section: Cellular Automata - Rule 27
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

def rule_27(left, center, right):
    """ Rule 27 logic """
    return left if center == right else 1 - left

def generate_automata_row(previous_row):
    """ Generate the next row in the automata """
    new_row = []
    for i in range(len(previous_row)):
        left = previous_row[i - 1] if i > 0 else previous_row[-1]
        center = previous_row[i]
        right = previous_row[i + 1] if i < len(previous_row) - 1 else previous_row[0]
        new_row.append(rule_27(left, center, right))
    return new_row

def create_cube(x, y, z):
    """ Create a cube at a specific location """
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z))

# Parameters
num_generations = 60
initial_state = [1 if i == num_generations // 2 else 0 for i in range(num_generations)]

# Clear existing cubes
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.select_by_type(type='MESH')
bpy.ops.object.delete()

# Create initial generation
current_generation = initial_state
for x, cell in enumerate(current_generation):
    if cell:
        create_cube(x, 0, 0)

# Generate and visualize subsequent generations
for y in range(1, num_generations):
    current_generation = generate_automata_row(current_generation)
    for x, cell in enumerate(current_generation):
        if cell:
            create_cube(x, y, 0)

# Adjust camera
bpy.context.scene.camera.location = (num_generations / 2, -num_generations, num_generations / 2)
bpy.context.scene.camera.rotation_euler = (1.05, 0, 0.75)
