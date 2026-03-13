extends Node3D

## Simple Oscillating Bridge
## Individual platform cubes that oscillate in X and Y based on sine/cosine
## Perfect for stepping from platform to platform

@export_group("Bridge Setup")
@export var num_platforms: int = 20  # Number of stepping platforms
@export var platform_spacing: float = 2.0  # Distance between platforms along Z
@export var platform_size: Vector3 = Vector3(1.5, 0.3, 1.5)  # Size of each platform

@export_group("Oscillation")
@export var oscillation_amplitude_x: float = 2.0  # How far platforms move in X (cosine)
@export var oscillation_amplitude_y: float = 1.5  # How far platforms move in Y (sine)
@export var oscillation_speed: float = 1.0  # Speed of oscillation
@export var phase_offset_per_platform: float = 0.3  # Phase shift between platforms

@export_group("Visual")
@export var use_gradient: bool = true
@export var base_color: Color = Color(0.5, 0.7, 1.0)
@export var emission_strength: float = 0.4

@export_group("Camera")
@export var camera_distance: float = 15.0
@export var camera_height: float = 8.0

# Internal
var platforms: Array[Node3D] = []
var time: float = 0.0

func _ready() -> void:
	generate_platforms()
	setup_camera()
	create_environment()
	print("SimpleOscillatingBridge: Created %d platforms" % num_platforms)

func _process(delta: float) -> void:
	time += delta * oscillation_speed
	update_platform_positions()

func generate_platforms() -> void:
	"""Create individual platform cubes"""
	platforms.clear()

	for i in range(num_platforms):
		var platform = create_platform(i)
		platforms.append(platform)
		add_child(platform)

		# Set initial position along Z axis
		var z_pos = i * platform_spacing
		platform.position.z = z_pos

func create_platform(index: int) -> Node3D:
	"""Create a single oscillating platform"""
	var platform_node = Node3D.new()
	platform_node.name = "Platform_%d" % index

	# Create visual mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Visual"
	var box_mesh = BoxMesh.new()
	box_mesh.size = platform_size
	mesh_instance.mesh = box_mesh

	# Create material with gradient
	var progress = float(index) / float(max(num_platforms - 1, 1))
	var platform_color = get_gradient_color(progress) if use_gradient else base_color

	var material = StandardMaterial3D.new()
	material.albedo_color = platform_color
	material.emission_enabled = true
	material.emission = platform_color * emission_strength
	material.metallic = 0.4
	material.roughness = 0.6
	mesh_instance.material_override = material

	platform_node.add_child(mesh_instance)

	# Create collision body
	var collision_body = StaticBody3D.new()
	collision_body.name = "CollisionBody"

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = platform_size
	collision_shape.shape = box_shape

	collision_body.add_child(collision_shape)
	platform_node.add_child(collision_body)

	# Store phase offset for this platform
	platform_node.set_meta("phase_offset", index * phase_offset_per_platform)

	return platform_node

func update_platform_positions() -> void:
	"""Update positions of all platforms based on sine/cosine"""
	for platform in platforms:
		if not is_instance_valid(platform):
			continue

		var phase = platform.get_meta("phase_offset", 0.0)
		var oscillation_angle = time + phase

		# X oscillation uses cosine (horizontal wave)
		var x_offset = cos(oscillation_angle) * oscillation_amplitude_x

		# Y oscillation uses sine (vertical wave)
		var y_offset = sin(oscillation_angle) * oscillation_amplitude_y

		# Keep Z position fixed, only oscillate in X and Y
		var base_z = platform.position.z
		platform.position = Vector3(x_offset, y_offset, base_z)

func setup_camera() -> void:
	"""Setup camera for good overview"""
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	add_child(camera)

	# Position camera to see the whole bridge
	var bridge_center_z = (num_platforms - 1) * platform_spacing * 0.5
	camera.position = Vector3(-camera_distance, camera_height, bridge_center_z)
	camera.look_at_from_position(camera.position, Vector3(0, 0, bridge_center_z), Vector3.UP)

func create_environment() -> void:
	"""Create lighting"""
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.position = Vector3(5, 10, 5)
	light.rotation_degrees = Vector3(-45, 45, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)

func get_gradient_color(progress: float) -> Color:
	"""Generate gradient color from blue to pink"""
	progress = clamp(progress, 0.0, 1.0)

	var blue_color = Color(0.2, 0.4, 1.0)
	var cyan_color = Color(0.0, 0.8, 1.0)
	var purple_color = Color(0.6, 0.3, 0.9)
	var pink_color = Color(1.0, 0.5, 0.8)

	if progress <= 0.33:
		return blue_color.lerp(cyan_color, progress * 3.0)
	elif progress <= 0.66:
		return cyan_color.lerp(purple_color, (progress - 0.33) * 3.0)
	else:
		return purple_color.lerp(pink_color, (progress - 0.66) * 3.0)

# Public API

func reset() -> void:
	"""Reset the bridge animation"""
	time = 0.0

func set_oscillation_speed(speed: float) -> void:
	"""Change oscillation speed"""
	oscillation_speed = speed

func set_amplitudes(x_amp: float, y_amp: float) -> void:
	"""Change oscillation amplitudes"""
	oscillation_amplitude_x = x_amp
	oscillation_amplitude_y = y_amp

func pause() -> void:
	"""Pause oscillation"""
	set_process(false)

func resume() -> void:
	"""Resume oscillation"""
	set_process(true)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

