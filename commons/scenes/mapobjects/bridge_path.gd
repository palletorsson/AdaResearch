# bridge_path.gd - A transparent grid bridge that spans voids
# Creates a walkable path of translucent green grid cubes between two points
# Usage in map_data.json utilities layer: "br:AXIS:LENGTH" e.g. "br:z:3", "br:-x:2"
extends Node3D

class_name BridgePath

# Configuration
@export var bridge_length: int = 4  # Number of bridge segments
@export var bridge_axis: String = "x"  # "x" or "z" axis
@export var cube_size: float = 1.0  # Size of each bridge segment

# Visual settings
@export var bridge_color: Color = Color(0.2, 0.5, 1.0, 0.15)  # Blue, very transparent
@export var wireframe_color: Color = Color(0.3, 0.6, 1.0, 0.6)  # Blue wireframe
@export var emission_color: Color = Color(0.2, 0.4, 1.0, 1.0)  # Blue glow
@export var emission_strength: float = 1.5
@export var pulse_speed: float = 1.0  # Pulsing glow speed (0 = no pulse)

# Internal
var bridge_segments: Array[StaticBody3D] = []
var bridge_material: ShaderMaterial
var time_passed: float = 0.0

func _ready() -> void:
	_create_bridge_material()
	_generate_bridge()
	print("BridgePath: Created %d-segment bridge along %s axis" % [bridge_length, bridge_axis])

func _process(delta: float) -> void:
	if pulse_speed > 0.0 and bridge_material:
		time_passed += delta
		var pulse = 0.8 + 0.4 * sin(time_passed * pulse_speed * TAU)
		bridge_material.set_shader_parameter("emission_strength", emission_strength * pulse)

func _create_bridge_material() -> void:
	# Try to load the project's Grid.gdshader for consistent look
	var shader = load("res://commons/resourses/shaders/Grid.gdshader") as Shader
	if not shader:
		# Fallback: use StandardMaterial3D
		push_warning("BridgePath: Grid.gdshader not found, using fallback material")
		return

	bridge_material = ShaderMaterial.new()
	bridge_material.shader = shader
	bridge_material.render_priority = 1  # Render after opaque geometry

	# Green transparent bridge look
	bridge_material.set_shader_parameter("modelColor", bridge_color)
	bridge_material.set_shader_parameter("wireframeColor", wireframe_color)
	bridge_material.set_shader_parameter("emissionColor", emission_color)
	bridge_material.set_shader_parameter("emission_strength", emission_strength)
	bridge_material.set_shader_parameter("width", 3.0)  # Thicker wireframe for visibility
	bridge_material.set_shader_parameter("blur", 1.5)
	bridge_material.set_shader_parameter("show_interior", true)

	# Transparency is handled by the shader itself (Grid.gdshader alpha)
	# ShaderMaterial does not have a transparency property like StandardMaterial3D

func _generate_bridge() -> void:
	var direction := Vector3.ZERO
	match bridge_axis.to_lower():
		"x": direction = Vector3(1, 0, 0)
		"z": direction = Vector3(0, 0, 1)
		"-x": direction = Vector3(-1, 0, 0)
		"-z": direction = Vector3(0, 0, -1)
		_: direction = Vector3(1, 0, 0)

	for i in range(bridge_length):
		var segment := _create_segment(i)
		segment.position = direction * float(i) * cube_size + Vector3(0, 0.5, 0)
		add_child(segment)
		bridge_segments.append(segment)

func _create_segment(index: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "BridgeSegment_%d" % index

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var box := BoxMesh.new()
	box.size = Vector3(cube_size * 0.98, cube_size * 0.2, cube_size * 0.98)  # Thin slab
	mesh_instance.mesh = box

	if bridge_material:
		mesh_instance.material_override = bridge_material
	else:
		# Fallback material
		var mat := StandardMaterial3D.new()
		mat.albedo_color = bridge_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_strength
		mesh_instance.material_override = mat

	body.add_child(mesh_instance)

	# Collision shape — full cube height so player can walk on it
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(cube_size * 0.98, cube_size * 0.2, cube_size * 0.98)
	collision.shape = shape
	body.add_child(collision)

	# Add to grid_cubes group for raycast compatibility
	body.add_to_group("grid_cubes")

	return body

# ===== Public API =====

func set_bridge_parameters(length: int, axis: String) -> void:
	bridge_length = length
	bridge_axis = axis
	# Regenerate if already in tree
	if is_inside_tree():
		_clear_segments()
		_generate_bridge()

func _clear_segments() -> void:
	for seg in bridge_segments:
		if is_instance_valid(seg):
			seg.queue_free()
	bridge_segments.clear()

# ===== Parameter parsing =====

static func parse_parameters(param_string: String) -> Dictionary:
	## Parse parameter string like 'z:3' or '-x:2' (AXIS:LENGTH format)
	var result = {"length": 4, "axis": "x"}

	if param_string.is_empty():
		return result

	var parts = param_string.split(":")
	if parts.size() >= 1:
		var axis_str = parts[0].strip_edges().to_lower()
		if axis_str in ["x", "z", "-x", "-z"]:
			result.axis = axis_str

	if parts.size() >= 2 and parts[1].is_valid_int():
		result.length = int(parts[1])

	return result
