extends Node3D

## Walkable Sine Bridge
## An interactive demonstration of the unit circle that creates a physical bridge
## following a sine wave path that players can walk across

@export_group("Bridge Parameters")
@export var bridge_length: float = 30.0  # Total length of the bridge
@export var bridge_width: float = 2.0    # Width of the walkable surface
@export var wave_amplitude: float = 3.0  # Height of the sine wave (radius equivalent)
@export var wave_frequency: float = 2.0  # Number of complete sine waves
@export var bridge_segments: int = 120   # Smoothness of the bridge

@export_group("Visual Style")
@export var use_gradient: bool = true
@export var bridge_color: Color = Color(0.6, 0.8, 1.0)
@export var emission_strength: float = 0.3
@export var show_unit_circle: bool = true
@export var show_projection_lines: bool = true

@export_group("Player Settings")
@export var player_speed: float = 5.0
@export var camera_follow_smoothing: float = 5.0
@export var spawn_player: bool = true

# Internal references
var bridge_mesh_instance: MeshInstance3D
var bridge_collision_body: StaticBody3D
var player: CharacterBody3D
var camera: Camera3D
var unit_circle_visual: Node3D

# Bridge path data
var bridge_points: PackedVector3Array = PackedVector3Array()

func _ready():
	generate_bridge()
	if show_unit_circle:
		create_unit_circle_reference()
	if spawn_player:
		create_player()
	setup_camera()
	create_environment()

func _process(delta: float):
	if player and camera:
		update_camera_follow(delta)

func generate_bridge():
	"""Generate the sine wave bridge geometry with collision"""
	bridge_points.clear()

	# Generate points along the sine wave
	for i in range(bridge_segments + 1):
		var t = float(i) / float(bridge_segments)
		var x = t * bridge_length
		var angle = t * wave_frequency * TAU
		var y = sin(angle) * wave_amplitude
		var z = 0.0
		bridge_points.append(Vector3(x, y, z))

	# Create the bridge mesh
	create_bridge_mesh()
	create_bridge_collision()

	# Add support pillars for visual interest
	if show_projection_lines:
		create_support_structures()

func create_bridge_mesh():
	"""Create a beautiful ribbon-like walkable surface"""
	bridge_mesh_instance = MeshInstance3D.new()
	bridge_mesh_instance.name = "BridgeSurface"
	add_child(bridge_mesh_instance)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	# Create the walkable surface
	for i in range(bridge_points.size() - 1):
		var current_point = bridge_points[i]
		var next_point = bridge_points[i + 1]

		# Calculate direction and perpendicular for width
		var direction = (next_point - current_point).normalized()
		var perpendicular = Vector3(0, 0, 1).normalized()  # Width goes in Z direction
		var half_width = bridge_width * 0.5

		# Calculate gradient color based on position
		var progress = float(i) / float(bridge_points.size() - 1)
		var gradient_color = get_gradient_color(progress) if use_gradient else bridge_color

		# Create vertices for this segment
		var base_index = vertices.size()

		# Bottom vertices
		vertices.append(current_point - perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0, progress))

		vertices.append(current_point + perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(1, progress))

		vertices.append(next_point - perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0, progress))

		vertices.append(next_point + perpendicular * half_width)
		colors.append(gradient_color)
		normals.append(Vector3.UP)
		uvs.append(Vector2(1, progress))

		# Create triangles
		indices.append(base_index)
		indices.append(base_index + 1)
		indices.append(base_index + 2)

		indices.append(base_index + 1)
		indices.append(base_index + 3)
		indices.append(base_index + 2)

	# Set up the mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	bridge_mesh_instance.mesh = mesh

	# Create material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = bridge_color * emission_strength
	material.metallic = 0.3
	material.roughness = 0.7
	bridge_mesh_instance.material_override = material

func create_bridge_collision():
	"""Create collision shape for the bridge"""
	bridge_collision_body = StaticBody3D.new()
	bridge_collision_body.name = "BridgeCollision"
	add_child(bridge_collision_body)

	var collision_shape = CollisionShape3D.new()
	var trimesh_shape = bridge_mesh_instance.mesh.create_trimesh_shape()
	collision_shape.shape = trimesh_shape
	bridge_collision_body.add_child(collision_shape)

func create_support_structures():
	"""Create vertical lines showing projection to ground plane"""
	var supports_container = Node3D.new()
	supports_container.name = "SupportStructures"
	add_child(supports_container)

	# Create supports at regular intervals
	var support_interval = max(int(bridge_segments / 15), 1)

	for i in range(0, bridge_segments + 1, support_interval):
		var point = bridge_points[i]
		var ground_point = Vector3(point.x, 0, point.z)

		# Create a thin line from bridge to ground
		var line = create_line_mesh(point, ground_point, 0.05)
		supports_container.add_child(line)

func create_line_mesh(from: Vector3, to: Vector3, thickness: float) -> MeshInstance3D:
	"""Create a line mesh between two points"""
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(thickness, thickness, 1.0)
	mesh_instance.mesh = box_mesh

	# Position and orient the line
	var delta = to - from
	var distance = delta.length()
	var midpoint = (from + to) * 0.5

	mesh_instance.position = midpoint
	if distance > 0.001:
		var direction = (to - from).normalized()
		var up_vector = Vector3.UP
		# Avoid colinear vectors by using a different up vector if needed
		if abs(direction.dot(Vector3.UP)) > 0.99:
			up_vector = Vector3.RIGHT
		mesh_instance.look_at_from_position(mesh_instance.position, to, up_vector)
	mesh_instance.scale.z = distance

	# Material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.6, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	return mesh_instance

func create_unit_circle_reference():
	"""Create a reference unit circle at the start of the bridge"""
	unit_circle_visual = Node3D.new()
	unit_circle_visual.name = "UnitCircleReference"
	add_child(unit_circle_visual)

	# Position it to the side of the bridge
	unit_circle_visual.position = Vector3(-5, wave_amplitude, 0)

	# Create circle outline
	var circle_segments = 48
	for i in range(circle_segments):
		var angle = float(i) / float(circle_segments) * TAU
		var next_angle = float(i + 1) / float(circle_segments) * TAU

		var pos1 = Vector3(cos(angle) * wave_amplitude, sin(angle) * wave_amplitude, 0)
		var pos2 = Vector3(cos(next_angle) * wave_amplitude, sin(next_angle) * wave_amplitude, 0)

		var segment = create_line_mesh(pos1, pos2, 0.03)
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.8, 0.9)
		material.emission_enabled = true
		material.emission = Color(0.8, 0.8, 0.9) * 0.4
		segment.material_override = material
		unit_circle_visual.add_child(segment)

	# Add axis lines
	var x_axis = create_line_mesh(
		Vector3(-wave_amplitude * 1.2, 0, 0),
		Vector3(wave_amplitude * 1.2, 0, 0),
		0.02
	)
	var y_axis = create_line_mesh(
		Vector3(0, -wave_amplitude * 1.2, 0),
		Vector3(0, wave_amplitude * 1.2, 0),
		0.02
	)
	unit_circle_visual.add_child(x_axis)
	unit_circle_visual.add_child(y_axis)

func create_player():
	"""Create a simple player controller"""
	player = CharacterBody3D.new()
	player.name = "Player"
	add_child(player)

	# Position at the start of the bridge
	player.position = bridge_points[0] + Vector3(0, 1.0, 0)

	# Create player visual (simple capsule)
	var mesh_instance = MeshInstance3D.new()
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.3
	capsule_mesh.height = 1.8
	mesh_instance.mesh = capsule_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.3)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.8, 0.3) * 0.5
	mesh_instance.material_override = material
	mesh_instance.position.y = 0.9
	player.add_child(mesh_instance)

	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.3
	capsule_shape.height = 1.8
	collision_shape.shape = capsule_shape
	collision_shape.position.y = 0.9
	player.add_child(collision_shape)

func _physics_process(delta: float):
	if not player:
		return

	# Simple player movement
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1.0
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("ui_down"):
		input_dir.z += 1.0
	if Input.is_action_pressed("ui_up"):
		input_dir.z -= 1.0

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

	player.velocity.x = input_dir.x * player_speed
	player.velocity.z = input_dir.z * player_speed

	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * delta

	player.move_and_slide()

func setup_camera():
	"""Setup camera to follow the player or provide a good overview"""
	camera = Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)

	if spawn_player and player:
		# Position camera behind and above player
		camera.position = player.position + Vector3(-5, 5, 3)
		camera.look_at_from_position(camera.position, player.position, Vector3.UP)
	else:
		# Position for overview of entire bridge
		var bridge_center = bridge_points[bridge_segments / 2]
		camera.position = bridge_center + Vector3(-bridge_length * 0.3, bridge_length * 0.3, bridge_width * 3)
		camera.look_at_from_position(camera.position, bridge_center, Vector3.UP)

func update_camera_follow(delta: float):
	"""Smoothly follow the player with the camera"""
	if not player or not camera:
		return

	var target_pos = player.position + Vector3(-5, 5, 3)
	camera.position = camera.position.lerp(target_pos, camera_follow_smoothing * delta)

	var look_target = player.position + Vector3(2, 0, 0)
	var current_forward = -camera.global_transform.basis.z
	var desired_forward = (look_target - camera.global_position).normalized()
	var new_forward = current_forward.lerp(desired_forward, camera_follow_smoothing * delta)

	if new_forward.length() > 0.001:
		camera.look_at_from_position(camera.position, camera.global_position + new_forward, Vector3.UP)

func create_environment():
	"""Create lighting and environment"""
	# Directional light
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.position = Vector3(0, 10, 0)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

	# Ambient light
	var env_light = Node3D.new()
	env_light.name = "AmbientLight"
	add_child(env_light)

func get_gradient_color(progress: float) -> Color:
	"""Generate a blue-pink gradient color based on progress (0.0 to 1.0)"""
	progress = clamp(progress, 0.0, 1.0)

	# Multi-stage gradient matching the unit circle visualization
	var blue_color = Color(0.1, 0.3, 1.0, 1.0)
	var cyan_color = Color(0.0, 0.8, 1.0, 1.0)
	var purple_color = Color(0.6, 0.2, 0.9, 1.0)
	var magenta_color = Color(1.0, 0.2, 0.8, 1.0)
	var pink_color = Color(1.0, 0.4, 0.9, 1.0)

	if progress <= 0.25:
		return blue_color.lerp(cyan_color, progress * 4.0)
	elif progress <= 0.5:
		return cyan_color.lerp(purple_color, (progress - 0.25) * 4.0)
	elif progress <= 0.75:
		return purple_color.lerp(magenta_color, (progress - 0.5) * 4.0)
	else:
		return magenta_color.lerp(pink_color, (progress - 0.75) * 4.0)

func restart():
	"""Reset the scene"""
	if player:
		player.position = bridge_points[0] + Vector3(0, 1.0, 0)
		player.velocity = Vector3.ZERO
