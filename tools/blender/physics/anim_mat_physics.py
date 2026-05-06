# anim_mat_physics.py — Animation + material + rigid body physics
# Source gist: https://gist.github.com/palletorsson/c8ddd537a9ab56658c551844b22b56ab
# Doc section: Animation, Physics and Materials
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy
import random


# Function to create a plane as ground
def create_ground(size=10):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, 0))
    plane = bpy.context.object
    plane.name = "Ground"
    bpy.ops.rigidbody.object_add()
    plane.rigid_body.type = 'PASSIVE'
    plane.rigid_body.collision_shape = 'MESH'

# Function to create a sphere with rigid body physics
def create_falling_sphere(radius=1, location=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
    sphere = bpy.context.object
    create_mat(sphere)
    bpy.ops.rigidbody.object_add()
    sphere.rigid_body.type = 'ACTIVE'
    sphere.rigid_body.collision_shape = 'SPHERE'

# Function to create a box with rigid body physics
def create_falling_box(size=1, location=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=size, location=location)
    box = bpy.context.object
    bpy.ops.rigidbody.object_add()
    create_mat(box)
    box.rigid_body.type = 'ACTIVE'
    box.rigid_body.collision_shape = 'BOX'

def create_mat(obj): 
     # generate a random color
    red = random.random()  # creates a value from 0.0 to 1.0
    green = random.random()
    blue = random.random()
    alpha = 1.0
    color = (red, green, blue, alpha)

    # create a new material
    mat = bpy.data.materials.new(name=f"mat_{random.random()}")
    mat.diffuse_color = color

    # add the material to the object
    obj.data.materials.append(mat)
    
# Create the ground plane
create_ground()

# Create 10 random spheres and boxes
for _ in range(10):
    # Random location for the sphere
    sphere_location = (random.uniform(-5, 5), random.uniform(-5, 5), random.uniform(5, 10))
    create_falling_sphere(radius=0.5, location=sphere_location)

    # Random location for the box
    box_location = (random.uniform(-5, 5), random.uniform(-5, 5), random.uniform(5, 10))
    create_falling_box(size=1, location=box_location)
