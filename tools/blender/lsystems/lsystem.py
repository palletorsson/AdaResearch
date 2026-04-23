# lsystem.py — L-system tree generator for Blender
# Source gist: https://gist.github.com/palletorsson/332c2f862c47e2e456b4c5a19855c66d
#
# Generates a branching L-system tree by rewriting the axiom "F" with
# "FF+[+F-F-F]-[-F+F+F]" a few times, interpreting the resulting string
# with a turtle that walks, rotates, pushes/pops state, and draws a
# cylinder between each pair of points. Per-step randomness adds a little
# organic drift to the otherwise deterministic grammar.
import bpy
import math
import random
from mathutils import Vector, Matrix

# L-System parameters
axiom = "F"
rules = {
    "F": "FF+[+F-F-F]-[-F+F+F]"
}
iterations = 2        # Number of iterations for growth
angle_deg = 25.0      # Angle of rotation for each branch
segment_length = 2.0  # Length of each branch segment
scale_factor = 0.9    # Scale factor for each new generation
random_factor = 0.2   # Randomness factor for x and y axis

# Stack to store the position and orientation
stack = []
# List to store points and their next points for branches
branch_points = []


# Apply L-system rules and generate a string
def generate_l_system(axiom, rules, iterations):
    result = axiom
    for _ in range(iterations):
        new_string = ""
        for char in result:
            new_string += rules.get(char, char)
        result = new_string
    return result


# Generate points with randomness
def generate_points(l_system, position, direction, length, angle, scale_factor):
    for char in l_system:
        if char == "F":
            # Introduce randomness in x and y axes
            rand_x = random.uniform(-random_factor, random_factor)
            rand_y = random.uniform(-random_factor, random_factor)
            random_offset = Vector((rand_x, rand_y, 0))
            # Store the starting and ending points of the branch
            new_position = position + direction * length + random_offset
            branch_points.append((position.copy(), new_position.copy()))
            position = new_position
        elif char == "+":
            rotation_matrix = Matrix.Rotation(math.radians(angle), 4, 'X')
            direction.rotate(rotation_matrix)
        elif char == "-":
            rotation_matrix = Matrix.Rotation(math.radians(-angle), 4, 'X')
            direction.rotate(rotation_matrix)
        elif char == "[":
            stack.append((position.copy(), direction.copy(), length))
        elif char == "]":
            position, direction, length = stack.pop()
        # Optionally, you can scale down the length of branches after each branch
        length *= scale_factor


# Create a cylinder branch between two points
def create_branch(start, end, radius=0.05):
    direction = end - start
    length = direction.length
    direction.normalize()
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8,
        radius=radius,
        depth=length,
        location=(0, 0, 0),
    )
    branch = bpy.context.object
    branch.location = (start + end) / 2
    branch.rotation_mode = 'QUATERNION'
    z_axis = Vector((0, 0, 1))
    rotation = z_axis.rotation_difference(direction)
    branch.rotation_quaternion = rotation
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


# Clear the scene before generating the tree
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Generate the final L-system string
final_l_system = generate_l_system(axiom, rules, iterations)

# Initial starting parameters
start_position = Vector((0, 0, 0))
start_direction = Vector((0, 0, 1))  # Upward along the Z-axis
start_length = segment_length

# Generate the points for the L-system tree with randomness
generate_points(final_l_system, start_position, start_direction, start_length, angle_deg, scale_factor)

# Draw the branches between points
for start, end in branch_points:
    create_branch(start, end)
