extends Node3D

## Inverted Recursive Tree - Geometric blocks pointing down with animated cube cloud
## Uses the same geometric style as the original tree but inverted
## Animated rectangular cube cloud appears above in a timeline

# @identity
# essence: tree(depth) = trunk_down + branches_down(random_angle, shrink) + cube_cloud(orbit, fade_timeline)
# desire: To unsettle — roots reaching down from the sky while a cloud of cubes orbits and pulses above
# critical_parameter: vertical_tilt range (-0.5 to -0.2) — controls how steeply branches plunge downward
# triggers: Recursive branch generation with random angles; cube cloud timeline loops with fade-in/out per cube
# emerges: The cube cloud feels alive — independent orbit speeds and fade offsets create the illusion of breathing
# needs: VR gravity toggle [missing], cloud interaction [missing]
# relationships: Inverts recursive_tree; the cloud above mirrors what roots extract below — visual metaphor for data flow
# truth: An inverted tree is not wrong — it is a root system, and roots are where the real computation happens.

@export_category("Inverted Tree Structure")
@export var num_main_branches: int = 5
@export var max_sub_branches: int = 4
@export var branch_length_min: float = 1.5
@export var branch_length_max: float = 4.0
@export var branch_width_min: float = 0.8
@export var branch_width_max: float = 2.5
@export var branch_height_min: float = 0.8
@export var branch_height_max: float = 2.5
@export var trunk_height: float = 5.0
@export var trunk_width: float = 1.5

@export_category("Tree Appearance")
@export_color_no_alpha var primary_color: Color = Color(0.95, 0.3, 0.3)
@export_color_no_alpha var secondary_color: Color = Color(0.85, 0.2, 0.2)
@export_color_no_alpha var trunk_color: Color = Color(0.8, 0.3, 0.3)
@export var metallic: float = 0.1
@export var roughness: float = 0.7
@export var emission_strength: float = 0.2

@export_category("Cube Cloud")
@export var cloud_start_height: float = 8.0
@export var cloud_center_cube_size: float = 2.0
@export var cloud_sub_cubes: int = 12
@export var cloud_sub_cube_size_min: float = 0.5
@export var cloud_sub_cube_size_max: float = 1.5
@export var cloud_orbit_radius: float = 4.0
@export var cloud_animation_duration: float = 8.0  # Timeline duration in seconds
@export var cloud_color: Color = Color(0.7, 0.85, 1.0, 0.8)

@export_category("Settings")
@export var random_seed: int = 42

# Materials
var primary_material: StandardMaterial3D
var secondary_material: StandardMaterial3D
var trunk_material: StandardMaterial3D
var cloud_material: StandardMaterial3D

# Internal state
var rng: RandomNumberGenerator
var cloud_cubes: Array = []
var animation_time: float = 0.0

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = random_seed

	create_materials()
	build_inverted_tree()

func create_materials() -> void:
	"""Create materials matching the original tree style"""
	# Primary material
	primary_material = StandardMaterial3D.new()
	primary_material.albedo_color = primary_color
	primary_material.metallic = metallic
	primary_material.roughness = roughness
	primary_material.emission_enabled = true
	primary_material.emission = primary_color
	primary_material.emission_energy_multiplier = emission_strength

	# Secondary material
	secondary_material = StandardMaterial3D.new()
	secondary_material.albedo_color = secondary_color
	secondary_material.metallic = metallic
	secondary_material.roughness = roughness
	secondary_material.emission_enabled = true
	secondary_material.emission = secondary_color
	secondary_material.emission_energy_multiplier = emission_strength * 0.7

	# Trunk material
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = trunk_color
	trunk_material.metallic = metallic
	trunk_material.roughness = roughness + 0.1
	trunk_material.emission_enabled = true
	trunk_material.emission = trunk_color
	trunk_material.emission_energy_multiplier = emission_strength * 0.5

	# Cloud material
	cloud_material = StandardMaterial3D.new()
	cloud_material.albedo_color = cloud_color
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.emission_enabled = true
	cloud_material.emission = Color(cloud_color.r, cloud_color.g, cloud_color.b)
	cloud_material.emission_energy_multiplier = 1.0
	cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func build_inverted_tree() -> void:
	"""Build the inverted tree structure"""
	var tree_root = Node3D.new()
	tree_root.name = "InvertedGeometricTree"
	add_child(tree_root)

	# Create trunk pointing down
	var trunk = create_inverted_trunk()
	tree_root.add_child(trunk)

	# Generate branches pointing downward
	var branch_origin = Vector3(0, 0, 0)  # Start at top
	generate_inverted_branches(tree_root, branch_origin, num_main_branches, 0, 3)

	# Create animated cube cloud above
	create_cube_cloud()

func create_inverted_trunk() -> Node3D:
	"""Create trunk pointing downward with geometric blocks"""
	var trunk_node = Node3D.new()
	trunk_node.name = "InvertedTrunk"

	# Main trunk block pointing down
	var trunk_mesh = BoxMesh.new()
	trunk_mesh.size = Vector3(trunk_width, trunk_height, trunk_width)

	var trunk_instance = MeshInstance3D.new()
	trunk_instance.mesh = trunk_mesh
	trunk_instance.material_override = trunk_material
	trunk_instance.position.y = -trunk_height / 2  # Pointing down

	trunk_node.add_child(trunk_instance)

	# Add detail blocks to trunk
	var num_details = rng.randi() % 4 + 1
	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()

		var detail_size = Vector3(
			trunk_width * rng.randf_range(0.3, 0.6),
			trunk_width * rng.randf_range(0.3, 0.6),
			trunk_width * rng.randf_range(0.3, 0.6)
		)
		detail_mesh.size = detail_size
		detail.mesh = detail_mesh

		# Position on trunk
		var height_pos = rng.randf_range(-trunk_height + trunk_width, -trunk_width)
		var angle = rng.randf_range(0, TAU)
		var radius = trunk_width / 2 * 0.9

		detail.position = Vector3(
			cos(angle) * radius,
			height_pos,
			sin(angle) * radius
		)

		detail.material_override = primary_material if rng.randf() > 0.3 else secondary_material
		trunk_node.add_child(detail)

	return trunk_node

func generate_inverted_branches(parent: Node, origin_point: Vector3, num_branches: int, current_depth: int, max_depth: int) -> void:
	"""Recursively generate branches pointing downward"""
	if current_depth >= max_depth:
		return

	for i in range(num_branches):
		var branch = Node3D.new()
		branch.name = "InvertedBranch_" + str(current_depth) + "_" + str(i)
		parent.add_child(branch)

		# Branch dimensions (shrinking with depth)
		var branch_width = rng.randf_range(branch_width_min, branch_width_max) * (1.0 - current_depth * 0.2)
		var branch_height = rng.randf_range(branch_height_min, branch_height_max) * (1.0 - current_depth * 0.2)
		var branch_length = rng.randf_range(branch_length_min, branch_length_max) * (1.0 - current_depth * 0.15)

		# Create branch mesh
		var branch_mesh = BoxMesh.new()
		branch_mesh.size = Vector3(branch_width, branch_height, branch_length)

		var branch_instance = MeshInstance3D.new()
		branch_instance.mesh = branch_mesh
		branch_instance.material_override = primary_material if rng.randf() > 0.3 else secondary_material

		# Direction pointing downward and outward
		var angle = rng.randf_range(0, TAU)
		var vertical_tilt = rng.randf_range(-0.5, -0.2)  # Negative for downward

		var direction = Vector3(
			cos(angle),
			vertical_tilt,
			sin(angle)
		).normalized()

		# Position branch
		var distance_from_origin = branch_length / 2
		var position = origin_point + direction * distance_from_origin
		branch_instance.position = position

		# Orient branch
		branch_instance.look_at_from_position(branch_instance.position, position + direction, Vector3.UP)

		branch.add_child(branch_instance)

		# Add detail blocks
		if rng.randf() > 0.4:
			add_inverted_detail_blocks(branch, branch_instance, branch_mesh.size)

		# Calculate end point for sub-branches
		var end_point = position + direction * (branch_length / 2)

		# Generate sub-branches
		var num_sub = rng.randi() % (max_sub_branches - current_depth) + 1
		if current_depth < 2:
			num_sub = rng.randi() % max_sub_branches + 2

		generate_inverted_branches(branch, end_point, num_sub, current_depth + 1, max_depth)

func add_inverted_detail_blocks(parent_node: Node, branch_instance: MeshInstance3D, branch_size: Vector3) -> void:
	"""Add detail blocks to inverted branches"""
	var num_details = rng.randi() % 3 + 1

	for i in range(num_details):
		var detail = MeshInstance3D.new()
		var detail_mesh = BoxMesh.new()

		var scale_factor = rng.randf_range(0.2, 0.5)
		var detail_size = Vector3(
			branch_size.x * scale_factor,
			branch_size.y * scale_factor,
			branch_size.z * scale_factor
		)
		detail_mesh.size = detail_size
		detail.mesh = detail_mesh

		# Position on branch surface
		var axis = rng.randi() % 3
		var sign_factor = 1 if rng.randf() > 0.5 else -1
		var relative_position = Vector3.ZERO

		match axis:
			0:
				relative_position.x = sign_factor * (branch_size.x / 2 + detail_size.x / 2 * 0.8)
				relative_position.y = rng.randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = rng.randf_range(-0.4, 0.4) * branch_size.z
			1:
				relative_position.x = rng.randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = sign_factor * (branch_size.y / 2 + detail_size.y / 2 * 0.8)
				relative_position.z = rng.randf_range(-0.4, 0.4) * branch_size.z
			2:
				relative_position.x = rng.randf_range(-0.4, 0.4) * branch_size.x
				relative_position.y = rng.randf_range(-0.4, 0.4) * branch_size.y
				relative_position.z = sign_factor * (branch_size.z / 2 + detail_size.z / 2 * 0.8)

		var global_transform = branch_instance.global_transform
		detail.position = branch_instance.to_local(global_position + global_transform.basis * relative_position)
		detail.rotation = branch_instance.rotation

		detail.material_override = secondary_material if rng.randf() > 0.4 else primary_material
		parent_node.add_child(detail)

func create_cube_cloud() -> void:
	"""Create animated cube cloud above the tree"""
	var cloud_root = Node3D.new()
	cloud_root.name = "CubeCloud"
	cloud_root.position.y = cloud_start_height
	add_child(cloud_root)

	# Center cube
	var center_cube = create_cloud_cube(cloud_center_cube_size)
	center_cube.position = Vector3.ZERO
	cloud_root.add_child(center_cube)

	cloud_cubes.append({
		"node": center_cube,
		"start_time": 0.0,
		"duration": cloud_animation_duration,
		"orbit_radius": 0.0,
		"orbit_angle": 0.0,
		"is_center": true
	})

	# Orbiting sub-cubes
	for i in range(cloud_sub_cubes):
		var cube_size = rng.randf_range(cloud_sub_cube_size_min, cloud_sub_cube_size_max)
		var cube = create_cloud_cube(cube_size)

		var orbit_angle = (i / float(cloud_sub_cubes)) * TAU
		var orbit_radius = cloud_orbit_radius * rng.randf_range(0.6, 1.0)

		# Timeline start offset
		var start_time = (i / float(cloud_sub_cubes)) * cloud_animation_duration

		cube.position = Vector3(
			cos(orbit_angle) * orbit_radius,
			rng.randf_range(-1.0, 1.0),
			sin(orbit_angle) * orbit_radius
		)

		cloud_root.add_child(cube)

		cloud_cubes.append({
			"node": cube,
			"start_time": start_time,
			"duration": cloud_animation_duration,
			"orbit_radius": orbit_radius,
			"orbit_angle": orbit_angle,
			"is_center": false,
			"base_y": cube.position.y
		})

func create_cloud_cube(size: float) -> MeshInstance3D:
	"""Create a rectangular cube for the cloud"""
	var cube = MeshInstance3D.new()

	var box = BoxMesh.new()
	box.size = Vector3(size, size, size)

	cube.mesh = box
	cube.material_override = cloud_material

	return cube

func _process(delta: float) -> void:
	animation_time += delta

	# Animate cube cloud with timeline
	for cube_data in cloud_cubes:
		var node = cube_data["node"]
		var start_time = cube_data["start_time"]
		var duration = cube_data["duration"]

		# Calculate timeline progress (loops)
		var timeline_time = fmod(animation_time, duration)

		# Calculate visibility based on timeline
		var time_since_start = timeline_time - start_time
		if time_since_start < 0:
			time_since_start += duration

		# Fade in/out window
		var fade_duration = duration * 0.15  # 15% of timeline for fade
		var visible_duration = duration * 0.5  # Visible for 50% of timeline

		var opacity = 0.0
		if time_since_start < fade_duration:
			# Fade in
			opacity = time_since_start / fade_duration
		elif time_since_start < visible_duration:
			# Fully visible
			opacity = 1.0
		elif time_since_start < visible_duration + fade_duration:
			# Fade out
			opacity = 1.0 - ((time_since_start - visible_duration) / fade_duration)
		else:
			# Invisible
			opacity = 0.0

		# Apply opacity to material
		if node.material_override and opacity > 0:
			var mat = node.material_override as StandardMaterial3D
			mat.albedo_color.a = cloud_color.a * opacity
			mat.emission_energy_multiplier = 1.0 * opacity
			node.visible = true
		else:
			node.visible = false

		# Animate position for non-center cubes
		if not cube_data["is_center"]:
			var orbit_radius = cube_data["orbit_radius"]
			var base_angle = cube_data["orbit_angle"]
			var base_y = cube_data["base_y"]

			# Orbit animation
			var orbit_speed = 0.3
			var current_angle = base_angle + animation_time * orbit_speed

			node.position = Vector3(
				cos(current_angle) * orbit_radius,
				base_y + sin(animation_time * 0.5) * 0.5,
				sin(current_angle) * orbit_radius
			)

func rebuild() -> void:
	"""Clear and rebuild the entire structure"""
	for child in get_children():
		child.queue_free()

	cloud_cubes.clear()
	animation_time = 0.0

	create_materials()
	build_inverted_tree()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
