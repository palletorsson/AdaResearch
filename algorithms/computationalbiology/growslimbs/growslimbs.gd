extends Node3D

# Morphogenesis System with Skeleton and Bones

class GrowthNode:
	var position: Vector3
	var parent: GrowthNode = null
	var children: Array[GrowthNode] = []
	var radius: float = 0.1
	var growth_direction: Vector3 = Vector3.ZERO
	var age: int = 0
	var can_branch: bool = true
	var bone_index: int = -1

var root_node: GrowthNode
var all_nodes: Array[GrowthNode] = []
var attractor_points: Array[Vector3] = []
var skeleton: Skeleton3D
var mesh_instance: MeshInstance3D

# Growth parameters
@export var max_iterations: int = 50
@export var growth_step: float = 0.3
@export var branch_angle: float = 45.0
@export var branch_probability: float = 0.15
@export var influence_radius: float = 2.0
@export var kill_distance: float = 0.4
@export var segment_thickness: float = 0.08

var current_iteration: int = 0
var is_growing: bool = false
var attractor_spheres: Array[Node3D] = []

func _ready():
	# Create skeleton
	skeleton = Skeleton3D.new()
	add_child(skeleton)
	
	# Create mesh instance for the skin
	mesh_instance = MeshInstance3D.new()
	skeleton.add_child(mesh_instance)
	
	# Create initial root
	root_node = GrowthNode.new()
	root_node.position = Vector3.ZERO
	root_node.radius = segment_thickness * 2
	all_nodes.append(root_node)
	
	# Add root bone
	root_node.bone_index = skeleton.add_bone("Root")
	skeleton.set_bone_pose_position(root_node.bone_index, root_node.position)
	
	# Create attractor points (define where limbs should grow)
	create_limb_attractors()
	
	# Visualize attractors
	visualize_attractors()
	
	print("Press SPACE to start growth, R to reset")

func create_limb_attractors():
	# Create attractors for multiple limbs (arms and legs pattern)
	var limb_configs = [
		{"base": Vector3(0.5, 0, 0), "end": Vector3(1.5, -0.3, 0.2)},  # Right arm
		{"base": Vector3(-0.5, 0, 0), "end": Vector3(-1.5, -0.3, 0.2)}, # Left arm
		{"base": Vector3(0.3, -0.5, 0), "end": Vector3(0.5, -2.0, 0.1)},  # Right leg
		{"base": Vector3(-0.3, -0.5, 0), "end": Vector3(-0.5, -2.0, 0.1)} # Left leg
	]
	
	for config in limb_configs:
		var points_per_limb = 8
		for i in range(points_per_limb):
			var t = float(i) / float(points_per_limb - 1)
			var pos = config.base.lerp(config.end, t)
			# Add some randomness
			pos += Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
			attractor_points.append(pos)

func visualize_attractors():
	for pos in attractor_points:
		var sphere = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.05
		sphere_mesh.height = 0.1
		sphere.mesh = sphere_mesh
		sphere.position = pos
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0.3, 0.3, 0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere.material_override = material
		add_child(sphere)
		attractor_spheres.append(sphere)

func _process(delta):
	if is_growing and current_iteration < max_iterations:
		grow_step()
		current_iteration += 1
		update_skeleton_and_mesh()
		
		if current_iteration >= max_iterations:
			is_growing = false
			print("Growth complete! %d bones created" % skeleton.get_bone_count())

func grow_step():
	var influenced_nodes: Dictionary = {}
	
	# Find which attractors influence which nodes
	for attractor in attractor_points:
		var closest_node: GrowthNode = null
		var closest_dist = influence_radius
		
		for node in all_nodes:
			if not node.can_branch:
				continue
			var dist = node.position.distance_to(attractor)
			if dist < closest_dist:
				closest_dist = dist
				closest_node = node
		
		if closest_node:
			if not influenced_nodes.has(closest_node):
				influenced_nodes[closest_node] = []
			influenced_nodes[closest_node].append(attractor)
	
	# Grow influenced nodes
	for node in influenced_nodes:
		var avg_direction = Vector3.ZERO
		for attractor in influenced_nodes[node]:
			var dir = (attractor - node.position).normalized()
			avg_direction += dir
		
		if influenced_nodes[node].size() > 0:
			avg_direction = avg_direction.normalized()
			
			# Create new growth node
			var new_node = GrowthNode.new()
			new_node.position = node.position + avg_direction * growth_step
			new_node.parent = node
			new_node.radius = node.radius * 0.9
			new_node.growth_direction = avg_direction
			
			# Add bone for this node
			var bone_name = "Bone_%d" % skeleton.get_bone_count()
			new_node.bone_index = skeleton.add_bone(bone_name)
			skeleton.set_bone_parent(new_node.bone_index, node.bone_index)
			skeleton.set_bone_pose_position(new_node.bone_index, new_node.position - node.position)
			
			node.children.append(new_node)
			all_nodes.append(new_node)
			
			# Branching logic
			if randf() < branch_probability and node.age > 3:
				var branch_node = GrowthNode.new()
				var random_offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
				var branch_dir = (avg_direction + random_offset * 0.5).normalized()
				branch_node.position = node.position + branch_dir * growth_step * 0.7
				branch_node.parent = node
				branch_node.radius = node.radius * 0.6
				
				# Add branch bone
				var branch_bone_name = "Branch_%d" % skeleton.get_bone_count()
				branch_node.bone_index = skeleton.add_bone(branch_bone_name)
				skeleton.set_bone_parent(branch_node.bone_index, node.bone_index)
				skeleton.set_bone_pose_position(branch_node.bone_index, branch_node.position - node.position)
				
				node.children.append(branch_node)
				all_nodes.append(branch_node)
			
			node.age += 1
	
	# Remove nearby attractors
	var attractors_to_remove = []
	for i in range(attractor_points.size()):
		for node in all_nodes:
			if node.position.distance_to(attractor_points[i]) < kill_distance:
				attractors_to_remove.append(i)
				break
	
	for i in range(attractors_to_remove.size() - 1, -1, -1):
		attractor_points.remove_at(attractors_to_remove[i])

func update_skeleton_and_mesh():
	# Update bone rest poses
	for node in all_nodes:
		if node.bone_index >= 0:
			skeleton.set_bone_rest(node.bone_index, Transform3D(Basis(), node.position if node.parent == null else node.position - node.parent.position))
	
	# Create mesh with skinning
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create cylindrical segments between bones
	for node in all_nodes:
		if node.parent and node.bone_index >= 0:
			create_skinned_segment(surface_tool, node.parent, node)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	# Set up skin
	var skin = Skin.new()
	for i in range(skeleton.get_bone_count()):
		skin.add_bind(i, skeleton.get_bone_global_rest(i).affine_inverse())
	mesh_instance.skin = skin
	
	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.4)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material

func create_skinned_segment(st: SurfaceTool, parent_node: GrowthNode, child_node: GrowthNode):
	var start = parent_node.position
	var end = child_node.position
	var radius_start = parent_node.radius
	var radius_end = child_node.radius
	
	var direction = (end - start).normalized()
	var perpendicular = Vector3.UP.cross(direction)
	if perpendicular.length() < 0.01:
		perpendicular = Vector3.RIGHT.cross(direction)
	perpendicular = perpendicular.normalized()
	
	var segments = 8
	var bones = PackedInt32Array([parent_node.bone_index, child_node.bone_index])
	var weights = PackedFloat32Array([1.0, 0.0])
	
	for i in range(segments):
		var angle1 = (float(i) / segments) * TAU
		var angle2 = (float(i + 1) / segments) * TAU
		
		var rot1 = perpendicular.rotated(direction, angle1)
		var rot2 = perpendicular.rotated(direction, angle2)
		
		var p1_start = start + rot1 * radius_start
		var p2_start = start + rot2 * radius_start
		var p1_end = end + rot1 * radius_end
		var p2_end = end + rot2 * radius_end
		
		# First triangle (start side)
		st.set_bones(bones)
		st.set_weights(weights)
		st.add_vertex(p1_start)
		
		st.set_bones(bones)
		st.set_weights(weights)
		st.add_vertex(p2_start)
		
		st.set_bones(bones)
		st.set_weights(PackedFloat32Array([0.0, 1.0]))
		st.add_vertex(p1_end)
		
		# Second triangle (end side)
		st.set_bones(bones)
		st.set_weights(weights)
		st.add_vertex(p2_start)
		
		st.set_bones(bones)
		st.set_weights(PackedFloat32Array([0.0, 1.0]))
		st.add_vertex(p2_end)
		
		st.set_bones(bones)
		st.set_weights(PackedFloat32Array([0.0, 1.0]))
		st.add_vertex(p1_end)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			start_growth()
		elif event.keycode == KEY_R:
			reset_growth()

func start_growth():
	is_growing = true
	print("Starting morphogenesis growth...")

func reset_growth():
	# Clear everything
	current_iteration = 0
	is_growing = false
	all_nodes.clear()
	attractor_points.clear()
	
	# Remove old skeleton
	if skeleton:
		skeleton.queue_free()
	
	# Create new skeleton
	skeleton = Skeleton3D.new()
	add_child(skeleton)
	
	mesh_instance = MeshInstance3D.new()
	skeleton.add_child(mesh_instance)
	
	# Recreate root
	root_node = GrowthNode.new()
	root_node.position = Vector3.ZERO
	root_node.radius = segment_thickness * 2
	all_nodes.append(root_node)
	
	root_node.bone_index = skeleton.add_bone("Root")
	skeleton.set_bone_pose_position(root_node.bone_index, root_node.position)
	
	create_limb_attractors()
	update_skeleton_and_mesh()
	print("Growth reset. Press SPACE to start.")
