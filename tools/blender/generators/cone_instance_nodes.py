# cone_instance_nodes.py — Cone instance via Geometry Nodes
# Source gist: https://gist.github.com/palletorsson/d97b43d0bfb93957121b8bd1610907de
# Doc section: Create Nodes Cone Instance
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Ensure there is an active object
obj = bpy.context.active_object

# Create a new geometry nodes group
geo_nodes = bpy.data.node_groups.new('DistributeConesOnGrid', 'GeometryNodeTree')

# Clear any existing nodes in the group
nodes = geo_nodes.nodes
nodes.clear()

# Add nodes for the setup
grid_node = nodes.new(type='GeometryNodeMeshGrid')
distribute_points_node = nodes.new(type='GeometryNodeDistributePointsOnFaces')
cone_node = nodes.new(type='GeometryNodeMeshCone')
random_value_node = nodes.new(type='FunctionNodeRandomValue')
instance_on_points_node = nodes.new(type='GeometryNodeInstanceOnPoints')
group_output_node = nodes.new(type='NodeGroupOutput')

# Create a geometry input for the Group Output node
#geo_nodes.outputs.new('NodeSocketGeometry', "Geometry")

# Position nodes for clarity
grid_node.location = (-600, 0)
distribute_points_node.location = (-400, 0)
cone_node.location = (-400, -200)
random_value_node.location = (-200, -100)
instance_on_points_node.location = (0, 0)
group_output_node.location = (200, 0)

# Link nodes together
links = geo_nodes.links
links.new(grid_node.outputs['Mesh'], distribute_points_node.inputs['Mesh'])
links.new(distribute_points_node.outputs['Points'], instance_on_points_node.inputs['Points'])
links.new(cone_node.outputs['Mesh'], instance_on_points_node.inputs['Instance'])
links.new(random_value_node.outputs['Value'], instance_on_points_node.inputs['Scale'])
#link = links.new(instance_on_points_node.outputs['Instances'], group_output_node.inputs['Geometry'])

# Set node properties based on the screenshot
grid_node.inputs['Size X'].default_value = 3.2
grid_node.inputs['Size Y'].default_value = 4.1
grid_node.inputs['Vertices X'].default_value = 26
grid_node.inputs['Vertices Y'].default_value = 24

distribute_points_node.inputs['Density'].default_value = 1400
random_value_node.inputs['Min'].default_value = -0.1
random_value_node.inputs['Max'].default_value = 0.6

# Cone settings
cone_node.inputs['Vertices'].default_value = 32
cone_node.inputs['Radius Top'].default_value = 0
cone_node.inputs['Radius Bottom'].default_value = 1
cone_node.inputs['Depth'].default_value = 3.7

# Assign the node group to a Geometry Nodes modifier
if not obj.modifiers.get("GeometryNodes"):
    modifier = obj.modifiers.new(name="GeometryNodes", type='NODES')
modifier.node_group = geo_nodes

# Update the view layer so everything shows up correctly
bpy.context.view_layer.update()
