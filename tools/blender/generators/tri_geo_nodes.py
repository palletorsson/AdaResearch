# tri_geo_nodes.py — Create triangle via Geometry Nodes
# Source gist: https://gist.github.com/palletorsson/a79c290c679ca44fe9a4b89f210a2fe7
# Doc section: Create triangle nodes
#
# Fetched from the palletorsson Blender scripting tutorial.
# Paste into Blender's Scripting workspace and press Alt+P.

import bpy

# Ensure there is an active object
obj = bpy.context.active_object

# Check if the active object is valid
if obj is None:
    raise ValueError("No active object found. Please select an object.")

# Add a Geometry Nodes modifier to the active object if it doesn't already have one
geo_mod = obj.modifiers.get("GeometryNodes") or obj.modifiers.new(name="GeometryNodes", type='NODES')

# Check if the modifier has a node group, if not, create one
if not geo_mod.node_group:
    geo_mod.node_group = bpy.data.node_groups.new('GeometryNodeGroup', 'GeometryNodeTree')

# Reference the node group from the Geometry Nodes modifier
node_tree = geo_mod.node_group

# Clear any existing nodes in the node tree
for node in node_tree.nodes:
    node_tree.nodes.remove(node)

# Create the necessary nodes
grid_node = node_tree.nodes.new(type='GeometryNodeMeshGrid')
subdivide_mesh_node = node_tree.nodes.new(type='GeometryNodeSubdivideMesh')
triangulate_node = node_tree.nodes.new(type='GeometryNodeTriangulate')
split_edges_node = node_tree.nodes.new(type='GeometryNodeSplitEdges')
scale_elements_node = node_tree.nodes.new(type='GeometryNodeScaleElements')
group_output_node = node_tree.nodes.new(type='NodeGroupOutput')

# Set properties for the nodes
subdivide_mesh_node.inputs["Level"].default_value = 3
scale_elements_node.inputs["Scale"].default_value = 0.8

# Set locations for the nodes (for clarity)
nodes = [grid_node, subdivide_mesh_node, triangulate_node, split_edges_node, scale_elements_node, group_output_node]
for index, node in enumerate(nodes):
    node.location.x = index * 200

# Link the nodes together
node_tree.links.new(grid_node.outputs['Mesh'], subdivide_mesh_node.inputs['Mesh'])
node_tree.links.new(subdivide_mesh_node.outputs['Mesh'], triangulate_node.inputs['Mesh'])
node_tree.links.new(triangulate_node.outputs['Mesh'], split_edges_node.inputs['Mesh'])
node_tree.links.new(split_edges_node.outputs['Mesh'], scale_elements_node.inputs['Geometry'])
node_tree.links.new(scale_elements_node.outputs['Geometry'], group_output_node.inputs['Geometry'])
