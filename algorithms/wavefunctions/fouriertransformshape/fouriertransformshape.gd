# Main scene script - attach to a Node3D
extends Node3D

const LIGHT_COUNT := 8
const LIGHT_SPAWN_TIME := TAU

# Wheel configuration - frequency, radius, phase
var wheels = [
	{"freq": 1.0, "radius": 2.0, "phase": 0.0},
	{"freq": 3.0, "radius": 0.8, "phase": 0.0},
	{"freq": 5.0, "radius": 0.4, "phase": PI / 2},
	{"freq": 7.0, "radius": 0.2, "phase": PI / 4}
]

var wheel_nodes = []
var connection_lines = []
var trace_points = []
var trace_line: Line3D
var time = 0.0
var trace_material: StandardMaterial3D
var light_nodes: Array = []
var lights_spawned := false

func _ready():
	setup_camera()
	setup_wheels()
	setup_trace()

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 3, 8)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	add_child(camera)

func setup_wheels():
	# Create materials
	var wheel_material = StandardMaterial3D.new()
	wheel_material.albedo_color = Color.CYAN
	wheel_material.emission_enabled = true
	wheel_material.emission = Color.CYAN
	wheel_material.emission_energy_multiplier = 0.6

	var connection_material = StandardMaterial3D.new()
	connection_material.albedo_color = Color.WHITE
	connection_material.emission_enabled = true
	connection_material.emission = Color(0.9, 0.95, 1.0)
	connection_material.emission_energy_multiplier = 1.0

	var center_pos = Vector3.ZERO

	for i in range(wheels.size()):
		var wheel_data = wheels[i]

		# Create wheel (torus)
		var wheel_mesh = TorusMesh.new()
		wheel_mesh.inner_radius = wheel_data.radius * 0.8
		wheel_mesh.outer_radius = wheel_data.radius
		wheel_mesh.rings = 16
		wheel_mesh.ring_segments = 32

		var wheel_node = MeshInstance3D.new()
		wheel_node.mesh = wheel_mesh
		wheel_node.material_override = wheel_material
		wheel_node.position = center_pos
		add_child(wheel_node)
		wheel_nodes.append(wheel_node)

		# Create connection line to next wheel (or trace point for last wheel)
		var line_mesh = CylinderMesh.new()
		line_mesh.top_radius = 0.04
		line_mesh.bottom_radius = 0.04
		line_mesh.height = 1.0

		var line_node = MeshInstance3D.new()
		line_node.mesh = line_mesh
		line_node.material_override = connection_material
		add_child(line_node)
		connection_lines.append(line_node)

func setup_trace():
	trace_material = StandardMaterial3D.new()
	trace_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trace_material.albedo_color = Color(1.0, 0.85, 0.2)
	trace_material.emission_enabled = true
	trace_material.emission = Color(1.0, 0.85, 0.3)
	trace_material.emission_energy_multiplier = 2.0
	trace_material.vertex_color_use_as_albedo = true
	trace_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	trace_line = Line3D.new()
	trace_line.width = 0.12
	# Use the custom Line3D implementation found in core/line3d.gd
	# which supports width, default_color, texture_mode and material_override.
	trace_line.texture_mode = Line3D.TEXTURE_MODE.TEXTURE_MODE_TILE
	trace_line.default_color = Color(1.0, 0.9, 0.4, 0.9)
	trace_line.material_override = trace_material
	add_child(trace_line)

func _process(delta):
	time += delta * 0.5  # Control animation speed

	update_wheels()
	update_trace()
	ensure_trace_lights()

func update_wheels():
	var current_pos = Vector3.ZERO

	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		var wheel_node = wheel_nodes[i]
		var line_node = connection_lines[i]

		# Calculate wheel rotation
		var angle = time * wheel_data.freq + wheel_data.phase
		wheel_node.rotation.z = angle

		# Position wheel at current position
		wheel_node.position = current_pos

		# Calculate next position (end of this wheel's arm)
		var arm_end = current_pos + Vector3(
			cos(angle) * wheel_data.radius,
			sin(angle) * wheel_data.radius,
			0
		)

		# Update connection line
		var line_center = (current_pos + arm_end) / 2
		var line_direction = (arm_end - current_pos).normalized()
		var line_length = current_pos.distance_to(arm_end)

		line_node.position = line_center
		line_node.scale.y = line_length

		# Rotate line to point in correct direction
		if line_direction.length() > 0:
			var up = Vector3.UP
			if abs(line_direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			var right = line_direction.cross(up).normalized()
			up = right.cross(line_direction).normalized()
			line_node.basis = Basis(right, line_direction, up)

		current_pos = arm_end

	# Add current end position to trace
	if trace_points.size() < 1000:  # Limit trace length
		trace_points.append(current_pos)
	else:
		trace_points.pop_front()
		trace_points.append(current_pos)

func update_trace():
	trace_line.clear_points()

	if trace_points.size() < 2:
		return

	for i in range(trace_points.size()):
		trace_line.add_point(trace_points[i])

func ensure_trace_lights():
	if lights_spawned:
		return
	if time < LIGHT_SPAWN_TIME:
		return
	if trace_points.is_empty():
		return

	var spacing = max(1, trace_points.size() / LIGHT_COUNT)
	for i in range(0, trace_points.size(), spacing):
		if light_nodes.size() >= LIGHT_COUNT:
			break

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.4)
		light.light_energy = 1.6
		light.omni_range = 2.8
		light.shadow_enabled = false
		light.position = trace_points[i]
		add_child(light)
		light_nodes.append(light)

	if light_nodes.size() > 0:
		lights_spawned = true
