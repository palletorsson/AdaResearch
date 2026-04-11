@tool
extends Node3D

# Parametric Pendulum Waves
# Array of pendulums with carefully chosen lengths creating wave patterns
# Famous physics demonstration: "pendulum snake" or "pendulum wave"

@export_group("Pendulum Array")
@export var num_pendulums: int = 15
@export var pendulum_spacing: float = 0.3
@export var base_height: float = 2.5

@export_group("Length Variation")
@export var shortest_length: float = 0.8
@export var longest_length: float = 1.5
@export var length_profile: String = "Linear"  # Linear, Quadratic, or Custom

@export_group("Physics")
@export var gravity: float = 9.8
@export var damping: float = 0.998
@export var release_all: bool = false  # Release all pendulums at once

@export_group("Visualization")
@export var bob_radius: float = 0.08
@export var rod_thickness: float = 0.02
@export var show_pivot_bar: bool = true
@export var trail_length: int = 100
@export var color_by_index: bool = true

@export_group("Animation")
@export var auto_release: bool = true
@export var release_angle: float = 0.5  # Initial angle in radians (about 30°)
@export var show_phase_info: bool = true

# Internal data
var pendulums: Array[Dictionary] = []
var time_since_release: float = 0.0
var is_released: bool = false
var trail_points: Array[Array] = []

func _ready() -> void:
	_build_pendulum_array()
	if auto_release:
		_release_pendulums()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if release_all and not is_released:
		_release_pendulums()
		release_all = false

	if is_released:
		time_since_release += delta
		_update_pendulums(delta)
		_update_visualization()

func _build_pendulum_array() -> void:
	# Clear existing
	for child in get_children():
		child.queue_free()

	pendulums.clear()
	trail_points.clear()

	# Create pivot bar
	if show_pivot_bar:
		_create_pivot_bar()

	# Calculate pendulum lengths using parametric formula
	# T = 2π√(L/g)
	# For wave effect: choose lengths so periods form arithmetic sequence
	var target_cycles_in_time = 60.0  # seconds for full recurrence
	var min_oscillations = 51  # Minimum number of complete cycles
	var max_oscillations = min_oscillations + num_pendulums - 1

	for i in range(num_pendulums):
		var fraction = float(i) / max(1.0, float(num_pendulums - 1))

		# Calculate oscillations for this pendulum
		var oscillations = lerp(float(min_oscillations), float(max_oscillations), fraction)

		# Period: time for one complete swing
		var period = target_cycles_in_time / oscillations

		# From T = 2π√(L/g), we get L = (T/(2π))² * g
		var length = pow(period / TAU, 2.0) * gravity

		# Clamp to reasonable values
		length = clamp(length, shortest_length, longest_length)

		var pendulum_data = {
			"index": i,
			"length": length,
			"angle": 0.0,  # Current angle (radians)
			"angular_velocity": 0.0,
			"angular_acceleration": 0.0,
			"oscillations": oscillations,
			"period": period,
			"pivot_position": Vector3(
				(i - (num_pendulums - 1) / 2.0) * pendulum_spacing,
				base_height,
				0.0
			)
		}

		pendulums.append(pendulum_data)
		trail_points.append([])

		# Create visual components
		_create_pendulum_visual(pendulum_data)

func _create_pivot_bar() -> void:
	"""Create horizontal bar showing pivot points"""
	var bar_width = num_pendulums * pendulum_spacing + pendulum_spacing
	var bar = MeshInstance3D.new()
	bar.name = "PivotBar"

	var box = BoxMesh.new()
	box.size = Vector3(bar_width, 0.05, 0.05)
	bar.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.3)
	mat.metallic = 0.0
	mat.roughness = 1.0
	bar.material_override = mat

	bar.position = Vector3(0, base_height, 0)
	add_child(bar)

func _create_pendulum_visual(pend: Dictionary) -> void:
	"""Create rod and bob for pendulum"""
	var container = Node3D.new()
	container.name = "Pendulum_%d" % pend.index
	container.position = pend.pivot_position
	add_child(container)

	# Bob (sphere at end)
	var bob = MeshInstance3D.new()
	bob.name = "Bob"

	var sphere = SphereMesh.new()
	sphere.radius = bob_radius
	sphere.height = bob_radius * 2.0
	bob.mesh = sphere

	var color: Color
	if color_by_index:
		var hue = float(pend.index) / float(num_pendulums)
		color = Color.from_hsv(hue, 0.8, 1.0)
	else:
		color = Color(0.9, 0.3, 0.3)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	bob.material_override = mat

	container.add_child(bob)

	# Rod (cylinder from pivot to bob)
	var rod = MeshInstance3D.new()
	rod.name = "Rod"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = rod_thickness
	cylinder.bottom_radius = rod_thickness
	cylinder.height = pend.length
	rod.mesh = cylinder

	var rod_mat = StandardMaterial3D.new()
	rod_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.7)
	rod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rod_mat.metallic = 0.0
	rod_mat.roughness = 1.0
	rod.material_override = rod_mat

	container.add_child(rod)

func _release_pendulums() -> void:
	"""Release all pendulums from starting angle"""
	for pend in pendulums:
		pend.angle = release_angle
		pend.angular_velocity = 0.0

	is_released = true
	time_since_release = 0.0

func _update_pendulums(delta: float) -> void:
	"""Update pendulum physics using simple harmonic approximation"""
	for pend in pendulums:
		# For small angles: θ'' = -(g/L) * θ
		# This gives simple harmonic motion with ω = √(g/L)

		# Angular acceleration from gravity
		pend.angular_acceleration = -(gravity / pend.length) * sin(pend.angle)

		# Update using Euler integration (or use more accurate integrator)
		pend.angular_velocity += pend.angular_acceleration * delta
		pend.angular_velocity *= damping  # Apply damping
		pend.angle += pend.angular_velocity * delta

func _update_visualization() -> void:
	"""Update visual position of pendulums"""
	for i in range(pendulums.size()):
		var pend = pendulums[i]
		var container_name = "Pendulum_%d" % i
		var container = get_node_or_null(NodePath(container_name))

		if not container:
			continue

		# Calculate bob position
		var angle = pend.angle
		var length = pend.length
		var bob_offset = Vector3(
			sin(angle) * length,
			-cos(angle) * length,
			0.0
		)

		# Update bob
		var bob = container.get_node_or_null("Bob")
		if bob:
			bob.position = bob_offset

			# Update trail
			var world_pos = container.global_position + bob_offset
			trail_points[i].append(world_pos)
			if trail_points[i].size() > trail_length:
				trail_points[i].pop_front()

		# Update rod position and rotation
		var rod = container.get_node_or_null("Rod")
		if rod:
			rod.position = bob_offset * 0.5
			rod.rotation.z = angle

func get_bob_position(index: int) -> Vector3:
	"""Get world position of specific pendulum bob"""
	if index >= 0 and index < pendulums.size():
		var pend = pendulums[index]
		var container_name = "Pendulum_%d" % index
		var container = get_node_or_null(NodePath(container_name))
		if container:
			var angle = pend.angle
			var length = pend.length
			var bob_offset = Vector3(sin(angle) * length, -cos(angle) * length, 0.0)
			return container.global_position + bob_offset
	return Vector3.ZERO

func get_wave_phase() -> float:
	"""Get current phase of the wave pattern (0 to 1)"""
	# The wave repeats when all pendulums return to start
	# This happens at the least common multiple of all periods
	if pendulums.size() == 0:
		return 0.0

	var first_period = pendulums[0].period if pendulums.size() > 0 else 1.0
	return fmod(time_since_release / first_period, 1.0)

func reset() -> void:
	"""Reset all pendulums to starting position"""
	is_released = false
	time_since_release = 0.0
	for pend in pendulums:
		pend.angle = 0.0
		pend.angular_velocity = 0.0
	for trail in trail_points:
		trail.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
